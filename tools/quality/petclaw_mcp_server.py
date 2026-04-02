#!/usr/bin/env python3
"""PetClaw MCP Server — 品質ツール群をMCPプロトコルで公開
teams-ai-agent のDynamic MCP Tool Discoveryパターンを応用。
外部AIエージェントがPetClawの品質チェックを呼び出せるようにする。

Usage:
    python3 petclaw_mcp_server.py [--port 8765]
    
MCP Tools exposed:
    - petclaw.agent_lint: エージェント定義の品質検証
    - petclaw.deslop: GDScriptスロップ検出
    - petclaw.drift: 設計文書ドリフト検出
    - petclaw.stats: プロジェクト統計
    - petclaw.get_pet_state: ペット個体の状態取得（Agent Teams連携）
    - petclaw.get_battle_stats: バトル統計取得
    - petclaw.get_language_metrics: 言語進化メトリクス取得
    - petclaw.karpathy_metrics: Karpathy Loop最適化メトリクス取得
"""

import json
import subprocess
import sys
import os
from pathlib import Path

# Simple JSON-RPC style MCP server (stdio transport)
# Compatible with MCP protocol for tool discovery and execution

TOOLS = [
    {
        "name": "petclaw.agent_lint",
        "description": "Validate PetClaw Agent Teams configuration files (agents, commands, CLAUDE.md)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_root": {"type": "string", "description": "Project root path", "default": "."}
            }
        }
    },
    {
        "name": "petclaw.deslop",
        "description": "Detect AI-generated GDScript quality degradation patterns (3-phase analysis)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_root": {"type": "string", "description": "Project root path", "default": "."}
            }
        }
    },
    {
        "name": "petclaw.drift",
        "description": "Check drift between design documents and GDScript implementation",
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_root": {"type": "string", "description": "Project root path", "default": "."}
            }
        }
    },
    {
        "name": "petclaw.stats",
        "description": "Get PetClaw project statistics (files, lines, systems, forms)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_root": {"type": "string", "description": "Project root path", "default": "."}
            }
        }
    },
    {
        "name": "petclaw.get_pet_state",
        "description": "Returns current state of a specific pet (stats, emotions, personality, evolution, relationships, vocabulary, battle record)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "pet_id": {"type": "integer", "description": "Pet ID to query"},
                "project_root": {"type": "string", "description": "Project root path", "default": "."}
            },
            "required": ["pet_id"]
        }
    },
    {
        "name": "petclaw.get_battle_stats",
        "description": "Returns battle statistics for a specific pet or all pets (total battles, wins, losses, best score, avg score)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "pet_id": {"type": "integer", "description": "Pet ID (optional, omit for all pets)"},
                "project_root": {"type": "string", "description": "Project root path", "default": "."}
            }
        }
    },
    {
        "name": "petclaw.get_language_metrics",
        "description": "Returns language evolution metrics (vocabulary size, stage, suffixes, word order, Hebbian strength, words per category)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_root": {"type": "string", "description": "Project root path", "default": "."}
            }
        }
    },
    {
        "name": "petclaw.karpathy_metrics",
        "description": "Returns Karpathy Loop optimization metrics (conversation quality, template/API ratio, cost, language diversity, battle distribution, emotional range)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_root": {"type": "string", "description": "Project root path", "default": "."}
            }
        }
    },
]


def find_project_root():
    """Auto-discover project root by looking for CLAUDE.md"""
    current = Path(__file__).resolve().parent
    for _ in range(5):
        if (current / "CLAUDE.md").exists():
            return str(current)
        current = current.parent
    return "."


def _load_save_data(project_root):
    """Load save data from petclaw_save.json (Godot user:// or project root)"""
    candidates = [
        Path(project_root) / "petclaw_save.json",
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


def get_pet_state(project_root, pet_id):
    """Get current state of a specific pet from save data"""
    save_data, source = _load_save_data(project_root)
    if save_data is None:
        return {"error": "No save data found", "hint": "Game must be saved at least once"}

    pets = save_data.get("pets", {})
    pet_key = str(pet_id)
    if pet_key not in pets:
        available = list(pets.keys())
        return {"error": f"Pet {pet_id} not found", "available_pet_ids": available}

    pet = pets[pet_key]
    stats = pet.get("stats", {})
    emotions_raw = pet.get("emotions", {})
    personality = pet.get("personality", {})

    # Top 3 emotions by intensity
    if isinstance(emotions_raw, dict):
        sorted_emotions = sorted(emotions_raw.items(), key=lambda x: x[1], reverse=True)[:3]
        top_emotions = [{"emotion": e, "intensity": round(v, 3)} for e, v in sorted_emotions]
    else:
        top_emotions = []

    # Relationship count from a2a conversation system
    a2a_data = save_data.get("a2a_conversation", {})
    relationships = a2a_data.get("pet_relationships", {})
    rel_count = len(relationships.get(pet_key, {})) if pet_key in relationships else 0

    # Vocabulary size from original language engine
    lang_data = save_data.get("original_language", {})
    vocab = lang_data.get("vocabulary", {})
    vocab_size = len(vocab)

    # Battle record
    battle_data = save_data.get("battle", save_data.get("language_battle", {}))
    battle_history = battle_data.get("battle_history", {})
    battle_record = battle_history.get(pet_key, {
        "total_battles": 0, "wins": 0, "losses": 0, "best_score": 0.0
    })

    # Evolution stage
    evo_data = save_data.get("evolution_mechanics", {})
    pet_forms = evo_data.get("pet_forms", {})
    evo_stage = pet.get("evolution_stage", pet_forms.get(pet_key, 0))

    return {
        "pet_id": pet_id,
        "pet_name": pet.get("pet_name", "Unknown"),
        "is_alive": pet.get("is_alive", True),
        "age": pet.get("age", 0.0),
        "stats": {
            "hunger": round(stats.get("hunger", 1.0), 3),
            "health": round(stats.get("health", 1.0), 3),
            "energy": round(stats.get("energy", 1.0), 3),
            "affection": round(stats.get("affection", 0.0), 3),
            "mood": round(stats.get("mood", 0.5), 3),
            "disease_resistance": round(stats.get("disease_resistance", 0.5), 3),
            "evolution_readiness": round(stats.get("evolution_readiness", 0.0), 3),
        },
        "top_emotions": top_emotions,
        "personality_traits": personality,
        "evolution_stage": evo_stage,
        "relationship_count": rel_count,
        "vocabulary_size": vocab_size,
        "battle_record": battle_record,
        "source": source,
    }


def get_battle_stats(project_root, pet_id=None):
    """Get battle statistics for one or all pets"""
    save_data, source = _load_save_data(project_root)
    if save_data is None:
        return {"error": "No save data found", "hint": "Game must be saved at least once"}

    battle_data = save_data.get("battle", save_data.get("language_battle", {}))
    battle_history = battle_data.get("battle_history", {})

    if pet_id is not None:
        pet_key = str(pet_id)
        entry = battle_history.get(pet_key, {
            "total_battles": 0, "wins": 0, "losses": 0, "best_score": 0.0
        })
        win_rate = (entry["wins"] / entry["total_battles"] * 100) if entry["total_battles"] > 0 else 0
        return {
            "pet_id": pet_id,
            "total_battles": entry["total_battles"],
            "wins": entry["wins"],
            "losses": entry["losses"],
            "best_score": entry["best_score"],
            "win_rate_pct": round(win_rate, 1),
            "source": source,
        }

    # Aggregate across all pets
    total_battles = 0
    total_wins = 0
    total_losses = 0
    global_best = 0.0
    per_pet = {}

    for pid, entry in battle_history.items():
        tb = entry.get("total_battles", 0)
        w = entry.get("wins", 0)
        lo = entry.get("losses", 0)
        bs = entry.get("best_score", 0.0)
        total_battles += tb
        total_wins += w
        total_losses += lo
        global_best = max(global_best, bs)
        per_pet[pid] = {
            "total_battles": tb, "wins": w, "losses": lo,
            "best_score": bs,
            "win_rate_pct": round(w / tb * 100, 1) if tb > 0 else 0,
        }

    # Most active battler
    favorite = max(per_pet, key=lambda k: per_pet[k]["total_battles"]) if per_pet else None

    return {
        "total_battles": total_battles,
        "total_wins": total_wins,
        "total_losses": total_losses,
        "global_best_score": global_best,
        "most_active_battler": favorite,
        "pet_count": len(per_pet),
        "per_pet": per_pet,
        "source": source,
    }


def get_language_metrics(project_root):
    """Get language evolution metrics from save data and GDScript analysis"""
    save_data, source = _load_save_data(project_root)

    result = {"source": source}

    if save_data:
        # Original language engine data
        lang = save_data.get("original_language", {})
        vocab = lang.get("vocabulary", {})
        result["vocabulary_size"] = len(vocab)
        result["language_stage"] = lang.get("current_stage", 0)
        result["total_words_invented"] = lang.get("total_words_invented", 0)

        # Word categories breakdown
        categories = {}
        for word, data in vocab.items():
            cat = data.get("category", "unknown") if isinstance(data, dict) else "unknown"
            categories[cat] = categories.get(cat, 0) + 1
        result["words_per_category"] = categories

        # Most used words (by usage count if available)
        word_usage = []
        for word, data in vocab.items():
            if isinstance(data, dict):
                usage = data.get("usage_count", data.get("frequency", 0))
                word_usage.append((word, usage))
        word_usage.sort(key=lambda x: x[1], reverse=True)
        result["most_used_words"] = [{"word": w, "usage": u} for w, u in word_usage[:10]]

        # Language evolution system data
        evo = save_data.get("language", {})
        result["suffix_count"] = len(evo.get("suffixes", []))
        result["current_word_order"] = evo.get("current_word_order", 0)
        result["total_evolutions"] = evo.get("total_evolutions", 0)
        result["suffix_usage_counts"] = evo.get("suffix_usage_counts", {})

        # Hebbian strength distribution (from biological memory)
        bio_mem = save_data.get("biological_memory", {})
        pets_mem = bio_mem.get("pets", {})
        hebbian_dist = {"strong": 0, "medium": 0, "weak": 0}
        for pid, pmem in pets_mem.items():
            cortex = pmem.get("cortex", [])
            for mem in cortex:
                strength = mem.get("hebbian_strength", mem.get("strength", 0.5))
                if strength >= 0.7:
                    hebbian_dist["strong"] += 1
                elif strength >= 0.3:
                    hebbian_dist["medium"] += 1
                else:
                    hebbian_dist["weak"] += 1
        result["hebbian_strength_distribution"] = hebbian_dist
    else:
        result["warning"] = "No save data found — showing GDScript-derived metrics only"

        # Fallback: analyze GDScript files
        root = Path(project_root)
        lang_files = list((root / "godot_project" / "scripts" / "language").rglob("*.gd"))
        result["language_scripts"] = len(lang_files)
        total_lines = 0
        for f in lang_files:
            try:
                total_lines += len(f.read_text(encoding="utf-8").splitlines())
            except OSError:
                pass
        result["language_code_lines"] = total_lines

    return result


def get_karpathy_metrics(project_root):
    """Get Karpathy Loop optimization metrics"""
    save_data, source = _load_save_data(project_root)
    root = Path(project_root)

    result = {"source": source}

    if save_data:
        # Conversation quality trends
        a2a = save_data.get("a2a_conversation", {})
        conv_log = a2a.get("conversation_log", [])
        result["total_conversations"] = len(conv_log)
        result["daily_cost"] = a2a.get("daily_cost", 0.0)
        result["daily_count"] = a2a.get("daily_count", 0)

        # Template vs API ratio
        template_count = sum(1 for c in conv_log if c.get("source", "") == "template")
        api_count = sum(1 for c in conv_log if c.get("source", "") == "api")
        total = template_count + api_count
        if total > 0:
            result["template_ratio_pct"] = round(template_count / total * 100, 1)
            result["api_ratio_pct"] = round(api_count / total * 100, 1)
        else:
            result["template_ratio_pct"] = 0
            result["api_ratio_pct"] = 0
        result["target_template_ratio_pct"] = 80  # P2: 80% template / 20% API

        # Cost per conversation
        if len(conv_log) > 0:
            total_cost = sum(c.get("cost", 0.0) for c in conv_log)
            result["cost_per_conversation"] = round(total_cost / len(conv_log), 4)
        else:
            result["cost_per_conversation"] = 0.0

        # Language diversity index (unique words / total words invented)
        lang = save_data.get("original_language", {})
        vocab_size = len(lang.get("vocabulary", {}))
        total_invented = lang.get("total_words_invented", 0)
        result["language_diversity_index"] = round(vocab_size / max(total_invented, 1), 3)
        result["vocabulary_size"] = vocab_size

        # Battle win distribution
        battle_data = save_data.get("battle", save_data.get("language_battle", {}))
        bh = battle_data.get("battle_history", {})
        total_battles = sum(e.get("total_battles", 0) for e in bh.values())
        total_wins = sum(e.get("wins", 0) for e in bh.values())
        result["battle_total"] = total_battles
        result["battle_win_rate_pct"] = round(total_wins / max(total_battles, 1) * 100, 1)

        # Emotional range score (how many distinct emotions appear across pets)
        pets = save_data.get("pets", {})
        all_emotions = set()
        for pet in pets.values():
            emotions = pet.get("emotions", {})
            if isinstance(emotions, dict):
                for emo, intensity in emotions.items():
                    if intensity > 0.1:
                        all_emotions.add(emo)
        result["emotional_range_score"] = len(all_emotions)
        result["active_emotions"] = sorted(all_emotions)
    else:
        result["warning"] = "No save data found — showing code-level metrics"

    # Code-level metrics (always available)
    scripts_dir = root / "godot_project" / "scripts"
    if scripts_dir.exists():
        gd_files = list(scripts_dir.rglob("*.gd"))
        total_lines = 0
        func_count = 0
        signal_count = 0
        for f in gd_files:
            try:
                content = f.read_text(encoding="utf-8")
                lines = content.splitlines()
                total_lines += len(lines)
                for line in lines:
                    stripped = line.strip()
                    if stripped.startswith("func "):
                        func_count += 1
                    elif stripped.startswith("signal "):
                        signal_count += 1
            except OSError:
                pass
        result["codebase_lines"] = total_lines
        result["codebase_functions"] = func_count
        result["codebase_signals"] = signal_count

    return result


def run_tool(name, args):
    """Execute a PetClaw quality tool and return results"""
    project_root = args.get("project_root", find_project_root())
    tool_dir = Path(__file__).resolve().parent
    
    tool_map = {
        "petclaw.agent_lint": "petclaw_agent_lint.py",
        "petclaw.deslop": "petclaw_deslop.py",
        "petclaw.drift": "petclaw_drift.py",
    }
    
    if name == "petclaw.stats":
        return get_project_stats(project_root)

    if name == "petclaw.get_pet_state":
        pet_id = args.get("pet_id")
        if pet_id is None:
            return {"error": "pet_id is required"}
        return get_pet_state(project_root, int(pet_id))

    if name == "petclaw.get_battle_stats":
        pet_id = args.get("pet_id")
        return get_battle_stats(project_root, int(pet_id) if pet_id is not None else None)

    if name == "petclaw.get_language_metrics":
        return get_language_metrics(project_root)

    if name == "petclaw.karpathy_metrics":
        return get_karpathy_metrics(project_root)

    if name not in tool_map:
        return {"error": f"Unknown tool: {name}"}
    
    script = tool_dir / tool_map[name]
    if not script.exists():
        return {"error": f"Tool script not found: {script}"}
    
    try:
        result = subprocess.run(
            [sys.executable, str(script), "--project-root", project_root, "--json"],
            capture_output=True, text=True, timeout=60
        )
        try:
            return json.loads(result.stdout)
        except json.JSONDecodeError:
            return {"stdout": result.stdout, "stderr": result.stderr, "exit_code": result.returncode}
    except subprocess.TimeoutExpired:
        return {"error": "Tool execution timed out (60s)"}
    except Exception as e:
        return {"error": str(e)}


def get_project_stats(project_root):
    """Gather project statistics"""
    root = Path(project_root)
    scripts_dir = root / "godot_project" / "scripts"
    kb_dir = root / "knowledge_base"
    
    gd_files = list(scripts_dir.rglob("*.gd")) if scripts_dir.exists() else []
    total_lines = 0
    for f in gd_files:
        try:
            total_lines += len(f.read_text(encoding="utf-8").splitlines())
        except:
            pass
    
    kb_files = list(kb_dir.glob("*.md")) if kb_dir.exists() else []
    
    agents_dir = root / ".claude" / "agents"
    commands_dir = root / ".claude" / "commands"
    agents = [f.stem for f in agents_dir.glob("*.md")] if agents_dir.exists() else []
    commands = [f.stem for f in commands_dir.glob("*.md")] if commands_dir.exists() else []
    
    return {
        "gdscript_files": len(gd_files),
        "gdscript_lines": total_lines,
        "knowledge_base_docs": len(kb_files),
        "agents": agents,
        "commands": commands,
        "agent_count": len(agents),
        "command_count": len(commands),
    }


def handle_request(request):
    """Handle a JSON-RPC MCP request"""
    method = request.get("method", "")
    req_id = request.get("id")
    params = request.get("params", {})
    
    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "petclaw-quality", "version": "1.0.0"}
            }
        }
    
    elif method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {"tools": TOOLS}
        }
    
    elif method == "tools/call":
        tool_name = params.get("name", "")
        tool_args = params.get("arguments", {})
        result = run_tool(tool_name, tool_args)
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "content": [{"type": "text", "text": json.dumps(result, ensure_ascii=False, indent=2)}]
            }
        }
    
    elif method == "notifications/initialized":
        return None  # No response for notifications
    
    else:
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "error": {"code": -32601, "message": f"Method not found: {method}"}
        }


def main():
    """Run MCP server on stdio transport"""
    import sys
    
    sys.stderr.write("PetClaw MCP Server started (stdio transport)\n")
    
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        
        try:
            request = json.loads(line)
            response = handle_request(request)
            if response is not None:
                sys.stdout.write(json.dumps(response) + "\n")
                sys.stdout.flush()
        except json.JSONDecodeError:
            error_response = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {"code": -32700, "message": "Parse error"}
            }
            sys.stdout.write(json.dumps(error_response) + "\n")
            sys.stdout.flush()


if __name__ == "__main__":
    main()
