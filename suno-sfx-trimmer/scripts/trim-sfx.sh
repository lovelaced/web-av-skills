#!/usr/bin/env bash
#
# trim-sfx.sh — Trim Suno Sounds WAV output to target durations, export MP3
#
# Usage:
#   ./trim-sfx.sh [options] [input_dir] [output_dir]
#
# Options:
#   -d DURATION   Target duration in seconds (default: 1.0)
#   -f FADE_OUT   Fade-out duration in seconds (default: auto based on duration)
#   -c CONFIG     Config file mapping filenames to duration:fade_out
#   -h            Show this help
#
# Config file format (one entry per line):
#   stem duration:fade_out
#   Example:
#     reveal-boom 0.6:0.03
#     card-flip 0.15:0.01
#     ambient-tone 8.0:0.3
#
# Files not listed in the config use the default duration/fade.
#
# Pipeline per file:
#   1. Per-frame RMS analysis (astats) to find the loudest moment
#   2. Trim a window around the peak in PCM domain (sample-accurate)
#   3. Apply tiny fade-in/out to prevent clicks
#   4. Two-pass peak normalize to -1 dBFS
#   5. Encode to MP3 (libmp3lame -q:a 2)
#   6. Generate before/after waveform PNGs for visual QA

set -euo pipefail

DEFAULT_DURATION="1.0"
DEFAULT_FADE=""
CONFIG_FILE=""

usage() {
  sed -n '3,/^$/s/^#//p' "$0"
  exit 0
}

while getopts "d:f:c:h" opt; do
  case "$opt" in
    d) DEFAULT_DURATION="$OPTARG" ;;
    f) DEFAULT_FADE="$OPTARG" ;;
    c) CONFIG_FILE="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

INPUT_DIR="${1:-./raw}"
OUTPUT_DIR="${2:-./sfx}"
WAVE_DIR="./waveforms"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v ffmpeg &>/dev/null; then
  echo "Error: ffmpeg is required but not found." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR" "$WAVE_DIR"

# Auto-calculate fade-out based on duration if not explicitly set.
auto_fade() {
  local dur="$1"
  awk "BEGIN {
    if ($dur < 0.2)       printf \"0.01\"
    else if ($dur < 0.5)  printf \"0.02\"
    else if ($dur < 1.5)  printf \"0.03\"
    else                  printf \"0.1\"
  }"
}

# Load config file into an associative array if provided.
declare -A CONFIG_MAP
if [ -n "$CONFIG_FILE" ]; then
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config file not found: $CONFIG_FILE" >&2
    exit 1
  fi
  while IFS=' ' read -r stem target; do
    # Skip blank lines and comments
    [[ -z "$stem" || "$stem" == \#* ]] && continue
    CONFIG_MAP["$stem"]="$target"
  done < "$CONFIG_FILE"
fi

# Returns "duration:fade_out" for a given filename stem.
get_target() {
  local stem="$1"
  local duration fade_out

  # Check config map first
  if [ -n "${CONFIG_MAP[$stem]+x}" ]; then
    echo "${CONFIG_MAP[$stem]}"
    return
  fi

  # Fall back to defaults
  duration="$DEFAULT_DURATION"
  if [ -n "$DEFAULT_FADE" ]; then
    fade_out="$DEFAULT_FADE"
  else
    fade_out=$(auto_fade "$duration")
  fi
  echo "${duration}:${fade_out}"
}

# Find the timestamp of peak RMS loudness using per-frame astats.
find_peak_time() {
  local file="$1"
  local peak_time
  peak_time=$(ffmpeg -i "$file" \
    -af "astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level:file=-" \
    -f null - 2>/dev/null \
    | awk '
      /^frame:/ {
        n = split($0, p, " ")
        for (i = 1; i <= n; i++)
          if (p[i] ~ /^pts_time:/)
            { split(p[i], t, ":"); time = t[2] + 0 }
      }
      /^lavfi\.astats\.Overall\.RMS_level=/ {
        split($0, a, "=")
        val = a[2] + 0
        if (val > max || NR <= 2) { max = val; max_time = time }
      }
      END { printf "%.4f", max_time }
    ') || true
  echo "${peak_time:-0.0}"
}

# Get duration of a file in seconds
file_duration() {
  ffprobe -v error -show_entries format=duration -of csv=p=0 "$1" 2>/dev/null
}

# Generate a waveform PNG
make_waveform() {
  local file="$1" out="$2"
  ffmpeg -y -hide_banner -loglevel error \
    -i "$file" \
    -filter_complex "showwavespic=s=800x120:colors=0x44aaff" \
    -frames:v 1 "$out"
}

echo "=== SFX Trimmer ==="
echo "Input:  $INPUT_DIR (WAV)"
echo "Output: $OUTPUT_DIR (MP3)"
echo "Waves:  $WAVE_DIR"
[ -n "$CONFIG_FILE" ] && echo "Config: $CONFIG_FILE"
echo "Default: ${DEFAULT_DURATION}s duration"
echo ""

processed=0

for file in "$INPUT_DIR"/*.wav; do
  [ -f "$file" ] || continue

  filename=$(basename "$file")
  stem="${filename%.wav}"
  target=$(get_target "$stem")

  duration="${target%%:*}"
  fade_out="${target##*:}"

  raw_dur=$(file_duration "$file")

  # Find the loudest moment
  peak_time=$(find_peak_time "$file")

  # Place trim window: peak at ~20% into the window
  offset_before=$(printf "%.4f" "$(echo "$duration * 0.2" | bc -l)")
  start=$(printf "%.4f" "$(echo "$peak_time - $offset_before" | bc -l)")

  # Clamp start >= 0
  if [ "$(echo "$start < 0" | bc -l)" = "1" ]; then
    start="0.0000"
  fi

  # Clamp so we don't run past end of file
  max_start=$(printf "%.4f" "$(echo "$raw_dur - $duration" | bc -l)")
  if [ "$(echo "$max_start < 0" | bc -l)" = "1" ]; then
    max_start="0.0000"
  fi
  if [ "$(echo "$start > $max_start" | bc -l)" = "1" ]; then
    start="$max_start"
  fi

  fade_in="0.005"
  fade_start=$(printf "%.4f" "$(echo "$duration - $fade_out" | bc -l)")

  echo "TRIM  $stem  raw=${raw_dur}s  peak=${peak_time}s  start=${start}s  dur=${duration}s  fade=${fade_out}s"

  # Waveform of raw input
  make_waveform "$file" "$WAVE_DIR/${stem}-raw.png"

  # Trim + fades using atrim filter (avoids -ss + -af interaction bug)
  tmp_trimmed="$TMP_DIR/${stem}.wav"
  ffmpeg -y -hide_banner -loglevel error \
    -i "$file" \
    -af "atrim=start=${start}:duration=${duration},asetpts=PTS-STARTPTS,afade=t=in:st=0:d=${fade_in},afade=t=out:st=${fade_start}:d=${fade_out}" \
    -acodec pcm_s16le \
    "$tmp_trimmed"

  # Two-pass peak normalize to -1 dBFS, encode to MP3
  max_vol=$(ffmpeg -i "$tmp_trimmed" -af "volumedetect" -f null /dev/null 2>&1 \
    | grep "max_volume" | awk '{print $5}')

  if [ -n "$max_vol" ]; then
    gain=$(printf "%.2f" "$(echo "-1.0 - $max_vol" | bc -l)")
  else
    gain="0.00"
  fi

  ffmpeg -y -hide_banner -loglevel error \
    -i "$tmp_trimmed" \
    -af "volume=${gain}dB" \
    -codec:a libmp3lame -q:a 2 \
    "$OUTPUT_DIR/${stem}.mp3"

  # Waveform of trimmed output
  make_waveform "$OUTPUT_DIR/${stem}.mp3" "$WAVE_DIR/${stem}-trimmed.png"

  rm -f "$tmp_trimmed"
  processed=$((processed + 1))
done

echo ""
echo "Done. $processed file(s) trimmed."
echo "Output in: $OUTPUT_DIR/"
echo "Waveforms in: $WAVE_DIR/"
