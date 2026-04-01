#!/usr/bin/env python3
"""
PetClaw Expression Template Generator
=====================================
ExpressionSystemの12目×10口×12エフェクトのプレースホルダースプライトを生成。
Asepriteがあればaseprite形式、なければPillowで直接PNGを生成。

Usage:
    python generate_expression_template.py --form forest_infant --size 32 --output ./out/
    python generate_expression_template.py --all-forms --size 32 --output ./out/
"""

import argparse
import json
import os
import subprocess
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
    HAS_PILLOW = True
except ImportError:
    HAS_PILLOW = False

# === Expression System定義（GDScript expression_system.gd と同期） ===

EYE_SHAPES = [
    "NORMAL", "HAPPY", "EXCITED", "SAD", "ANGRY", "SCARED",
    "SLEEPY", "LOVE", "CURIOUS", "CLOSED", "DOT", "SPARKLE",
]

MOUTH_SHAPES = [
    "NEUTRAL", "SMILE", "WIDE_SMILE", "FROWN", "OPEN",
    "WAVY", "CHOMP", "POUT", "WHISTLE", "TINY_SMILE",
]

EXPRESSION_EFFECTS = [
    "NONE", "HEART", "MUSIC_NOTE", "EXCLAMATION", "QUESTION",
    "ANGER_MARK", "SWEAT_DROP", "SPARKLES", "ZZZZZ", "TEARS", "BLUSH", "SHADOW",
]

# 進化フォームID（evolution_tree.gd と同期）
ALL_FORMS = [
    # Stage 2
    "forest_infant", "sea_infant", "ruins_infant", "city_infant", "neglected_infant",
    # Stage 3
    "warrior_youth", "scholar_youth", "healer_youth", "trickster_youth",
    "sentinel_youth", "diplomat_youth", "shadow_youth",
    # Stage 4
    "guardian_adult", "sage_adult", "bond_master_adult",
    "storm_warrior_adult", "mystic_adult", "dark_sovereign_adult",
    # Stage 5
    "ancient_elder", "eternal_companion", "language_sage_elder", "redeemed_elder",
]

# フォームごとの基本カラーパレット
FORM_PALETTES = {
    "forest_infant":   {"body": (76, 175, 80),  "accent": (139, 195, 74),  "eye": (33, 33, 33)},
    "sea_infant":      {"body": (66, 165, 245),  "accent": (129, 212, 250), "eye": (33, 33, 33)},
    "ruins_infant":    {"body": (171, 71, 188),  "accent": (206, 147, 216), "eye": (33, 33, 33)},
    "city_infant":     {"body": (255, 167, 38),  "accent": (255, 213, 79),  "eye": (33, 33, 33)},
    "neglected_infant":{"body": (97, 97, 97),    "accent": (66, 66, 66),    "eye": (183, 28, 28)},
    # Youth
    "warrior_youth":   {"body": (211, 47, 47),   "accent": (255, 138, 101), "eye": (33, 33, 33)},
    "scholar_youth":   {"body": (48, 63, 159),   "accent": (121, 134, 203), "eye": (33, 33, 33)},
    "healer_youth":    {"body": (236, 64, 122),  "accent": (248, 187, 208), "eye": (33, 33, 33)},
    "trickster_youth": {"body": (255, 179, 0),   "accent": (255, 224, 130), "eye": (33, 33, 33)},
    "sentinel_youth":  {"body": (69, 90, 100),   "accent": (144, 164, 174), "eye": (33, 33, 33)},
    "diplomat_youth":  {"body": (0, 150, 136),   "accent": (128, 203, 196), "eye": (33, 33, 33)},
    "shadow_youth":    {"body": (49, 27, 146),   "accent": (94, 53, 177),   "eye": (244, 67, 54)},
    # Adult
    "guardian_adult":  {"body": (255, 193, 7),   "accent": (255, 224, 130), "eye": (33, 33, 33)},
    "sage_adult":      {"body": (30, 136, 229),  "accent": (100, 181, 246), "eye": (33, 33, 33)},
    "bond_master_adult":{"body": (233, 30, 99),  "accent": (248, 187, 208), "eye": (33, 33, 33)},
    "storm_warrior_adult":{"body": (183, 28, 28),"accent": (239, 83, 80),   "eye": (33, 33, 33)},
    "mystic_adult":    {"body": (106, 27, 154),  "accent": (186, 104, 200), "eye": (33, 33, 33)},
    "dark_sovereign_adult":{"body": (33, 33, 33),"accent": (69, 39, 160),   "eye": (244, 67, 54)},
    # Elder
    "ancient_elder":   {"body": (255, 214, 0),   "accent": (255, 241, 118), "eye": (33, 33, 33)},
    "eternal_companion":{"body": (233, 30, 99),  "accent": (252, 228, 236), "eye": (33, 33, 33)},
    "language_sage_elder":{"body": (0, 131, 143),"accent": (128, 222, 234), "eye": (33, 33, 33)},
    "redeemed_elder":  {"body": (230, 81, 0),    "accent": (255, 171, 64),  "eye": (245, 127, 23)},
}

# === Aseprite CLI操作 ===

def check_aseprite() -> bool:
    """Aseprite CLIが利用可能か確認"""
    try:
        result = subprocess.run(["aseprite", "--version"], capture_output=True, text=True, timeout=5)
        return result.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def create_aseprite_template(form_id: str, size: int, output_dir: str) -> str:
    """Aseprite CLIでテンプレート.asepriteファイルを生成"""
    palette = FORM_PALETTES.get(form_id, FORM_PALETTES["forest_infant"])
    output_path = os.path.join(output_dir, f"{form_id}_expressions.aseprite")

    # Aseprite Lua スクリプトを生成
    lua_script = f"""
-- PetClaw Expression Template Generator
-- Form: {form_id}

local sprite = Sprite({size * len(EYE_SHAPES)}, {size * 4})
sprite.filename = "{output_path}"

-- Layer: eyes
local eyeLayer = sprite.layers[1]
eyeLayer.name = "eyes"

-- Layer: mouth
local mouthLayer = sprite:newLayer()
mouthLayer.name = "mouth"

-- Layer: effects
local fxLayer = sprite:newLayer()
fxLayer.name = "effects"

-- Layer: body (base)
local bodyLayer = sprite:newLayer()
bodyLayer.name = "body"

-- Set palette
local pal = Palette(8)
pal:setColor(0, Color{{ r=0, g=0, b=0, a=0 }})
pal:setColor(1, Color{{ r={palette['body'][0]}, g={palette['body'][1]}, b={palette['body'][2]} }})
pal:setColor(2, Color{{ r={palette['accent'][0]}, g={palette['accent'][1]}, b={palette['accent'][2]} }})
pal:setColor(3, Color{{ r={palette['eye'][0]}, g={palette['eye'][1]}, b={palette['eye'][2]} }})
pal:setColor(4, Color{{ r=255, g=255, b=255 }})
pal:setColor(5, Color{{ r=247, g=120, b=186 }})  -- blush/love
pal:setColor(6, Color{{ r=255, g=235, b=59 }})   -- sparkle
pal:setColor(7, Color{{ r=139, g=92, b=246 }})    -- shadow/dark

sprite:setPalette(pal)
sprite:saveAs("{output_path}")
"""
    lua_path = os.path.join(output_dir, f"_gen_{form_id}.lua")
    with open(lua_path, "w") as f:
        f.write(lua_script)

    subprocess.run(["aseprite", "-b", "--script", lua_path], capture_output=True)
    os.remove(lua_path)
    return output_path


# === Pillow フォールバック ===

def draw_eye(draw: "ImageDraw.Draw", x: int, y: int, size: int, shape: str, color: tuple):
    """目パターンを描画"""
    s = max(2, size // 4)
    cx, cy = x + size // 2, y + size // 2

    if shape == "NORMAL":
        draw.ellipse([cx - s, cy - s, cx + s, cy + s], fill=color)
    elif shape == "HAPPY":
        draw.arc([cx - s, cy - s//2, cx + s, cy + s], 0, 180, fill=color, width=1)
    elif shape == "EXCITED":
        # 星形（簡易）
        for angle_offset in range(0, 360, 72):
            import math
            a = math.radians(angle_offset - 90)
            ex = cx + int(math.cos(a) * s)
            ey = cy + int(math.sin(a) * s)
            draw.line([cx, cy, ex, ey], fill=color, width=1)
    elif shape == "SAD":
        draw.arc([cx - s, cy, cx + s, cy + s * 2], 180, 360, fill=color, width=1)
    elif shape == "ANGRY":
        draw.line([cx - s, cy - s, cx + s, cy + s//2], fill=color, width=1)
    elif shape == "SCARED":
        draw.ellipse([cx - s - 1, cy - s - 1, cx + s + 1, cy + s + 1], fill=color)
    elif shape == "SLEEPY":
        draw.line([cx - s, cy, cx + s, cy], fill=color, width=1)
    elif shape == "LOVE":
        draw.text((cx - s, cy - s), "♥", fill=(247, 120, 186))
    elif shape == "CURIOUS":
        draw.ellipse([cx - s, cy - s, cx + s - 1, cy + s], fill=color)
        draw.ellipse([cx + 1, cy - s - 1, cx + s + 1, cy + s + 1], fill=color)
    elif shape == "CLOSED":
        draw.line([cx - s, cy - 1, cx - 1, cy + 1], fill=color, width=1)
        draw.line([cx + 1, cy - 1, cx + s, cy + 1], fill=color, width=1)
    elif shape == "DOT":
        draw.point([cx, cy], fill=color)
    elif shape == "SPARKLE":
        draw.line([cx, cy - s, cx, cy + s], fill=(255, 235, 59), width=1)
        draw.line([cx - s, cy, cx + s, cy], fill=(255, 235, 59), width=1)


def draw_mouth(draw: "ImageDraw.Draw", x: int, y: int, w: int, h: int, shape: str, color: tuple):
    """口パターンを描画"""
    cx = x + w // 2
    cy = y + h // 2
    s = max(1, w // 4)

    if shape == "NEUTRAL":
        draw.line([cx - s, cy, cx + s, cy], fill=color, width=1)
    elif shape == "SMILE":
        draw.arc([cx - s, cy - s//2, cx + s, cy + s], 0, 180, fill=color, width=1)
    elif shape == "WIDE_SMILE":
        draw.arc([cx - s - 1, cy - s, cx + s + 1, cy + s], 0, 180, fill=color, width=1)
    elif shape == "FROWN":
        draw.arc([cx - s, cy, cx + s, cy + s * 2], 180, 360, fill=color, width=1)
    elif shape == "OPEN":
        draw.ellipse([cx - s//2, cy - s//2, cx + s//2, cy + s//2], fill=color)
    elif shape == "WAVY":
        for i in range(-s, s + 1):
            import math
            oy = int(math.sin(i * 0.8) * 1)
            draw.point([cx + i, cy + oy], fill=color)
    elif shape == "CHOMP":
        draw.polygon([(cx - s, cy), (cx, cy + s), (cx + s, cy)], fill=color)
    elif shape == "POUT":
        draw.ellipse([cx - s//2, cy - 1, cx + s//2, cy + s//2], fill=color)
    elif shape == "WHISTLE":
        draw.ellipse([cx - 1, cy - 1, cx + 1, cy + 1], fill=color)
    elif shape == "TINY_SMILE":
        draw.arc([cx - s//2, cy - 1, cx + s//2, cy + s//2], 0, 180, fill=color, width=1)


def generate_pillow_template(form_id: str, size: int, output_dir: str) -> dict:
    """Pillowで表情テンプレートPNGを生成"""
    if not HAS_PILLOW:
        print("ERROR: Pillow not installed. Run: pip install Pillow")
        sys.exit(1)

    palette = FORM_PALETTES.get(form_id, FORM_PALETTES["forest_infant"])
    generated = {"eyes": [], "mouths": [], "combined": []}

    # --- 目スプライトシート ---
    eye_sheet_w = size * len(EYE_SHAPES)
    eye_sheet_h = size
    eye_img = Image.new("RGBA", (eye_sheet_w, eye_sheet_h), (0, 0, 0, 0))
    eye_draw = ImageDraw.Draw(eye_img)

    for i, shape in enumerate(EYE_SHAPES):
        x = i * size
        # 左目
        draw_eye(eye_draw, x + 2, 2, size // 2, shape, palette["eye"])
        # 右目
        draw_eye(eye_draw, x + size // 2, 2, size // 2, shape, palette["eye"])
        generated["eyes"].append(shape)

    eye_path = os.path.join(output_dir, f"{form_id}_eyes.png")
    eye_img.save(eye_path)

    # --- 口スプライトシート ---
    mouth_sheet_w = size * len(MOUTH_SHAPES)
    mouth_sheet_h = size // 2
    mouth_img = Image.new("RGBA", (mouth_sheet_w, mouth_sheet_h), (0, 0, 0, 0))
    mouth_draw = ImageDraw.Draw(mouth_img)

    for i, shape in enumerate(MOUTH_SHAPES):
        draw_mouth(mouth_draw, i * size, 0, size, size // 2, shape, palette["eye"])
        generated["mouths"].append(shape)

    mouth_path = os.path.join(output_dir, f"{form_id}_mouths.png")
    mouth_img.save(mouth_path)

    # --- 組み合わせプリセット（よく使う8表情） ---
    presets = [
        ("idle",       "NORMAL",  "NEUTRAL"),
        ("happy",      "HAPPY",   "SMILE"),
        ("excited",    "EXCITED", "WIDE_SMILE"),
        ("sad",        "SAD",     "FROWN"),
        ("scared",     "SCARED",  "OPEN"),
        ("love",       "LOVE",    "SMILE"),
        ("sleepy",     "SLEEPY",  "NEUTRAL"),
        ("angry",      "ANGRY",   "FROWN"),
    ]

    preset_img = Image.new("RGBA", (size * len(presets), size), (0, 0, 0, 0))
    preset_draw = ImageDraw.Draw(preset_img)

    for i, (name, eye, mouth) in enumerate(presets):
        x = i * size
        # Body silhouette
        body_margin = size // 8
        preset_draw.rounded_rectangle(
            [x + body_margin, body_margin, x + size - body_margin, size - body_margin],
            radius=size // 6, fill=palette["body"]
        )
        # Belly
        belly_m = size // 4
        preset_draw.rounded_rectangle(
            [x + belly_m, size // 3, x + size - belly_m, size - belly_m],
            radius=size // 8, fill=palette["accent"]
        )
        # Eyes
        draw_eye(preset_draw, x + 2, size // 6, size // 2, eye, palette["eye"])
        draw_eye(preset_draw, x + size // 2, size // 6, size // 2, eye, palette["eye"])
        # Mouth
        draw_mouth(preset_draw, x, size // 2, size, size // 4, mouth, palette["eye"])
        generated["combined"].append(name)

    preset_path = os.path.join(output_dir, f"{form_id}_presets.png")
    preset_img.save(preset_path)

    # --- メタデータJSON ---
    meta = {
        "form_id": form_id,
        "sprite_size": size,
        "palette": {k: list(v) for k, v in palette.items()},
        "eye_sheet": f"{form_id}_eyes.png",
        "eye_shapes": EYE_SHAPES,
        "eye_frame_width": size,
        "mouth_sheet": f"{form_id}_mouths.png",
        "mouth_shapes": MOUTH_SHAPES,
        "mouth_frame_width": size,
        "mouth_frame_height": size // 2,
        "preset_sheet": f"{form_id}_presets.png",
        "presets": [p[0] for p in presets],
        "preset_frame_width": size,
    }
    meta_path = os.path.join(output_dir, f"{form_id}_meta.json")
    with open(meta_path, "w") as f:
        json.dump(meta, f, indent=2)

    return generated


# === Aseprite バッチエクスポート ===

def batch_export_aseprite(input_dir: str, output_dir: str, size: int):
    """Asepriteファイルを一括でスプライトシートにエクスポート"""
    if not check_aseprite():
        print("WARNING: Aseprite not found. Skipping batch export.")
        return

    for fname in os.listdir(input_dir):
        if not fname.endswith(".aseprite") and not fname.endswith(".ase"):
            continue
        input_path = os.path.join(input_dir, fname)
        base = os.path.splitext(fname)[0]
        sheet_path = os.path.join(output_dir, f"{base}_sheet.png")
        data_path = os.path.join(output_dir, f"{base}_sheet.json")

        cmd = [
            "aseprite", "-b",
            input_path,
            "--sheet", sheet_path,
            "--data", data_path,
            "--format", "json-array",
            "--sheet-type", "horizontal",
        ]
        print(f"  Exporting: {fname} → {base}_sheet.png")
        subprocess.run(cmd, capture_output=True)


# === ダークルート色調変換 ===

def create_dark_variant(input_path: str, output_path: str):
    """通常フォームからダークルート版を生成（彩度↓明度↓色相シフト）"""
    if not HAS_PILLOW:
        print("ERROR: Pillow not installed.")
        return

    img = Image.open(input_path).convert("RGBA")
    pixels = img.load()

    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            # HSV変換 → 色相-30°, 彩度-20%, 明度-25%
            import colorsys
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            h = (h - 30 / 360) % 1.0
            s = max(0, s - 0.2)
            v = max(0, v - 0.25)
            r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
            pixels[x, y] = (int(r2 * 255), int(g2 * 255), int(b2 * 255), a)

    img.save(output_path)
    print(f"  Dark variant: {input_path} → {output_path}")


# === Godot SpriteFrames リソース生成 ===

def generate_sprite_frames_resource(sprites_dir: str, output_dir: str):
    """スプライトシートからGodot SpriteFrames .tres リソースを生成"""
    os.makedirs(output_dir, exist_ok=True)

    for meta_file in sorted(os.listdir(sprites_dir)):
        if not meta_file.endswith("_meta.json"):
            continue
        meta_path = os.path.join(sprites_dir, meta_file)
        with open(meta_path) as f:
            meta = json.load(f)

        form_id = meta["form_id"]
        size = meta["sprite_size"]
        presets = meta.get("presets", [])

        # Godot .tres は手書きが必要だが、ここではインポートスクリプト用の
        # 設定ファイルを生成する
        import_config = {
            "form_id": form_id,
            "animations": {},
        }

        # プリセットアニメーション
        for i, preset_name in enumerate(presets):
            import_config["animations"][preset_name] = {
                "sheet": meta["preset_sheet"],
                "frame_index": i,
                "frame_width": meta["preset_frame_width"],
                "frame_height": size,
                "loop": preset_name in ("idle", "sleepy"),
            }

        config_path = os.path.join(output_dir, f"{form_id}_import.json")
        with open(config_path, "w") as f:
            json.dump(import_config, f, indent=2)
        print(f"  Import config: {config_path}")


# === Main ===

def main():
    parser = argparse.ArgumentParser(description="PetClaw Expression Sprite Generator")
    parser.add_argument("--form", type=str, help="Form ID to generate (e.g. forest_infant)")
    parser.add_argument("--all-forms", action="store_true", help="Generate all forms")
    parser.add_argument("--size", type=int, default=32, help="Sprite size in pixels (default: 32)")
    parser.add_argument("--output", type=str, default="./output", help="Output directory")
    parser.add_argument("--dark-variant", type=str, help="Input PNG to create dark variant from")
    parser.add_argument("--batch-export", type=str, help="Input dir of .aseprite files to batch export")
    parser.add_argument("--generate-import", type=str, help="Sprites dir to generate Godot import configs")
    args = parser.parse_args()

    os.makedirs(args.output, exist_ok=True)

    if args.dark_variant:
        dark_out = os.path.join(args.output, "dark_" + os.path.basename(args.dark_variant))
        create_dark_variant(args.dark_variant, dark_out)
        return

    if args.batch_export:
        batch_export_aseprite(args.batch_export, args.output, args.size)
        return

    if args.generate_import:
        generate_sprite_frames_resource(args.generate_import, args.output)
        return

    forms = ALL_FORMS if args.all_forms else ([args.form] if args.form else ["forest_infant"])
    has_aseprite = check_aseprite()

    for form_id in forms:
        print(f"\n=== Generating: {form_id} (size={args.size}px) ===")
        form_output = os.path.join(args.output, form_id)
        os.makedirs(form_output, exist_ok=True)

        if has_aseprite:
            print("  Using Aseprite CLI...")
            create_aseprite_template(form_id, args.size, form_output)
        else:
            print("  Aseprite not found, using Pillow fallback...")

        result = generate_pillow_template(form_id, args.size, form_output)
        print(f"  Eyes: {len(result['eyes'])} shapes")
        print(f"  Mouths: {len(result['mouths'])} shapes")
        print(f"  Presets: {len(result['combined'])} expressions")

    print(f"\nDone! Output: {args.output}")


if __name__ == "__main__":
    main()
