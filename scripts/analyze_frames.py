#!/usr/bin/env python3
"""Analyze Claude sprites per-frame: extract bounding boxes, key feature locations."""
from PIL import Image
import os

ASSETS = os.path.join(os.path.dirname(__file__), "..", "notchi", "notchi", "Assets.xcassets")

def get_opaque_pixels(img, fx, fw, fh):
    """Return set of (x,y) with alpha > 0 within a frame."""
    pts = set()
    for y in range(fh):
        for x in range(fw):
            r, g, b, a = img.getpixel((fx + x, y))
            if a > 10:
                pts.add((x, y))
    return pts

sprites = [
    'idle_neutral', 'idle_happy', 'idle_sad', 'idle_sob',
    'working_neutral', 'sleeping_neutral', 'waiting_neutral', 'compacting_neutral',
]

for name in sprites:
    path = os.path.join(ASSETS, f"{name}.imageset", "sprite_sheet.png")
    if not os.path.exists(path):
        continue
    img = Image.open(path).convert('RGBA')
    w, h = img.size
    fc = w // 64
    
    print(f"\n{'='*60}")
    print(f"  {name}  ({w}x{h}, {fc} frames)")
    
    for f in range(fc):
        pts = get_opaque_pixels(img, f * 64, 64, 64)
        if not pts:
            print(f"  Frame {f}: empty")
            continue
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        print(f"  Frame {f}: bbox=({min(xs)},{min(ys)})→({max(xs)},{max(ys)})  "
              f"size={max(xs)-min(xs)+1}x{max(ys)-min(ys)+1}  "
              f"px={len(pts)}  "
              f"center=({(min(xs)+max(xs))//2},{(min(ys)+max(ys))//2})")
    
    # Compare frame 0 vs frame 1 pixel diff
    f0 = get_opaque_pixels(img, 0, 64, 64)
    f1 = get_opaque_pixels(img, 64, 64, 64)
    diff = f0.symmetric_difference(f1)
    print(f"  Frame 0↔1 diff: {len(diff)} pixels changed")
