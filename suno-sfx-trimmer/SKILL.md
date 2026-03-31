---
name: suno-sfx-trimmer
description: Generate Suno Sounds prompts for game/app SFX and auto-trim the output to precise durations using ffmpeg. Use when user asks to create sound effects, write Suno prompts for SFX, trim audio files to target durations, batch process game audio, or normalize sound effects. Triggers on "Suno sound effects", "SFX prompts", "trim audio", "sound effect generation", "game audio", "booster pack sounds", "normalize SFX". Do NOT use for music production, full song generation, or non-SFX audio work.
metadata:
  author: burrito
  version: 1.0.0
  category: audio
  tags: [suno, sfx, audio, ffmpeg, game-audio]
---

# Suno SFX Trimmer

End-to-end workflow for generating short sound effects with Suno Sounds and auto-trimming them to exact durations using ffmpeg. Built for game UI, app interactions, and interactive experiences.

## When to Use

- Writing Suno Sounds prompts optimized for SFX (not music)
- Batch trimming AI-generated audio to precise durations
- Normalizing a set of sound effects to consistent loudness
- Building an SFX spec for interactive experiences (games, apps, pack openings)

## Prerequisites

- **ffmpeg** (with libmp3lame) installed and on PATH
- **Suno** account with access to the Sounds feature (Create > Custom > Sounds)
- Raw audio files as **WAV** (not MP3 -- Suno offers WAV downloads, always prefer them)

## Part 1: Writing Suno Sounds Prompts

### Prompt Structure

Suno Sounds prompts should be concise and use recognizable audio vocabulary. Each prompt should specify:

1. **Type**: One Shot (single sound) or Loop (seamless repeating)
2. **Key**: Always specify a musical key, even for non-tonal SFX -- it anchors the resonant frequency
3. **Prompt text**: 1-2 sentences of clear, evocative description
4. **Duration note**: Suno has no precise duration control, so generate long and trim in post

### Key Scheme Strategy

Use a consistent key scheme so layered sounds never clash:
- **Minor key** (e.g., C minor) for tension, atmosphere, anticipation
- **Major key** (e.g., C major) for rewards, positive moments, resolution
- Keep everything in the same root note (e.g., all in C) so simultaneous sounds harmonize

### Prompt Best Practices

**DO:**
- Use evocative, physical descriptions: "glass-shattering sparkle", "treasure chest bursting open"
- Name specific sound qualities: "whoosh", "chime", "rumble", "shimmer", "crinkle"
- Describe the emotional quality: "satisfying", "ethereal", "weighty", "crisp"
- Use analogies: "like tiny metal confetti hitting a surface"

**DON'T:**
- Use Hz frequency ranges (Suno ignores "40-60Hz" -- say "deep sub-bass" instead)
- Use overly technical audio terms (no "8-12kHz transient" -- say "bright crystalline top end")
- Write prompts longer than ~200 characters
- Use contradictory descriptors

### Example Prompts

```
Type: One Shot | Key: C minor
Prompt: Deep bass boom with bright glass-shattering sparkle on top. Heavy sub-bass
hit layered with sharp crystalline chime transient. Magical impact, powerful but
contained. Like a treasure chest bursting open.
```

```
Type: One Shot | Key: C major
Prompt: Three-note ascending arpeggio C-E-G with crystalline sparkle burst at the
peak. Musical phrase rising into a wash of bright shimmering particles. Exciting
and celebratory.
```

```
Type: Loop | Key: C minor
Prompt: Quiet high-frequency twinkling sparkle. Tiny crystal bells catching light.
Magical shimmering texture, very soft and delicate. Seamless ambient shimmer.
```

### Suno Sounds Workflow

1. Go to **Suno > Create > Custom > Sounds**
2. Set **Type** (One Shot or Loop)
3. Set **Key** as specified
4. Paste the prompt text
5. Generate -- Suno produces 2 takes per prompt
6. Listen to both, download the best as **WAV**
7. Name the file to match your spec (e.g., `reveal-boom.wav`)

## Part 2: Auto-Trimming with trim-sfx.sh

### How It Works

The trimmer script (`trim-sfx.sh`) processes each WAV file through this pipeline:

1. **Peak detection** via `astats` -- finds the loudest moment using per-frame RMS analysis (~24ms resolution)
2. **Window placement** -- positions the trim window so the peak is ~20% in (captures attack + sustain/tail)
3. **Trim** via `atrim` filter -- sample-accurate extraction in the filter graph
4. **Fade in/out** -- 5ms fade-in, auto-calculated fade-out (10-100ms based on duration) to prevent clicks
5. **Peak normalize** -- two-pass `volumedetect` + `volume` to hit -1 dBFS
6. **Encode** to MP3 via libmp3lame at quality 2
7. **Waveform PNGs** generated for visual QA (raw vs trimmed)

### Usage

```bash
# Trim all WAVs to 1.0s (default) with auto fade-out
./trim-sfx.sh ./raw ./sfx

# Trim all WAVs to a specific duration
./trim-sfx.sh -d 0.5 ./raw ./sfx

# Trim with explicit duration and fade-out
./trim-sfx.sh -d 0.5 -f 0.03 ./raw ./sfx

# Use a config file for per-file durations
./trim-sfx.sh -c sfx-config.txt ./raw ./sfx
```

Trimmed MP3s appear in the output dir, waveform PNGs in `./waveforms/`.

### Config File

For projects with many sounds at different durations, create a config file (one entry per line):

```
# stem  duration:fade_out
reveal-boom 0.6:0.03
card-flip 0.15:0.01
ambient-tone 8.0:0.3
```

Files not listed in the config fall back to the default duration (`-d` flag, or 1.0s).

### Fade-Out Guidelines

If you don't specify a fade-out, the script auto-calculates one based on duration:

| Duration | Auto Fade-Out |
|----------|---------------|
| < 0.2s   | 10ms          |
| 0.2-0.5s | 20ms          |
| 0.5-1.5s | 30ms          |
| > 1.5s   | 100ms         |

Override with `-f` globally or per-file in the config.

### Visual QA

After running, check `waveforms/` for before/after PNGs:
- `*-raw.png` shows the full Suno output with audio placement
- `*-trimmed.png` shows the extracted, normalized clip
- If a trimmed waveform looks empty, the peak detection may have found the wrong region -- check the raw waveform to understand the file's structure

## Critical Technical Decisions (and Why)

These were learned through debugging. Consult `references/ffmpeg-pitfalls.md` for full details.

### Use `atrim` filter, NOT `-ss` flag for trimming

**Never combine `-ss` (seek) with `-af` (audio filters) in the same ffmpeg command.** The fade filter gets applied to the pre-seek timeline, zeroing out audio at the wrong position. Use `atrim` inside the filter graph instead:

```bash
# BAD: -ss + -af interaction produces silence
ffmpeg -i input.wav -ss 0.5 -t 0.4 -af "afade=..." output.wav

# GOOD: atrim keeps everything in the filter graph
ffmpeg -i input.wav -af "atrim=start=0.5:duration=0.4,asetpts=PTS-STARTPTS,afade=..." output.wav
```

### Use `astats` for peak detection, NOT `ebur128`

ebur128 uses a fixed 400ms sliding window (mandated by the EBU R128 standard). For sub-second SFX, this window is too wide -- it quantizes all results to the same boundary. `astats=reset=1` gives per-frame analysis at ~24ms resolution.

### Use two-pass peak normalization, NOT `dynaudnorm` or `loudnorm`

- **dynaudnorm** produces silence on clips under ~500ms. It needs a Gaussian window of multiple frames and has insufficient context for short SFX.
- **loudnorm** (EBU R128) needs at least 400ms for meaningful measurement. Unreliable for sub-second clips.
- **volumedetect + volume** works perfectly at any length. Simple, deterministic, preserves waveform shape.

### Always use WAV input, not MP3

MP3 has frame-based seeking (~26ms granularity), encoder delay padding, and generation loss on re-encode. WAV is sample-accurate. Suno offers WAV downloads -- always use them.

## Layering SFX

Many game moments play multiple sounds simultaneously. Design your SFX to layer:

- **Frequency separation**: bass impact + mid-range body + high sparkle = full spectrum
- **Temporal offset**: stagger by 50-100ms so transients don't collide
- **Rarity escalation**: more layers, richer harmonics, longer tails = rarer/more important
- **Consistent key**: everything in the same key so simultaneous playback harmonizes

## Common Issues

### Trimmed file is silent
The Suno WAV has the actual sound at the end of the file. The peak detection should find it, but if the window math is wrong, check `waveforms/*-raw.png` to see where the audio actually is.

### Peak detection finds noise instead of the sound
Lower the RMS threshold or try `Peak_level` instead of `RMS_level` in the astats key for transient-heavy sounds.

### Sound is too short after trimming
Suno generated less audio than the target duration. Re-generate with a prompt that implies longer duration, or adjust the target in `get_target()`.
