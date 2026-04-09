---
name: nano-to-svg
description: Convert AI-generated images (from Nano Banana 2 or similar generators) to clean SVG vectors, and provide prompt-writing guidance for vector-friendly image generation. Use when user says "convert to svg", "vectorize", "trace image", "make svg", "svg convert", "nano to svg", or asks for tips on generating images that convert well to SVG. Invoke with "convert" to process an image, or "tips" for prompt-writing best practices.
compatibility: Requires Homebrew (macOS). Installs potrace, imagemagick, autotrace, and Python vtracer if not present.
---

# Nano-to-SVG

Convert AI-generated raster images to clean, scalable SVG vectors. Optimized for output from Nano Banana 2 and similar image generation models.

## Modes

This skill has two modes based on the argument provided:

- **`convert`** — Analyze and convert a raster image (PNG/JPG/WebP) to SVG
- **`tips`** — Provide best practices for writing Nano Banana 2 prompts that produce conversion-friendly images

If no argument is given, ask the user which mode they want.

---

## Mode: convert

### Step 1: Ensure Dependencies

Check for required tools. Install any that are missing:

```bash
which potrace || brew install potrace
which magick || brew install imagemagick
which autotrace || brew install autotrace
python3 -c "import vtracer" 2>/dev/null || pip3 install vtracer
```

### Step 2: Locate the Source Image

Ask the user for the image path if not provided. Verify it exists and read its metadata:

```bash
magick identify <image_path>
```

Record: dimensions, color mode (RGB/RGBA), file size.

### Step 3: Analyze the Image

Run auto-detection to determine the image type and optimal conversion strategy. Use Python with Pillow and numpy:

```python
from PIL import Image
import numpy as np

img = Image.open(image_path)
arr = np.array(img.convert("RGB"))

# 1. Dominant colors — sample and cluster
# 2. Contrast ratio — std deviation of luminance
# 3. Edge density — gradient magnitude
# 4. Color count — unique color clusters after quantization
# 5. Has transparency — check for alpha channel
```

Classify the image into one of these categories:

| Category | Characteristics | Strategy |
|----------|----------------|----------|
| **Line art** | High contrast, thin strokes on solid bg, few colors | Potrace pipeline (best curves) |
| **Flat illustration** | Solid color regions, clean edges, limited palette | Potrace multi-pass or vtracer color |
| **Complex/painterly** | Many colors, gradients, textured | vtracer color mode |
| **Mixed** | Line art + colored elements | Layer separation |

Report the classification and strategy to the user before proceeding.

### Step 4: Prepare the Image

**Trim borders** if the subject doesn't fill the frame:
```bash
magick <input> -fuzz 10% -trim +repage <trimmed>
```

**Sample the background color** from interior points for later use in the SVG:
```bash
magick <trimmed> -crop 1x1+<x>+<y> -depth 8 txt:- | tail -1
```

### Step 5: Convert

#### Strategy A — Potrace Pipeline (for line art, monochrome, or when smooth Bezier curves matter most)

This is the default for AI-generated images with clear lines on solid backgrounds.

**Pipeline:**
```bash
magick <input> \
  -colorspace Gray \
  -normalize \
  -gaussian-blur 0x<blur> \
  -threshold <threshold>% \
  -morphology Dilate Disk:<dilate> \
  -negate \
  PBM:- | potrace -s \
  --turdsize <turdsize> \
  --alphamax <alphamax> \
  --opttolerance <opttolerance> \
  -C '<fg_color>' \
  --fillcolor '<bg_color>' \
  --opaque --tight \
  -o <output>.svg -
```

**Auto-detected parameter ranges:**

| Parameter | Detailed | Minimal | What it controls |
|-----------|----------|---------|-----------------|
| blur | 0x0.5 | 0x0.8 | Edge smoothing before threshold |
| threshold | 35-40% | 40-45% | What counts as foreground |
| dilate | Disk:1 | Disk:1 | Fill hollow interiors of thin lines |
| turdsize | 4-6 | 8-12 | Remove small artifacts (higher = cleaner) |
| alphamax | 1.0-1.2 | 1.2-1.3 | Corner smoothing (higher = smoother curves) |
| opttolerance | 0.3-0.5 | 0.5-0.8 | Curve simplification (higher = fewer nodes) |

**Choosing between Detailed and Minimal:**
- **Detailed**: More nodes, captures fine features, larger SVG. Use when the image has important small text or intricate detail.
- **Minimal**: Fewer nodes, cleaner curves, smaller SVG. Use for icons, logos, decorative art where smooth flow matters more than pixel-accuracy.

Generate BOTH variants and let the user choose. Name them `<name>-detailed.svg` and `<name>-minimal.svg`.

#### Strategy B — vtracer Color Mode (for multi-color images)

Use when the image has multiple distinct colors that must be preserved:

```python
import vtracer
vtracer.convert_image_to_svg_py(
    image_path=input_path,
    out_path=output_path,
    colormode='color',
    mode='spline',
    filter_speckle=2,
    color_precision=6,
    layer_difference=16,
    corner_threshold=60,
    length_threshold=4.0,
    splice_threshold=45,
    path_precision=3,
    hierarchical='stacked',
)
```

Warn the user: vtracer color output produces larger files and may include jagged edges on thin lines. For best results on line art, prefer Strategy A even if it means losing color.

#### Strategy C — Layer Separation (for mixed content)

When the image has both line art AND colored elements (e.g., wireframe + colored logo):

1. **Extract monochrome layer** via grayscale threshold (captures lines + text)
2. **Extract color layer** via HSL saturation channel (captures only saturated/colored elements)
3. **Trace each** with the optimal tool (potrace for lines, vtracer for colors)
4. **Composite** into a single SVG with layered groups

### Step 6: Open and Present

Open the result in the user's default browser/viewer:
```bash
open <output>.svg
```

Report file size and which strategy was used. Ask if adjustments are needed.

### Iterating on Results

Common user feedback and how to respond:

| Feedback | Fix |
|----------|-----|
| "Lines are jagged" | Increase gaussian blur (0x0.8 to 0x1.0) |
| "Missing thin lines" | Lower threshold (35% to 30%), reduce turdsize |
| "Too many small artifacts" | Increase turdsize (6 to 12), increase threshold |
| "Curves aren't smooth enough" | Increase opttolerance (0.5 to 0.8), increase alphamax (1.2 to 1.3) |
| "Lines have holes/gaps" | Increase morphology Dilate (Disk:1 to Disk:2), or add Close morphology |
| "Lost too much detail" | Lower opttolerance (0.3 to 0.1), lower alphamax (1.0 to 0.8) |
| "File is too large" | Increase opttolerance, increase turdsize, reduce path precision |

---

## Mode: tips

Provide the user with best practices for writing Nano Banana 2 prompts that produce images optimized for SVG conversion. Consult `references/prompt-guide.md` for the complete guide, then present the key points conversationally.

Key principles to cover:
1. Request flat, graphic styles — not photorealistic
2. Ask for high contrast and solid colors
3. Specify clean line work and minimal gradients
4. Avoid complex textures, noise, and film grain
5. Request solid or simple backgrounds
6. Specify the art style explicitly (vector art, line art, flat illustration)
7. Include negative prompts to avoid conversion-hostile features

---

## Common Issues

### potrace not found
```bash
brew install potrace
```

### ImageMagick version conflict (v6 `convert` vs v7 `magick`)
Always use `magick` (v7). If only `convert` is available, install v7:
```bash
brew install imagemagick
```

### vtracer produces huge files
Increase `layer_difference` (16 to 32), decrease `color_precision` (6 to 4), increase `filter_speckle` (2 to 8).

### Image has a background border/frame from the generator
Always trim first:
```bash
magick <input> -fuzz 10% -trim +repage <trimmed>
```
