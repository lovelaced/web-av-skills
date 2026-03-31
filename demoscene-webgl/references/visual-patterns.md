# Visual Patterns Reference

## Section-to-Visual Strategy Map

Each section type has proven visual approaches:

| Section | Camera | Geometry | Materials | Post-processing |
|---------|--------|----------|-----------|-----------------|
| **Void/Intro** | Static or very slow drift | Minimal or absent | Dark, monochrome | Clean, maybe subtle fog |
| **Build** | Slow approach | Growing, emerging | Warming colors | Increasing bloom |
| **Drop** | Snap to new angle | Burst/expansion | Bright flash, saturated | Bloom spike, screen shake |
| **Main/Chorus** | Smooth orbit | Full scene visible | Rich, layered | Moderate bloom |
| **Breakdown** | Drift, lose focus | Fracture, glitch | Desaturated | UV displacement, scanlines |
| **Storm/Peak** | Fast movement, close | Maximum complexity | Hot, intense | Heavy bloom, shake |
| **Transition** | Dolly or whip pan | Morph/transform | Palette swap | Color grading shift |
| **Outro/Fade** | Slow pull back | Simplifying | Cooling/dimming | Fade to black |

## SDF Raymarching Patterns

### Preventing Geometry Intersection

When objects must not intersect (e.g., rings around a star), compute the inner
object's radius dynamically and clamp:

```glsl
float innerR = getInnerRadius() + clearance;
outerR = max(outerR, innerR + index * gap);
```

### Surface Detail via Noise

Layer noise at different frequencies for organic surfaces:

```glsl
float detail = noise(p * 5.0 + t * 0.3) * noise(p * 7.0 - t * 0.5);
col *= 0.75 + detail * 0.5;
```

Animate noise offsets with `t` at different speeds per layer for convincing motion.

## Post-Processing

### Bloom

Bright extract → separable Gaussian blur → additive composite:

```glsl
vec3 bloom = texture(blurTex, uv).rgb;
col += bloom * (1.2 + audioE * 0.4);
```

### Glitch Effects

UV displacement gated to timestamp windows from the choreography map:

```glsl
uv.x += step(0.99, sin(uv.y * 400.0 + t * 50.0)) * glitchAmt * 0.02; // scanline tears
uv.x += (floor(sin(uv.y * 8.0 + t * 3.0) * 4.0) / 4.0) * glitchAmt * 0.03; // block shifts
```

### Fade to Black

```glsl
float fade = smoothstep(endTime - fadeDuration, endTime, t);
col *= 1.0 - fade;
```
