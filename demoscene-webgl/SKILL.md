---
name: demoscene-webgl
description: >
  Build audio-synchronized visual demos in a single HTML file using WebGL2/GLSL
  raymarching. Covers SDF-based 3D scenes, multi-pass rendering with bloom,
  phase-based timeline choreography, and real-time audio-reactive visuals via
  Web Audio API. Use when asked to create demoscene demos, WebGL raymarching,
  audio-reactive graphics, music visualizers, or choreographed visual experiences.
metadata:
  author: burrito
  version: 1.0.0
  category: graphics
  tags: [webgl, glsl, demoscene, audio-reactive, raymarching]
---

# Audio-Synced WebGL Demo Skill

## Architecture

Single `index.html` containing all shaders, WebGL setup, audio integration, and
overlays. Self-contained by design — no build step, no dependencies.

### Multi-Pass Rendering Pipeline

1. **Scene pass** — Raymarching with SDFs, lighting, volumetrics, materials
2. **Bright extract** — Threshold filter isolating bloom-worthy pixels
3. **Gaussian blur** — Two-pass separable blur on the bright extract
4. **Composite** — Combines scene + bloom, applies post-effects (glitch, fade, color grading)

Each pass renders to its own framebuffer/texture. Final composite goes to screen.

---

## Computing Choreography from Audio

This is the most important part of making a demo. Build the choreography map
**before writing any shader code**. Bad choreography makes a technically impressive
demo feel lifeless.

### Step 1: Analyze the Audio File

Build a complete picture of the track's energy and structure using ffmpeg, Web Audio
API, or Python librosa. Consult `references/audio-analysis.md` for code and methods
for all three approaches, plus BPM detection and optional baked energy envelopes.

### Step 2: Identify Structural Sections

Segment the track into sections. Look for these patterns in waveform/energy data:

| Pattern in waveform | What it means | Musical term |
|---------------------|---------------|--------------|
| Near-zero amplitude → gradual rise | Energy building | **Intro / Build** |
| Sudden jump from low to high | Energy release | **Drop** |
| Sustained high amplitude | Full arrangement | **Chorus / Main section** |
| Brief dip in sustained energy | Tension/release cycle | **Breakdown** |
| High → gradually decreasing | Energy winding down | **Outro / Fade** |
| Texture change (spectrogram shift) | Instrument swap | **Transition** |
| Isolated spike in low energy | Percussive accent | **Hit** |
| Flat near-silence | Space/rest | **Void / Silence** |

Note **exact timestamps** to the nearest 0.1s. These become your `smoothstep` parameters.

### Step 3: Build the Choreography Map

Create a plain-text document — the single source of truth for all visual timing.

```
CHOREOGRAPHY MAP — track: [filename] ([duration]s, [BPM] BPM)

SECTIONS:
  [start] - [end]   [NAME]     — [description of what happens visually]

KEY HITS (one-shot events):
  [time]  — [what happens in the music] → [visual response]

ENERGY ARC:
  [prose description, e.g. "slow build → explosive drop → sustained
   intensity → brief calm → second build → climactic transformation → fade"]

MOOD TRANSITIONS:
  [time]: [mood A] → [mood B]  (e.g. "warm/organic → cold/digital")
```

Rules:
- Every section needs a distinct visual identity
- Drops must have a visual event
- Builds must have visible escalation
- Quiet sections must actually be quiet visually — contrast makes loud sections louder
- The map should read like a story arc, not a flat list

### Step 4: Translate Map to Phase Code

Each section becomes a `smoothstep` phase field (0→1):

```glsl
// Ramp in, hold, ramp out
ph.sectionName = smoothstep(startTime, startTime + fadeIn, t)
               * (1.0 - smoothstep(endTime - fadeOut, endTime, t));
```

Transition sharpness:
- `0.1s` — near-instant snap (drops, impacts)
- `0.5-1.0s` — quick but smooth (normal transitions)
- `2.0-5.0s` — gradual blend (mood shifts, slow builds)
- `10.0-30.0s` — glacial evolution (entire build sections)

One-shot hits as `exp()` pulses:

```glsl
float hit = exp(-abs(t - hitTime) * sharpness);
// sharpness 4-6: wide pulse, ~0.5s | 8-12: tight spike, ~0.2s | 15-20: flash
```

### Step 5: Iterate

1. Play the demo with the track
2. Where visuals feel early/late — adjust timestamps ±0.1-0.5s
3. Where energy feels flat — add audio multipliers or one-shot pulses
4. Where transitions feel abrupt/mushy — widen/narrow `smoothstep` ranges
5. Repeat until every musical moment has a visual counterpart

Consult `references/visual-patterns.md` for proven section-to-visual strategies,
SDF patterns, and post-processing recipes.

### Choreography Quality Checklist

- [ ] Every drop has a visual impact (flash, snap, bloom spike)
- [ ] Every build has visible escalation (growth, approach, brightening)
- [ ] Every breakdown has a visual shift (glitch, desaturation, fracture)
- [ ] Camera never stays static for more than ~15s
- [ ] Adjacent sections have visual contrast
- [ ] Quiet moments are actually quiet (dim, sparse, slow)
- [ ] The finale feels like a finale (biggest visual moment, then resolution)
- [ ] Mood transitions in the music have corresponding color/material shifts
- [ ] One-shot hits land on the beat, not between beats
- [ ] The demo still looks good without audio (base values are reasonable)

---

## Audio-Visual Sync System

The sync system is **hybrid**: hardcoded timestamps provide structure, real-time
FFT adds organic responsiveness.

### Time Source: Always Use `audio.currentTime`

The shader `time` uniform must come from `audioElement.currentTime`, NOT from a JS
accumulator or `performance.now()`. This locks visuals to audio even when frames
drop or the browser throttles.

```javascript
const time = audioEl ? audioEl.currentTime : 0;
gl.uniform1f(timeLoc, time);
```

### FFT Data Pipeline

```javascript
analyser.fftSize = 512;
analyser.smoothingTimeConstant = 0.55;

const freq = new Uint8Array(analyser.frequencyBinCount);
analyser.getByteFrequencyData(freq);

let bass = 0;    for (let i=0;  i<4;  i++) bass    += freq[i]; bass    /= 4*255;
let mid = 0;     for (let i=4;  i<16; i++) mid     += freq[i]; mid     /= 12*255;
let treble = 0;  for (let i=16; i<64; i++) treble  += freq[i]; treble  /= 48*255;
let overall = 0; for (let i=0;  i<128;i++) overall += freq[i]; overall /= 128*255;

gl.uniform4f(audioLoc, bass, mid, treble, overall);
```

Tuning:
- **`fftSize`**: 512 is a good default. 256 = snappier but coarser. 1024+ = more
  frequency detail but more latency.
- **`smoothingTimeConstant`**: 0.55 is balanced. 0.3 = twitchy (good for percussion-
  heavy tracks). 0.8 = sluggish (good for ambient/drone).

| Band | Freq range | Visual target | Example |
|------|-----------|---------------|---------|
| `bass` (audio.x) | Sub/kicks | Camera shake, bloom pulse | `col += glow * audio.x * 0.4` |
| `mid` (audio.y) | Melody/pads | Color shifts, surface detail | `col *= 1.0 + audio.y * 0.15` |
| `treble` (audio.z) | Hi-hats/shimmer | Scanlines, sparkle | `br *= 0.3 + audio.z * 0.7` |
| `overall` (audio.w) | Full energy | Bloom intensity | `bloom *= 1.2 + audioE * 0.4` |

### Critical Rule: Audio Never Drives SDF Geometry

Positions, sizes, angles, and shapes must be deterministic from `time`. Audio
reactivity only affects materials, brightness, glow, and post-processing. This
prevents visual jitter across devices.

### Multiplier Pattern

Always use audio as a **multiplier on a base value**, never as the sole driver:

```glsl
// CORRECT — works without audio, enhanced with it
col *= 1.0 + audio.x * 0.2;

// WRONG — black screen when audio is silent
col *= audio.x;
```

### Camera Shake

Square the bass energy so only strong hits register:

```glsl
float shake = audio.x * audio.x * 0.003;
```

---

## Phase-Based Timeline

### Phase Struct

```glsl
struct Phase {
  float emerge;     // opening — geometry fades in
  float build;      // tension rising
  float ignite;     // the drop
  float system;     // full scene, cruising
  float storm;      // intensity peak
  float breakdown;  // momentary collapse
  float transform;  // mood/texture shift
  float reveal;     // resolution, finale
  float pulse;      // audio-reactive multiplier (1.0 + audio)
};
```

Adapt field names and count to your track.

### Phase Transitions

```glsl
ph.drop = smoothstep(dropTime - 0.1, dropTime + 0.1, t);           // snap
ph.cold = smoothstep(shiftTime - 1.0, shiftTime + 1.0, t);         // crossfade
ph.build = smoothstep(buildStart, buildEnd, t);                      // gradual
ph.breakdown = smoothstep(bdStart, bdStart + 0.2, t)                // bounded
             * (1.0 - smoothstep(bdEnd - 0.3, bdEnd, t));
```

### Dynamic Geometry with Phases

```glsl
radius += ph.build * 0.8;              // grows during build
radius += ph.storm * (0.5 + i * 0.2); // expands per-instance in storm
radius *= 1.0 - ph.breakdown * 0.3;   // shrinks during breakdown
```

### Camera Choreography

```glsl
float camDist = initialDist
  - approach   * smoothstep(tA, tB, t)     // move in
  + pullBack   * smoothstep(tC, tD, t)     // move out
  - rushIn     * smoothstep(tE, tF, t);    // final approach
```

The camera tells the same story as the music — approaching during builds, snapping
on drops, drifting during calm sections, pulling back for the finale.

---

## Common Pitfalls

1. **Audio context requires user gesture** — always gate on a click-to-start overlay
2. **Shader compilation errors are silent** — check `gl.getShaderInfoLog()` and log it
3. **`smoothstep` needs margin** — `smoothstep(10.0, 10.5, t)` not `step(10.0, t)`
4. **Phase overlaps are features** — two phases at 50/50 during crossfade = natural transition
5. **Audio uniform fallback** — if `analyser` is null, return `[0,0,0,0]` so shaders still work
6. **Use `onended` not timeouts** — actual playback may differ from expected track length
7. **Test without audio** — the multiplier pattern ensures visuals degrade gracefully
8. **Choreography map first, code second** — changing timestamps without updating the map leads to drift
