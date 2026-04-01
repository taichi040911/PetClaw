# PetClaw Sprite Pipeline

Aseprite CLIを使った表情・進化フォームスプライトの量産パイプライン。

## 必要環境
- Aseprite (CLI対応版) — `aseprite` がPATHに通っていること
- Python 3.10+
- Pillow (`pip install Pillow`)

## 使い方

```bash
# 表情テンプレートの生成（プレースホルダー）
python generate_expression_template.py --form forest_infant --output ../godot_project/assets/sprites/expressions/

# 全進化フォームの一括処理
python batch_export.py --input ./aseprite_sources/ --output ../godot_project/assets/sprites/evolution_forms/

# ダークルート色調変換
python dark_variant.py --input base_form.png --output dark_form.png

# Godot SpriteFrames リソース生成
python generate_sprite_frames.py --sprites-dir ../godot_project/assets/sprites/ --output ../godot_project/resources/
```
