---
name: nano-to-svg
description: Convert AI-generated images (from Nano Banana 2 or similar generators) to clean SVG vectors, and provide prompt-writing guidance for vector-friendly image generation. Use when user says "convert to svg", "vectorize", "trace image", "make svg", "svg convert", "nano to svg", "animate sprite sheet", or asks for tips on generating images that convert well to SVG. Invoke with "convert" to process an image, "tips" for prompt-writing best practices, or "convert" + sprite sheet for animated SVG output.
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

---

## Watermark Removal

AI image generators often add small watermarks (sparkles, logos, text) in corners. Remove these before conversion — they trace into unwanted SVG paths.

### Detecting Watermarks

Scan corner regions of the image for bright pixels against the background:

```python
from PIL import Image
import numpy as np

img = Image.open(image_path)
arr = np.array(img.convert("RGB"))
h, w, _ = arr.shape

# Check each corner region (200x400px)
corners = {
    "top-left": arr[:200, :400],
    "top-right": arr[:200, w-400:],
    "bottom-left": arr[h-200:, :400],
    "bottom-right": arr[h-200:, w-400:],
}

# Sample the background color from nearby interior points
bg_brightness = np.max(arr[10:20, 10:20], axis=2).mean()

for name, region in corners.items():
    brightness = np.max(region, axis=2)
    # Pixels that differ significantly from background
    anomalous = np.sum(np.abs(brightness - bg_brightness) > 50)
    if anomalous > 100:  # more than 100 bright outlier pixels
        ys, xs = np.where(np.abs(brightness - bg_brightness) > 50)
        print(f"Watermark detected in {name}: {xs.min()}-{xs.max()}, {ys.min()}-{ys.max()}")
```

### Removing Watermarks

Paint over the detected region with the background color, adding a small margin:

```bash
# For a dark/black background
magick <input> -fill black -draw "rectangle <x1>,<y1> <x2>,<y2>" <output>

# For a white background
magick <input> -fill white -draw "rectangle <x1>,<y1> <x2>,<y2>" <output>

# For any detected background color
magick <input> -fill '<bg_hex>' -draw "rectangle <x1>,<y1> <x2>,<y2>" <output>
```

Always add ~10px margin around the detected watermark bounds to catch anti-aliased edges.

---

## Sprite Sheet Animation

Convert a sprite sheet (multiple frames in a single image) into an animated SVG with CSS keyframe animation.

### Step 1: Trace the Full Sheet

Trace the entire sprite sheet as one image using the appropriate strategy (usually Strategy B for color sprites):

```python
import vtracer
vtracer.convert_image_to_svg_py(
    image_path=input_path,
    out_path=output_path,
    colormode='color',
    mode='spline',
    filter_speckle=8,
    color_precision=5,
    layer_difference=24,
    corner_threshold=60,
    length_threshold=4.0,
    splice_threshold=45,
    path_precision=2,
    hierarchical='stacked',
)
```

### Step 2: Assign Paths to Frames

Split the traced SVG paths into frame groups based on their horizontal position. For a sheet with N evenly-spaced frames:

```python
frame_w = total_w / num_frames

def get_frame_for_path(path_str):
    """Determine frame from translate() offset + first M command."""
    tx = 0
    t_match = re.search(r'translate\(([^,]+),([^)]+)\)', path_str)
    if t_match:
        tx = float(t_match.group(1))
    d_match = re.search(r'd="M([-\d.]+)\s+([-\d.]+)', path_str)
    mx = float(d_match.group(1)) if d_match else 0
    abs_x = tx + mx
    return max(0, min(num_frames - 1, int(abs_x / frame_w)))
```

Skip background paths (large rectangles spanning the full width).

### Step 3: Center-Align All Frames

**Critical step.** Sprite sheet frames often have subjects at different horizontal positions. Without alignment, the animation will appear to drift left/right.

Do NOT rely on pixel analysis of the source raster — it's imprecise due to anti-aliasing and color blending. Instead, render each frame's SVG paths to a temporary PNG and measure the bounding box from the rendered output:

```python
import subprocess
from PIL import Image
import numpy as np

# For each frame: write a standalone SVG, render to PNG, measure bounds
for i in range(num_frames):
    # Write frame SVG with paths shifted to local coords
    # ...
    
    # Render and measure
    subprocess.run(["magick", frame_svg_path, "-background", "black", 
                    "-flatten", frame_png_path])
    
    img = Image.open(frame_png_path)
    arr = np.array(img.convert("RGB"))
    brightness = np.max(arr, axis=2)
    mask = brightness > 15
    ys, xs = np.where(mask)
    center_x = (xs.min() + xs.max()) / 2
    # Store center_x for alignment
```

Compute the shift needed to align each frame's center to the output midpoint:

```python
target_x = frame_w // 2
shifts = [target_x - center for center in frame_centers]
```

Apply these shifts when adjusting each path's `translate()` transform.

### Step 4: Build Animated SVG

Use CSS `@keyframes` with `steps(1)` for crisp frame-by-frame switching:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {frame_w} {frame_h}">
<style>
  @keyframes frame0 {
    0%     { opacity: 1; }
    16.66% { opacity: 1; }
    16.67% { opacity: 0; }
    100%   { opacity: 0; }
  }
  @keyframes frame1 {
    0%     { opacity: 0; }
    16.66% { opacity: 0; }
    16.67% { opacity: 1; }
    33.32% { opacity: 1; }
    33.33% { opacity: 0; }
    100%   { opacity: 0; }
  }
  /* ... one @keyframes per frame ... */
  
  .frame0 { animation: frame0 0.6s steps(1) infinite; opacity: 1; }
  .frame1 { animation: frame1 0.6s steps(1) infinite; opacity: 0; }
  /* ... */
</style>

<rect width="{frame_w}" height="{frame_h}" fill="#000000"/>

<g class="frame0">
  <!-- paths for frame 0, translated to local coords + alignment shift -->
</g>
<g class="frame1">
  <!-- paths for frame 1 -->
</g>
<!-- ... -->
</svg>
```

**Animation timing guidelines:**
- Fire, water, sparkle effects: **0.6-0.8s** loop (100-133ms per frame for 6 frames)
- Character idle animations: **1.0-1.5s** loop
- UI loading spinners: **0.8-1.2s** loop
- Explosions / one-shots: use `animation-iteration-count: 1` instead of `infinite`

### Step 5: Trim Dead Space

Sprite sheet SVGs often have excess vertical/horizontal space. After building the animation, measure the maximum bounds across all rendered frames and crop the viewBox:

```python
# Find max vertical extent across all frames
y_max_overall = max(y_maxes_per_frame) + 20  # 20px padding

# Update the SVG viewBox and background rect
# viewBox="0 0 {frame_w} {y_max_overall}"
```

This can cut file height by 50%+ for sprites that don't fill their frames vertically.
