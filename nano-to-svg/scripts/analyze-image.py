#!/usr/bin/env python3
"""Analyze a raster image and recommend optimal SVG conversion strategy."""

import sys
import json
from PIL import Image
import numpy as np


def analyze(image_path):
    img = Image.open(image_path)
    has_alpha = img.mode in ("RGBA", "LA", "PA")
    rgb = np.array(img.convert("RGB"), dtype=np.float32)
    h, w, _ = rgb.shape

    # Luminance
    lum = 0.299 * rgb[:, :, 0] + 0.587 * rgb[:, :, 1] + 0.114 * rgb[:, :, 2]

    # Contrast: std deviation of luminance
    contrast = float(np.std(lum))

    # Edge density: Sobel-like gradient magnitude
    gy = np.abs(np.diff(lum, axis=0))
    gx = np.abs(np.diff(lum, axis=1))
    edge_density = float((np.mean(gy) + np.mean(gx)) / 2)

    # Color analysis: quantize to 32 levels per channel, count unique
    quantized = (rgb // 32).astype(np.uint8)
    flat = quantized.reshape(-1, 3)
    unique_colors = len(np.unique(flat, axis=0))

    # Dominant bg color: sample corners
    corners = [rgb[5, 5], rgb[5, w - 5], rgb[h - 5, 5], rgb[h - 5, w - 5]]
    bg_color = np.mean(corners, axis=0).astype(int)
    bg_hex = "#{:02x}{:02x}{:02x}".format(*bg_color)

    # Determine if mostly monochrome
    saturation = np.std(rgb, axis=2).mean()
    is_monochrome = saturation < 25

    # Classify
    if unique_colors < 50 and contrast > 60 and is_monochrome:
        category = "line-art"
        strategy = "potrace"
    elif unique_colors < 150 and contrast > 40:
        category = "flat-illustration"
        strategy = "potrace" if is_monochrome else "vtracer-color"
    elif unique_colors > 500 or contrast < 30:
        category = "complex"
        strategy = "vtracer-color"
    else:
        category = "mixed"
        strategy = "layer-separation"

    # Recommend parameters based on analysis
    if strategy == "potrace":
        params = {
            "blur": "0x0.5" if edge_density > 5 else "0x0.8",
            "threshold": "38%" if contrast > 80 else "42%",
            "dilate": "Disk:1",
            "turdsize": 6 if edge_density > 3 else 10,
            "alphamax": 1.2,
            "opttolerance_detailed": 0.5,
            "opttolerance_minimal": 0.8,
        }
    else:
        params = {
            "filter_speckle": 2 if edge_density > 5 else 4,
            "color_precision": 6,
            "layer_difference": 16,
        }

    result = {
        "dimensions": f"{w}x{h}",
        "has_alpha": bool(has_alpha),
        "contrast": round(contrast, 1),
        "edge_density": round(edge_density, 1),
        "unique_colors": int(unique_colors),
        "saturation": round(float(saturation), 1),
        "is_monochrome": bool(is_monochrome),
        "bg_color": bg_hex,
        "category": category,
        "strategy": strategy,
        "params": params,
    }

    return result


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: analyze-image.py <image_path>", file=sys.stderr)
        sys.exit(1)
    result = analyze(sys.argv[1])
    print(json.dumps(result, indent=2))
