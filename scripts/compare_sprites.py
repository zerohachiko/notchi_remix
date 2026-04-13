#!/usr/bin/env python3
"""Quick comparison: dump codex sprite side-by-side with claude to verify quality."""
from PIL import Image
import os

ASSETS = os.path.join(os.path.dirname(__file__), "..", "notchi", "notchi", "Assets.xcassets")

def dump_frame_colored(img, fx, fy, fw, fh):
    lines = []
    for y in range(fy, fy + fh):
        line = ''
        for x in range(fx, fx + fw):
            r, g, b, a = img.getpixel((x, y))
            if a < 10:
                line += '.'
            else:
                lum = (r + g + b) / 3
                if lum > 200: line += 'W'
                elif lum > 150: line += '#'
                elif lum > 100: line += 'o'
                elif lum > 60: line += '+'
                elif lum > 30: line += '-'
                else: line += '@'
        lines.append(line)
    return lines

pairs = [
    ('idle_neutral', 'codex_idle_neutral'),
    ('working_neutral', 'codex_working_neutral'),
    ('sleeping_neutral', 'codex_sleeping_neutral'),
    ('idle_sob', 'codex_idle_sob'),
]

for claude_name, codex_name in pairs:
    claude_path = os.path.join(ASSETS, f"{claude_name}.imageset", "sprite_sheet.png")
    codex_path = os.path.join(ASSETS, f"{codex_name}.imageset", "sprite_sheet.png")
    
    ci = Image.open(claude_path).convert('RGBA')
    xi = Image.open(codex_path).convert('RGBA')
    
    cl = dump_frame_colored(ci, 0, 0, 64, 64)
    xl = dump_frame_colored(xi, 0, 0, 64, 64)
    
    print(f"\n{'='*140}")
    print(f"  {claude_name:30s}  vs  {codex_name:30s}")
    print(f"{'='*140}")
    
    for i in range(64):
        cs = cl[i].rstrip('.')
        xs = xl[i].rstrip('.')
        if cs or xs:
            print(f"{i:2d}|{cl[i]}|  |{xl[i]}|")
