# Nano Banana 2 Prompt Guide for SVG-Friendly Output

Best practices for writing prompts that produce images optimized for raster-to-SVG conversion.

## Core Principle

SVG conversion works by tracing boundaries between color regions. The cleaner and more distinct those boundaries are in the source image, the better the SVG output. Every prompt decision should serve this goal: **maximize contrast, minimize noise**.

## Style Keywords That Help

Include one or more of these style descriptors in your prompt:

- **"vector art style"** — the single most effective phrase
- **"flat illustration"** — solid color fills, no gradients
- **"clean line art"** — well-defined strokes
- **"graphic design style"** — crisp edges, intentional composition
- **"silhouette"** — maximum contrast, simplest conversion
- **"cut paper art"** — solid shapes with clear boundaries
- **"logo design"** — designed for scalability
- **"screen print style"** — limited color palette, solid fills
- **"woodblock print"** — bold lines, high contrast
- **"stencil art"** — binary foreground/background

## Style Keywords to Avoid

These produce features that trace poorly:

- "photorealistic", "photograph", "4k photo" — too many colors and gradients
- "watercolor" — soft blended edges resist clean tracing
- "oil painting" — textured brushstrokes create noise
- "bokeh", "depth of field" — out-of-focus regions trace as blobs
- "film grain", "noise", "texture overlay" — adds thousands of artifacts
- "glow", "bloom", "lens flare" — soft gradients trace poorly
- "smoke", "fog", "mist" — undefined edges

## Color Guidance

**Do:**
- Request a limited color palette: "using only 3 colors", "monochrome", "duotone"
- Specify exact colors when possible: "black lines on white background"
- Ask for "solid colors" or "flat colors"
- Use "high contrast" in the prompt

**Don't:**
- Request gradients, color transitions, or ombre effects
- Ask for subtle color variations or "pastel wash"
- Use "iridescent", "holographic", "rainbow gradient"

## Background Guidance

**Best for conversion:**
- "on a solid white background"
- "on a solid black background"
- "on a plain [color] background"
- "isolated on white" or "no background"

**Avoid:**
- Complex scenic backgrounds
- Gradient backgrounds
- Textured backgrounds (paper, fabric, concrete)
- Busy patterns behind the subject

## Line and Shape Guidance

**Do:**
- "bold outlines", "thick strokes", "strong contours"
- "clean edges", "sharp boundaries"
- "geometric shapes", "defined shapes"
- Specify line weight: "2px lines", "thick black outlines"

**Don't:**
- "soft edges", "feathered", "blurred"
- "sketchy", "rough", "hand-drawn" (unless you want that aesthetic and accept some tracing artifacts)
- "wispy", "delicate hairline" — very thin lines may be lost in conversion

## Composition Tips

- **Simplify**: Fewer elements = cleaner trace. A single subject traces better than a crowded scene.
- **Scale matters**: Important details should be large enough to survive threshold and tracing. Small text or tiny features may be lost.
- **Separation**: Ask for clear separation between elements. Overlapping shapes with similar colors will merge during tracing.

## Prompt Templates

### For clean monochrome line art (easiest to convert)
```
[subject description] in clean vector line art style, bold black lines on white background, flat design, no shading, no gradients, high contrast, graphic design aesthetic
```

### For flat color illustration
```
[subject description] in flat vector illustration style, solid colors, limited palette of [N] colors, clean edges, no gradients, no textures, on solid [color] background
```

### For icons/logos
```
[subject description] as a simple vector icon, minimal design, solid shapes, [color] on [background color], geometric, clean lines, suitable for scaling
```

### For decorative/artistic (accepting some trace artifacts)
```
[subject description] in graphic art style, bold shapes, high contrast, screen print aesthetic, limited color palette, solid fills, strong outlines
```

## Post-Generation Checklist

Before converting, evaluate the generated image:

1. **Contrast**: Can you clearly distinguish foreground from background? If not, regenerate.
2. **Edge clarity**: Are boundaries between colors crisp? Soft/blurry edges will produce jagged SVG paths.
3. **Noise**: Zoom in — is there grain, dithering, or texture? These create thousands of tiny artifacts in the SVG.
4. **Color count**: How many distinct colors are present? Fewer = cleaner SVG. More than 8-10 distinct colors may benefit from vtracer instead of potrace.
5. **Line weight**: Are the thinnest lines at least 2-3 pixels wide? Thinner lines may require the dilate preprocessing step.

If the image fails any of these checks, consider regenerating with adjusted prompts before converting. A clean source image always produces a better SVG than aggressive post-processing of a noisy one.

## Resolution

- Generate at the highest resolution available. Higher resolution = more pixel data for the tracer to work with = smoother curves.
- If your generator supports it, request at least 2048px on the longest edge.
- Upscaling a low-res generation before tracing is inferior to generating at high resolution in the first place.
