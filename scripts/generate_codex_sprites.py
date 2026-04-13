#!/usr/bin/env python3
"""
Generate pixel-art sprite sheets for the Codex "Repair Bot" character.

Design: A tiny glowing repair robot
- Round dome head with visor + antenna light
- Tool backpack on back (visible from side)
- Short mechanical arms
- Palette: warm orange + cyan-blue, high contrast
- Hover/float idle animation, thinking light flash
- Personality: reliable, friendly, always ready

Each sprite sheet: 64x64 per frame
- Most states: 6 frames (384x64)
- Compacting: 5 frames (320x64)

States × Emotions = 16 sheets total:
  idle_{neutral,happy,sad,sob}
  working_{neutral,happy,sad,sob}
  waiting_{neutral,happy,sad,sob}
  sleeping_{neutral,happy}
  compacting_{neutral,happy}
"""

from PIL import Image, ImageDraw
import os, math

ASSETS = os.path.join(os.path.dirname(__file__), "..", "notchi", "notchi", "Assets.xcassets")

# === COLOR PALETTE ===
P = {
    # Main body - warm orange
    'body':         (255, 152, 56),    # orange main
    'body_hi':      (255, 196, 112),   # orange highlight
    'body_dk':      (204, 108, 20),    # orange dark
    'body_shadow':  (153, 76, 10),     # deep shadow

    # Accents - cyan blue
    'cyan':         (56, 204, 232),    # cyan main
    'cyan_hi':      (128, 232, 255),   # cyan bright
    'cyan_dk':      (20, 148, 180),    # cyan dark

    # Visor / eyes
    'visor':        (56, 204, 232),    # same cyan
    'visor_hi':     (180, 244, 255),   # visor glint
    'visor_dk':     (20, 120, 156),    # visor shadow

    # Antenna light
    'light_on':     (255, 255, 180),   # warm white-yellow glow
    'light_glow':   (255, 220, 100),   # glow halo
    'light_off':    (180, 140, 60),    # dimmed light

    # Backpack
    'pack':         (80, 90, 100),     # dark gray-blue
    'pack_hi':      (120, 135, 148),   # highlight
    'pack_dk':      (50, 58, 66),      # dark

    # Outline
    'outline':      (40, 30, 20),      # near-black warm
    'outline_soft':  (80, 60, 40),     # soft outline

    # Misc
    'white':        (255, 255, 255),
    'cheek':        (255, 180, 120),   # happy blush
    'tear':         (100, 180, 255),   # sad tear
    'tear_hi':      (160, 220, 255),   # tear highlight
    'zzz':          (128, 200, 255),   # sleep Z
    'spark':        (255, 240, 140),   # working spark
    'question':     (56, 204, 232),    # waiting ?
    'none':         (0, 0, 0, 0),
}

def px(draw, x, y, color):
    if isinstance(color, tuple) and len(color) == 4 and color[3] == 0:
        return
    draw.point((x, y), fill=color)

def rect(draw, x, y, w, h, color):
    if isinstance(color, tuple) and len(color) == 4 and color[3] == 0:
        return
    for dy in range(h):
        for dx in range(w):
            draw.point((x + dx, y + dy), fill=color)

def draw_circle_filled(draw, cx, cy, r, color):
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx*dx + dy*dy <= r*r:
                draw.point((cx + dx, cy + dy), fill=color)

def draw_circle_outline(draw, cx, cy, r, color):
    for dy in range(-r-1, r + 2):
        for dx in range(-r-1, r + 2):
            d = dx*dx + dy*dy
            if r*r - r <= d <= r*r + r:
                draw.point((cx + dx, cy + dy), fill=color)


# === ROBOT PARTS ===

def draw_antenna(draw, cx, head_top, light_color):
    """Antenna sticking up from dome top."""
    # Stem (2px wide, 5px tall)
    rect(draw, cx, head_top - 5, 2, 5, P['pack_hi'])
    rect(draw, cx, head_top - 5, 1, 5, P['pack'])
    # Light bulb (3x3)
    rect(draw, cx - 1, head_top - 8, 4, 3, light_color)
    px(draw, cx, head_top - 8, light_color)
    px(draw, cx + 1, head_top - 8, light_color)

def draw_head(draw, cx, cy, emotion='neutral'):
    """Round dome head with visor. cx,cy = center of head."""
    r = 9  # head radius
    # Head dome (filled circle)
    draw_circle_filled(draw, cx, cy, r, P['body'])
    # Highlight on upper-left quadrant
    draw_circle_filled(draw, cx - 2, cy - 2, r - 3, P['body_hi'])
    draw_circle_filled(draw, cx, cy, r - 3, P['body'])
    # Outline
    draw_circle_outline(draw, cx, cy, r, P['outline'])

    # Visor band (horizontal bar across face)
    visor_y = cy + 1
    visor_w = 14
    vx = cx - visor_w // 2
    rect(draw, vx, visor_y - 1, visor_w, 4, P['visor_dk'])
    rect(draw, vx + 1, visor_y, visor_w - 2, 2, P['visor'])
    # Visor glint
    px(draw, vx + 2, visor_y, P['visor_hi'])
    px(draw, vx + 3, visor_y, P['visor_hi'])

    if emotion == 'neutral':
        # Two bright eye dots
        px(draw, cx - 4, visor_y, P['white'])
        px(draw, cx - 3, visor_y, P['white'])
        px(draw, cx + 3, visor_y, P['white'])
        px(draw, cx + 4, visor_y, P['white'])
    elif emotion == 'happy':
        # ^^ happy eyes (arched)
        px(draw, cx - 4, visor_y, P['white'])
        px(draw, cx - 3, visor_y - 1, P['white'])
        px(draw, cx - 2, visor_y, P['white'])
        px(draw, cx + 2, visor_y, P['white'])
        px(draw, cx + 3, visor_y - 1, P['white'])
        px(draw, cx + 4, visor_y, P['white'])
    elif emotion == 'sad':
        # Droopy eyes
        px(draw, cx - 4, visor_y + 1, P['visor_hi'])
        px(draw, cx - 3, visor_y + 1, P['visor_hi'])
        px(draw, cx + 3, visor_y + 1, P['visor_hi'])
        px(draw, cx + 4, visor_y + 1, P['visor_hi'])
        # Dimmer visor
        rect(draw, vx + 1, visor_y, visor_w - 2, 2, P['visor_dk'])
        px(draw, cx - 4, visor_y + 1, P['visor_hi'])
        px(draw, cx + 4, visor_y + 1, P['visor_hi'])
    elif emotion == 'sob':
        # X_X eyes
        px(draw, cx - 4, visor_y - 1, P['white'])
        px(draw, cx - 2, visor_y + 1, P['white'])
        px(draw, cx - 3, visor_y, P['white'])
        px(draw, cx + 2, visor_y - 1, P['white'])
        px(draw, cx + 4, visor_y + 1, P['white'])
        px(draw, cx + 3, visor_y, P['white'])

    return visor_y  # return for tear positioning

def draw_body(draw, cx, by, emotion='neutral'):
    """Rectangular body with chest panel."""
    # Main body (12 wide, 12 tall)
    bw, bh = 12, 12
    bx = cx - bw // 2
    rect(draw, bx, by, bw, bh, P['body'])
    # Highlight left edge
    rect(draw, bx, by, 2, bh, P['body_hi'])
    # Shadow right edge
    rect(draw, bx + bw - 2, by, 2, bh, P['body_dk'])
    # Outline
    rect(draw, bx - 1, by, 1, bh, P['outline'])
    rect(draw, bx + bw, by, 1, bh, P['outline'])
    rect(draw, bx, by - 1, bw, 1, P['outline'])
    rect(draw, bx, by + bh, bw, 1, P['outline'])

    # Chest panel (cyan accent, 6x4 centered)
    pw, ph = 6, 4
    px_start = cx - pw // 2
    py_start = by + 3
    rect(draw, px_start, py_start, pw, ph, P['cyan_dk'])
    rect(draw, px_start + 1, py_start + 1, pw - 2, ph - 2, P['cyan'])
    # Panel glow dot
    px(draw, px_start + 2, py_start + 1, P['cyan_hi'])

    if emotion == 'happy':
        # Small cheek marks
        px(draw, bx + 1, by + bh - 3, P['cheek'])
        px(draw, bx + bw - 2, by + bh - 3, P['cheek'])

    return bx, by, bw, bh

def draw_backpack(draw, cx, by, bh):
    """Tool backpack on the right side of body."""
    pack_x = cx + 7
    pack_y = by + 2
    pack_w, pack_h = 5, bh - 3
    rect(draw, pack_x, pack_y, pack_w, pack_h, P['pack'])
    rect(draw, pack_x, pack_y, pack_w, 1, P['pack_hi'])
    rect(draw, pack_x, pack_y + pack_h - 1, pack_w, 1, P['pack_dk'])
    # Tool sticking out (wrench shape)
    px(draw, pack_x + 3, pack_y - 1, P['pack_hi'])
    px(draw, pack_x + 3, pack_y - 2, P['pack_hi'])
    px(draw, pack_x + 2, pack_y - 2, P['pack_hi'])
    px(draw, pack_x + 4, pack_y - 2, P['pack_hi'])
    # Outline
    rect(draw, pack_x - 1, pack_y, 1, pack_h, P['outline_soft'])
    rect(draw, pack_x + pack_w, pack_y, 1, pack_h, P['outline_soft'])

def draw_arms(draw, cx, by, frame=0, working=False):
    """Short mechanical arms."""
    bw = 12
    bx = cx - bw // 2
    arm_y = by + 3
    arm_len = 4

    # Left arm
    lax = bx - 3
    rect(draw, lax, arm_y, 3, 2, P['cyan_dk'])
    rect(draw, lax, arm_y, 2, 1, P['cyan'])
    # Claw/hand
    px(draw, lax - 1, arm_y, P['pack_hi'])
    px(draw, lax - 1, arm_y + 1, P['pack_hi'])

    # Right arm
    rax = bx + bw
    arm_swing = [0, 0, -1, -1, 0, 0][frame % 6] if working else 0
    rect(draw, rax, arm_y + arm_swing, 3, 2, P['cyan_dk'])
    rect(draw, rax + 1, arm_y + arm_swing, 2, 1, P['cyan'])
    px(draw, rax + 3, arm_y + arm_swing, P['pack_hi'])
    px(draw, rax + 3, arm_y + arm_swing + 1, P['pack_hi'])

    if working:
        # Tool in right hand
        px(draw, rax + 4, arm_y + arm_swing - 1, P['spark'])
        px(draw, rax + 4, arm_y + arm_swing, P['pack_hi'])

def draw_legs(draw, cx, by, bh, frame=0, hover_offset=0):
    """Short legs with hover glow."""
    bw = 12
    bx = cx - bw // 2
    leg_y = by + bh + 1
    # Left leg
    rect(draw, bx + 2, leg_y, 3, 3, P['body_dk'])
    rect(draw, bx + 1, leg_y + 3, 5, 2, P['outline'])
    # Right leg
    rect(draw, bx + bw - 5, leg_y, 3, 3, P['body_dk'])
    rect(draw, bx + bw - 6, leg_y + 3, 5, 2, P['outline'])

    # Hover glow under feet
    glow_y = leg_y + 5 + hover_offset
    glow_alpha = [180, 140, 100, 140, 180, 160][frame % 6]
    glow_color = (56, 204, 232, glow_alpha)
    for i in range(10):
        px(draw, bx + 1 + i, glow_y, glow_color)
    for i in range(6):
        px(draw, bx + 3 + i, glow_y + 1, (56, 204, 232, glow_alpha // 2))

def draw_tears(draw, cx, visor_y, frame):
    """Falling tears for sob emotion."""
    tear_offset = frame % 3
    # Left tear
    tx1 = cx - 5
    ty = visor_y + 3 + tear_offset
    px(draw, tx1, ty, P['tear'])
    px(draw, tx1, ty + 1, P['tear'])
    if tear_offset > 0:
        px(draw, tx1, ty - 1, P['tear_hi'])
    # Right tear
    tx2 = cx + 5
    px(draw, tx2, ty, P['tear'])
    px(draw, tx2, ty + 1, P['tear'])
    if tear_offset > 0:
        px(draw, tx2, ty - 1, P['tear_hi'])

def draw_thought_bubble(draw, cx, top_y, frame):
    """Thought bubble above head for working state."""
    bx = cx + 6
    by = top_y - 4
    # Small dots leading up
    dot_off = [0, -1, 0, 1, 0, -1][frame % 6]
    px(draw, cx + 3, top_y + 2 + dot_off, P['white'])
    px(draw, cx + 5, top_y - 1 + dot_off, P['white'])
    # Bubble
    rect(draw, bx - 1, by - 3, 6, 4, P['white'])
    # Gear inside bubble
    px(draw, bx + 1, by - 2, P['cyan'])
    px(draw, bx + 2, by - 1, P['cyan'])
    px(draw, bx, by - 1, P['cyan'])
    px(draw, bx + 1, by, P['cyan_dk'])

def draw_question_mark(draw, cx, top_y, frame):
    """Question mark for waiting state."""
    qx = cx - 8
    qy = top_y - 2
    vis = frame % 6 < 4
    if vis:
        px(draw, qx, qy - 4, P['question'])
        px(draw, qx + 1, qy - 4, P['question'])
        px(draw, qx + 2, qy - 3, P['question'])
        px(draw, qx + 1, qy - 2, P['question'])
        px(draw, qx, qy - 1, P['question'])
        # Dot
        px(draw, qx, qy + 1, P['question'])

def draw_zzz(draw, cx, top_y, frame):
    """ZZZ for sleeping."""
    base_x = cx + 10
    off = -(frame % 3)
    # Z 1
    zx, zy = base_x, top_y + off
    px(draw, zx, zy, P['zzz'])
    px(draw, zx + 1, zy, P['zzz'])
    px(draw, zx + 1, zy + 1, P['zzz'])
    px(draw, zx, zy + 2, P['zzz'])
    px(draw, zx + 1, zy + 2, P['zzz'])
    # Z 2 (smaller, higher)
    if frame >= 2:
        z2x, z2y = base_x + 3, top_y - 4 + off
        px(draw, z2x, z2y, P['zzz'])
        px(draw, z2x + 1, z2y, P['zzz'])
        px(draw, z2x, z2y + 1, P['zzz'])
        px(draw, z2x + 1, z2y + 1, P['zzz'])

def draw_sparks(draw, cx, arm_y, frame):
    """Working sparks near hands."""
    spark_positions = [
        [(cx + 12, arm_y - 1), (cx - 8, arm_y + 2)],
        [(cx + 13, arm_y), (cx - 7, arm_y)],
        [(cx + 11, arm_y + 1), (cx - 9, arm_y + 1)],
        [(cx + 12, arm_y - 2), (cx - 8, arm_y - 1)],
        [(cx + 10, arm_y), (cx - 7, arm_y + 2)],
        [(cx + 13, arm_y + 1), (cx - 9, arm_y)],
    ]
    colors = [P['spark'], P['white'], P['spark']]
    for i, (sx, sy) in enumerate(spark_positions[frame % 6]):
        c = colors[i % len(colors)]
        px(draw, sx, sy, c)


# === FULL ROBOT DRAWING ===

def draw_robot(draw, ox, oy, frame=0, emotion='neutral',
               state='idle', light_on=True):
    """
    Draw complete robot at offset (ox, oy).
    Robot centered at (ox+32, oy+42) in 64x64 frame.
    """
    cx = ox + 32
    # Hover bob
    bob_offsets = {
        'idle':       [0, -1, -2, -1, 0, 1],
        'working':    [0, -1, 0, 1, 0, -1],
        'waiting':    [0, -1, -1, 0, 1, 1],
        'sleeping':   [0, 0, 0, 0, 0, 0],
        'compacting': [0, 0, 0, 0, 0],
    }
    bob = bob_offsets.get(state, [0]*6)[frame % len(bob_offsets.get(state, [0]*6))]

    if state == 'sleeping':
        # Lying down: shift everything down, tilt
        head_cy = oy + 46 + bob
        body_top = head_cy + 4
        antenna_light = P['light_off']
        draw_antenna(draw, cx + 1, head_cy - 8, antenna_light)
        visor_y = draw_head(draw, cx, head_cy, emotion)
        # Closed visor
        visor_w = 14
        vx = cx - visor_w // 2
        rect(draw, vx + 1, visor_y, visor_w - 2, 2, P['visor_dk'])
        # Horizontal lines for closed eyes
        px(draw, cx - 4, visor_y, P['visor_hi'])
        px(draw, cx - 3, visor_y, P['visor_hi'])
        px(draw, cx - 2, visor_y, P['visor_hi'])
        px(draw, cx + 2, visor_y, P['visor_hi'])
        px(draw, cx + 3, visor_y, P['visor_hi'])
        px(draw, cx + 4, visor_y, P['visor_hi'])
        # Body drawn wider/flatter
        bw, bh = 14, 8
        bx_s = cx - bw // 2
        rect(draw, bx_s, body_top, bw, bh, P['body'])
        rect(draw, bx_s, body_top, 2, bh, P['body_hi'])
        rect(draw, bx_s + bw - 2, body_top, 2, bh, P['body_dk'])
        # Chest panel
        rect(draw, cx - 3, body_top + 2, 6, 3, P['cyan_dk'])
        rect(draw, cx - 2, body_top + 3, 4, 1, P['cyan'])
        # Stubby arms flat
        rect(draw, bx_s - 2, body_top + 2, 2, 2, P['cyan_dk'])
        rect(draw, bx_s + bw, body_top + 2, 2, 2, P['cyan_dk'])
        # Legs tucked
        rect(draw, cx - 3, body_top + bh, 2, 2, P['body_dk'])
        rect(draw, cx + 1, body_top + bh, 2, 2, P['body_dk'])
        # Ground shadow
        for i in range(14):
            px(draw, bx_s + i, body_top + bh + 2, P['outline_soft'])
        # Backpack flat
        rect(draw, cx + 8, body_top + 1, 4, bh - 2, P['pack'])
        # ZZZ
        draw_zzz(draw, cx, head_cy - 10, frame)
        if emotion == 'happy':
            px(draw, cx - 6, head_cy + 3, P['cheek'])
            px(draw, cx + 6, head_cy + 3, P['cheek'])
        return

    if state == 'compacting':
        # Shrinking animation
        scales = [1.0, 0.7, 0.35, 0.1, 1.0]
        s = scales[frame % 5]
        if s < 0.2:
            # Tiny dot
            px(draw, cx, oy + 56, P['body'])
            px(draw, cx + 1, oy + 56, P['body'])
            px(draw, cx, oy + 57, P['cyan'])
            return
        head_cy = oy + int(32 + (1 - s) * 12) + bob
        # Draw at reduced scale conceptually (simulated)
        if s < 0.5:
            # Medium-small: just head + mini body
            r = 5
            draw_circle_filled(draw, cx, head_cy, r, P['body'])
            draw_circle_outline(draw, cx, head_cy, r, P['outline'])
            rect(draw, cx - 3, head_cy - 1, 6, 2, P['visor'])
            px(draw, cx - 2, head_cy - 1, P['white'])
            px(draw, cx + 2, head_cy - 1, P['white'])
            rect(draw, cx - 3, head_cy + r + 1, 6, 4, P['body_dk'])
            rect(draw, cx - 2, head_cy + r + 2, 4, 2, P['cyan'])
            return
        # Full size (s >= 0.7)
        pass  # Fall through to normal draw

    # Normal states
    head_cy = oy + 36 + bob
    body_top = head_cy + 10

    # Antenna
    light_color = P['light_on'] if light_on else P['light_off']
    if state == 'working':
        # Pulsing light
        light_color = [P['light_on'], P['light_glow'], P['light_on'],
                      P['light_glow'], P['light_on'], P['light_on']][frame % 6]
    elif state == 'waiting':
        # Slow blink
        light_color = P['light_on'] if frame % 6 < 3 else P['light_off']

    draw_antenna(draw, cx, head_cy - 9, light_color)

    # Glow halo around antenna when on
    if light_color in (P['light_on'], P['light_glow']):
        for dx in [-2, -1, 0, 1, 2, 3]:
            for dy in [-1, 0, 1]:
                if abs(dx) + abs(dy) <= 2:
                    gx, gy = cx + dx, head_cy - 14 + dy
                    px(draw, gx, gy, (*P['light_glow'][:3], 60))

    # Head
    visor_y = draw_head(draw, cx, head_cy, emotion)

    # Body
    draw_body(draw, cx, body_top, emotion)

    # Backpack
    draw_backpack(draw, cx, body_top, 12)

    # Arms
    draw_arms(draw, cx, body_top, frame, working=(state == 'working'))

    # Legs + hover glow
    draw_legs(draw, cx, body_top, 12, frame, hover_offset=abs(bob))

    # State-specific decorations
    if state == 'working':
        draw_thought_bubble(draw, cx, head_cy - 10, frame)
        draw_sparks(draw, cx, body_top + 3, frame)
    elif state == 'waiting':
        draw_question_mark(draw, cx, head_cy - 10, frame)

    # Emotion-specific
    if emotion == 'sob':
        draw_tears(draw, cx, visor_y, frame)
    elif emotion == 'sad' and state not in ('sleeping',):
        # Single small tear on one side
        if frame % 4 < 2:
            px(draw, cx - 5, visor_y + 3, P['tear'])


# === SPRITE SHEET GENERATORS ===

def generate_sheet(name, state, emotion, frame_count=6):
    w = 64 * frame_count
    h = 64
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    for f in range(frame_count):
        ox = f * 64
        light_on = True
        if state == 'idle':
            light_on = (f % 4 == 0)
        elif state == 'sleeping':
            light_on = False

        draw_robot(draw, ox, 0, frame=f, emotion=emotion,
                  state=state, light_on=light_on)

    return img


SPRITE_SPECS = [
    ('codex_idle_neutral',       'idle',       'neutral', 6),
    ('codex_idle_happy',         'idle',       'happy',   6),
    ('codex_idle_sad',           'idle',       'sad',     6),
    ('codex_idle_sob',           'idle',       'sob',     6),
    ('codex_working_neutral',    'working',    'neutral', 6),
    ('codex_working_happy',      'working',    'happy',   6),
    ('codex_working_sad',        'working',    'sad',     6),
    ('codex_working_sob',        'working',    'sob',     6),
    ('codex_waiting_neutral',    'waiting',    'neutral', 6),
    ('codex_waiting_happy',      'waiting',    'happy',   6),
    ('codex_waiting_sad',        'waiting',    'sad',     6),
    ('codex_waiting_sob',        'waiting',    'sob',     6),
    ('codex_sleeping_neutral',   'sleeping',   'neutral', 6),
    ('codex_sleeping_happy',     'sleeping',   'happy',   6),
    ('codex_compacting_neutral', 'compacting', 'neutral', 5),
    ('codex_compacting_happy',   'compacting', 'happy',   5),
]

CONTENTS_JSON = """{
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
"""

def main():
    print("🤖 Generating Codex Repair Bot sprite sheets...\n")

    for name, state, emotion, frames in SPRITE_SPECS:
        img = generate_sheet(name, state, emotion, frames)
        w, h = img.size

        dst_dir = os.path.join(ASSETS, f"{name}.imageset")
        os.makedirs(dst_dir, exist_ok=True)

        img.save(os.path.join(dst_dir, "sprite_sheet.png"), "PNG")

        contents_path = os.path.join(dst_dir, "Contents.json")
        with open(contents_path, 'w') as f:
            f.write(CONTENTS_JSON)

        print(f"  ✅ {name} ({w}x{h}, {frames} frames)")

    print(f"\n🔧 Generated {len(SPRITE_SPECS)} Codex Repair Bot sprite sheets!")
    print("   Design: Round dome head, tool backpack, mechanical arms")
    print("   Palette: Warm orange + Cyan blue")

if __name__ == '__main__':
    main()
