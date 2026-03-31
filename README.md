<div align="center">

# web-av-skills

*Claude Code skills for game animations, sound effects, music generation, and audio-reactive visuals.*

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](#license)

</div>

## What This Is

A collection of [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code/skills) for building rich audio-visual experiences -- game-feel animations with GSAP, AI music and SFX with Suno, audio trimming with ffmpeg, and audio-synced WebGL demos.

Drop these into your Claude Code setup and get expert-level guidance on animation choreography, music/SFX prompt engineering, audio post-processing, and demoscene visuals without repeating yourself across projects.

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

### suno-v5-prompts

Write effective Suno v5 style prompts and structure fields for full music tracks in any genre.

- **Style prompt anatomy** -- Genre, BPM, key, instruments, mood, production cues, and exclusions
- **Structure field mastery** -- Section tags, instrumental arrangements with parenthetical descriptions and punctuation patterns
- **Dynamic arcs** -- Energy mapping across sections so tracks go somewhere
- **Vocal prompting** -- Register, delivery tags, intensity via caps and line length
- **Iteration strategy** -- Refine one variable at a time, curate from multiple takes

Includes genre example prompts (`references/genre-examples.md`).

### demoscene-webgl

Build audio-synchronized visual demos in a single HTML file using WebGL2/GLSL raymarching and Web Audio API.

- **Choreography-first workflow** -- Analyze audio with ffmpeg/Web Audio/librosa, build a timing map before writing any shader code
- **Phase-based timeline** -- GLSL `smoothstep` phases that map 1:1 to musical sections
- **Audio-reactive sync** -- Hybrid system: hardcoded timestamps for structure, real-time FFT for organic responsiveness
- **Multi-pass rendering** -- Scene, bloom extract, Gaussian blur, composite with post-effects
- **Critical rule: audio never drives SDF geometry** -- Only materials, brightness, glow, and post-processing react to audio

## Quick Start

### Install as Claude Code skills

Copy the skill directories into your Claude Code skills folder:

```bash
cp -r gsap-game-animations ~/.claude/skills/
cp -r suno-sfx-trimmer ~/.claude/skills/
cp -r suno-v5-prompts ~/.claude/skills/
cp -r demoscene-webgl ~/.claude/skills/
```

The skills activate automatically based on your queries -- GSAP animations, Suno music/SFX, audio trimming, WebGL demos, etc.

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
  SKILL.md                       # Animation skill definition
  references/gsap-api.md         # GSAP 3.x API quick reference

suno-sfx-trimmer/
  SKILL.md                       # SFX generation + trimming skill
  references/ffmpeg-pitfalls.md  # Hard-won ffmpeg lessons
  scripts/trim-sfx.sh           # Batch trim + normalize script

suno-v5-prompts/
  SKILL.md                       # Music prompt writing skill
  references/genre-examples.md   # Style prompt examples by genre

demoscene-webgl/
  SKILL.md                       # Audio-synced WebGL demo skill
  references/audio-analysis.md   # ffmpeg, Web Audio, librosa methods
  references/visual-patterns.md  # Section-to-visual strategies, SDF, post-fx
```

## License

MIT
