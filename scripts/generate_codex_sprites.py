#!/usr/bin/env python3
"""
Generate Codex sprite sheets by re-coloring the original Claude sprites.
This preserves the exact same pixel art quality and design, just shifts the
warm brown/orange palette to a cool green/teal palette for Codex identity.

Additionally applies per-state visual modifications:
- idle:      Add small antenna dot on head (green glow)
- working:   Keep sparkle/thought effects, tint them green
- sleeping:  Keep sleep bubble, tint green  
- waiting:   Keep question mark / signal, tint green
- compacting: Keep compression animation, tint green
- happy:     Keep happy expression
- sad:       Keep sad expression
- sob:       Tint tears to a lighter cyan
"""

from PIL import Image
import os
import colorsys

ASSETS = os.path.join(os.path.dirname(__file__), "..", "notchi", "notchi", "Assets.xcassets")

CLAUDE_SPRITES = [
    'idle_neutral', 'idle_happy', 'idle_sad', 'idle_sob',
    'working_neutral', 'working_happy', 'working_sad', 'working_sob',
    'waiting_neutral', 'waiting_happy', 'waiting_sad', 'waiting_sob',
    'sleeping_neutral', 'sleeping_happy',
    'compacting_neutral', 'compacting_happy',
]

def rgb_to_hsv(r, g, b):
    return colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)

def hsv_to_rgb(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    return (int(r * 255), int(g * 255), int(b * 255))

def remap_color(r, g, b, a):
    if a < 10:
        return (r, g, b, a)

    h, s, v = rgb_to_hsv(r, g, b)

    is_tear = (b > 150 and r < 150 and g < 200 and b > g)
    if is_tear:
        return (int(r * 0.7), int(min(255, g * 1.1)), int(min(255, b * 0.9)), a)

    is_white = (r > 230 and g > 230 and b > 230)
    if is_white:
        return (min(255, r - 5), min(255, g + 5), min(255, b - 10), a)

    is_near_black = (v < 0.15)
    if is_near_black:
        nr, ng, nb = hsv_to_rgb(0.42, min(s * 1.3, 0.5), v)
        return (nr, ng, nb, a)

    is_dark_brown = (v < 0.35 and s > 0.2)
    if is_dark_brown:
        new_h = 0.42
        new_s = min(s * 1.2 + 0.15, 0.7)
        new_v = v * 1.05
        nr, ng, nb = hsv_to_rgb(new_h, new_s, new_v)
        return (nr, ng, nb, a)

    is_warm = (0.0 <= h <= 0.12) or (h >= 0.92)
    is_red_accent = (r > 150 and g < 100 and b < 100)

    if is_warm or is_red_accent:
        if is_red_accent:
            new_h = 0.38
            new_s = min(s * 0.9 + 0.1, 0.85)
            new_v = min(v * 1.1, 1.0)
        elif v > 0.7:
            new_h = 0.35 + (h - 0.05) * 0.3
            new_s = min(s * 0.85 + 0.1, 0.9)
            new_v = min(v * 1.05, 1.0)
        elif v > 0.4:
            new_h = 0.40
            new_s = min(s * 0.9 + 0.15, 0.85)
            new_v = min(v * 1.0, 1.0)
        else:
            new_h = 0.42
            new_s = min(s * 1.0 + 0.1, 0.75)
            new_v = v
        nr, ng, nb = hsv_to_rgb(new_h, new_s, new_v)
        return (nr, ng, nb, a)

    if 0.12 < h < 0.92:
        new_h = h
        if 0.12 < h < 0.2:
            new_h = 0.28 + (h - 0.12) * 2
        return (*hsv_to_rgb(new_h, s, v), a)

    return (r, g, b, a)


def add_antenna_detail(img, frame_idx, frame_count):
    w, h = img.size
    frame_w = w // frame_count
    
    for f in range(frame_count):
        fx = f * frame_w
        
        for y in range(h):
            for x in range(frame_w):
                r, g, b, a = img.getpixel((fx + x, y))
                if a > 200:
                    top_y = y
                    break
            else:
                continue
            break
        
        mid_x = fx + frame_w // 2
        
        glow_color = (74, 222, 128, 220)
        bright_color = (134, 239, 172, 255)
        
        if f % 3 == 0:
            img.putpixel((mid_x, top_y - 2), bright_color)
            img.putpixel((mid_x + 1, top_y - 2), bright_color)
            img.putpixel((mid_x, top_y - 1), glow_color)
            img.putpixel((mid_x + 1, top_y - 1), glow_color)
        else:
            img.putpixel((mid_x, top_y - 1), glow_color)
            img.putpixel((mid_x + 1, top_y - 1), glow_color)


def process_sprite(claude_name):
    codex_name = f"codex_{claude_name}"
    src_path = os.path.join(ASSETS, f"{claude_name}.imageset", "sprite_sheet.png")
    
    if not os.path.exists(src_path):
        print(f"  ⚠️  Source not found: {claude_name}")
        return False

    img = Image.open(src_path).convert('RGBA')
    w, h = img.size
    
    new_img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    
    for y in range(h):
        for x in range(w):
            pixel = img.getpixel((x, y))
            new_pixel = remap_color(*pixel)
            new_img.putpixel((x, y), new_pixel)
    
    frame_count = w // 64
    
    task = claude_name.split('_')[0]
    if task in ('idle', 'working', 'waiting'):
        add_antenna_detail(new_img, 0, frame_count)
    
    dst_dir = os.path.join(ASSETS, f"{codex_name}.imageset")
    os.makedirs(dst_dir, exist_ok=True)
    
    dst_path = os.path.join(dst_dir, "sprite_sheet.png")
    new_img.save(dst_path, 'PNG')
    
    contents_path = os.path.join(dst_dir, "Contents.json")
    with open(contents_path, 'w') as f:
        f.write("""{
  "images" : [
    {
      "filename" : "sprite_sheet.png",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "preserves-vector-representation" : false
  }
}
""")
    
    print(f"  ✅ {codex_name} ({w}x{h})")
    return True


def main():
    print("🎨 Generating Codex sprites by re-coloring Claude sprites...\n")
    
    success = 0
    for name in CLAUDE_SPRITES:
        if process_sprite(name):
            success += 1
    
    print(f"\n🤖 Generated {success}/{len(CLAUDE_SPRITES)} Codex sprite sheets!")
    print("   Palette: warm brown/orange → cool green/teal")


if __name__ == '__main__':
    main()
