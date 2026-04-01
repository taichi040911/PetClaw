#!/usr/bin/env python3
"""PetClaw Palette Generator — ui-avatarsのMaterial Designパレットロジックを進化フォームに適用
22フォーム × 自動パレット生成（名前ハッシュ→色選択）

Usage:
    python3 palette_generator.py [--output palettes.json] [--format gdscript|json|css]
"""

import json
import hashlib
import colorsys
import click
from pathlib import Path

# Material Design inspired palette (from ui-avatars, expanded for PetClaw)
MATERIAL_COLORS = [
    # Red family
    {"bg": "#F44336", "fg": "#FFFFFF", "family": "red"},
    {"bg": "#E91E63", "fg": "#FFFFFF", "family": "pink"},
    {"bg": "#9C27B0", "fg": "#FFFFFF", "family": "purple"},
    {"bg": "#673AB7", "fg": "#FFFFFF", "family": "deep_purple"},
    # Blue family
    {"bg": "#3F51B5", "fg": "#FFFFFF", "family": "indigo"},
    {"bg": "#2196F3", "fg": "#FFFFFF", "family": "blue"},
    {"bg": "#03A9F4", "fg": "#FFFFFF", "family": "light_blue"},
    {"bg": "#00BCD4", "fg": "#FFFFFF", "family": "cyan"},
    # Green family
    {"bg": "#009688", "fg": "#FFFFFF", "family": "teal"},
    {"bg": "#4CAF50", "fg": "#FFFFFF", "family": "green"},
    {"bg": "#8BC34A", "fg": "#000000", "family": "light_green"},
    {"bg": "#CDDC39", "fg": "#000000", "family": "lime"},
    # Warm family
    {"bg": "#FFEB3B", "fg": "#000000", "family": "yellow"},
    {"bg": "#FFC107", "fg": "#000000", "family": "amber"},
    {"bg": "#FF9800", "fg": "#000000", "family": "orange"},
    {"bg": "#FF5722", "fg": "#FFFFFF", "family": "deep_orange"},
    # Neutral family
    {"bg": "#795548", "fg": "#FFFFFF", "family": "brown"},
    {"bg": "#607D8B", "fg": "#FFFFFF", "family": "blue_grey"},
]

# PetClaw 22 evolution forms (synced with evolution_tree.gd)
ALL_FORMS = [
    # Stage 2
    "flame_sprite", "aqua_pup", "leaf_dancer", "shadow_wisp",
    # Stage 3
    "blaze_fox", "tide_wolf", "grove_deer", "night_cat",
    "storm_hawk", "crystal_rabbit",
    # Stage 4
    "inferno_lion", "ocean_dragon", "forest_guardian", "void_panther",
    "thunder_eagle", "diamond_unicorn", "chaos_chimera", "harmony_phoenix",
    # Stage 5
    "celestial_sovereign", "abyssal_leviathan", "world_tree_spirit", "redeemed_elder",
]

# Dark evolution forms get special dark palette treatment
DARK_FORMS = {"shadow_wisp", "night_cat", "void_panther", "chaos_chimera", "abyssal_leviathan"}

# Special forms get rainbow/luminous treatment
SPECIAL_FORMS = {"harmony_phoenix", "celestial_sovereign", "world_tree_spirit", "redeemed_elder"}


def name_to_hash(name: str) -> int:
    """Generate deterministic hash from form name (ui-avatars pattern)"""
    return int(hashlib.md5(name.encode()).hexdigest()[:8], 16)


def generate_palette(form_name: str) -> dict:
    """Generate a complete color palette for a form"""
    h = name_to_hash(form_name)
    base_idx = h % len(MATERIAL_COLORS)
    base = MATERIAL_COLORS[base_idx]
    
    # Parse base color
    bg_hex = base["bg"]
    r, g, b = int(bg_hex[1:3], 16), int(bg_hex[3:5], 16), int(bg_hex[5:7], 16)
    h_val, s_val, v_val = colorsys.rgb_to_hsv(r/255, g/255, b/255)
    
    if form_name in DARK_FORMS:
        # Dark forms: desaturate slightly, darken significantly
        v_val = max(0.15, v_val * 0.4)
        s_val = min(1.0, s_val * 1.2)
        accent_h = (h_val + 0.5) % 1.0  # Complementary accent
        accent_r, accent_g, accent_b = colorsys.hsv_to_rgb(accent_h, 0.8, 0.9)
    elif form_name in SPECIAL_FORMS:
        # Special forms: high saturation, luminous
        v_val = min(1.0, v_val * 1.2)
        s_val = min(1.0, s_val * 1.3)
        accent_h = (h_val + 0.15) % 1.0  # Analogous accent
        accent_r, accent_g, accent_b = colorsys.hsv_to_rgb(accent_h, 0.9, 1.0)
    else:
        accent_h = (h_val + 0.33) % 1.0  # Triadic accent
        accent_r, accent_g, accent_b = colorsys.hsv_to_rgb(accent_h, s_val * 0.8, v_val * 0.9)
    
    main_r, main_g, main_b = colorsys.hsv_to_rgb(h_val, s_val, v_val)
    
    # Generate light/dark variants
    light_r, light_g, light_b = colorsys.hsv_to_rgb(h_val, s_val * 0.3, min(1.0, v_val * 1.4))
    dark_r, dark_g, dark_b = colorsys.hsv_to_rgb(h_val, min(1.0, s_val * 1.3), v_val * 0.5)
    
    def to_hex(r, g, b):
        return "#{:02X}{:02X}{:02X}".format(int(r*255), int(g*255), int(b*255))
    
    def to_rgb_tuple(r, g, b):
        return [int(r*255), int(g*255), int(b*255)]
    
    return {
        "form": form_name,
        "is_dark": form_name in DARK_FORMS,
        "is_special": form_name in SPECIAL_FORMS,
        "family": base["family"],
        "main": to_hex(main_r, main_g, main_b),
        "main_rgb": to_rgb_tuple(main_r, main_g, main_b),
        "accent": to_hex(accent_r, accent_g, accent_b),
        "accent_rgb": to_rgb_tuple(accent_r, accent_g, accent_b),
        "light": to_hex(light_r, light_g, light_b),
        "light_rgb": to_rgb_tuple(light_r, light_g, light_b),
        "dark": to_hex(dark_r, dark_g, dark_b),
        "dark_rgb": to_rgb_tuple(dark_r, dark_g, dark_b),
        "text": "#FFFFFF" if v_val < 0.6 else "#000000",
    }


def format_gdscript(palettes: list) -> str:
    """Output as GDScript dictionary constant"""
    lines = ["## Auto-generated by palette_generator.py (ui-avatars Material Design pattern)",
             "## 22 evolution forms × deterministic palette",
             "const FORM_PALETTES: Dictionary = {"]
    for p in palettes:
        rgb = p["main_rgb"]
        accent = p["accent_rgb"]
        tag = ""
        if p["is_dark"]:
            tag = " # DARK"
        elif p["is_special"]:
            tag = " # SPECIAL"
        lines.append(f'\t"{p["form"]}": {{"main": Color({rgb[0]/255:.3f}, {rgb[1]/255:.3f}, {rgb[2]/255:.3f}), '
                     f'"accent": Color({accent[0]/255:.3f}, {accent[1]/255:.3f}, {accent[2]/255:.3f})}},{tag}')
    lines.append("}")
    return "\n".join(lines)


@click.command()
@click.option("--output", "-o", default=None, help="Output file path")
@click.option("--format", "fmt", type=click.Choice(["json", "gdscript", "css"]), default="json")
def main(output, fmt):
    """Generate color palettes for all 22 PetClaw evolution forms"""
    palettes = [generate_palette(form) for form in ALL_FORMS]
    
    if fmt == "json":
        content = json.dumps(palettes, ensure_ascii=False, indent=2)
    elif fmt == "gdscript":
        content = format_gdscript(palettes)
    elif fmt == "css":
        lines = ["/* Auto-generated PetClaw form palettes */"]
        for p in palettes:
            lines.append(f'.form-{p["form"].replace("_", "-")} {{')
            lines.append(f'  --color-main: {p["main"]};')
            lines.append(f'  --color-accent: {p["accent"]};')
            lines.append(f'  --color-light: {p["light"]};')
            lines.append(f'  --color-dark: {p["dark"]};')
            lines.append(f'  --color-text: {p["text"]};')
            lines.append("}")
        content = "\n".join(lines)
    
    if output:
        Path(output).write_text(content, encoding="utf-8")
        click.echo(f"Written {len(palettes)} palettes to {output}")
    else:
        click.echo(content)
    
    # Summary
    dark_count = sum(1 for p in palettes if p["is_dark"])
    special_count = sum(1 for p in palettes if p["is_special"])
    click.echo(f"\n--- {len(palettes)} forms: {dark_count} dark, {special_count} special, "
               f"{len(palettes) - dark_count - special_count} normal ---", err=True)


if __name__ == "__main__":
    main()
