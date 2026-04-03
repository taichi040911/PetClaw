#!/usr/bin/env python3
"""
PetClaw Form Sprite Generator v2
=================================
22進化形態 + blob の高品質ピクセルアートスプライトを生成。
各フォームに固有のシルエット・アクセサリー・オーラを描画。

Usage:
    python generate_form_sprites.py --all --size 64 --output ./out/
    python generate_form_sprites.py --form warrior_youth --size 64 --output ./out/
"""

import argparse
import json
import math
import os
import sys

try:
    from PIL import Image, ImageDraw
    HAS_PILLOW = True
except ImportError:
    HAS_PILLOW = False
    print("ERROR: Pillow not installed. Run: pip install Pillow")
    sys.exit(1)


# === Form Definitions ===

FORMS = {
    # --- Stage 1 ---
    "blob": {
        "stage": 1, "display": "幼体",
        "body": (255, 224, 178), "accent": (255, 243, 224), "eye": (33, 33, 33),
        "shape": "blob", "accessories": [], "aura": None,
    },
    # --- Stage 2: Infant ---
    "forest_infant": {
        "stage": 2, "display": "森の幼子",
        "body": (76, 175, 80), "accent": (200, 230, 201), "eye": (33, 33, 33),
        "shape": "round", "accessories": ["leaf_ears", "vine_tail"], "aura": "leaf",
    },
    "sea_infant": {
        "stage": 2, "display": "海の幼子",
        "body": (66, 165, 245), "accent": (187, 222, 251), "eye": (33, 33, 33),
        "shape": "round", "accessories": ["fins", "dorsal"], "aura": "bubble",
    },
    "ruins_infant": {
        "stage": 2, "display": "遺跡の幼子",
        "body": (171, 71, 188), "accent": (225, 190, 231), "eye": (74, 20, 140),
        "shape": "round", "accessories": ["crystal_horn", "rune_mark"], "aura": "rune",
    },
    "city_infant": {
        "stage": 2, "display": "街の幼子",
        "body": (255, 167, 38), "accent": (255, 224, 130), "eye": (33, 33, 33),
        "shape": "round", "accessories": ["scarf", "cowlick"], "aura": "gear",
    },
    "neglected_infant": {
        "stage": 2, "display": "さすらいの幼子", "dark": True,
        "body": (97, 97, 97), "accent": (66, 66, 66), "eye": (183, 28, 28),
        "shape": "angular_round", "accessories": ["torn_ear", "scar"], "aura": "shadow",
    },
    # --- Stage 3: Youth ---
    "warrior_youth": {
        "stage": 3, "display": "勇者の若者",
        "body": (211, 47, 47), "accent": (255, 138, 101), "eye": (33, 33, 33),
        "shape": "upright", "accessories": ["crest", "shield_mark", "cape"], "aura": "ember",
    },
    "scholar_youth": {
        "stage": 3, "display": "知恵の若者",
        "body": (48, 63, 159), "accent": (121, 134, 203), "eye": (33, 33, 33),
        "shape": "slim_tall", "accessories": ["glasses", "book_mark"], "aura": "text",
    },
    "healer_youth": {
        "stage": 3, "display": "癒しの若者",
        "body": (236, 64, 122), "accent": (248, 187, 208), "eye": (33, 33, 33),
        "shape": "soft_round", "accessories": ["halo", "flower_crown"], "aura": "heart",
    },
    "trickster_youth": {
        "stage": 3, "display": "いたずらの若者",
        "body": (255, 179, 0), "accent": (255, 224, 130), "eye": (33, 33, 33),
        "shape": "bouncy", "accessories": ["curly_tail", "star_cheeks"], "aura": "confetti",
    },
    "sentinel_youth": {
        "stage": 3, "display": "静寂の若者",
        "body": (69, 90, 100), "accent": (144, 164, 174), "eye": (33, 33, 33),
        "shape": "grounded", "accessories": ["crystal_forehead", "geo_ears"], "aura": "geometric",
    },
    "diplomat_youth": {
        "stage": 3, "display": "語り部の若者",
        "body": (0, 150, 136), "accent": (128, 203, 196), "eye": (33, 33, 33),
        "shape": "open_stance", "accessories": ["speech_mark", "ribbon_tail"], "aura": "speech",
    },
    "shadow_youth": {
        "stage": 3, "display": "影の若者", "dark": True,
        "body": (49, 27, 146), "accent": (26, 10, 74), "eye": (244, 67, 54),
        "shape": "angular", "accessories": ["flame_crest", "shadow_tendrils"], "aura": "dark_flame",
    },
    # --- Stage 4: Adult ---
    "guardian_adult": {
        "stage": 4, "display": "守護者",
        "body": (255, 193, 7), "accent": (255, 241, 118), "eye": (33, 33, 33),
        "shape": "large_protective", "accessories": ["shield_arm", "shoulder_wings", "heart_emblem"], "aura": "golden",
    },
    "sage_adult": {
        "stage": 4, "display": "賢者",
        "body": (30, 136, 229), "accent": (100, 181, 246), "eye": (33, 33, 33),
        "shape": "tall_serene", "accessories": ["floating_book", "staff", "hood"], "aura": "star",
    },
    "bond_master_adult": {
        "stage": 4, "display": "絆の達人",
        "body": (233, 30, 99), "accent": (248, 187, 208), "eye": (33, 33, 33),
        "shape": "open_arms", "accessories": ["rainbow_ribbons", "heart_crystal"], "aura": "rainbow",
    },
    "storm_warrior_adult": {
        "stage": 4, "display": "嵐の戦士",
        "body": (183, 28, 28), "accent": (239, 83, 80), "eye": (33, 33, 33),
        "shape": "action_pose", "accessories": ["lightning_crest", "storm_cape"], "aura": "lightning",
    },
    "mystic_adult": {
        "stage": 4, "display": "神秘者",
        "body": (106, 27, 154), "accent": (186, 104, 200), "eye": (33, 33, 33),
        "shape": "floating", "accessories": ["rune_circle", "third_eye"], "aura": "cosmic",
    },
    "dark_sovereign_adult": {
        "stage": 4, "display": "闇の覇者", "dark": True,
        "body": (33, 33, 33), "accent": (69, 39, 160), "eye": (244, 67, 54),
        "shape": "imposing", "accessories": ["dark_crown", "shadow_wings"], "aura": "void",
    },
    # --- Stage 5: Elder ---
    "ancient_elder": {
        "stage": 5, "display": "太古の長老",
        "body": (255, 214, 0), "accent": (255, 241, 118), "eye": (33, 33, 33),
        "shape": "large_serene", "accessories": ["floating_stones", "tree_rings", "flower_crown"], "aura": "ancient_gold",
    },
    "eternal_companion": {
        "stage": 5, "display": "永遠の伴侶",
        "body": (233, 30, 99), "accent": (252, 228, 236), "eye": (33, 33, 33),
        "shape": "graceful", "accessories": ["light_wings", "heart_orbit", "eternal_flame"], "aura": "eternal_light",
    },
    "language_sage_elder": {
        "stage": 5, "display": "言語の大賢者",
        "body": (0, 131, 143), "accent": (128, 222, 234), "eye": (33, 33, 33),
        "shape": "tall_floating", "accessories": ["crystal_crown", "word_streams"], "aura": "language_flow",
    },
    "redeemed_elder": {
        "stage": 5, "display": "闇からの帰還者",
        "body": (230, 81, 0), "accent": (255, 171, 64), "eye": (245, 127, 23),
        "shape": "dual_nature", "accessories": ["dual_wings", "glow_scars"], "aura": "redemption",
    },
}


# === Drawing Helpers ===

def lerp_color(c1, c2, t):
    """Linearly interpolate between two RGB colors."""
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def darken(color, amount=0.3):
    return tuple(max(0, int(c * (1 - amount))) for c in color)


def lighten(color, amount=0.3):
    return tuple(min(255, int(c + (255 - c) * amount)) for c in color)


def draw_ellipse_aa(draw, bbox, fill, outline=None):
    """Draw an anti-aliased-ish ellipse."""
    draw.ellipse(bbox, fill=fill, outline=outline)


def draw_pixel_circle(img, cx, cy, r, color):
    """Draw a filled pixel circle."""
    draw = ImageDraw.Draw(img)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)


def draw_rounded_body(draw, x, y, w, h, radius, fill, outline=None):
    """Draw a rounded rectangle body."""
    draw.rounded_rectangle([x, y, x + w, y + h], radius=radius, fill=fill, outline=outline)


# === Body Shape Drawers ===

def draw_body_blob(img, s, form):
    """Stage 1 blob - simple pear shape."""
    draw = ImageDraw.Draw(img)
    cx, cy = s // 2, s // 2 + 2
    bw, bh = int(s * 0.38), int(s * 0.42)
    # Body
    draw.ellipse([cx - bw, cy - bh + 4, cx + bw, cy + bh], fill=form["body"],
                 outline=darken(form["body"], 0.15))
    # Belly
    bew, beh = int(bw * 0.65), int(bh * 0.55)
    draw.ellipse([cx - bew, cy - beh + 8, cx + bew, cy + beh], fill=form["accent"])
    # Blush
    draw.ellipse([cx - bw + 3, cy + 2, cx - bw + 7, cy + 5], fill=(255, 180, 180, 180))
    draw.ellipse([cx + bw - 7, cy + 2, cx + bw - 3, cy + 5], fill=(255, 180, 180, 180))
    return cx, cy, bw, bh


def draw_body_round(img, s, form):
    """Stage 2 round body with small features."""
    draw = ImageDraw.Draw(img)
    cx, cy = s // 2, s // 2 + 3
    bw, bh = int(s * 0.34), int(s * 0.38)
    # Body
    draw.ellipse([cx - bw, cy - bh + 2, cx + bw, cy + bh], fill=form["body"],
                 outline=darken(form["body"], 0.2))
    # Belly
    bew, beh = int(bw * 0.6), int(bh * 0.5)
    draw.ellipse([cx - bew, cy - beh + 7, cx + bew, cy + beh - 1], fill=form["accent"])
    # Feet
    fw = max(3, bw // 3)
    draw.ellipse([cx - bw + 2, cy + bh - 4, cx - bw + 2 + fw * 2, cy + bh + 3],
                 fill=darken(form["body"], 0.1))
    draw.ellipse([cx + bw - 2 - fw * 2, cy + bh - 4, cx + bw - 2, cy + bh + 3],
                 fill=darken(form["body"], 0.1))
    return cx, cy, bw, bh


def draw_body_angular_round(img, s, form):
    """Dark infant - slightly angular."""
    draw = ImageDraw.Draw(img)
    cx, cy = s // 2, s // 2 + 3
    bw, bh = int(s * 0.33), int(s * 0.37)
    # Slightly angular body (polygon approximation)
    pts = []
    for a in range(0, 360, 15):
        r = bw if abs(a - 90) > 45 and abs(a - 270) > 45 else bh
        # Add angularity
        r_mod = r * (1.0 + 0.08 * math.sin(a * 3 * math.pi / 180))
        px = cx + int(r_mod * math.cos(math.radians(a)))
        py = cy + int(r_mod * 0.95 * math.sin(math.radians(a)))
        pts.append((px, py))
    draw.polygon(pts, fill=form["body"], outline=darken(form["body"], 0.25))
    bew, beh = int(bw * 0.55), int(bh * 0.45)
    draw.ellipse([cx - bew, cy - beh + 6, cx + bew, cy + beh - 2], fill=form["accent"])
    return cx, cy, bw, bh


def draw_body_upright(img, s, form):
    """Youth warrior - upright stance."""
    draw = ImageDraw.Draw(img)
    cx, cy = s // 2, s // 2 + 2
    # Head (upper)
    hw = int(s * 0.28)
    hh = int(s * 0.24)
    head_y = cy - int(s * 0.18)
    draw.ellipse([cx - hw, head_y - hh, cx + hw, head_y + hh], fill=form["body"],
                 outline=darken(form["body"], 0.2))
    # Body (lower, slightly narrower)
    bw = int(s * 0.24)
    bh = int(s * 0.22)
    body_y = cy + int(s * 0.08)
    draw.rounded_rectangle([cx - bw, body_y - bh, cx + bw, body_y + bh + 4],
                           radius=bw // 2, fill=form["body"], outline=darken(form["body"], 0.2))
    # Chest accent
    draw.rounded_rectangle([cx - bw + 4, body_y - bh + 4, cx + bw - 4, body_y + 2],
                           radius=3, fill=form["accent"])
    # Arms
    draw.ellipse([cx - bw - 5, body_y - 4, cx - bw + 2, body_y + 8], fill=form["body"])
    draw.ellipse([cx + bw - 2, body_y - 4, cx + bw + 5, body_y + 8], fill=form["body"])
    # Feet
    draw.ellipse([cx - bw + 2, body_y + bh, cx - 2, body_y + bh + 6], fill=darken(form["body"], 0.1))
    draw.ellipse([cx + 2, body_y + bh, cx + bw - 2, body_y + bh + 6], fill=darken(form["body"], 0.1))
    return cx, head_y, hw, hh


def draw_body_slim_tall(img, s, form):
    """Scholar - slim and tall."""
    draw = ImageDraw.Draw(img)
    cx, cy = s // 2, s // 2
    hw = int(s * 0.26)
    hh = int(s * 0.22)
    head_y = cy - int(s * 0.2)
    # Large head
    draw.ellipse([cx - hw, head_y - hh, cx + hw, head_y + hh], fill=form["body"],
                 outline=darken(form["body"], 0.2))
    # Slim body
    bw = int(s * 0.18)
    bh = int(s * 0.26)
    body_y = cy + int(s * 0.12)
    draw.rounded_rectangle([cx - bw, body_y - bh, cx + bw, body_y + bh],
                           radius=bw // 2, fill=form["body"], outline=darken(form["body"], 0.2))
    draw.rounded_rectangle([cx - bw + 3, body_y - bh + 3, cx + bw - 3, body_y],
                           radius=3, fill=form["accent"])
    return cx, head_y, hw, hh


def draw_body_soft_round(img, s, form):
    """Healer - extra soft and round."""
    draw = ImageDraw.Draw(img)
    cx, cy = s // 2, s // 2 + 2
    bw, bh = int(s * 0.36), int(s * 0.4)
    draw.ellipse([cx - bw, cy - bh + 3, cx + bw, cy + bh], fill=form["body"],
                 outline=darken(form["body"], 0.15))
    bew, beh = int(bw * 0.7), int(bh * 0.55)
    draw.ellipse([cx - bew, cy - beh + 8, cx + bew, cy + beh - 2], fill=form["accent"])
    # Soft glow around
    for i in range(3):
        r = bw + 3 + i * 2
        alpha = 60 - i * 20
        overlay = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        glow_color = lighten(form["body"], 0.5) + (alpha,)
        od.ellipse([cx - r, cy - r + 3, cx + r, cy + r], fill=glow_color)
        img.paste(Image.alpha_composite(img, overlay))
    return cx, cy, bw, bh


def draw_body_bouncy(img, s, form):
    """Trickster - bouncy, leaning forward."""
    draw = ImageDraw.Draw(img)
    cx, cy = s // 2 - 1, s // 2 + 2
    bw, bh = int(s * 0.32), int(s * 0.35)
    # Tilted body
    draw.ellipse([cx - bw + 2, cy - bh + 2, cx + bw + 2, cy + bh],
                 fill=form["body"], outline=darken(form["body"], 0.2))
    bew = int(bw * 0.6)
    draw.ellipse([cx - bew + 2, cy - bew + 7, cx + bew + 2, cy + bew],
                 fill=form["accent"])
    return cx, cy, bw, bh


def draw_body_generic(img, s, form, shape_name):
    """Generic body for forms that share similar base shapes."""
    draw = ImageDraw.Draw(img)
    stage = form["stage"]
    cx, cy = s // 2, s // 2 + 2

    if stage <= 3:
        bw, bh = int(s * 0.32), int(s * 0.36)
    elif stage == 4:
        bw, bh = int(s * 0.36), int(s * 0.4)
    else:
        bw, bh = int(s * 0.38), int(s * 0.42)

    is_dark = form.get("dark", False)
    outline_color = darken(form["body"], 0.3 if is_dark else 0.2)

    if shape_name in ("angular", "imposing"):
        # Angular dark forms
        pts = []
        for a in range(0, 360, 10):
            r = bw * (1.0 + 0.12 * math.sin(a * 4 * math.pi / 180))
            px = cx + int(r * math.cos(math.radians(a)))
            py = cy + int(r * 0.9 * math.sin(math.radians(a)))
            pts.append((px, py))
        draw.polygon(pts, fill=form["body"], outline=outline_color)
    elif shape_name in ("tall_serene", "tall_floating"):
        # Tall forms
        hw = int(s * 0.26)
        hh = int(s * 0.22)
        head_y = cy - int(s * 0.18)
        draw.ellipse([cx - hw, head_y - hh, cx + hw, head_y + hh], fill=form["body"],
                     outline=outline_color)
        body_bw = int(s * 0.22)
        body_bh = int(s * 0.24)
        body_y = cy + int(s * 0.1)
        draw.rounded_rectangle([cx - body_bw, body_y - body_bh, cx + body_bw, body_y + body_bh],
                               radius=body_bw // 2, fill=form["body"], outline=outline_color)
        draw.rounded_rectangle([cx - body_bw + 3, body_y - body_bh + 3, cx + body_bw - 3, body_y - 2],
                               radius=3, fill=form["accent"])
        return cx, head_y, hw, hh
    elif shape_name in ("large_protective", "large_serene"):
        # Large forms
        draw.ellipse([cx - bw, cy - bh + 2, cx + bw, cy + bh], fill=form["body"],
                     outline=outline_color)
        bew = int(bw * 0.65)
        draw.ellipse([cx - bew, cy - bew + 6, cx + bew, cy + bew], fill=form["accent"])
        # Shoulder plates for guardian
        if "shoulder_wings" in form.get("accessories", []):
            draw.polygon([(cx - bw - 3, cy - bh // 2), (cx - bw + 5, cy - bh - 3),
                          (cx - bw + 8, cy - bh // 2 + 3)], fill=form["accent"])
            draw.polygon([(cx + bw + 3, cy - bh // 2), (cx + bw - 5, cy - bh - 3),
                          (cx + bw - 8, cy - bh // 2 + 3)], fill=form["accent"])
    elif shape_name in ("graceful", "open_arms"):
        # Graceful forms
        draw.ellipse([cx - bw, cy - bh + 2, cx + bw, cy + bh], fill=form["body"],
                     outline=outline_color)
        bew = int(bw * 0.6)
        draw.ellipse([cx - bew, cy - bew + 6, cx + bew, cy + bew], fill=form["accent"])
        # Open arms
        arm_w = max(3, bw // 4)
        draw.ellipse([cx - bw - 6, cy - 2, cx - bw + arm_w, cy + 6], fill=form["body"])
        draw.ellipse([cx + bw - arm_w, cy - 2, cx + bw + 6, cy + 6], fill=form["body"])
    elif shape_name == "dual_nature":
        # Redeemed - split light/dark
        draw.ellipse([cx - bw, cy - bh + 2, cx + bw, cy + bh], fill=form["body"],
                     outline=outline_color)
        # Left half darker
        overlay = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        od.rectangle([0, 0, cx, s], fill=(0, 0, 0, 40))
        img.paste(Image.alpha_composite(img, overlay))
        draw = ImageDraw.Draw(img)
        bew = int(bw * 0.6)
        draw.ellipse([cx - bew, cy - bew + 6, cx + bew, cy + bew], fill=form["accent"])
    else:
        # Default round
        draw.ellipse([cx - bw, cy - bh + 2, cx + bw, cy + bh], fill=form["body"],
                     outline=outline_color)
        bew = int(bw * 0.6)
        draw.ellipse([cx - bew, cy - bew + 6, cx + bew, cy + bew], fill=form["accent"])

    return cx, cy, bw, bh


# === Eye Drawers ===

def draw_eyes(img, cx, cy, bw, bh, form):
    """Draw expressive eyes appropriate to the form."""
    draw = ImageDraw.Draw(img)
    eye_color = form["eye"]
    is_dark = form.get("dark", False)
    stage = form["stage"]

    # Eye size scales with stage
    eye_r = max(2, int(bw * 0.22) + stage)
    eye_spacing = max(4, int(bw * 0.45))
    eye_y = cy - int(bh * 0.15)

    # Left eye
    lx = cx - eye_spacing
    rx = cx + eye_spacing

    # White/light part
    white_r = eye_r + 1
    draw.ellipse([lx - white_r, eye_y - white_r, lx + white_r, eye_y + white_r], fill=(255, 255, 255))
    draw.ellipse([rx - white_r, eye_y - white_r, rx + white_r, eye_y + white_r], fill=(255, 255, 255))

    # Pupil
    if is_dark:
        # Narrow/angular eyes for dark forms
        draw.ellipse([lx - eye_r + 1, eye_y - eye_r, lx + eye_r - 1, eye_y + eye_r], fill=eye_color)
        draw.ellipse([rx - eye_r + 1, eye_y - eye_r, rx + eye_r - 1, eye_y + eye_r], fill=eye_color)
        # Red glow
        draw.point([lx - 1, eye_y - 1], fill=(255, 100, 100))
        draw.point([rx - 1, eye_y - 1], fill=(255, 100, 100))
    else:
        draw.ellipse([lx - eye_r, eye_y - eye_r, lx + eye_r, eye_y + eye_r], fill=eye_color)
        draw.ellipse([rx - eye_r, eye_y - eye_r, rx + eye_r, eye_y + eye_r], fill=eye_color)

    # Catchlight (white reflection dot)
    cl_r = max(1, eye_r // 3)
    cl_off = max(1, eye_r // 3)
    draw.ellipse([lx - cl_off - cl_r, eye_y - cl_off - cl_r,
                  lx - cl_off + cl_r, eye_y - cl_off + cl_r], fill=(255, 255, 255))
    draw.ellipse([rx - cl_off - cl_r, eye_y - cl_off - cl_r,
                  rx - cl_off + cl_r, eye_y - cl_off + cl_r], fill=(255, 255, 255))

    return eye_y


# === Accessory Drawers ===

def draw_accessories(img, cx, cy, bw, bh, form, s):
    """Draw form-specific accessories."""
    draw = ImageDraw.Draw(img)
    accessories = form.get("accessories", [])
    body_color = form["body"]
    accent = form.get("accent", body_color)

    for acc in accessories:
        if acc == "leaf_ears":
            # Two leaf-shaped ears
            for dx in [-1, 1]:
                ex = cx + dx * (bw - 4)
                ey = cy - bh - 2
                pts = [(ex, ey + 6), (ex + dx * 4, ey - 4), (ex + dx * 2, ey + 8)]
                draw.polygon(pts, fill=(139, 195, 74))

        elif acc == "vine_tail":
            pts = [(cx + bw - 2, cy + bh // 2), (cx + bw + 5, cy + bh // 2 - 3),
                   (cx + bw + 8, cy + bh // 2 + 1), (cx + bw + 6, cy + bh // 2 + 4)]
            draw.line(pts, fill=(139, 195, 74), width=2)

        elif acc == "fins":
            for dx in [-1, 1]:
                fx = cx + dx * (bw + 1)
                fy = cy - 2
                pts = [(fx, fy), (fx + dx * 6, fy - 4), (fx + dx * 5, fy + 4)]
                draw.polygon(pts, fill=(129, 212, 250))

        elif acc == "dorsal":
            pts = [(cx - 3, cy - bh), (cx, cy - bh - 6), (cx + 3, cy - bh)]
            draw.polygon(pts, fill=(129, 212, 250))

        elif acc == "crystal_horn":
            pts = [(cx - 2, cy - bh + 2), (cx, cy - bh - 8), (cx + 2, cy - bh + 2)]
            draw.polygon(pts, fill=(206, 147, 216))
            draw.point([cx, cy - bh - 5], fill=(255, 255, 255))

        elif acc == "rune_mark":
            # Triangle rune on forehead
            ry = cy - bh // 2 - 2
            draw.polygon([(cx, ry - 3), (cx - 2, ry + 2), (cx + 2, ry + 2)],
                         outline=(206, 147, 216))

        elif acc == "scarf":
            # Tiny red scarf
            sy = cy - bh // 2 + 4
            draw.line([(cx - 4, sy), (cx + 4, sy)], fill=(239, 83, 80), width=2)
            draw.line([(cx + 3, sy), (cx + 7, sy + 5)], fill=(239, 83, 80), width=2)

        elif acc == "cowlick":
            draw.line([(cx + 2, cy - bh), (cx + 5, cy - bh - 5)], fill=darken(body_color, 0.1), width=2)

        elif acc == "torn_ear":
            ex = cx + bw - 3
            ey = cy - bh - 1
            pts = [(ex, ey + 4), (ex + 4, ey - 3), (ex + 3, ey)]
            draw.polygon(pts, fill=(97, 97, 97))

        elif acc == "scar":
            draw.line([(cx + bw // 2, cy - 2), (cx + bw // 2 + 3, cy + 3)], fill=(66, 66, 66), width=1)

        elif acc == "crest":
            # Flame crest on head
            pts = [(cx - 4, cy - bh + 1), (cx - 2, cy - bh - 8),
                   (cx, cy - bh - 4), (cx + 2, cy - bh - 10),
                   (cx + 4, cy - bh + 1)]
            draw.polygon(pts, fill=(255, 213, 79))

        elif acc == "shield_mark":
            # Small shield on chest
            sy = cy + 2
            draw.polygon([(cx - 3, sy - 2), (cx + 3, sy - 2),
                          (cx + 3, sy + 2), (cx, sy + 4), (cx - 3, sy + 2)],
                         fill=(255, 213, 79), outline=darken(body_color, 0.2))

        elif acc == "cape":
            # Small cape behind
            draw.polygon([(cx - bw + 2, cy - bh // 2),
                          (cx - bw - 3, cy + bh),
                          (cx + bw + 3, cy + bh),
                          (cx + bw - 2, cy - bh // 2)],
                         fill=darken(body_color, 0.15))

        elif acc == "glasses":
            ey = cy - int(bh * 0.15)
            # Round glasses frame
            gr = max(3, bw // 4)
            lx, rx = cx - int(bw * 0.4), cx + int(bw * 0.4)
            draw.ellipse([lx - gr, ey - gr, lx + gr, ey + gr], outline=(200, 200, 220), width=1)
            draw.ellipse([rx - gr, ey - gr, rx + gr, ey + gr], outline=(200, 200, 220), width=1)
            draw.line([(lx + gr, ey), (rx - gr, ey)], fill=(200, 200, 220), width=1)

        elif acc == "book_mark":
            # Tiny book icon on back
            bx = cx + bw - 2
            by = cy + 4
            draw.rectangle([bx, by, bx + 4, by + 5], fill=(200, 200, 220), outline=(150, 150, 180))

        elif acc == "halo":
            hy = cy - bh - 4
            draw.ellipse([cx - bw // 2, hy - 2, cx + bw // 2, hy + 2],
                         outline=(255, 223, 100), width=1)

        elif acc == "flower_crown":
            for dx in [-6, -3, 0, 3, 6]:
                fx = cx + dx
                fy = cy - bh - 1
                draw.ellipse([fx - 1, fy - 1, fx + 1, fy + 1], fill=(255, 182, 193))

        elif acc == "curly_tail":
            tx, ty = cx + bw, cy + bh // 3
            for i in range(8):
                a = i * 45
                dx = int(3 * math.cos(math.radians(a))) + i
                dy = int(3 * math.sin(math.radians(a)))
                draw.point([tx + dx, ty + dy], fill=darken(body_color, 0.1))

        elif acc == "star_cheeks":
            for dx in [-1, 1]:
                sx = cx + dx * (bw - 2)
                sy = cy + 3
                draw.point([sx, sy], fill=(255, 152, 0))
                draw.point([sx - 1, sy], fill=(255, 152, 0))
                draw.point([sx + 1, sy], fill=(255, 152, 0))
                draw.point([sx, sy - 1], fill=(255, 152, 0))
                draw.point([sx, sy + 1], fill=(255, 152, 0))

        elif acc == "crystal_forehead":
            pts = [(cx, cy - bh - 4), (cx - 3, cy - bh + 1), (cx + 3, cy - bh + 1)]
            draw.polygon(pts, fill=(38, 166, 154))
            draw.point([cx, cy - bh - 2], fill=(255, 255, 255))

        elif acc == "geo_ears":
            for dx in [-1, 1]:
                ex = cx + dx * (bw - 2)
                ey = cy - bh - 1
                pts = [(ex, ey + 3), (ex + dx * 5, ey - 2), (ex + dx * 3, ey + 5)]
                draw.polygon(pts, fill=(144, 164, 174))

        elif acc == "speech_mark":
            # Speech bubble mark on chest
            sy = cy + 2
            draw.ellipse([cx - 3, sy - 2, cx + 3, sy + 2], fill=(255, 215, 0))
            draw.point([cx, sy], fill=(0, 150, 136))

        elif acc == "ribbon_tail":
            tx, ty = cx + bw, cy + bh // 3
            draw.line([(tx, ty), (tx + 6, ty - 3), (tx + 10, ty + 1)],
                      fill=(255, 215, 0), width=1)

        elif acc == "flame_crest":
            pts = [(cx - 5, cy - bh), (cx - 2, cy - bh - 10),
                   (cx + 1, cy - bh - 5), (cx + 3, cy - bh - 12),
                   (cx + 5, cy - bh)]
            draw.polygon(pts, fill=(94, 53, 177))

        elif acc == "shadow_tendrils":
            for dx in [-1, 0, 1]:
                tx = cx + dx * (bw - 3)
                ty = cy + bh
                draw.line([(tx, ty), (tx + dx * 3, ty + 6)], fill=(26, 10, 74), width=1)

        elif acc == "shield_arm":
            # Crystal shield on left arm
            ax = cx - bw - 3
            ay = cy - 2
            draw.polygon([(ax - 4, ay - 4), (ax + 2, ay - 5),
                          (ax + 3, ay + 4), (ax - 1, ay + 6), (ax - 5, ay + 2)],
                         fill=(100, 181, 246), outline=(30, 136, 229))

        elif acc == "shoulder_wings":
            pass  # Handled in body drawer

        elif acc == "heart_emblem":
            hy = cy
            draw.polygon([(cx - 2, hy), (cx, hy - 3), (cx + 2, hy),
                          (cx, hy + 3)], fill=(255, 82, 82))

        elif acc == "floating_book":
            bx = cx + bw + 3
            by = cy - bh // 2
            draw.rectangle([bx, by, bx + 5, by + 6], fill=(224, 224, 224), outline=(189, 189, 189))
            draw.line([(bx + 2, by), (bx + 2, by + 6)], fill=(189, 189, 189))

        elif acc == "staff":
            draw.line([(cx + bw + 1, cy - bh), (cx + bw + 1, cy + bh + 4)],
                      fill=(189, 189, 189), width=1)
            draw.ellipse([cx + bw - 1, cy - bh - 4, cx + bw + 3, cy - bh],
                         fill=(100, 181, 246))

        elif acc == "hood":
            hy = cy - bh
            draw.arc([cx - bw - 2, hy - 4, cx + bw + 2, hy + 8], 180, 360,
                     fill=darken(body_color, 0.15), width=2)

        elif acc == "rainbow_ribbons":
            colors = [(255, 152, 0), (76, 175, 80), (33, 150, 243)]
            for i, c in enumerate(colors):
                angle = i * 40 + 30
                dx = int(8 * math.cos(math.radians(angle)))
                dy = int(8 * math.sin(math.radians(angle)))
                draw.line([(cx, cy), (cx + dx, cy + dy)], fill=c, width=1)

        elif acc == "heart_crystal":
            hy = cy - 1
            draw.polygon([(cx - 2, hy), (cx, hy - 3), (cx + 2, hy), (cx, hy + 3)],
                         fill=(255, 82, 82))

        elif acc == "lightning_crest":
            pts = [(cx - 2, cy - bh - 8), (cx + 1, cy - bh - 3),
                   (cx - 1, cy - bh - 3), (cx + 2, cy - bh + 2)]
            draw.line(pts, fill=(255, 235, 59), width=2)

        elif acc == "storm_cape":
            draw.polygon([(cx - bw, cy), (cx - bw - 5, cy + bh + 3),
                          (cx + bw + 5, cy + bh + 3), (cx + bw, cy)],
                         fill=darken(body_color, 0.2))

        elif acc == "rune_circle":
            rc = bw + 6
            draw.ellipse([cx - rc, cy - rc, cx + rc, cy + rc],
                         outline=(255, 215, 0, 150), width=1)
            # Rune dots
            for a in range(0, 360, 60):
                rx = cx + int(rc * math.cos(math.radians(a)))
                ry = cy + int(rc * math.sin(math.radians(a)))
                draw.point([rx, ry], fill=(255, 215, 0))

        elif acc == "third_eye":
            draw.ellipse([cx - 2, cy - bh - 2, cx + 2, cy - bh + 2],
                         fill=(186, 104, 200), outline=(106, 27, 154))

        elif acc == "dark_crown":
            for dx in [-4, -1, 2, 5]:
                draw.line([(cx + dx, cy - bh + 1), (cx + dx, cy - bh - 5)],
                          fill=(69, 39, 160), width=1)
                draw.point([cx + dx, cy - bh - 5], fill=(106, 27, 154))

        elif acc == "shadow_wings":
            for dx in [-1, 1]:
                wx = cx + dx * (bw + 2)
                pts = [(wx, cy - 4), (wx + dx * 10, cy - 8),
                       (wx + dx * 8, cy + 2), (wx + dx * 6, cy + 6)]
                draw.polygon(pts, fill=(49, 27, 146))

        elif acc == "floating_stones":
            for a in [45, 135, 225, 315]:
                sx = cx + int((bw + 8) * math.cos(math.radians(a)))
                sy = cy + int((bh + 6) * math.sin(math.radians(a)))
                draw.rectangle([sx - 2, sy - 2, sx + 2, sy + 2], fill=(161, 136, 127))

        elif acc == "tree_rings":
            for i in range(3):
                r = bw - 4 - i * 3
                if r > 2:
                    draw.ellipse([cx - r, cy - r + 4, cx + r, cy + r + 4],
                                 outline=darken(body_color, 0.1 + i * 0.05))

        elif acc == "light_wings":
            for dx in [-1, 1]:
                wx = cx + dx * (bw + 1)
                pts = [(wx, cy - 4), (wx + dx * 10, cy - 10),
                       (wx + dx * 12, cy - 2), (wx + dx * 8, cy + 6)]
                draw.polygon(pts, fill=(255, 255, 255, 200))
                # Feather detail
                draw.line([(wx + dx * 3, cy - 6), (wx + dx * 10, cy - 8)],
                          fill=(252, 228, 236), width=1)

        elif acc == "heart_orbit":
            for a in range(0, 360, 90):
                hx = cx + int((bw + 10) * math.cos(math.radians(a)))
                hy = cy + int((bh + 8) * math.sin(math.radians(a)))
                draw.polygon([(hx, hy - 2), (hx - 1, hy - 3), (hx + 1, hy - 3), (hx, hy + 1)],
                             fill=(255, 82, 82))

        elif acc == "eternal_flame":
            fy = cy - 1
            pts = [(cx - 2, fy + 2), (cx, fy - 4), (cx + 2, fy + 2)]
            draw.polygon(pts, fill=(255, 235, 59))

        elif acc == "crystal_crown":
            for dx in [-5, -2, 1, 4]:
                draw.polygon([(cx + dx, cy - bh + 1), (cx + dx + 1, cy - bh - 5),
                              (cx + dx + 2, cy - bh + 1)],
                             fill=(224, 247, 250))

        elif acc == "word_streams":
            for a in [30, 150, 270]:
                sx = cx + int((bw + 8) * math.cos(math.radians(a)))
                sy = cy + int((bh + 6) * math.sin(math.radians(a)))
                draw.rectangle([sx - 3, sy - 1, sx + 3, sy + 1], fill=(128, 222, 234))

        elif acc == "dual_wings":
            # Light wing (right)
            wx = cx + bw + 1
            pts = [(wx, cy - 4), (wx + 10, cy - 8), (wx + 8, cy + 4)]
            draw.polygon(pts, fill=(255, 255, 255))
            # Shadow wing (left)
            wx = cx - bw - 1
            pts = [(wx, cy - 4), (wx - 10, cy - 8), (wx - 8, cy + 4)]
            draw.polygon(pts, fill=(158, 158, 158))

        elif acc == "glow_scars":
            draw.line([(cx - bw // 2, cy - 3), (cx - bw // 2 + 4, cy + 3)],
                      fill=(255, 171, 64), width=1)
            draw.line([(cx + bw // 2 - 2, cy - 4), (cx + bw // 2 + 2, cy + 2)],
                      fill=(255, 171, 64), width=1)


# === Aura/Particle Drawers ===

def draw_aura(img, cx, cy, bw, bh, form, s):
    """Draw form-specific aura/particle effects."""
    draw = ImageDraw.Draw(img)
    aura = form.get("aura")
    if not aura:
        return

    import random
    random.seed(hash(form.get("display", "")) + 42)  # Deterministic

    if aura == "leaf":
        for _ in range(4):
            lx = cx + random.randint(-bw - 8, bw + 8)
            ly = cy + random.randint(-bh - 6, bh + 6)
            draw.ellipse([lx, ly, lx + 2, ly + 1], fill=(139, 195, 74))

    elif aura == "bubble":
        for _ in range(5):
            bx = cx + random.randint(-bw - 6, bw + 6)
            by = cy + random.randint(-bh - 8, -bh // 2)
            r = random.randint(1, 2)
            draw.ellipse([bx - r, by - r, bx + r, by + r], outline=(129, 212, 250))

    elif aura == "rune":
        for _ in range(3):
            rx = cx + random.randint(-bw - 5, bw + 5)
            ry = cy + random.randint(-bh - 5, bh + 5)
            draw.point([rx, ry], fill=(206, 147, 216))

    elif aura == "shadow":
        overlay = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        for _ in range(6):
            sx = cx + random.randint(-bw - 4, bw + 4)
            sy = cy + random.randint(bh - 2, bh + 8)
            od.point([sx, sy], fill=(33, 33, 33, 100))
        img.paste(Image.alpha_composite(img, overlay))

    elif aura == "ember":
        for _ in range(5):
            ex = cx + random.randint(-bw - 4, bw + 4)
            ey = cy + random.randint(-bh - 8, -bh)
            draw.point([ex, ey], fill=(255, 152, 0))

    elif aura == "heart":
        for _ in range(3):
            hx = cx + random.randint(-bw - 6, bw + 6)
            hy = cy + random.randint(-bh - 6, bh)
            draw.point([hx, hy], fill=(248, 187, 208))

    elif aura == "confetti":
        colors = [(255, 152, 0), (76, 175, 80), (33, 150, 243), (244, 67, 54)]
        for _ in range(6):
            cx2 = cx + random.randint(-bw - 8, bw + 8)
            cy2 = cy + random.randint(-bh - 8, bh + 4)
            c = random.choice(colors)
            draw.point([cx2, cy2], fill=c)

    elif aura == "dark_flame":
        for _ in range(5):
            fx = cx + random.randint(-bw - 3, bw + 3)
            fy = cy + random.randint(-bh - 6, -bh + 2)
            draw.point([fx, fy], fill=(94, 53, 177))

    elif aura == "golden":
        overlay = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        r = bw + 6
        od.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 235, 59, 25))
        img.paste(Image.alpha_composite(img, overlay))

    elif aura == "star":
        for _ in range(5):
            sx = cx + random.randint(-bw - 8, bw + 8)
            sy = cy + random.randint(-bh - 8, bh + 4)
            draw.point([sx, sy], fill=(255, 255, 255))

    elif aura == "rainbow":
        colors = [(255, 82, 82), (255, 152, 0), (255, 235, 59),
                  (76, 175, 80), (33, 150, 243), (156, 39, 176)]
        for i, c in enumerate(colors):
            r = bw + 8 + i
            a = i * 60
            px = cx + int(r * math.cos(math.radians(a)))
            py = cy + int(r * math.sin(math.radians(a)))
            draw.point([px, py], fill=c)

    elif aura == "lightning":
        for _ in range(3):
            lx = cx + random.randint(-bw - 6, bw + 6)
            ly = cy + random.randint(-bh - 8, bh)
            draw.line([(lx, ly), (lx + random.randint(-3, 3), ly + 4)],
                      fill=(255, 235, 59), width=1)

    elif aura == "cosmic":
        for _ in range(8):
            sx = cx + random.randint(-bw - 10, bw + 10)
            sy = cy + random.randint(-bh - 10, bh + 10)
            draw.point([sx, sy], fill=(186, 104, 200))

    elif aura == "void":
        overlay = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        r = bw + 8
        od.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(20, 0, 40, 30))
        img.paste(Image.alpha_composite(img, overlay))

    elif aura == "ancient_gold":
        overlay = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        r = bw + 8
        od.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 214, 0, 20))
        img.paste(Image.alpha_composite(img, overlay))
        draw = ImageDraw.Draw(img)
        for _ in range(6):
            gx = cx + random.randint(-bw - 10, bw + 10)
            gy = cy + random.randint(-bh - 10, bh + 10)
            draw.point([gx, gy], fill=(255, 241, 118))

    elif aura == "eternal_light":
        overlay = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        r = bw + 10
        od.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 255, 255, 20))
        img.paste(Image.alpha_composite(img, overlay))

    elif aura == "language_flow":
        for _ in range(5):
            tx = cx + random.randint(-bw - 10, bw + 10)
            ty = cy + random.randint(-bh - 8, bh + 4)
            draw.rectangle([tx, ty, tx + 3, ty + 1], fill=(128, 222, 234))

    elif aura == "redemption":
        overlay = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        r = bw + 8
        # Dawn gradient
        od.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 171, 64, 20))
        img.paste(Image.alpha_composite(img, overlay))


# === Mouth Drawer ===

def draw_mouth(img, cx, cy, bw, bh, form):
    """Draw a small default mouth."""
    draw = ImageDraw.Draw(img)
    my = cy + int(bh * 0.25)
    is_dark = form.get("dark", False)
    mouth_color = form["eye"] if not is_dark else (180, 50, 50)
    # Simple smile
    mw = max(2, bw // 4)
    draw.arc([cx - mw, my - 1, cx + mw, my + mw], 0, 180, fill=mouth_color, width=1)


# === Main Generator ===

def generate_form_sprite(form_id: str, size: int) -> Image.Image:
    """Generate a single form sprite."""
    form = FORMS[form_id]
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shape = form["shape"]

    # Draw body based on shape type
    if shape == "blob":
        cx, cy, bw, bh = draw_body_blob(img, size, form)
    elif shape == "round":
        cx, cy, bw, bh = draw_body_round(img, size, form)
    elif shape == "angular_round":
        cx, cy, bw, bh = draw_body_angular_round(img, size, form)
    elif shape == "upright":
        cx, cy, bw, bh = draw_body_upright(img, size, form)
    elif shape == "slim_tall":
        cx, cy, bw, bh = draw_body_slim_tall(img, size, form)
    elif shape == "soft_round":
        cx, cy, bw, bh = draw_body_soft_round(img, size, form)
    elif shape == "bouncy":
        cx, cy, bw, bh = draw_body_bouncy(img, size, form)
    else:
        cx, cy, bw, bh = draw_body_generic(img, size, form, shape)

    # Draw accessories (behind body for some, in front for others)
    draw_accessories(img, cx, cy, bw, bh, form, size)

    # Draw eyes
    draw_eyes(img, cx, cy, bw, bh, form)

    # Draw mouth
    draw_mouth(img, cx, cy, bw, bh, form)

    # Draw aura/particles
    draw_aura(img, cx, cy, bw, bh, form, size)

    return img


def main():
    parser = argparse.ArgumentParser(description="PetClaw Form Sprite Generator v2")
    parser.add_argument("--form", type=str, help="Single form to generate")
    parser.add_argument("--all", action="store_true", help="Generate all forms")
    parser.add_argument("--size", type=int, default=64, help="Sprite size (default: 64)")
    parser.add_argument("--output", type=str, default="./output", help="Output directory")
    args = parser.parse_args()

    os.makedirs(args.output, exist_ok=True)

    forms = list(FORMS.keys()) if args.all else ([args.form] if args.form else ["blob"])

    for form_id in forms:
        if form_id not in FORMS:
            print(f"WARNING: Unknown form '{form_id}', skipping")
            continue

        print(f"Generating: {form_id} ({FORMS[form_id]['display']}) @ {args.size}px...")
        img = generate_form_sprite(form_id, args.size)
        out_path = os.path.join(args.output, f"{form_id}.png")
        img.save(out_path)
        print(f"  -> {out_path}")

    print(f"\nDone! {len(forms)} sprites generated in {args.output}/")


if __name__ == "__main__":
    main()
