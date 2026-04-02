#!/usr/bin/env python3
"""PetClaw Metrics Collector — GDScriptコードベース＆セーブデータからメトリクスを収集

Usage:
    python3 collect_metrics.py [--project-root PATH] [--json]

Scans:
    - godot_project/scripts/ for code metrics (lines, functions, signals, classes)
    - Save data (petclaw_save.json) for game metrics
"""

import argparse
import json
import re
import sys
from pathlib import Path


def find_project_root():
    """Auto-discover project root by looking for CLAUDE.md"""
    current = Path(__file__).resolve().parent
    for _ in range(5):
        if (current / "CLAUDE.md").exists():
            return current
        current = current.parent
    return Path(".")


def load_save_data(project_root: Path):
    """Load save data from available locations"""
    candidates = [
        project_root / "petclaw_save.json",
        Path.home() / ".local" / "share" / "godot" / "app_userdata" / "PetClaw" / "petclaw_save.json",
        Path.home() / "Library" / "Application Support" / "Godot" / "app_userdata" / "PetClaw" / "petclaw_save.json",
    ]
    for p in candidates:
        if p.exists():
            try:
                return json.loads(p.read_text(encoding="utf-8")), str(p)
            except (json.JSONDecodeError, OSError):
                continue
    return None, None


def collect_code_metrics(project_root: Path):
    """Scan GDScript files for code metrics"""
    scripts_dir = project_root / "godot_project" / "scripts"
    if not scripts_dir.exists():
        return {"error": f"Scripts directory not found: {scripts_dir}"}

    gd_files = list(scripts_dir.rglob("*.gd"))
    total_lines = 0
    blank_lines = 0
    comment_lines = 0
    func_count = 0
    signal_count = 0
    class_count = 0
    class_name_count = 0
    enum_count = 0
    const_count = 0
    to_dict_count = 0
    from_dict_count = 0
    subsystems = {}

    for f in gd_files:
        try:
            content = f.read_text(encoding="utf-8")
            lines = content.splitlines()
            total_lines += len(lines)

            # Track per-subsystem
            rel_path = f.relative_to(scripts_dir)
            subsystem = rel_path.parts[0] if len(rel_path.parts) > 1 else "root"
            if subsystem not in subsystems:
                subsystems[subsystem] = {"files": 0, "lines": 0, "functions": 0}
            subsystems[subsystem]["files"] += 1
            subsystems[subsystem]["lines"] += len(lines)

            for line in lines:
                stripped = line.strip()
                if not stripped:
                    blank_lines += 1
                elif stripped.startswith("#"):
                    comment_lines += 1
                if stripped.startswith("func "):
                    func_count += 1
                    subsystems[subsystem]["functions"] += 1
                    if "to_dict" in stripped:
                        to_dict_count += 1
                    elif "from_dict" in stripped:
                        from_dict_count += 1
                elif stripped.startswith("signal "):
                    signal_count += 1
                elif stripped.startswith("class ") and not stripped.startswith("class_name"):
                    class_count += 1
                elif stripped.startswith("class_name "):
                    class_name_count += 1
                elif stripped.startswith("enum "):
                    enum_count += 1
                elif stripped.startswith("const "):
                    const_count += 1
        except OSError:
            pass

    return {
        "gdscript_files": len(gd_files),
        "total_lines": total_lines,
        "code_lines": total_lines - blank_lines - comment_lines,
        "blank_lines": blank_lines,
        "comment_lines": comment_lines,
        "function_count": func_count,
        "signal_count": signal_count,
        "class_count": class_count,
        "class_name_count": class_name_count,
        "enum_count": enum_count,
        "const_count": const_count,
        "serializable_systems": to_dict_count,  # systems with to_dict/from_dict
        "subsystems": subsystems,
    }


def collect_game_metrics(project_root: Path):
    """Extract game metrics from save data"""
    save_data, source = load_save_data(project_root)
    if save_data is None:
        return {"available": False, "reason": "No save data found"}

    pets = save_data.get("pets", {})
    alive_pets = sum(1 for p in pets.values() if p.get("is_alive", True))

    # Language metrics
    lang = save_data.get("original_language", {})
    vocab = lang.get("vocabulary", {})

    # Battle metrics
    battle_data = save_data.get("battle", save_data.get("language_battle", {}))
    bh = battle_data.get("battle_history", {})
    total_battles = sum(e.get("total_battles", 0) for e in bh.values())

    # Conversation metrics
    a2a = save_data.get("a2a_conversation", {})
    conv_log = a2a.get("conversation_log", [])

    # Evolution metrics
    evo = save_data.get("evolution_mechanics", {})
    pet_forms = evo.get("pet_forms", {})
    unique_forms = set(str(v) for v in pet_forms.values())

    return {
        "available": True,
        "source": source,
        "total_pets": len(pets),
        "alive_pets": alive_pets,
        "game_time": save_data.get("game_time", 0),
        "vocabulary_size": len(vocab),
        "total_words_invented": lang.get("total_words_invented", 0),
        "language_stage": lang.get("current_stage", 0),
        "total_battles": total_battles,
        "total_conversations": len(conv_log),
        "daily_cost": a2a.get("daily_cost", 0.0),
        "unique_evolution_forms": len(unique_forms),
        "evolution_forms_seen": sorted(unique_forms),
    }


def main():
    parser = argparse.ArgumentParser(description="PetClaw Metrics Collector")
    parser.add_argument("--project-root", default=None, help="Project root path")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    project_root = Path(args.project_root) if args.project_root else find_project_root()

    code_metrics = collect_code_metrics(project_root)
    game_metrics = collect_game_metrics(project_root)

    result = {
        "project_root": str(project_root),
        "code": code_metrics,
        "game": game_metrics,
    }

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print("=" * 60)
        print("  PetClaw Metrics Report")
        print("=" * 60)
        print()
        print("--- Code Metrics ---")
        if "error" not in code_metrics:
            print(f"  GDScript files:    {code_metrics['gdscript_files']}")
            print(f"  Total lines:       {code_metrics['total_lines']}")
            print(f"  Code lines:        {code_metrics['code_lines']}")
            print(f"  Comment lines:     {code_metrics['comment_lines']}")
            print(f"  Functions:         {code_metrics['function_count']}")
            print(f"  Signals:           {code_metrics['signal_count']}")
            print(f"  Classes:           {code_metrics['class_name_count']}")
            print(f"  Enums:             {code_metrics['enum_count']}")
            print(f"  Constants:         {code_metrics['const_count']}")
            print(f"  Serializable:      {code_metrics['serializable_systems']} systems")
            print()
            print("  Subsystems:")
            for sub, data in sorted(code_metrics["subsystems"].items()):
                print(f"    {sub:20s}  {data['files']:3d} files  {data['lines']:5d} lines  {data['functions']:3d} funcs")
        else:
            print(f"  Error: {code_metrics['error']}")

        print()
        print("--- Game Metrics ---")
        if game_metrics["available"]:
            print(f"  Save data:         {game_metrics['source']}")
            print(f"  Total pets:        {game_metrics['total_pets']}")
            print(f"  Alive pets:        {game_metrics['alive_pets']}")
            print(f"  Game time:         {game_metrics['game_time']:.1f}")
            print(f"  Vocabulary:        {game_metrics['vocabulary_size']} words")
            print(f"  Language stage:    {game_metrics['language_stage']}")
            print(f"  Battles:           {game_metrics['total_battles']}")
            print(f"  Conversations:     {game_metrics['total_conversations']}")
            print(f"  Daily API cost:    ${game_metrics['daily_cost']:.4f}")
            print(f"  Evolution forms:   {game_metrics['unique_evolution_forms']} unique")
        else:
            print(f"  {game_metrics['reason']}")
        print()


if __name__ == "__main__":
    main()
