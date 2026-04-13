#!/usr/bin/env python3
"""
Generate pixel-art sprite sheets for a "small glowing repair robot" character.

Design – distinctly different from the Claude orange-blob sprite:
- Circular dome head with a wide cyan visor (wrap-around style)
- Orange body with rounded shoulders
- Small tool backpack mounted on the back
- Stubby mechanical arms with pincer hands
- Hover glow underneath (no visible legs while hovering)
- Antenna on top with a light that flashes when thinking

Each sprite sheet: 64x64 per frame, single row
- Most states: 6 frames → 384x64
- Compacting: 5 frames → 320x64

States × Emotions = 16 sheets:
  idle      × {neutral, happy, sad, sob}
  working   × {neutral, happy, sad, sob}
  waiting   × {neutral, happy, sad, sob}
  sleeping  × {neutral, happy}
  compacting× {neutral, happy}
"""

from PIL import Image, ImageDraw, ImageFilter
import os
import math

ASSETS = os.path.join(
    os.path.dirname(__file__), "..", "notchi", "notchi", "Assets.xcassets"
)

C = {
    "body": (245, 140, 50),
    "body_hi": (255, 190, 100),
    "body_dk": (195, 100, 20),
    "body_shadow": (140, 70, 10),
    "cyan": (0, 210, 240),
    "cyan_hi": (120, 240, 255),
    "cyan_dk": (0, 150, 180),
    "cyan_glow": (0, 210, 240, 90),
    "visor": (0, 190, 220),
    "visor_hi": (200, 250, 255),
    "visor_dk": (0, 110, 140),
    "visor_band": (0, 140, 170),
    "light_on": (255, 255, 200),
    "light_glow": (255, 230, 120),
    "light_off": (160, 130, 60),
    "light_halo": (255, 240, 150, 50),
    "pack": (70, 80, 95),
    "pack_hi": (110, 125, 140),
    "pack_dk": (45, 52, 60),
    "pack_rivet": (150, 160, 170),
    "outline": (30, 25, 20),
    "outline_soft": (70, 55, 40),
    "white": (255, 255, 255),
    "cheek": (255, 170, 110),
    "tear": (90, 170, 255),
    "tear_hi": (160, 215, 255),
    "zzz": (120, 195, 255),
    "spark": (255, 235, 130),
    "spark_white": (255, 255, 220),
    "question": (0, 210, 240),
    "hover": (0, 210, 240, 160),
    "hover_dim": (0, 210, 240, 60),
    "none": (0, 0, 0, 0),
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


def circle_filled(draw, cx, cy, r, color):
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx * dx + dy * dy <= r * r:
                draw.point((cx + dx, cy + dy), fill=color)


def circle_outline(draw, cx, cy, r, color):
    for dy in range(-r - 1, r + 2):
        for dx in range(-r - 1, r + 2):
            d = dx * dx + dy * dy
            if r * r - r <= d <= r * r + r:
                draw.point((cx + dx, cy + dy), fill=color)


def ellipse_filled(draw, cx, cy, rx, ry, color):
    for dy in range(-ry, ry + 1):
        for dx in range(-rx, rx + 1):
            if (dx * dx) / max(rx * rx, 1) + (dy * dy) / max(ry * ry, 1) <= 1.0:
                draw.point((cx + dx, cy + dy), fill=color)


def ellipse_outline(draw, cx, cy, rx, ry, color):
    for dy in range(-ry - 1, ry + 2):
        for dx in range(-rx - 1, rx + 2):
            val = (dx * dx) / max(rx * rx, 1) + (dy * dy) / max(ry * ry, 1)
            if 0.75 <= val <= 1.25:
                draw.point((cx + dx, cy + dy), fill=color)


# ---------- robot components ----------


def _antenna(draw, cx, top_y, light_color, frame=0):
    stem_x = cx
    stem_top = top_y - 6
    rect(draw, stem_x, stem_top, 2, 6, C["pack_hi"])
    rect(draw, stem_x, stem_top, 1, 6, C["pack"])

    bulb_cx = stem_x + 1
    bulb_cy = stem_top - 2
    circle_filled(draw, bulb_cx, bulb_cy, 2, light_color)
    px(draw, bulb_cx - 1, bulb_cy - 1, C["white"])


def _antenna_halo(draw, cx, top_y, active):
    if not active:
        return
    bulb_cx = cx + 1
    bulb_cy = top_y - 8
    for dy in range(-3, 4):
        for dx in range(-3, 4):
            if 4 <= dx * dx + dy * dy <= 12:
                px(draw, bulb_cx + dx, bulb_cy + dy, C["light_halo"])


def _dome_head(draw, cx, cy, emotion="neutral"):
    r = 10
    circle_filled(draw, cx, cy, r, C["body"])

    for dy in range(-r + 2, 0):
        for dx in range(-r + 2, r - 2):
            if dx * dx + dy * dy <= (r - 2) * (r - 2):
                if dx < 1 and dy < -1:
                    px(draw, cx + dx, cy + dy, C["body_hi"])

    circle_outline(draw, cx, cy, r, C["outline"])

    vy = cy + 1
    vw = 16
    vh = 5
    vx = cx - vw // 2
    rect(draw, vx, vy - 1, vw, vh, C["visor_dk"])
    rect(draw, vx + 1, vy, vw - 2, vh - 2, C["visor"])
    rect(draw, vx + 1, vy, 3, 1, C["visor_hi"])
    rect(draw, vx + 1, vy + 1, 2, 1, C["visor_hi"])

    rect(draw, vx - 1, vy, 1, vh - 1, C["visor_band"])
    rect(draw, vx + vw, vy, 1, vh - 1, C["visor_band"])

    _draw_eyes(draw, cx, vy, emotion)

    return vy


def _draw_eyes(draw, cx, vy, emotion):
    if emotion == "neutral":
        for ex in [cx - 4, cx + 4]:
            px(draw, ex, vy + 1, C["white"])
            px(draw, ex + 1, vy + 1, C["white"])
            px(draw, ex, vy + 2, C["white"])
            px(draw, ex + 1, vy + 2, C["white"])
    elif emotion == "happy":
        for ex in [cx - 4, cx + 4]:
            px(draw, ex, vy + 2, C["white"])
            px(draw, ex + 1, vy + 1, C["white"])
            px(draw, ex + 2, vy + 2, C["white"])
    elif emotion == "sad":
        for ex in [cx - 4, cx + 4]:
            px(draw, ex, vy + 1, C["visor_hi"])
            px(draw, ex + 1, vy + 2, C["visor_hi"])
    elif emotion == "sob":
        for ex in [cx - 4, cx + 4]:
            px(draw, ex, vy + 1, C["white"])
            px(draw, ex + 2, vy + 3, C["white"])
            px(draw, ex + 1, vy + 2, C["white"])
            px(draw, ex + 2, vy + 1, C["white"])
            px(draw, ex, vy + 3, C["white"])


def _torso(draw, cx, ty, emotion="neutral"):
    tw, th = 14, 14
    tx = cx - tw // 2
    ellipse_filled(draw, cx, ty + th // 2, tw // 2, th // 2, C["body"])
    rect(draw, tx, ty + 2, tw, th - 4, C["body"])
    rect(draw, tx, ty + 2, 2, th - 4, C["body_hi"])
    rect(draw, tx + tw - 2, ty + 2, 2, th - 4, C["body_dk"])

    ellipse_outline(draw, cx, ty + th // 2, tw // 2 + 1, th // 2, C["outline"])
    rect(draw, tx - 1, ty + 3, 1, th - 6, C["outline"])
    rect(draw, tx + tw, ty + 3, 1, th - 6, C["outline"])

    pw, ph = 8, 5
    ppx = cx - pw // 2
    ppy = ty + 4
    rect(draw, ppx, ppy, pw, ph, C["cyan_dk"])
    rect(draw, ppx + 1, ppy + 1, pw - 2, ph - 2, C["cyan"])
    px(draw, ppx + 2, ppy + 1, C["cyan_hi"])
    px(draw, ppx + 3, ppy + 1, C["cyan_hi"])
    px(draw, ppx + 1, ppy + 2, C["cyan_hi"])

    if emotion == "happy":
        px(draw, tx + 1, ty + th - 4, C["cheek"])
        px(draw, tx + tw - 2, ty + th - 4, C["cheek"])

    return tx, ty, tw, th


def _backpack(draw, cx, ty, th):
    bpx = cx + 8
    bpy = ty + 3
    bpw, bph = 6, th - 5
    rect(draw, bpx, bpy, bpw, bph, C["pack"])
    rect(draw, bpx, bpy, bpw, 1, C["pack_hi"])
    rect(draw, bpx, bpy + bph - 1, bpw, 1, C["pack_dk"])

    px(draw, bpx + 1, bpy + 2, C["pack_rivet"])
    px(draw, bpx + 4, bpy + 2, C["pack_rivet"])
    px(draw, bpx + 1, bpy + bph - 3, C["pack_rivet"])
    px(draw, bpx + 4, bpy + bph - 3, C["pack_rivet"])

    px(draw, bpx + 3, bpy - 1, C["pack_hi"])
    px(draw, bpx + 3, bpy - 2, C["pack_hi"])
    px(draw, bpx + 2, bpy - 2, C["pack_hi"])
    px(draw, bpx + 4, bpy - 2, C["pack_hi"])
    px(draw, bpx + 2, bpy - 3, C["pack_hi"])
    px(draw, bpx + 4, bpy - 3, C["pack_hi"])

    rect(draw, bpx - 1, bpy, 1, bph, C["outline_soft"])
    rect(draw, bpx + bpw, bpy, 1, bph, C["outline_soft"])


def _arms(draw, cx, ty, frame=0, working=False):
    tw = 14
    tx = cx - tw // 2
    arm_y = ty + 5
    seg = 4
    hand = 2

    lax = tx - seg - hand
    rect(draw, tx - seg, arm_y, seg, 3, C["cyan_dk"])
    rect(draw, tx - seg, arm_y, seg, 1, C["cyan"])
    px(draw, lax + 1, arm_y, C["pack_hi"])
    px(draw, lax, arm_y + 1, C["pack_hi"])
    px(draw, lax + 1, arm_y + 2, C["pack_hi"])

    swing = [0, -1, -2, -1, 0, 1][frame % 6] if working else 0
    rax = tx + tw
    rect(draw, rax, arm_y + swing, seg, 3, C["cyan_dk"])
    rect(draw, rax, arm_y + swing, seg, 1, C["cyan"])
    px(draw, rax + seg, arm_y + swing, C["pack_hi"])
    px(draw, rax + seg + 1, arm_y + swing + 1, C["pack_hi"])
    px(draw, rax + seg, arm_y + swing + 2, C["pack_hi"])

    if working:
        px(draw, rax + seg + 2, arm_y + swing - 1, C["spark"])
        px(draw, rax + seg + 1, arm_y + swing - 1, C["spark_white"])


def _hover_glow(draw, cx, bottom_y, frame):
    glow_w = 14
    gx = cx - glow_w // 2
    alpha_cycle = [180, 150, 120, 100, 120, 150]
    a = alpha_cycle[frame % 6]
    for i in range(glow_w):
        fade = max(0, a - abs(i - glow_w // 2) * 20)
        px(draw, gx + i, bottom_y, (0, 210, 240, fade))
    inner_w = 8
    ix = cx - inner_w // 2
    for i in range(inner_w):
        fade2 = max(0, a // 2 - abs(i - inner_w // 2) * 15)
        px(draw, ix + i, bottom_y + 1, (0, 210, 240, fade2))
    outer_w = 10
    ox2 = cx - outer_w // 2
    for i in range(outer_w):
        fade3 = max(0, a // 3 - abs(i - outer_w // 2) * 10)
        px(draw, ox2 + i, bottom_y - 1, (0, 210, 240, fade3))


def _tears(draw, cx, vy, frame):
    off = frame % 3
    for tx_base in [cx - 6, cx + 6]:
        ty = vy + 4 + off
        px(draw, tx_base, ty, C["tear"])
        px(draw, tx_base, ty + 1, C["tear"])
        if off > 0:
            px(draw, tx_base, ty - 1, C["tear_hi"])
        if off > 1:
            px(draw, tx_base, ty + 2, C["tear"])


def _thought_bubble(draw, cx, top_y, frame):
    bob = [0, -1, 0, 1, 0, -1][frame % 6]
    dot_x = cx + 4
    dot_y = top_y + 2 + bob
    px(draw, dot_x, dot_y, C["white"])
    px(draw, dot_x + 2, dot_y - 2, C["white"])

    bx = cx + 8
    by = top_y - 4 + bob
    rect(draw, bx - 1, by - 3, 7, 5, C["white"])
    circle_filled(draw, bx + 2, by - 1, 1, C["cyan"])
    px(draw, bx + 1, by - 2, C["cyan_dk"])
    px(draw, bx + 3, by, C["cyan_dk"])
    px(draw, bx + 1, by, C["cyan_dk"])
    px(draw, bx + 3, by - 2, C["cyan_dk"])


def _question_mark(draw, cx, top_y, frame):
    vis = frame % 6 < 4
    if not vis:
        return
    bob = [0, -1, -1, 0, 0, 0][frame % 6]
    qx = cx - 9
    qy = top_y - 1 + bob
    px(draw, qx, qy - 4, C["question"])
    px(draw, qx + 1, qy - 5, C["question"])
    px(draw, qx + 2, qy - 5, C["question"])
    px(draw, qx + 3, qy - 4, C["question"])
    px(draw, qx + 2, qy - 3, C["question"])
    px(draw, qx + 1, qy - 2, C["question"])
    px(draw, qx + 1, qy, C["question"])


def _zzz(draw, cx, top_y, frame):
    base_x = cx + 11
    drift = -(frame % 3)
    zx, zy = base_x, top_y + drift
    for d in range(3):
        px(draw, zx + d, zy, C["zzz"])
    px(draw, zx + 2, zy + 1, C["zzz"])
    px(draw, zx + 1, zy + 2, C["zzz"])
    for d in range(3):
        px(draw, zx + d, zy + 3, C["zzz"])
    if frame >= 2:
        z2x, z2y = base_x + 4, top_y - 5 + drift
        for d in range(2):
            px(draw, z2x + d, z2y, C["zzz"])
        px(draw, z2x + 1, z2y + 1, C["zzz"])
        for d in range(2):
            px(draw, z2x + d, z2y + 2, C["zzz"])


def _sparks(draw, cx, arm_y, frame):
    patterns = [
        [(cx + 14, arm_y - 2), (cx - 10, arm_y + 1)],
        [(cx + 15, arm_y - 1), (cx - 9, arm_y)],
        [(cx + 13, arm_y), (cx - 11, arm_y - 1)],
        [(cx + 14, arm_y - 3), (cx - 10, arm_y + 2)],
        [(cx + 12, arm_y - 1), (cx - 9, arm_y + 1)],
        [(cx + 15, arm_y), (cx - 11, arm_y)],
    ]
    colors = [C["spark"], C["spark_white"], C["spark"]]
    for i, (sx, sy) in enumerate(patterns[frame % 6]):
        px(draw, sx, sy, colors[i % len(colors)])
        px(draw, sx + 1, sy, colors[(i + 1) % len(colors)])


# ---------- full robot ----------


def draw_robot(draw, ox, oy, frame=0, emotion="neutral", state="idle", light_on=True):
    cx = ox + 32

    bob_table = {
        "idle": [0, -1, -2, -2, -1, 0],
        "working": [0, -1, 0, 1, 0, -1],
        "waiting": [0, -1, -1, 0, 1, 1],
        "sleeping": [0, 0, 0, 0, 0, 0],
        "compacting": [0, 0, 0, 0, 0],
    }
    seq = bob_table.get(state, [0] * 6)
    bob = seq[frame % len(seq)]

    if state == "sleeping":
        _draw_sleeping(draw, cx, oy, frame, emotion)
        return

    if state == "compacting":
        if _draw_compacting(draw, cx, oy, frame, emotion):
            return

    head_cy = oy + 24 + bob
    body_top = head_cy + 11

    light_color = C["light_on"] if light_on else C["light_off"]
    if state == "working":
        light_color = [
            C["light_on"],
            C["light_glow"],
            C["light_on"],
            C["light_glow"],
            C["light_on"],
            C["light_on"],
        ][frame % 6]
    elif state == "waiting":
        light_color = C["light_on"] if frame % 6 < 3 else C["light_off"]
    elif state == "idle":
        light_color = C["light_on"] if frame % 4 != 1 else C["light_off"]

    _antenna(draw, cx, head_cy - 10, light_color, frame)
    _antenna_halo(draw, cx, head_cy - 10, light_color != C["light_off"])

    vy = _dome_head(draw, cx, head_cy, emotion)

    _torso(draw, cx, body_top, emotion)
    _backpack(draw, cx, body_top, 14)
    _arms(draw, cx, body_top, frame, working=(state == "working"))

    hover_y = body_top + 16
    _hover_glow(draw, cx, hover_y, frame)

    if state == "working":
        _thought_bubble(draw, cx, head_cy - 12, frame)
        _sparks(draw, cx, body_top + 5, frame)
    elif state == "waiting":
        _question_mark(draw, cx, head_cy - 12, frame)

    if emotion == "sob":
        _tears(draw, cx, vy, frame)
    elif emotion == "sad" and state != "sleeping":
        if frame % 4 < 2:
            px(draw, cx - 6, vy + 4, C["tear"])


def _draw_sleeping(draw, cx, oy, frame, emotion):
    head_cy = oy + 40
    body_top = head_cy + 6

    _antenna(draw, cx + 1, head_cy - 9, C["light_off"])

    vy = _dome_head(draw, cx, head_cy, "neutral")
    vw = 16
    vx = cx - vw // 2
    rect(draw, vx + 1, vy, vw - 2, 3, C["visor_dk"])
    for ex in [cx - 4, cx + 4]:
        px(draw, ex, vy + 1, C["visor_hi"])
        px(draw, ex + 1, vy + 1, C["visor_hi"])
        px(draw, ex + 2, vy + 1, C["visor_hi"])

    bw, bh = 16, 9
    bx = cx - bw // 2
    rect(draw, bx, body_top, bw, bh, C["body"])
    rect(draw, bx, body_top, 2, bh, C["body_hi"])
    rect(draw, bx + bw - 2, body_top, 2, bh, C["body_dk"])
    rect(draw, cx - 4, body_top + 2, 8, 4, C["cyan_dk"])
    rect(draw, cx - 3, body_top + 3, 6, 2, C["cyan"])

    rect(draw, bx - 2, body_top + 3, 2, 2, C["cyan_dk"])
    rect(draw, bx + bw, body_top + 3, 2, 2, C["cyan_dk"])

    rect(draw, cx - 3, body_top + bh, 2, 2, C["body_dk"])
    rect(draw, cx + 1, body_top + bh, 2, 2, C["body_dk"])
    for i in range(16):
        px(draw, bx + i, body_top + bh + 2, C["outline_soft"])

    rect(draw, cx + 9, body_top + 1, 5, bh - 2, C["pack"])
    px(draw, cx + 10, body_top + 2, C["pack_rivet"])
    px(draw, cx + 13, body_top + 2, C["pack_rivet"])

    _zzz(draw, cx, head_cy - 12, frame)

    if emotion == "happy":
        px(draw, cx - 7, head_cy + 3, C["cheek"])
        px(draw, cx + 7, head_cy + 3, C["cheek"])


def _draw_compacting(draw, cx, oy, frame, emotion):
    scales = [1.0, 0.7, 0.35, 0.1, 1.0]
    s = scales[frame % 5]
    if s < 0.2:
        px(draw, cx, oy + 56, C["body"])
        px(draw, cx + 1, oy + 56, C["body"])
        px(draw, cx, oy + 57, C["cyan"])
        px(draw, cx + 1, oy + 57, C["cyan"])
        return True
    if s < 0.5:
        mid_y = oy + int(38 + (1 - s) * 10)
        r = 6
        circle_filled(draw, cx, mid_y, r, C["body"])
        circle_outline(draw, cx, mid_y, r, C["outline"])
        rect(draw, cx - 4, mid_y, 8, 3, C["visor"])
        px(draw, cx - 2, mid_y, C["white"])
        px(draw, cx - 1, mid_y, C["white"])
        px(draw, cx + 2, mid_y, C["white"])
        px(draw, cx + 3, mid_y, C["white"])
        rect(draw, cx - 4, mid_y + r + 1, 8, 5, C["body_dk"])
        rect(draw, cx - 3, mid_y + r + 2, 6, 3, C["cyan"])
        return True
    return False


# ---------- sprite sheet generation ----------


def generate_sheet(name, state, emotion, frame_count):
    w = 64 * frame_count
    h = 64
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    for f in range(frame_count):
        ox = f * 64
        light_on = True
        if state == "idle":
            light_on = f % 4 != 1
        elif state == "sleeping":
            light_on = False

        draw_robot(draw, ox, 0, frame=f, emotion=emotion, state=state, light_on=light_on)

    smooth = img.filter(ImageFilter.SMOOTH_MORE)
    result = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            orig = img.getpixel((x, y))
            blur = smooth.getpixel((x, y))
            if orig[3] > 0:
                result.putpixel((x, y), orig)
            elif blur[3] > 20:
                result.putpixel((x, y), (blur[0], blur[1], blur[2], blur[3] // 3))

    return result


SPRITE_SPECS = [
    ("codex_idle_neutral", "idle", "neutral", 6),
    ("codex_idle_happy", "idle", "happy", 6),
    ("codex_idle_sad", "idle", "sad", 6),
    ("codex_idle_sob", "idle", "sob", 6),
    ("codex_working_neutral", "working", "neutral", 6),
    ("codex_working_happy", "working", "happy", 6),
    ("codex_working_sad", "working", "sad", 6),
    ("codex_working_sob", "working", "sob", 6),
    ("codex_waiting_neutral", "waiting", "neutral", 6),
    ("codex_waiting_happy", "waiting", "happy", 6),
    ("codex_waiting_sad", "waiting", "sad", 6),
    ("codex_waiting_sob", "waiting", "sob", 6),
    ("codex_sleeping_neutral", "sleeping", "neutral", 6),
    ("codex_sleeping_happy", "sleeping", "happy", 6),
    ("codex_compacting_neutral", "compacting", "neutral", 5),
    ("codex_compacting_happy", "compacting", "happy", 5),
]

CONTENTS_JSON = """\
{
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
    print("\U0001f916 Generating Repair Robot sprite sheets...\n")

    for name, state, emotion, frames in SPRITE_SPECS:
        img = generate_sheet(name, state, emotion, frames)
        w, h = img.size

        dst_dir = os.path.join(ASSETS, f"{name}.imageset")
        os.makedirs(dst_dir, exist_ok=True)

        img.save(os.path.join(dst_dir, "sprite_sheet.png"), "PNG")

        contents_path = os.path.join(dst_dir, "Contents.json")
        with open(contents_path, "w") as f:
            f.write(CONTENTS_JSON)

        print(f"  \u2705 {name} ({w}x{h}, {frames} frames)")

    print(f"\n\U0001f527 Generated {len(SPRITE_SPECS)} sprite sheets!")
    print("   Design: Dome head + cyan visor, orange body, tool backpack")
    print("   Palette: Warm orange + Cyan blue, hover glow, antenna light")


if __name__ == "__main__":
    main()
