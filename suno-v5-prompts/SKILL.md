---
name: suno-v5-prompts
description: >
  Write effective Suno v5 style prompts and structure fields for any genre, mood,
  or use case. Covers style prompt anatomy, section tags, instrumental arrangement,
  dynamic arcs, vocal delivery, and iteration strategy. Use when user asks to write
  Suno prompts, generate music with Suno, create a Suno style prompt, structure a
  Suno track, or produce AI-generated music. Do NOT use for Suno Sounds SFX (use
  suno-sfx-trimmer instead) or for non-Suno music production tools.
metadata:
  author: burrito
  version: 1.0.0
  category: audio
  tags: [suno, music, prompts, ai-music]
---

# Writing Effective Suno v5 Prompts

Suno v5 has two input fields: a **Style Prompt** (controls the sound) and a **Lyrics/Structure Field** (controls the shape). This skill covers how to write both for any genre, mood, or use case.

## Style Prompt Anatomy

A good style prompt has 4-6 components in this order:

```
[Genre + Subgenre], [BPM], [Key (optional)]. [Instruments]. [Mood/Emotion]. [Production/Mix cues]. [Exclusions].
```

### 1. Genre + Subgenre

Be specific. The more precise you are, the tighter the output.

- Bad: "electronic music"
- Good: "melodic techno"
- Best: "deep melodic techno, progressive structure, Berlin club sound"

Blend genres with commas or "meets" / "x" / "with":
- "trip-hop meets orchestral, downtempo cinematic"
- "Afrobeat x jazz fusion, complex polyrhythms"

### 2. BPM

Always include a specific number. Suno respects BPM fairly well.

| Genre | BPM range |
|-------|-----------|
| Ambient/downtempo | 60-90 |
| Hip-hop/R&B | 80-100 |
| Pop/indie | 100-120 |
| House/techno | 120-130 |
| Drum and bass/jungle | 130-175 |
| Breakcore | 160-200 |

### 3. Key (optional but useful)

Specify if you care about harmonic content or plan to layer/stitch multiple generations. Use standard notation: "C minor", "Eb major", "F# minor".

Minor keys = darker, more tense. Major keys = brighter, more euphoric.

### 4. Instruments

Name 3-5 specific instruments. This is one of the most powerful levers. Don't say "synths" — say which synths.

- Generic: "synths, drums, bass"
- Specific: "analog Juno pads, 303 acid bassline, chopped amen breaks, sub bass"

Suno responds to instrument-specific vocabulary:
- "Rhodes piano" ≠ "grand piano" ≠ "honky-tonk piano"
- "reese bass" ≠ "sub bass" ≠ "303 acid bass" ≠ "fuzz bass"
- "gated reverb snare" ≠ "tight dry snare" ≠ "brushed snare"

### 5. Mood / Emotion

Use 2-3 adjectives that describe the feeling, not the sound.

- "melancholic but hopeful"
- "tense, building, cathartic release"
- "playful, irreverent, slightly chaotic"

Avoid vague superlatives: "epic", "amazing", "cool" mean nothing to the model.

### 6. Production / Mix Cues

- "clean mix, clear instrument separation"
- "lo-fi, warm tape saturation, vinyl crackle"
- "wide stereo, heavy reverb, spacious"
- "dry, punchy, in-your-face, compressed"

### 7. Exclusions (Negative Prompts)

Use "no [element]" format. Keep to 2-3 max — too many can hollow out the arrangement.

- "no vocals, no singing, no humming, no choir"
- "no autotune"
- "no EDM drops"

Consult `references/genre-examples.md` for full style prompt examples across genres.

## Structure Field: Section Tags

Place tags in square brackets on their own line. These define the arrangement.

### Standard Tags

```
[Intro], [Verse], [Pre-Chorus], [Chorus], [Bridge],
[Instrumental Break], [Outro]
```

### Extended Tags

```
[Build], [Drop], [Breakdown], [Ambient Break], [Climax],
[Fade Out], [Hook], [Solo], [Half-time], [Double-time]
```

### Performance Tags (placed before or within sections)

```
[Whispered], [Belted], [Spoken Word], [Building], [Powerful], [Gentle]
```

## Structure Field: Instrumental Tracks

For instrumentals, replace lyrics with either parenthetical descriptions or punctuation patterns.

### Parenthetical descriptions (more reliable)

```
[Intro]
(sparse piano, single notes, large reverb, building tension)

[Chorus]
(full arrangement, all instruments, maximum energy, anthemic)

[Outro]
(instruments drop out one by one, ending on sustained piano chord)
```

### Punctuation patterns (less predictable, can force instrumental passages)

```
[Build]
.. .! . .. ! .
. ! .. .

[Drop]
!! .! !! .! !! .! !! .!
```

## Dynamic Arcs

The biggest difference between a forgettable AI track and a compelling one is **dynamic arc** — the track needs to go somewhere.

### In the Style Prompt

Describe the journey: "Dynamic arc: quiet ambient intro building to full-intensity peak, then graceful breakdown"

### In the Structure Field

Think in energy percentages:

```
[Intro]        — 10% energy
[Verse 1]      — 30% energy
[Pre-Chorus]   — 50% energy
[Chorus]        — 80% energy
[Bridge]       — 20% energy (contrast!)
[Final Chorus] — 100% energy
[Outro]        — 15% energy
```

Reinforce with parenthetical cues:
```
[Bridge]
(strip everything back, just vocals and a single instrument, quiet, vulnerable)
```

## Vocal Prompting

### In the Style Prompt

Specify register, tone, and delivery:
- "Male baritone, warm, slightly raspy, restrained emotion"
- "Female alto, breathy, intimate, close-mic feel"

### In the Structure Field

```
[Verse 1]
[Whispered] In the silence of the night
[Building] I feel you pulling me close
[Belted] AND I WON'T LET GO
```

Tips:
- ALL CAPS text tends to be sung louder/more intensely
- Short lines = punchier delivery, longer lines = more flowing
- Hyphens extend words: "lo-ove", "sooo-long"

## Multi-Section Stitching

For longer or more complex pieces, generate each section separately and stitch in Suno Studio or a DAW.

Keep consistent across all prompts:
- BPM (exact same number)
- Key
- Core instrument list
- Production style descriptors

Change between sections:
- Energy descriptors
- Which instruments are active
- Mood adjectives

## Iteration Strategy

1. **Start rough.** Short style prompt, basic structure. Generate 3-4 takes. Listen for the right *feel*.
2. **Identify what's working.** Note which elements sound right.
3. **Refine one variable at a time.** "dark" → "ominous" → "foreboding" each give different shadings.
4. **Use negative prompts to fix problems.** If unwanted elements appear, add targeted exclusions.
5. **Generate 4-6 takes of your final prompt.** Pick the best.
6. **Use Suno Studio for surgery.** Region editing to regenerate just a bad section.

## Common Pitfalls

- **Too many words.** Crisp phrases beat long prose. "Warm analog synth pads, wide stereo" > "I want the synth pads to sound warm and analog, spread across the stereo field."
- **Contradictory instructions.** "Aggressive, calm" confuses the model. Put contrast in the arc, not a single descriptor.
- **Overloading exclusions.** More than 3-4 negatives can hollow out the output.
- **Ignoring structure.** A style prompt alone gives formless sound. Section tags give it shape.
- **Expecting exact reproduction.** Suno interprets, it doesn't execute literally. Curate from multiple takes.
- **Using artist names.** Suno blocks them. Instead describe the sonic qualities: "Radiohead" → "experimental art-rock, complex time signatures, atmospheric guitars, falsetto vocals, melancholic beauty."
