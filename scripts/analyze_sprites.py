#!/usr/bin/env python3
"""Analyze existing Claude sprite sheets to understand pixel art design patterns."""
import struct
import zlib
import os
import collections

ASSETS = os.path.join(os.path.dirname(__file__), "..", "notchi", "notchi", "Assets.xcassets")

def read_png(path):
    with open(path, 'rb') as f:
        sig = f.read(8)
        chunks = {}
        idat_data = b''
        width = height = 0
        while True:
            raw = f.read(4)
            if len(raw) < 4:
                break
            length = struct.unpack('>I', raw)[0]
            chunk_type = f.read(4)
            data = f.read(length)
            crc = f.read(4)
            if chunk_type == b'IHDR':
                width, height = struct.unpack('>II', data[:8])
                bit_depth, color_type = data[8], data[9]
            elif chunk_type == b'IDAT':
                idat_data += data
        
        raw_data = zlib.decompress(idat_data)
        pixels = []
        bpp = 4  # RGBA
        stride = width * bpp + 1
        for y in range(height):
            row_start = y * stride
            filter_byte = raw_data[row_start]
            row = []
            for x in range(width):
                idx = row_start + 1 + x * bpp
                r, g, b, a = raw_data[idx], raw_data[idx+1], raw_data[idx+2], raw_data[idx+3]
                
                # Handle PNG filters (simplified - filter 0 = None, 1 = Sub, 2 = Up)
                if filter_byte == 1:  # Sub
                    if x > 0:
                        pr, pg, pb, pa = row[-1]
                        r = (r + pr) % 256
                        g = (g + pg) % 256
                        b = (b + pb) % 256
                        a = (a + pa) % 256
                elif filter_byte == 2:  # Up
                    if y > 0:
                        ur, ug, ub, ua = pixels[y-1][x]
                        r = (r + ur) % 256
                        g = (g + ug) % 256
                        b = (b + ub) % 256
                        a = (a + ua) % 256
                
                row.append((r, g, b, a))
            pixels.append(row)
        return width, height, pixels

def analyze_sprite(name):
    path = os.path.join(ASSETS, f"{name}.imageset", "sprite_sheet.png")
    if not os.path.exists(path):
        return None
    w, h, pixels = read_png(path)
    
    # Collect unique colors (ignoring transparent)
    colors = collections.Counter()
    frame_count = w // 64
    
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[y][x]
            if a > 0:
                colors[(r, g, b, a)] += 1
    
    # Find bounding box per frame
    frames_info = []
    for f in range(frame_count):
        fx = f * 64
        min_x, min_y, max_x, max_y = 64, 64, 0, 0
        px_count = 0
        for y in range(h):
            for x in range(64):
                r, g, b, a = pixels[y][fx + x]
                if a > 0:
                    min_x = min(min_x, x)
                    min_y = min(min_y, y)
                    max_x = max(max_x, x)
                    max_y = max(max_y, y)
                    px_count += 1
        frames_info.append({
            'bbox': (min_x, min_y, max_x, max_y),
            'size': (max_x - min_x + 1, max_y - min_y + 1) if px_count > 0 else (0, 0),
            'pixels': px_count
        })
    
    return {
        'name': name,
        'dimensions': f"{w}x{h}",
        'frames': frame_count,
        'unique_colors': len(colors),
        'top_colors': colors.most_common(15),
        'frames_info': frames_info,
    }

# Analyze all Claude sprites
claude_sprites = [
    'idle_neutral', 'idle_happy', 'idle_sad', 'idle_sob',
    'working_neutral', 'working_happy', 'working_sad', 'working_sob',
    'waiting_neutral', 'waiting_happy', 'waiting_sad', 'waiting_sob',
    'sleeping_neutral', 'sleeping_happy',
    'compacting_neutral', 'compacting_happy',
]

for name in claude_sprites:
    info = analyze_sprite(name)
    if info:
        print(f"\n{'='*60}")
        print(f"📊 {info['name']} — {info['dimensions']}, {info['frames']} frames, {info['unique_colors']} colors")
        print(f"Top colors (RGBA, count):")
        for c, cnt in info['top_colors']:
            print(f"  #{c[0]:02x}{c[1]:02x}{c[2]:02x} a={c[3]:3d} — {cnt:5d}px")
        for i, fi in enumerate(info['frames_info']):
            print(f"  Frame {i}: bbox={fi['bbox']} size={fi['size']} px={fi['pixels']}")
