<div align="center">

# web-av-skills

*Claude Code skills for game animations, sound effects, and interactive web audio-visual experiences.*

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](#license)

</div>

## What This Is

A collection of [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code/skills) for building rich audio-visual experiences -- game-feel animations with GSAP, sound effect generation with Suno, and precise audio trimming with ffmpeg.

Drop these into your Claude Code setup and get expert-level guidance on animation choreography, SFX prompt engineering, and audio post-processing without repeating yourself across projects.

## Skills

### gsap-game-animations

Build premium, tactile game-feel animations using GSAP 3.x and Canvas 2D. Think Peggle, Balatro, Hearthstone -- animations that make the user smile.

- **Timeline choreography** -- Sequence complex multi-beat animations with labels and position parameters
- **Particle systems** -- Object-pooled Canvas 2D particles with additive blending for zero-GC glow effects
- **Physical easing** -- Opinionated easing guide: `back.out` for entrances, `elastic.out` for impacts, two-phase tweens for deceleration
- **Clever techniques** -- Progressive clip-path tears, canvas light shafts, alpha-aware glow
- **Mobile performance** -- Only animate `transform`/`opacity`, pool particles, pause on `visibilitychange`

Includes a GSAP 3.x API quick reference (`references/gsap-api.md`).

### suno-sfx-trimmer

End-to-end workflow for generating short sound effects with Suno Sounds and auto-trimming them to exact durations using ffmpeg.

- **Suno prompt engineering** -- Prompt structure, key scheme strategy, and best practices for SFX (not music)
- **Precision trimming** -- Peak detection via `astats`, sample-accurate trim via `atrim` filter, fade in/out, two-pass peak normalization
- **Visual QA** -- Before/after waveform PNGs for every processed file
- **Battle-tested pipeline** -- Documents every ffmpeg pitfall for short audio: the `-ss`/`-af` interaction bug, why `ebur128` fails under 2s, why `dynaudnorm` destroys sub-500ms clips

Includes the `trim-sfx.sh` script and an ffmpeg pitfalls reference (`references/ffmpeg-pitfalls.md`).

## Quick Start

### Install as Claude Code skills

Copy the skill directories into your Claude Code skills folder:

```bash
cp -r gsap-game-animations ~/.claude/skills/
cp -r suno-sfx-trimmer ~/.claude/skills/
```

The skills activate automatically when you ask Claude Code about GSAP animations, particle effects, Suno sound effects, or audio trimming.

### Use the SFX trimmer standalone

```bash
# Prerequisites: ffmpeg with libmp3lame
brew install ffmpeg

# Place Suno WAV files in ./raw/, then:
./suno-sfx-trimmer/scripts/trim-sfx.sh ./raw ./sfx
```

Trimmed MP3s land in `./sfx/`, waveform PNGs in `./waveforms/`.

## Project Structure

```
gsap-game-animations/
  SKILL.md                    # Animation skill definition
  references/gsap-api.md      # GSAP 3.x API quick reference

suno-sfx-trimmer/
  SKILL.md                    # SFX skill definition
  references/ffmpeg-pitfalls.md  # Hard-won ffmpeg lessons
  scripts/trim-sfx.sh         # Batch trim + normalize script
```

## License

MIT
