#!/usr/bin/env python3
"""Dump pixel-level layout of Claude sprite frames as ASCII art for design reference."""
import struct, zlib, os

ASSETS = os.path.join(os.path.dirname(__file__), "..", "notchi", "notchi", "Assets.xcassets")

def read_png_pillow(path):
    """Use PIL if available for accurate filter handling."""
    try:
        from PIL import Image
        img = Image.open(path).convert('RGBA')
        w, h = img.size
        pixels = []
        for y in range(h):
            row = []
            for x in range(w):
                row.append(img.getpixel((x, y)))
            pixels.append(row)
        return w, h, pixels
    except ImportError:
        return None

def dump_frame(pixels, fx, fy, fw, fh):
    """Dump a single frame as colored ASCII."""
    lines = []
    for y in range(fy, fy + fh):
        line = ''
        for x in range(fx, fx + fw):
            r, g, b, a = pixels[y][x]
            if a < 10:
                line += '.'
            else:
                lum = (r + g + b) / 3
                if lum > 200:
                    line += 'W'
                elif lum > 150:
                    line += '#'
                elif lum > 100:
                    line += 'o'
                elif lum > 60:
                    line += '+'
                elif lum > 30:
                    line += '-'
                else:
                    line += '@'
            
        lines.append(line)
    return lines

sprites = ['idle_neutral', 'working_neutral', 'sleeping_neutral', 'waiting_neutral', 'compacting_neutral',
           'idle_happy', 'idle_sad', 'idle_sob']

for name in sprites:
    path = os.path.join(ASSETS, f"{name}.imageset", "sprite_sheet.png")
    result = read_png_pillow(path)
    if result is None:
        print(f"PIL not available, skipping {name}")
        continue
    w, h, pixels = result
    frame_count = w // 64
    print(f"\n{'='*70}")
    print(f"  {name}  ({w}x{h}, {frame_count} frames)")
    print(f"{'='*70}")
    for f_idx in range(min(frame_count, 3)):  # First 3 frames only
        print(f"\n--- Frame {f_idx} ---")
        lines = dump_frame(pixels, f_idx * 64, 0, 64, 64)
        for i, line in enumerate(lines):
            stripped = line.rstrip('.')
            if stripped:
                print(f"{i:2d}|{line}|")
