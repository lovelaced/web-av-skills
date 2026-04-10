<div align="center">

# web-av-skills

*Claude Code skills for game animations, sound effects, music generation, audio-reactive visuals, and image-to-SVG conversion.*

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](#license)

</div>

## What This Is

A collection of [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code/skills) for building rich audio-visual experiences. Drop these into your Claude Code setup and describe what you want -- the skills handle the technical details.

## Install

```bash
git clone https://github.com/user/web-av-skills.git
cd web-av-skills

# Install all
for skill in gsap-game-animations suno-sfx-trimmer suno-v5-prompts demoscene-webgl nano-to-svg; do
  cp -r "$skill" ~/.claude/skills/
done
```

Skills activate automatically based on what you ask for.

## Putting It All Together

These skills combine naturally. Here's what building a game UI with original art, animation, and sound looks like end to end:

**1. Generate your art**

> *"I need a fire effect sprite sheet for a 2D RPG. Give me a Nano Banana 2 prompt for it."*

Claude writes an optimized prompt. Paste it into Nano Banana 2, download the full-size result.

**2. Convert to SVG**

> *"Convert ~/Downloads/fire-sprite.png to an animated SVG, 0.7 second loop"*

Claude analyzes the image, traces it, splits the frames, center-aligns them, and outputs a looping animated SVG.

**3. Animate it in your game UI**

> *"Build a GSAP animation sequence: when the player takes damage, flash the screen red, shake the viewport, and show this fire SVG on the hit location with a particle burst behind it"*

Claude choreographs a multi-beat GSAP timeline with the right easing and timing for game feel.

**4. Generate SFX from the timeline**

> *"Look at the GSAP timeline you just built. What sound effects do I need, and how long should each one be?"*

Claude reads the animation it created -- the screen flash is 0.15s, the shake is 0.4s, the fire appears over 0.3s, the particle burst is 0.6s -- and produces a list of SFX with exact durations and Suno Sounds prompts for each, all in a consistent key.

**5. Trim the SFX to match**

Generate the sounds in Suno, download the WAVs, then:

> *"Trim these to the durations from the timeline and normalize them"*

Claude runs the ffmpeg pipeline with the exact durations it specified -- peak detection, sample-accurate trim, fade, two-pass normalization, MP3 export. Every sound fits its animation beat precisely.

Now you have vector art, choreographed animation, and precisely trimmed sound that all work together -- and the timing was derived from the animation itself, not guessed.

---

## Skills

### nano-to-svg

Convert AI-generated images to clean SVG vectors. Auto-detects the best conversion strategy.

**Get a prompt for your image generator:**

> *"I need some SVG sprite sheet assets for a video game -- a fire animation, a water splash, and a healing sparkle effect. Give me Nano Banana 2 prompts for each."*

Claude gives you optimized prompts that produce SVG-friendly output (flat colors, clean edges, high contrast). Paste into Nano Banana 2 and download the full-size results.

**Convert a single image:**

> *"Vectorize ~/Downloads/game-icon.png"*

Claude runs the analysis script, picks the right pipeline, and generates both a detailed and minimal variant. You pick which one works.

**Convert and animate a sprite sheet:**

> *"Convert this sprite sheet to an animated SVG with a 0.8 second loop"* [paste image or point to file]

Claude splits the sheet into frames, traces each one, center-aligns them, and assembles a CSS-animated SVG with crisp frame transitions.

**Fine-tune the output:**

> *"The curves are a bit jagged, can you smooth them out?"*

> *"There are some small artifacts near the edges, clean those up"*

> *"I'm losing some thin lines -- can you capture more detail?"*

Claude adjusts the pipeline parameters and regenerates.

---

### gsap-game-animations

Build premium, tactile game-feel animations using GSAP and Canvas 2D.

**Describe the moment, not the math:**

> *"Build a card pack opening -- 5 cards fan out from a pack, each flips to reveal its face with a shimmer, then the rarest card scales up with a particle burst and glow behind it"*

Claude builds a complete GSAP timeline with overlapping animations, physical easing (back.out for entrances, elastic.out for impacts), and canvas particle effects.

**Add juice to existing UI:**

> *"I have a score counter component. When the score increments, I want the number to scale up slightly, change color briefly, and have a small burst of particles fly out"*

> *"Make a damage number popup that floats up with a slight random drift, scales from 0 to 1.2 then settles, and fades while rising"*

**Choreograph complex sequences:**

> *"Build a level-complete celebration: stars fly in from the edges, a banner slides down with a bounce, the score counts up with each digit popping, then confetti rains with a slow fade"*

Claude thinks in timelines with labels and position parameters -- overlapping animations that feel like one cohesive moment rather than a sequence of isolated effects.

**Derive your sound design from the animation:**

> *"Based on this timeline, what SFX do I need and what duration should each one be? Write Suno prompts for all of them."*

Claude inspects the timeline it built -- every tween has a start time and duration -- and produces a complete SFX shot list with Suno prompts and exact trim durations that match each animation beat.

---

### suno-sfx-trimmer

Generate short sound effects with Suno Sounds and auto-trim them to exact durations.

**Generate a set of SFX:**

> *"I need sound effects for a booster pack opening: a pack rip, a card whoosh for each of 5 cards, a shimmer for the rare reveal, and a celebration chime"*

Claude writes Suno Sounds prompts with a consistent musical key so all the sounds layer without clashing. Generate them in Suno and download.

**Trim and normalize:**

> *"Trim all the WAVs in ./raw/ to 0.5 seconds and normalize"*

Claude handles peak detection, sample-accurate trimming, fade in/out, and two-pass normalization. Output lands as MP3s with before/after waveform PNGs for QA.

**Extract a specific hit from a longer clip:**

> *"This 10-second Suno output has a great transient at around 1.2 seconds. Extract just that as a 0.3 second clip."*

**Standalone script:**

```bash
./suno-sfx-trimmer/scripts/trim-sfx.sh ./raw ./sfx              # default 1.0s
./suno-sfx-trimmer/scripts/trim-sfx.sh -d 0.5 ./raw ./sfx       # custom duration
```

---

### suno-v5-prompts

Write Suno v5 prompts for full music tracks in any genre.

**Describe what you're scoring:**

> *"I need a background track for a chill puzzle game. Something lo-fi and warm, about 2 minutes, no vocals. It should feel relaxing but not sleepy."*

Claude builds a complete Suno v5 prompt with style fields (genre, BPM, key, specific instruments, mood, production cues) and a structure field with section tags and energy arc.

**Score a specific scene:**

> *"Write a Suno prompt for a boss fight theme. Relentless, dark, heavy. Needs to loop cleanly."*

> *"I need a victory fanfare -- short, triumphant, orchestral. Think Final Fantasy but modern."*

**Iterate on a generation you like:**

> *"I generated this track and the verse is great but the chorus falls flat. How do I adjust the prompt to make the chorus hit harder without changing what works?"*

Claude refines one variable at a time -- the skill's iteration strategy ensures you don't lose what's already working.

---

### demoscene-webgl

Build audio-synchronized visual demos in a single HTML file using WebGL2/GLSL raymarching and Web Audio API.

**Give it a track and a vision:**

> *"Build a WebGL demo synced to track.mp3. Dark void that fills with geometric shapes during the intro, explodes into color at the drop, dissolves to particles for the outro."*

Claude analyzes the audio structure first (the skill enforces choreography-first workflow), builds a timing map, then writes the shaders and phase system to match.

**Start from a visual concept:**

> *"Raymarched tunnel that morphs with the music -- organic and flowing during quiet parts, angular and fractured during loud parts. Bass drives the bloom intensity."*

**Iterate on timing:**

> *"The visual transition at 0:34 feels early -- the drop actually hits at 0:35.2. Also the breakdown section needs to be more visually quiet, there's too much going on."*

Claude adjusts timestamps and phase transitions. Quiet sections stay visually quiet -- contrast is what makes loud moments hit.

---

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

nano-to-svg/
  SKILL.md                       # Image-to-SVG conversion skill
  scripts/analyze-image.py       # Auto-detect image type and optimal params
  references/prompt-guide.md     # Nano Banana 2 prompt tips for SVG-friendly output
```

## License

MIT
