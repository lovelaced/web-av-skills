# ffmpeg Pitfalls for Short Audio Trimming

Hard-won lessons from building the SFX trimmer pipeline. These apply to any ffmpeg work with sub-second audio clips.

## 1. The `-ss` + `-af` Interaction Bug

**Problem:** When `-ss` (seek) and `-af` (audio filter chain) are used in the same command, the filters operate on the pre-seek timeline. A fade-out set at 0.38s into a 0.4s clip will be applied at 0.38s of the *original file*, not the trimmed output.

**Result:** The audio in the trim window gets zeroed out by the fade, producing silence.

**Solution:** Use `atrim` inside the filter graph. This keeps seeking and filtering in the same timeline:

```bash
ffmpeg -i input.wav \
  -af "atrim=start=0.5:duration=0.4,asetpts=PTS-STARTPTS,afade=t=out:st=0.38:d=0.02" \
  -acodec pcm_s16le output.wav
```

The `asetpts=PTS-STARTPTS` resets timestamps after the trim so the fade operates on the correct timeline.

## 2. ebur128 Is Wrong for Short Clips

**Problem:** The ebur128 filter's Momentary loudness (M) uses a **fixed 400ms sliding window** per the EBU R128 standard. This cannot be changed. For files under 2s, many unrelated files will report the same peak timestamp because they hit the same quantization boundary.

**Evidence:** In our batch of 23 files, 12 reported `peak=0.3000s` -- all landing on the same 400ms window edge.

**Solution:** Use `astats=metadata=1:reset=1` which resets statistics per codec frame (~24ms for 48kHz audio). Parse with `ametadata=print`:

```bash
ffmpeg -i input.wav \
  -af "astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level:file=-" \
  -f null - 2>/dev/null
```

Available keys: `RMS_level` (perceived loudness), `Peak_level` (transient detection), `Crest_factor` (peak-to-RMS ratio).

## 3. dynaudnorm Destroys Short Clips

**Problem:** `dynaudnorm` divides audio into frames (default 500ms) and applies gain smoothing over a Gaussian window (default 31 frames). For a 0.15s clip:
- Only ~1-3 analysis frames exist
- Gaussian smoothing has almost nothing to work with
- The filter can boost quiet sections to full scale while crushing transients
- Sub-200ms clips often come out as silence

**Solution:** Two-pass peak normalization with `volumedetect` + `volume`:

```bash
# Pass 1: measure
MAX_VOL=$(ffmpeg -i input.wav -af "volumedetect" -f null /dev/null 2>&1 \
  | grep "max_volume" | awk '{print $5}')

# Pass 2: apply
GAIN=$(echo "-1.0 - $MAX_VOL" | bc -l)
ffmpeg -i input.wav -af "volume=${GAIN}dB" output.wav
```

This works at any clip length, preserves waveform shape, and is deterministic.

## 4. loudnorm Is Also Unreliable for Short Clips

**Problem:** `loudnorm` targets integrated loudness using a 400ms gating window with 75% overlap. Clips shorter than ~400ms don't provide enough data for meaningful measurement. The filter technically runs but the target loudness won't reflect perceived loudness.

**When to use:** Only for clips 1s and above where you need perceptual loudness matching. For a mixed batch of 0.15s-8s SFX, peak normalization is more consistent.

## 5. MP3 Seeking Is Frame-Based

**Problem:** MP3 frames are ~26ms at 44.1kHz (1152 samples). Seeking with `-ss` lands on the nearest frame boundary, not the exact sample. For a 0.15s clip, the start point can be off by up to 26ms -- a 17% relative error.

**Solution:** Always work in WAV/PCM domain for trimming. Decode MP3 to WAV first, or better yet, download WAV from the source. Only encode to MP3 as the final step.

## 6. Suno WAV Files Have Quirky Headers

**Problem:** Some WAV files from Suno have metadata or header structures that cause ffmpeg's stream copy and seeking to behave incorrectly. Seeking to a valid position returns silence.

**Solution:** Force decode during trimming by specifying `-acodec pcm_s16le` on output, or use the `atrim` filter approach which always decodes.

## 7. Waveform Color Format

**Problem:** ffmpeg's `showwavespic` filter does not accept shorthand hex colors like `#4af`.

**Solution:** Use full `0xRRGGBB` format: `colors=0x44aaff`.

## Summary: The Reliable Pipeline

```
WAV input
  -> atrim (trim in filter graph, not -ss)
  -> asetpts=PTS-STARTPTS (reset timestamps)
  -> afade in + afade out (prevent clicks)
  -> pcm_s16le WAV intermediate
  -> volumedetect (measure peak)
  -> volume (apply gain to hit -1 dBFS)
  -> libmp3lame -q:a 2 (final encode)
```

Every step is simple, deterministic, and works at any clip length.
