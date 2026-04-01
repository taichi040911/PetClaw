#!/usr/bin/env python3
"""
PetClaw Debug CLI
=================
PetClawシステムのデバッグ・検査用コマンドラインツール。
GDScriptのデータ定義を直接パースし、進化条件チェック、
フィールド状態検査、AtoAシミュレーション等を実行。

CLI-Anything互換のJSON出力モードをサポート。

Usage:
    python petclaw_cli.py evolution check --pet-id 1
    python petclaw_cli.py evolution tree --stage 3
    python petclaw_cli.py field status
    python petclaw_cli.py expression show --emotion joy --intensity 0.8
    python petclaw_cli.py ethics report
    python petclaw_cli.py a2a simulate --pet1 1 --pet2 2
"""

import json
import os
import re
import sys
from pathlib import Path

import click

# プロジェクトルート検出
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
GODOT_DIR = PROJECT_ROOT / "godot_project"
SCRIPTS_DIR = GODOT_DIR / "scripts"
KB_DIR = PROJECT_ROOT / "knowledge_base"


# === ユーティリティ ===

def output(data: dict, json_mode: bool):
    """結果出力（JSON or human-readable）"""
    if json_mode:
        click.echo(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        for key, val in data.items():
            if isinstance(val, dict):
                click.echo(f"\n  {click.style(key, fg='cyan', bold=True)}:")
                for k2, v2 in val.items():
                    click.echo(f"    {k2}: {v2}")
            elif isinstance(val, list):
                click.echo(f"\n  {click.style(key, fg='cyan', bold=True)}:")
                for item in val:
                    if isinstance(item, dict):
                        click.echo(f"    - {item.get('id', item.get('name', str(item)))}")
                    else:
                        click.echo(f"    - {item}")
            else:
                click.echo(f"  {click.style(key, fg='cyan')}: {val}")


def read_gdscript(path: Path) -> str:
    """GDScriptファイルを読み込み"""
    if not path.exists():
        click.echo(f"ERROR: File not found: {path}", err=True)
        sys.exit(1)
    return path.read_text(encoding="utf-8")


# === Evolution Tree パーサー ===

def parse_evolution_tree() -> dict:
    """evolution_tree.gd から進化パスデータを抽出"""
    tree_path = SCRIPTS_DIR / "evolution" / "evolution_tree.gd"
    content = read_gdscript(tree_path)

    stages = {}
    # パスの抽出: "id": "xxx", "display_name": "xxx" のパターンを探す
    current_stage = None
    lines = content.split("\n")

    for i, line in enumerate(lines):
        # ステージ見出しを検出
        stage_match = re.search(r'Stage\s*(\d)', line)
        if stage_match:
            current_stage = int(stage_match.group(1))
            if current_stage not in stages:
                stages[current_stage] = []

        # パスIDを検出
        id_match = re.search(r'"id":\s*"([^"]+)"', line)
        if id_match and current_stage:
            form_id = id_match.group(1)
            # 周辺行からdisplay_nameを取得
            display_name = ""
            description = ""
            is_dark = False
            is_special = False
            conditions = {}
            stat_bonus = {}

            for j in range(max(0, i - 2), min(len(lines), i + 20)):
                dn_match = re.search(r'"display_name":\s*"([^"]+)"', lines[j])
                if dn_match:
                    display_name = dn_match.group(1)
                desc_match = re.search(r'"description":\s*"([^"]+)"', lines[j])
                if desc_match:
                    description = desc_match.group(1)
                if '"is_dark_route": true' in lines[j]:
                    is_dark = True
                if '"is_special": true' in lines[j]:
                    is_special = True

            stages[current_stage].append({
                "id": form_id,
                "display_name": display_name,
                "description": description,
                "is_dark": is_dark,
                "is_special": is_special,
                "stage": current_stage,
            })

    return stages


def parse_care_thresholds() -> dict:
    """ケア品質閾値を取得"""
    return {
        "excellent": {"max_misses": 1, "label": "優秀"},
        "good": {"max_misses": 3, "label": "良好"},
        "average": {"max_misses": 5, "label": "平均"},
        "poor": {"min_misses": 6, "label": "不良 → ダークルート"},
    }


# === Expression System パーサー ===

EMOTION_EXPRESSION_MAP = {
    "joy_low": {"eye": "NORMAL", "mouth": "TINY_SMILE", "effect": "NONE"},
    "joy_mid": {"eye": "HAPPY", "mouth": "SMILE", "effect": "MUSIC_NOTE"},
    "joy_high": {"eye": "HAPPY", "mouth": "WIDE_SMILE", "effect": "SPARKLES"},
    "fear_low": {"eye": "NORMAL", "mouth": "WAVY", "effect": "SWEAT_DROP"},
    "fear_mid": {"eye": "SCARED", "mouth": "OPEN", "effect": "SWEAT_DROP"},
    "fear_high": {"eye": "SCARED", "mouth": "OPEN", "effect": "SWEAT_DROP"},
    "excitement_low": {"eye": "NORMAL", "mouth": "SMILE", "effect": "EXCLAMATION"},
    "excitement_mid": {"eye": "EXCITED", "mouth": "WIDE_SMILE", "effect": "SPARKLES"},
    "excitement_high": {"eye": "SPARKLE", "mouth": "WIDE_SMILE", "effect": "SPARKLES"},
    "sadness_low": {"eye": "NORMAL", "mouth": "FROWN", "effect": "NONE"},
    "sadness_mid": {"eye": "SAD", "mouth": "FROWN", "effect": "NONE"},
    "sadness_high": {"eye": "SAD", "mouth": "FROWN", "effect": "TEARS"},
    "love_low": {"eye": "NORMAL", "mouth": "TINY_SMILE", "effect": "BLUSH"},
    "love_mid": {"eye": "HAPPY", "mouth": "SMILE", "effect": "HEART"},
    "love_high": {"eye": "LOVE", "mouth": "SMILE", "effect": "HEART"},
}

EYE_DISPLAY = {
    "NORMAL": "●●", "HAPPY": "＾＾", "EXCITED": "★★", "SAD": "；；",
    "ANGRY": "＞＜", "SCARED": "◎◎", "SLEEPY": "ーー", "LOVE": "♥♥",
    "CURIOUS": "？●", "CLOSED": "××", "DOT": "・・", "SPARKLE": "✧✧",
}

MOUTH_DISPLAY = {
    "NEUTRAL": "ー", "SMILE": "⌒", "WIDE_SMILE": "Ｕ", "FROWN": "⌓",
    "OPEN": "○", "WAVY": "～", "CHOMP": "▽", "POUT": "ω",
    "WHISTLE": "◯", "TINY_SMILE": "`",
}


# === CLI定義 ===

@click.group()
@click.option("--json", "json_mode", is_flag=True, help="JSON output mode")
@click.pass_context
def cli(ctx, json_mode):
    """PetClaw Debug CLI — ゲームシステムの検査・デバッグツール"""
    ctx.ensure_object(dict)
    ctx.obj["json"] = json_mode


# --- Evolution Commands ---

@cli.group()
def evolution():
    """進化システムの検査"""
    pass


@evolution.command("tree")
@click.option("--stage", type=int, default=0, help="表示するステージ (0=全て)")
@click.pass_context
def evo_tree(ctx, stage):
    """進化ツリーの全パスを表示"""
    stages = parse_evolution_tree()

    if stage > 0:
        stages = {stage: stages.get(stage, [])}

    if ctx.obj["json"]:
        output({"evolution_tree": stages}, True)
        return

    for s, paths in sorted(stages.items()):
        click.echo(f"\n{'=' * 50}")
        click.echo(click.style(f"  Stage {s}", fg="magenta", bold=True))
        click.echo(f"{'=' * 50}")

        for p in paths:
            color = "red" if p["is_dark"] else ("yellow" if p["is_special"] else "green")
            tag = " 🌑DARK" if p["is_dark"] else (" ⭐SPECIAL" if p["is_special"] else "")
            click.echo(f"\n  {click.style(p['id'], fg=color, bold=True)}{tag}")
            click.echo(f"  名前: {p['display_name']}")
            if p["description"]:
                click.echo(f"  説明: {p['description']}")


@evolution.command("check")
@click.option("--pet-id", type=int, required=True, help="ペットID")
@click.option("--personality", type=str, default="brave:0.5,curious:0.6,calm:0.5,affectionate:0.5,playful:0.5",
              help="性格値 (key:value,...)")
@click.option("--care-misses", type=int, default=2, help="ケアミス回数")
@click.option("--age", type=float, default=10.0, help="年齢（ゲーム内時間）")
@click.option("--a2a-count", type=int, default=15, help="AtoA会話回数")
@click.option("--environment", type=str, default="forest", help="現在の環境")
@click.option("--stage", type=int, default=2, help="現在のステージ")
@click.pass_context
def evo_check(ctx, pet_id, personality, care_misses, age, a2a_count, environment, stage):
    """指定条件で進化可能なパスをシミュレート"""
    # 性格値パース
    pers = {}
    for pair in personality.split(","):
        k, v = pair.split(":")
        pers[k.strip()] = float(v.strip())

    # ケア品質判定
    if care_misses <= 1:
        care_quality = "excellent"
    elif care_misses <= 3:
        care_quality = "good"
    elif care_misses <= 5:
        care_quality = "average"
    else:
        care_quality = "poor"

    target_stage = stage + 1
    stages = parse_evolution_tree()
    paths = stages.get(target_stage, [])

    # 簡易条件マッチング
    reachable = []
    for path in paths:
        # ダーク進化はpoorケアが必要
        if path["is_dark"] and care_quality != "poor":
            continue
        # 通常進化はpoorケアでは不可
        if not path["is_dark"] and care_quality == "poor":
            continue

        reachable.append({
            "id": path["id"],
            "display_name": path["display_name"],
            "is_dark": path["is_dark"],
            "is_special": path["is_special"],
        })

    result = {
        "pet_id": pet_id,
        "current_stage": stage,
        "target_stage": target_stage,
        "age": age,
        "care_quality": care_quality,
        "care_misses": care_misses,
        "a2a_conversations": a2a_count,
        "environment": environment,
        "personality": pers,
        "reachable_forms": reachable,
        "reachable_count": len(reachable),
        "total_forms_at_stage": len(paths),
    }

    if ctx.obj["json"]:
        output(result, True)
    else:
        click.echo(f"\n{click.style('=== Evolution Check ===', fg='magenta', bold=True)}")
        click.echo(f"  Pet #{pet_id} | Stage {stage} → {target_stage}")
        click.echo(f"  Age: {age}h | Care: {care_quality} ({care_misses} misses)")
        click.echo(f"  A2A: {a2a_count} | Env: {environment}")
        click.echo(f"\n  {click.style('Reachable Forms:', fg='cyan', bold=True)} {len(reachable)}/{len(paths)}")
        for form in reachable:
            color = "red" if form["is_dark"] else "green"
            click.echo(f"    {'🌑' if form['is_dark'] else '✦'} {click.style(form['display_name'], fg=color)} ({form['id']})")

        if not reachable:
            click.echo(click.style("    → フォールバック: デフォルト進化", fg="yellow"))


@evolution.command("care")
@click.pass_context
def evo_care(ctx):
    """ケア品質の閾値テーブルを表示"""
    thresholds = parse_care_thresholds()
    if ctx.obj["json"]:
        output({"care_quality_thresholds": thresholds}, True)
    else:
        click.echo(f"\n{click.style('=== Care Quality Thresholds (たまごっち直系) ===', fg='cyan', bold=True)}")
        click.echo(f"  {'品質':<12} {'ミス回数':<12} {'備考'}")
        click.echo(f"  {'─' * 40}")
        click.echo(f"  {'excellent':<12} {'0-1回':<12} 最良ルート解放")
        click.echo(f"  {'good':<12} {'2-3回':<12} 通常進化可能")
        click.echo(f"  {'average':<12} {'4-5回':<12} 一部制限あり")
        click.echo(f"  {'poor':<12} {'6回以上':<12} ダークルート突入")


# --- Expression Commands ---

@cli.group()
def expression():
    """表情システムの検査"""
    pass


@expression.command("show")
@click.option("--emotion", type=click.Choice(["joy", "fear", "excitement", "sadness", "love"]),
              required=True, help="感情タイプ")
@click.option("--intensity", type=float, default=0.5, help="感情強度 (0.0-1.0)")
@click.pass_context
def expr_show(ctx, emotion, intensity):
    """指定感情・強度での表情を表示"""
    if intensity < 0.15:
        level = "neutral"
        expr = {"eye": "NORMAL", "mouth": "NEUTRAL", "effect": "NONE"}
    elif intensity < 0.4:
        level = "low"
        expr = EMOTION_EXPRESSION_MAP.get(f"{emotion}_low", {})
    elif intensity < 0.7:
        level = "mid"
        expr = EMOTION_EXPRESSION_MAP.get(f"{emotion}_mid", {})
    else:
        level = "high"
        expr = EMOTION_EXPRESSION_MAP.get(f"{emotion}_high", {})

    result = {
        "emotion": emotion,
        "intensity": intensity,
        "level": level,
        "eye_shape": expr.get("eye", "NORMAL"),
        "mouth_shape": expr.get("mouth", "NEUTRAL"),
        "effect": expr.get("effect", "NONE"),
    }

    if ctx.obj["json"]:
        output(result, True)
    else:
        eye_str = EYE_DISPLAY.get(result["eye_shape"], "??")
        mouth_str = MOUTH_DISPLAY.get(result["mouth_shape"], "?")
        click.echo(f"\n{click.style('=== Expression Preview ===', fg='cyan', bold=True)}")
        click.echo(f"  Emotion: {emotion} ({intensity:.1f}) → level: {level}")
        click.echo(f"  Eye: {result['eye_shape']} {eye_str}")
        click.echo(f"  Mouth: {result['mouth_shape']} {mouth_str}")
        click.echo(f"  Effect: {result['effect']}")
        click.echo(f"\n  {click.style('ASCII Face:', fg='yellow')}")
        click.echo(f"      {eye_str}")
        click.echo(f"       {mouth_str}")


@expression.command("all")
@click.pass_context
def expr_all(ctx):
    """全表情マッピングを表示"""
    if ctx.obj["json"]:
        output({"expression_map": EMOTION_EXPRESSION_MAP}, True)
    else:
        click.echo(f"\n{click.style('=== Full Expression Map (15 patterns) ===', fg='cyan', bold=True)}")
        click.echo(f"  {'感情_強度':<20} {'目':<10} {'口':<14} {'エフェクト':<14} {'顔'}")
        click.echo(f"  {'─' * 70}")
        for key, expr in sorted(EMOTION_EXPRESSION_MAP.items()):
            eye_str = EYE_DISPLAY.get(expr["eye"], "??")
            mouth_str = MOUTH_DISPLAY.get(expr["mouth"], "?")
            click.echo(
                f"  {key:<20} {expr['eye']:<10} {expr['mouth']:<14} {expr['effect']:<14} {eye_str}{mouth_str}"
            )


# --- Ethics Commands ---

@cli.group()
def ethics():
    """倫理セーフガードの検査"""
    pass


@ethics.command("report")
@click.option("--session-hours", type=float, default=1.5, help="セッション時間（時間）")
@click.option("--interactions", type=int, default=25, help="インタラクション回数")
@click.option("--a2a-today", type=int, default=10, help="本日のAtoA会話回数")
@click.option("--consecutive-days", type=int, default=5, help="連続日数")
@click.pass_context
def ethics_report(ctx, session_hours, interactions, a2a_today, consecutive_days):
    """倫理セーフガードの状態レポート"""
    # 依存スコア簡易計算（ethical_safeguard.gd と同期）
    time_factor = min(1.0, session_hours / 8.0) * 0.25
    interaction_factor = min(1.0, interactions / 100.0) * 0.25
    streak_factor = min(1.0, consecutive_days / 14.0) * 0.20
    a2a_ratio = a2a_today / 50.0
    a2a_factor = min(1.0, a2a_ratio) * 0.30
    dep_score = time_factor + interaction_factor + streak_factor + a2a_factor

    if dep_score < 0.3:
        level = "healthy"
        color = "green"
    elif dep_score < 0.6:
        level = "moderate"
        color = "yellow"
    elif dep_score < 0.8:
        level = "warning"
        color = "red"
    else:
        level = "critical"
        color = "red"

    result = {
        "dependency_score": round(dep_score, 3),
        "level": level,
        "factors": {
            "time": round(time_factor, 3),
            "interaction": round(interaction_factor, 3),
            "streak": round(streak_factor, 3),
            "a2a": round(a2a_factor, 3),
        },
        "session_hours": session_hours,
        "interactions_today": interactions,
        "a2a_today": a2a_today,
        "a2a_limit": 50,
        "consecutive_days": consecutive_days,
        "session_limit_hours": 4.0,
        "break_suggested": session_hours >= 4.0,
        "a2a_limit_reached": a2a_today >= 50,
    }

    if ctx.obj["json"]:
        output(result, True)
    else:
        click.echo(f"\n{click.style('=== Ethical Safeguard Report ===', fg='cyan', bold=True)}")
        click.echo(f"  Dependency Score: {click.style(f'{dep_score:.3f}', fg=color, bold=True)} [{level}]")
        click.echo(f"\n  Factors:")
        click.echo(f"    Time:        {time_factor:.3f} (session: {session_hours:.1f}h / 8h)")
        click.echo(f"    Interaction: {interaction_factor:.3f} ({interactions} / 100)")
        click.echo(f"    Streak:      {streak_factor:.3f} ({consecutive_days} days / 14)")
        click.echo(f"    A2A:         {a2a_factor:.3f} ({a2a_today} / 50)")
        click.echo(f"\n  Status:")
        if result["break_suggested"]:
            click.echo(click.style("    ⚠ Break suggested (session > 4h)", fg="yellow"))
        if result["a2a_limit_reached"]:
            click.echo(click.style("    ⚠ A2A daily limit reached", fg="yellow"))
        if level == "healthy":
            click.echo(click.style("    ✓ All systems healthy", fg="green"))


# --- A2A Commands ---

@cli.group()
def a2a():
    """AtoA会話システムの検査"""
    pass


@a2a.command("simulate")
@click.option("--pet1", type=int, required=True, help="ペット1のID")
@click.option("--pet2", type=int, required=True, help="ペット2のID")
@click.option("--trigger", type=str, default="proximity", help="会話トリガー")
@click.option("--environment", type=str, default="forest", help="環境")
@click.option("--turns", type=int, default=3, help="ターン数")
@click.pass_context
def a2a_simulate(ctx, pet1, pet2, trigger, environment, turns):
    """AtoA会話のドライランシミュレーション"""
    # サンプル出力を生成
    sample_utterances = {
        "forest": [
            "ki-ga yure-teru... kaze-da ne",
            "sou-da! mori-no oto-ga suki-da",
            "ashita-mo issho-ni explore-suru?",
        ],
        "sea": [
            "nami-no oto... ochitsuku-ne",
            "sakana-mita! kirei-datta",
            "shio-kaze ga tsuyoi-kedo tanoshii",
        ],
        "ruins": [
            "koko... fushigi-na basho-da",
            "mukashi-no mono-ga takusan aru",
            "chotto kowai-kedo... curious-da!",
        ],
        "city": [
            "hito-ga ooi-ne! nigiyaka!",
            "ano mise... oishii nioi-ga suru",
            "machi-no akari-ga kirei-da",
        ],
    }

    utterances = sample_utterances.get(environment, sample_utterances["forest"])[:turns]

    conversation = []
    for i, utt in enumerate(utterances):
        speaker = pet1 if i % 2 == 0 else pet2
        conversation.append({
            "turn": i + 1,
            "speaker_id": speaker,
            "utterance": utt,
            "emotion": "joy" if i % 2 == 0 else "curiosity",
            "intensity": 0.4 + i * 0.1,
        })

    result = {
        "simulation": True,
        "pet1_id": pet1,
        "pet2_id": pet2,
        "trigger": trigger,
        "environment": environment,
        "turns": len(conversation),
        "conversation": conversation,
        "estimated_api_cost": f"~${0.003 * turns:.4f}",
        "relationship_boost": round(0.02 + 0.03 * 0.5, 3),
    }

    if ctx.obj["json"]:
        output(result, True)
    else:
        click.echo(f"\n{click.style('=== A2A Conversation Simulation ===', fg='cyan', bold=True)}")
        click.echo(f"  Pet #{pet1} ↔ Pet #{pet2} | Trigger: {trigger} | Env: {environment}")
        click.echo(f"  Estimated API cost: {result['estimated_api_cost']}")
        click.echo(f"  Relationship boost: +{result['relationship_boost']}")
        click.echo(f"\n  {'─' * 45}")
        for turn in conversation:
            speaker_id = turn["speaker_id"]
            emo = turn["emotion"]
            emo_int = turn["intensity"]
            name_color = "green" if speaker_id == pet1 else "blue"
            click.echo(
                f"  {click.style(f'Pet#{speaker_id}', fg=name_color)}: "
                f"{turn['utterance']}"
                f"  {click.style(f'({emo} {emo_int:.1f})', fg='bright_black')}"
            )
        click.echo(f"  {'─' * 45}")


# --- Field Commands ---

@cli.group()
def field():
    """PersistentFieldの検査"""
    pass


@field.command("status")
@click.pass_context
def field_status(ctx):
    """PersistentFieldのステータスサマリ"""
    # セーブファイルが存在すればパース、なければサンプル
    save_path = GODOT_DIR / "user" / "persistent_field.json"

    if save_path.exists():
        with open(save_path) as f:
            data = json.load(f)
    else:
        data = {
            "field_mood": {"dominant": "calm", "intensity": 0.5, "secondary": "joy"},
            "relationship_graph": {
                "1_2": {"score": 0.72, "history": ["a2a_conversation", "shared_adventure"]},
                "1_3": {"score": 0.45, "history": ["a2a_conversation"]},
                "2_3": {"score": 0.61, "history": ["a2a_conversation", "battle_together"]},
            },
            "shared_events": 42,
            "community_topics": ["forest exploration", "language discovery", "night sky"],
            "last_save": "2026-04-01T12:00:00",
            "_note": "Sample data (no save file found)",
        }

    result = {
        "field_mood": data.get("field_mood", {}),
        "relationships": len(data.get("relationship_graph", {})),
        "relationship_details": data.get("relationship_graph", {}),
        "shared_events": data.get("shared_events", 0),
        "community_topics": data.get("community_topics", []),
        "source": "save_file" if save_path.exists() else "sample_data",
    }

    if ctx.obj["json"]:
        output(result, True)
    else:
        mood = data.get("field_mood", {})
        click.echo(f"\n{click.style('=== PersistentField Status ===', fg='cyan', bold=True)}")
        click.echo(f"  Source: {'Save file' if save_path.exists() else 'Sample data (no save found)'}")
        click.echo(f"\n  Community Mood: {mood.get('dominant', '?')} (intensity: {mood.get('intensity', 0):.1f})")
        click.echo(f"  Shared Events: {data.get('shared_events', 0)}")
        click.echo(f"  Topics: {', '.join(data.get('community_topics', []))}")
        click.echo(f"\n  Relationships ({len(data.get('relationship_graph', {}))}):")
        for key, rel in data.get("relationship_graph", {}).items():
            score = rel.get("score", 0)
            bar = "█" * int(score * 10) + "░" * (10 - int(score * 10))
            color = "green" if score >= 0.7 else ("yellow" if score >= 0.4 else "red")
            click.echo(f"    {key}: [{click.style(bar, fg=color)}] {score:.2f}")


# --- Stats Commands ---

@cli.command("stats")
@click.pass_context
def project_stats(ctx):
    """プロジェクト全体の統計"""
    gd_files = list(SCRIPTS_DIR.rglob("*.gd"))
    kb_files = list(KB_DIR.rglob("*.md"))
    sprite_dirs = list((GODOT_DIR / "assets" / "sprites").rglob("*_meta.json")) if (GODOT_DIR / "assets" / "sprites").exists() else []

    total_lines = 0
    for f in gd_files:
        total_lines += len(f.read_text(encoding="utf-8").split("\n"))

    result = {
        "gdscript_files": len(gd_files),
        "gdscript_total_lines": total_lines,
        "knowledge_base_docs": len(kb_files),
        "sprite_forms_generated": len(sprite_dirs),
        "systems": [f.parent.name for f in gd_files],
        "directories": sorted(set(str(f.parent.relative_to(SCRIPTS_DIR)) for f in gd_files)),
    }

    if ctx.obj["json"]:
        output(result, True)
    else:
        click.echo(f"\n{click.style('=== PetClaw Project Stats ===', fg='cyan', bold=True)}")
        click.echo(f"  GDScript files: {len(gd_files)}")
        click.echo(f"  Total lines: {total_lines:,}")
        click.echo(f"  Knowledge base docs: {len(kb_files)}")
        click.echo(f"  Sprite forms generated: {len(sprite_dirs)}")
        click.echo(f"\n  System directories:")
        for d in result["directories"]:
            click.echo(f"    📁 {d}")


if __name__ == "__main__":
    cli()
