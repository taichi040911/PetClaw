#!/usr/bin/env python3
"""
Karpathy Loop Optimization Framework for PetClaw
=================================================
Continuously measures, evaluates, and suggests improvements for PetClaw's
AtoA system, language evolution, battle balance, and code quality.

Train -> Evaluate -> Analyze -> Improve -> Repeat

Usage:
    python3 karpathy_loop.py              # Run one iteration
    python3 karpathy_loop.py --history    # Show improvement history
    python3 karpathy_loop.py --compare N  # Compare iteration N with current
    python3 karpathy_loop.py --json       # Output as JSON
"""

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Optional


# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

def discover_project_root(script_path: str) -> Path:
    """Walk up from this script until we find CLAUDE.md."""
    current = Path(script_path).resolve().parent
    while current != current.parent:
        if (current / "CLAUDE.md").exists():
            return current
        current = current.parent
    return Path.cwd()


PROJECT_ROOT = discover_project_root(__file__)
SCRIPTS_DIR = PROJECT_ROOT / "godot_project" / "scripts"
TESTS_DIR = PROJECT_ROOT / "godot_project" / "tests"
HISTORY_FILE = PROJECT_ROOT / "tools" / "quality" / "karpathy_history.json"


# ---------------------------------------------------------------------------
# GDScript file scanner helpers
# ---------------------------------------------------------------------------

def _read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return ""


def _find_gd_files(root: Path) -> list[Path]:
    """Recursively find all .gd files under *root*."""
    return sorted(root.rglob("*.gd")) if root.exists() else []


# ---------------------------------------------------------------------------
# KarpathyLoop
# ---------------------------------------------------------------------------

class KarpathyLoop:
    """Single-iteration Karpathy-style optimization loop for PetClaw."""

    def __init__(self, project_root: Path | None = None):
        self.project_root = project_root or PROJECT_ROOT
        self.scripts_dir = self.project_root / "godot_project" / "scripts"
        self.tests_dir = self.project_root / "godot_project" / "tests"
        self.metrics_history: list[dict] = []
        self.iteration: int = 0
        self._load_history()

    # ------------------------------------------------------------------
    # History persistence
    # ------------------------------------------------------------------

    def _load_history(self) -> None:
        if HISTORY_FILE.exists():
            try:
                data = json.loads(HISTORY_FILE.read_text(encoding="utf-8"))
                self.metrics_history = data.get("iterations", [])
                self.iteration = len(self.metrics_history)
            except (json.JSONDecodeError, KeyError):
                self.metrics_history = []
                self.iteration = 0

    def _save_history(self, result: dict) -> None:
        HISTORY_FILE.parent.mkdir(parents=True, exist_ok=True)
        self.metrics_history.append(result)
        payload = {
            "version": 1,
            "last_updated": datetime.now().isoformat(),
            "iterations": self.metrics_history,
        }
        HISTORY_FILE.write_text(
            json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8"
        )

    # ------------------------------------------------------------------
    # 1. COLLECT METRICS
    # ------------------------------------------------------------------

    def collect_metrics(self) -> dict:
        """Scan GDScript files and derive quantitative metrics."""
        metrics: dict[str, Any] = {
            "timestamp": datetime.now().isoformat(),
            "iteration": self.iteration,
        }

        gd_files = _find_gd_files(self.scripts_dir)
        test_files = _find_gd_files(self.tests_dir)

        # --- Per-file stats ---
        file_stats: list[dict] = []
        total_functions = 0
        total_signals = 0
        total_classes = 0
        total_lines = 0
        total_type_annotations = 0
        total_var_declarations = 0
        total_const_declarations = 0
        total_enum_declarations = 0

        for gd in gd_files:
            content = _read_text(gd)
            lines = content.splitlines()
            num_lines = len(lines)

            # Count functions (func <name>)
            funcs = re.findall(r"^(?:static\s+)?func\s+\w+", content, re.MULTILINE)
            # Count signals
            sigs = re.findall(r"^signal\s+\w+", content, re.MULTILINE)
            # Count class_name declarations
            classes = re.findall(r"^class_name\s+\w+", content, re.MULTILINE)
            # Count typed var declarations (var name: Type)
            typed_vars = re.findall(
                r"^(?:export\s+)?var\s+\w+\s*:", content, re.MULTILINE
            )
            # Count all var declarations
            all_vars = re.findall(
                r"^(?:export\s+)?var\s+\w+", content, re.MULTILINE
            )
            # Count typed func return (-> Type)
            typed_returns = re.findall(r"\)\s*->\s*\w+", content)
            # Count consts
            consts = re.findall(r"^const\s+\w+", content, re.MULTILINE)
            # Count enums
            enums = re.findall(r"^enum\s+\w+", content, re.MULTILINE)

            total_functions += len(funcs)
            total_signals += len(sigs)
            total_classes += len(classes)
            total_lines += num_lines
            total_type_annotations += len(typed_vars) + len(typed_returns)
            total_var_declarations += len(all_vars)
            total_const_declarations += len(consts)
            total_enum_declarations += len(enums)

            file_stats.append(
                {
                    "path": str(gd.relative_to(self.project_root)),
                    "lines": num_lines,
                    "functions": len(funcs),
                    "signals": len(sigs),
                    "typed_vars": len(typed_vars),
                    "all_vars": len(all_vars),
                    "typed_returns": len(typed_returns),
                    "consts": len(consts),
                }
            )

        # --- Aggregate code metrics ---
        avg_lines = total_lines / max(len(gd_files), 1)
        avg_funcs = total_functions / max(len(gd_files), 1)
        type_coverage = (
            total_type_annotations / max(total_var_declarations, 1) * 100
        )

        metrics["code"] = {
            "total_files": len(gd_files),
            "test_files": len(test_files),
            "total_lines": total_lines,
            "total_functions": total_functions,
            "total_signals": total_signals,
            "total_classes": total_classes,
            "total_consts": total_const_declarations,
            "total_enums": total_enum_declarations,
            "avg_lines_per_file": round(avg_lines, 1),
            "avg_functions_per_file": round(avg_funcs, 1),
            "type_annotation_coverage_pct": round(type_coverage, 1),
        }

        # --- AtoA metrics (scan a2a_conversation_system.gd) ---
        metrics["atoa"] = self._collect_atoa_metrics()

        # --- Language metrics ---
        metrics["language"] = self._collect_language_metrics()

        # --- Battle metrics ---
        metrics["battle"] = self._collect_battle_metrics()

        # --- Cost metrics ---
        metrics["cost"] = self._collect_cost_metrics()

        # Top files by size (actionable: find bloated files)
        top_files = sorted(file_stats, key=lambda f: f["lines"], reverse=True)[:10]
        metrics["top_files_by_lines"] = [
            {"path": f["path"], "lines": f["lines"], "functions": f["functions"]}
            for f in top_files
        ]

        return metrics

    # --- Sub-collectors ---

    def _collect_atoa_metrics(self) -> dict:
        """Scan AtoA conversation system for template/API metrics."""
        atoa_file = self.scripts_dir / "conversation" / "a2a_conversation_system.gd"
        content = _read_text(atoa_file)
        if not content:
            return {"available": False}

        # Count template strings (quoted strings in template dictionaries)
        template_strings = re.findall(r'"[^"]{10,}"', content)
        # Estimate prompt length: only count strings inside _build_*_prompt functions
        # (not template arrays which are data, not sent per-turn)
        prompt_section = ""
        for fn_match in re.finditer(
            r'func _build_\w*prompt\b.*?(?=\nfunc |\Z)', content, re.DOTALL
        ):
            prompt_section += fn_match.group(0)
        prompt_strings = re.findall(r'"[^"]{10,}"', prompt_section)
        prompt_chars = sum(len(s) for s in prompt_strings) if prompt_strings else 0
        # Fallback: if no prompt functions found, use a conservative estimate
        if prompt_chars == 0 and template_strings:
            prompt_chars = min(sum(len(s) for s in template_strings), 8000)
        # Count template categories (keys in template dictionaries)
        template_categories = re.findall(
            r'"(\w+)"\s*:\s*\[', content
        )
        # Count unique {placeholder} patterns
        placeholders = set(re.findall(r"\{(\w+)\}", content))
        # Detect cost-related constants
        daily_budget_match = re.search(
            r"DAILY_CONVERSATION_BUDGET.*?=\s*([\d.]+)", content
        )
        cost_per_turn_match = re.search(
            r"COST_PER_TURN.*?=\s*([\d.]+)", content
        )
        max_daily_match = re.search(
            r"MAX_DAILY_CONVERSATIONS.*?=\s*(\d+)", content
        )
        max_turns_match = re.search(
            r"MAX_TURNS_PER_CONVERSATION.*?=\s*(\d+)", content
        )

        return {
            "available": True,
            "template_count": len(template_strings),
            "template_categories": template_categories,
            "template_category_count": len(set(template_categories)),
            "placeholder_types": sorted(placeholders),
            "prompt_chars_estimate": prompt_chars,
            "prompt_token_estimate": prompt_chars // 4,  # rough: 1 token ~ 4 chars
            "daily_budget_usd": float(daily_budget_match.group(1))
            if daily_budget_match
            else None,
            "cost_per_turn_usd": float(cost_per_turn_match.group(1))
            if cost_per_turn_match
            else None,
            "max_daily_conversations": int(max_daily_match.group(1))
            if max_daily_match
            else None,
            "max_turns_per_conversation": int(max_turns_match.group(1))
            if max_turns_match
            else None,
        }

    def _collect_language_metrics(self) -> dict:
        """Scan language systems for vocabulary and evolution metrics."""
        lang_engine = self.scripts_dir / "language" / "original_language_engine.gd"
        lang_evo = self.scripts_dir / "language" / "language_evolution_system.gd"
        content_engine = _read_text(lang_engine)
        content_evo = _read_text(lang_evo)

        if not content_engine and not content_evo:
            return {"available": False}

        # Count syllable pool size
        syllables = re.findall(r'"(\w{2,3})"', content_engine)
        # Count language stages (enum values)
        stages = re.findall(r"^\s+(\w+),?\s*#", content_engine, re.MULTILINE)
        # Count suffix entries in evolution system
        suffix_contexts = re.findall(r'"(\w+)"\s*:', content_evo)
        # Count word order types
        word_orders = re.findall(r"^\s+(\w+),?\s*#.*$", content_evo, re.MULTILINE)
        # Count Hebbian parameters
        hebbian_params = re.findall(
            r"const\s+(\w+).*?=\s*([\d.]+)", content_engine
        )

        return {
            "available": True,
            "syllable_pool_size": len(set(syllables)),
            "language_stages": len(stages) if stages else 5,
            "word_order_types": len(word_orders) if word_orders else 6,
            "suffix_context_count": len(set(suffix_contexts)),
            "hebbian_parameters": {k: float(v) for k, v in hebbian_params},
        }

    def _collect_battle_metrics(self) -> dict:
        """Scan battle system for balance metrics."""
        battle_file = self.scripts_dir / "battle" / "language_battle_system.gd"
        content = _read_text(battle_file)

        if not content:
            return {"available": False}

        # Score category maximums
        score_cats = re.findall(
            r"const\s+MAX_(\w+)_SCORE.*?=\s*([\d.]+)", content
        )
        # Total templates per theme
        themes = re.findall(r"RoundTheme\.(\w+)\s*:\s*\[", content)
        template_blocks = re.split(r"RoundTheme\.\w+\s*:\s*\[", content)[1:]
        templates_per_theme: dict[str, int] = {}
        for theme, block in zip(themes, template_blocks):
            # Truncate block at first '],' or '}' to avoid counting strings
            # outside the template array.
            end_idx = block.find("],")
            if end_idx == -1:
                end_idx = block.find("]")
            array_block = block[:end_idx] if end_idx != -1 else block
            count = len(re.findall(r'"[^"]*"', array_block))
            templates_per_theme[theme] = count

        # Reward constants
        rewards = re.findall(
            r"const\s+(WINNER_\w+|LOSER_\w+).*?=\s*([\d.]+)", content
        )

        max_scores = {cat.lower(): float(val) for cat, val in score_cats}
        total_max = sum(max_scores.values())

        # Balance: how evenly distributed are the max score categories?
        if max_scores:
            values = list(max_scores.values())
            mean_val = sum(values) / len(values)
            variance = sum((v - mean_val) ** 2 for v in values) / len(values)
        else:
            variance = 0.0

        return {
            "available": True,
            "score_categories": max_scores,
            "total_max_score": total_max,
            "score_variance": round(variance, 2),
            "round_themes": themes,
            "templates_per_theme": templates_per_theme,
            "total_battle_templates": sum(templates_per_theme.values()),
            "reward_constants": {k: float(v) for k, v in rewards},
        }

    def _collect_cost_metrics(self) -> dict:
        """Estimate daily API cost from code constants."""
        atoa_file = self.scripts_dir / "conversation" / "a2a_conversation_system.gd"
        content = _read_text(atoa_file)
        if not content:
            return {"available": False}

        cost_per_turn = 0.002
        max_turns = 6
        max_daily = 25
        daily_budget = 0.50

        m = re.search(r"COST_PER_TURN.*?=\s*([\d.]+)", content)
        if m:
            cost_per_turn = float(m.group(1))
        m = re.search(r"MAX_TURNS_PER_CONVERSATION.*?=\s*(\d+)", content)
        if m:
            max_turns = int(m.group(1))
        m = re.search(r"MAX_DAILY_CONVERSATIONS.*?=\s*(\d+)", content)
        if m:
            max_daily = int(m.group(1))
        m = re.search(r"DAILY_CONVERSATION_BUDGET.*?=\s*([\d.]+)", content)
        if m:
            daily_budget = float(m.group(1))

        worst_case_daily = cost_per_turn * max_turns * max_daily
        # Template ratio: estimate from template count vs API call sites
        api_calls = len(re.findall(r"claude_api|api_client|_call_api", content, re.I))
        template_refs = len(
            re.findall(r"TEMPLATE|template|_templates", content, re.I)
        )
        total_refs = api_calls + template_refs
        template_ratio = template_refs / max(total_refs, 1) * 100

        return {
            "available": True,
            "cost_per_turn_usd": cost_per_turn,
            "max_turns_per_conversation": max_turns,
            "max_daily_conversations": max_daily,
            "daily_budget_usd": daily_budget,
            "worst_case_daily_cost_usd": round(worst_case_daily, 2),
            "budget_headroom_usd": round(daily_budget - worst_case_daily, 2),
            "template_ratio_estimate_pct": round(template_ratio, 1),
            "api_call_references": api_calls,
            "template_references": template_refs,
        }

    # ------------------------------------------------------------------
    # 2. EVALUATE
    # ------------------------------------------------------------------

    def evaluate(self, metrics: dict) -> dict:
        """Score current state on 0-100 scales across five dimensions."""
        scores: dict[str, dict] = {}

        # --- Code Quality (0-100) ---
        code = metrics.get("code", {})
        cq_score = 0.0
        cq_notes: list[str] = []

        # Type annotation coverage (target: >= 80%)
        type_cov = code.get("type_annotation_coverage_pct", 0)
        type_score = min(type_cov / 80.0 * 30, 30)
        cq_score += type_score
        if type_cov < 60:
            cq_notes.append(f"Type coverage low: {type_cov:.0f}% (target >=80%)")

        # Average function count per file (sweet spot: 5-15)
        avg_funcs = code.get("avg_functions_per_file", 0)
        if 5 <= avg_funcs <= 15:
            cq_score += 20
        elif 3 <= avg_funcs <= 20:
            cq_score += 12
            cq_notes.append(f"Avg funcs/file: {avg_funcs:.1f} (sweet spot: 5-15)")
        else:
            cq_score += 5
            cq_notes.append(f"Avg funcs/file: {avg_funcs:.1f} is outside norm")

        # Average file length (sweet spot: 100-400 lines)
        avg_lines = code.get("avg_lines_per_file", 0)
        if 100 <= avg_lines <= 400:
            cq_score += 20
        elif 50 <= avg_lines <= 600:
            cq_score += 12
            cq_notes.append(
                f"Avg lines/file: {avg_lines:.0f} (sweet spot: 100-400)"
            )
        else:
            cq_score += 5
            cq_notes.append(f"Avg lines/file: {avg_lines:.0f} is outside norm")

        # Test file ratio (target: >= 1 test per 5 source files)
        src = code.get("total_files", 1)
        tst = code.get("test_files", 0)
        test_ratio = tst / max(src, 1)
        test_score = min(test_ratio / 0.2 * 15, 15)
        cq_score += test_score
        if test_ratio < 0.1:
            cq_notes.append(f"Low test coverage: {tst} tests for {src} files")

        # Const / Enum usage bonus (signals good structure)
        struct_score = min(
            (code.get("total_consts", 0) + code.get("total_enums", 0)) / 50.0 * 15,
            15,
        )
        cq_score += struct_score

        scores["code_quality"] = {
            "score": round(min(cq_score, 100), 1),
            "notes": cq_notes,
        }

        # --- AtoA Quality (0-100) ---
        atoa = metrics.get("atoa", {})
        aq_score = 0.0
        aq_notes: list[str] = []

        if atoa.get("available"):
            # Template variety (target: >= 20 templates)
            tc = atoa.get("template_count", 0)
            aq_score += min(tc / 20.0 * 30, 30)
            if tc < 10:
                aq_notes.append(f"Only {tc} templates (target >=20)")

            # Template categories (target: >= 4)
            cats = atoa.get("template_category_count", 0)
            aq_score += min(cats / 4.0 * 20, 20)
            if cats < 3:
                aq_notes.append(f"Only {cats} template categories (target >=4)")

            # Prompt efficiency (lower is better, target: < 2000 tokens)
            tokens = atoa.get("prompt_token_estimate", 0)
            if tokens > 0:
                if tokens <= 2000:
                    aq_score += 25
                elif tokens <= 4000:
                    aq_score += 15
                    aq_notes.append(
                        f"Prompt token estimate: {tokens} (target <2000)"
                    )
                else:
                    aq_score += 5
                    aq_notes.append(f"Prompt bloat: ~{tokens} tokens")

            # Placeholder variety (target: >= 3 types)
            ph = len(atoa.get("placeholder_types", []))
            aq_score += min(ph / 3.0 * 15, 15)

            # Cost guard presence
            if atoa.get("daily_budget_usd") is not None:
                aq_score += 10
            else:
                aq_notes.append("No daily budget constant detected")
        else:
            aq_notes.append("AtoA conversation system not found")

        scores["atoa_quality"] = {
            "score": round(min(aq_score, 100), 1),
            "notes": aq_notes,
        }

        # --- Language Diversity (0-100) ---
        lang = metrics.get("language", {})
        ld_score = 0.0
        ld_notes: list[str] = []

        if lang.get("available"):
            # Syllable pool (target: >= 30)
            syl = lang.get("syllable_pool_size", 0)
            ld_score += min(syl / 30.0 * 25, 25)
            if syl < 15:
                ld_notes.append(f"Syllable pool small: {syl} (target >=30)")

            # Language stages (target: >= 4)
            stages = lang.get("language_stages", 0)
            ld_score += min(stages / 4.0 * 25, 25)

            # Word order variety (target: >= 4)
            wo = lang.get("word_order_types", 0)
            ld_score += min(wo / 4.0 * 25, 25)

            # Suffix context count
            sc = lang.get("suffix_context_count", 0)
            ld_score += min(sc / 5.0 * 25, 25)
            if sc < 3:
                ld_notes.append(f"Few suffix contexts: {sc}")
        else:
            ld_notes.append("Language systems not found")

        scores["language_diversity"] = {
            "score": round(min(ld_score, 100), 1),
            "notes": ld_notes,
        }

        # --- Battle Balance (0-100) ---
        battle = metrics.get("battle", {})
        bb_score = 0.0
        bb_notes: list[str] = []

        if battle.get("available"):
            # Score variance (lower is better-balanced, target: variance < 20)
            var = battle.get("score_variance", 999)
            if var <= 10:
                bb_score += 30
            elif var <= 20:
                bb_score += 20
            elif var <= 40:
                bb_score += 10
                bb_notes.append(f"Score variance: {var:.1f} (target <20)")
            else:
                bb_notes.append(f"High score variance: {var:.1f}")

            # Template count (target: >= 12)
            bt = battle.get("total_battle_templates", 0)
            bb_score += min(bt / 12.0 * 25, 25)
            if bt < 8:
                bb_notes.append(f"Only {bt} battle templates (target >=12)")

            # Theme count (target: >= 3)
            themes = len(battle.get("round_themes", []))
            bb_score += min(themes / 3.0 * 20, 20)

            # Templates evenly distributed across themes
            tpt = battle.get("templates_per_theme", {})
            if tpt:
                vals = list(tpt.values())
                if vals:
                    min_t = min(vals)
                    max_t = max(vals)
                    evenness = min_t / max(max_t, 1)
                    bb_score += evenness * 25
                    if evenness < 0.75:
                        bb_notes.append(
                            f"Uneven template distribution: {tpt}"
                        )
        else:
            bb_notes.append("Battle system not found")

        scores["battle_balance"] = {
            "score": round(min(bb_score, 100), 1),
            "notes": bb_notes,
        }

        # --- Cost Efficiency (0-100) ---
        cost = metrics.get("cost", {})
        ce_score = 0.0
        ce_notes: list[str] = []

        if cost.get("available"):
            # Budget headroom (positive is good)
            headroom = cost.get("budget_headroom_usd", 0)
            if headroom >= 0.1:
                ce_score += 30
            elif headroom >= 0:
                ce_score += 20
                ce_notes.append(
                    f"Tight budget headroom: ${headroom:.2f}"
                )
            else:
                ce_score += 5
                ce_notes.append(
                    f"Over budget! Headroom: ${headroom:.2f}"
                )

            # Template ratio (target: >= 70%)
            tr = cost.get("template_ratio_estimate_pct", 0)
            ce_score += min(tr / 80.0 * 35, 35)
            if tr < 60:
                ce_notes.append(
                    f"Template ratio: {tr:.0f}% (target >=80%)"
                )

            # Worst case cost vs budget
            wc = cost.get("worst_case_daily_cost_usd", 0)
            budget = cost.get("daily_budget_usd", 0.50)
            if budget > 0:
                efficiency = 1.0 - (wc / budget)
                ce_score += max(efficiency * 35, 0)
                if wc > budget:
                    ce_notes.append(
                        f"Worst-case daily: ${wc:.2f} exceeds ${budget:.2f} budget"
                    )
        else:
            ce_notes.append("Cost metrics not available")

        scores["cost_efficiency"] = {
            "score": round(min(ce_score, 100), 1),
            "notes": ce_notes,
        }

        # --- Overall ---
        all_scores = [s["score"] for s in scores.values()]
        overall = sum(all_scores) / max(len(all_scores), 1)
        scores["overall"] = round(overall, 1)

        return scores

    # ------------------------------------------------------------------
    # 3. ANALYZE
    # ------------------------------------------------------------------

    def analyze(self, evaluation: dict) -> list[str]:
        """Compare with previous iterations and produce prioritized recommendations."""
        recommendations: list[str] = []

        prev_eval = None
        if self.metrics_history:
            prev_eval = self.metrics_history[-1].get("evaluation")

        for dimension in [
            "code_quality",
            "atoa_quality",
            "language_diversity",
            "battle_balance",
            "cost_efficiency",
        ]:
            current = evaluation.get(dimension, {})
            if not isinstance(current, dict):
                continue
            cur_score = current.get("score", 0)
            notes = current.get("notes", [])

            # Check for regression
            if prev_eval and isinstance(prev_eval.get(dimension), dict):
                prev_score = prev_eval[dimension].get("score", 0)
                delta = cur_score - prev_score
                if delta < -5:
                    recommendations.insert(
                        0,
                        f"[REGRESSION] {dimension}: {prev_score:.0f} -> {cur_score:.0f} "
                        f"(delta {delta:+.1f}). Investigate immediately.",
                    )
                elif delta < -1:
                    recommendations.append(
                        f"[DECLINE] {dimension}: slight decline "
                        f"{prev_score:.0f} -> {cur_score:.0f}",
                    )
                elif abs(delta) < 1:
                    recommendations.append(
                        f"[STAGNANT] {dimension}: no progress at {cur_score:.0f}",
                    )
                elif delta > 5:
                    recommendations.append(
                        f"[IMPROVED] {dimension}: {prev_score:.0f} -> {cur_score:.0f} "
                        f"(+{delta:.1f}). Good progress.",
                    )

            # Low-score alert
            if cur_score < 50:
                recommendations.insert(
                    0,
                    f"[LOW] {dimension} at {cur_score:.0f}/100. "
                    + (notes[0] if notes else "Needs attention."),
                )
            elif cur_score < 70:
                recommendations.append(
                    f"[MODERATE] {dimension} at {cur_score:.0f}/100. "
                    + (notes[0] if notes else "Room for improvement."),
                )

            # Append specific notes
            for note in notes:
                if note not in " ".join(recommendations):
                    recommendations.append(f"  -> {dimension}: {note}")

        # Deduplicate while preserving order
        seen: set[str] = set()
        unique: list[str] = []
        for r in recommendations:
            if r not in seen:
                seen.add(r)
                unique.append(r)

        return unique

    # ------------------------------------------------------------------
    # 4. SUGGEST IMPROVEMENTS
    # ------------------------------------------------------------------

    def suggest_improvements(self, analysis: list[str]) -> list[dict]:
        """Convert analysis into actionable tasks with file, change_type, priority."""
        tasks: list[dict] = []

        for item in analysis:
            task: dict[str, Any] = {
                "description": item,
                "priority": "medium",
                "change_type": "unknown",
                "file": None,
                "function": None,
            }

            lowered = item.lower()

            # Determine priority
            if "[regression]" in lowered or "[low]" in lowered:
                task["priority"] = "high"
            elif "[stagnant]" in lowered or "[decline]" in lowered:
                task["priority"] = "medium"
            elif "[improved]" in lowered:
                task["priority"] = "low"
            elif "[moderate]" in lowered:
                task["priority"] = "medium"

            # Map to files and change types
            if "type coverage" in lowered or "type annotation" in lowered:
                task["file"] = "godot_project/scripts/ (all .gd files)"
                task["change_type"] = "add_type_annotations"
                task["function"] = "Add : Type to var declarations lacking annotations"

            elif "template" in lowered and "atoa" in lowered:
                task["file"] = "godot_project/scripts/conversation/a2a_conversation_system.gd"
                task["change_type"] = "add_templates"
                task["function"] = "Add more template strings to EVENT_CONVERSATION_TEMPLATES"

            elif "template" in lowered and "battle" in lowered:
                task["file"] = "godot_project/scripts/battle/language_battle_system.gd"
                task["change_type"] = "add_templates"
                task["function"] = "Add battle template strings to BATTLE_TEMPLATES"

            elif "prompt" in lowered and ("bloat" in lowered or "token" in lowered):
                task["file"] = "godot_project/scripts/conversation/a2a_conversation_system.gd"
                task["change_type"] = "reduce_tokens"
                task["function"] = "Shorten system prompts and remove redundant context"

            elif "syllable" in lowered:
                task["file"] = "godot_project/scripts/language/original_language_engine.gd"
                task["change_type"] = "expand_vocabulary"
                task["function"] = "Add more syllables to SYLLABLES constant array"

            elif "suffix" in lowered:
                task["file"] = "godot_project/scripts/language/language_evolution_system.gd"
                task["change_type"] = "expand_vocabulary"
                task["function"] = "Add more suffix context entries"

            elif "test" in lowered:
                task["file"] = "godot_project/tests/"
                task["change_type"] = "add_tests"
                task["function"] = "Create test files for under-tested subsystems"

            elif "variance" in lowered and "score" in lowered:
                task["file"] = "godot_project/scripts/battle/language_battle_system.gd"
                task["change_type"] = "balance_tuning"
                task["function"] = "Adjust MAX_*_SCORE constants for more even distribution"

            elif "budget" in lowered or "cost" in lowered:
                task["file"] = "godot_project/scripts/conversation/a2a_conversation_system.gd"
                task["change_type"] = "cost_optimization"
                task["function"] = "Review API call paths and increase template fallback coverage"

            elif "template ratio" in lowered:
                task["file"] = "godot_project/scripts/conversation/a2a_conversation_system.gd"
                task["change_type"] = "increase_template_ratio"
                task["function"] = "Identify API-only paths that can be converted to templates"

            else:
                task["change_type"] = "investigate"

            tasks.append(task)

        # Sort by priority
        priority_order = {"high": 0, "medium": 1, "low": 2}
        tasks.sort(key=lambda t: priority_order.get(t["priority"], 9))

        return tasks

    # ------------------------------------------------------------------
    # 5. RUN ITERATION (full loop)
    # ------------------------------------------------------------------

    def run_iteration(self) -> dict:
        """Execute one full Karpathy Loop cycle: collect -> evaluate -> analyze -> suggest."""
        metrics = self.collect_metrics()
        evaluation = self.evaluate(metrics)
        analysis = self.analyze(evaluation)
        improvements = self.suggest_improvements(analysis)

        result = {
            "iteration": self.iteration,
            "timestamp": datetime.now().isoformat(),
            "metrics": metrics,
            "evaluation": evaluation,
            "analysis": analysis,
            "improvements": improvements,
        }

        self._save_history(result)
        self.iteration += 1

        return result

    # ------------------------------------------------------------------
    # History queries
    # ------------------------------------------------------------------

    def get_history_summary(self) -> list[dict]:
        """Return a compact summary of all past iterations."""
        summaries = []
        for entry in self.metrics_history:
            ev = entry.get("evaluation", {})
            summaries.append(
                {
                    "iteration": entry.get("iteration", "?"),
                    "timestamp": entry.get("timestamp", "?"),
                    "overall": ev.get("overall", "?"),
                    "code_quality": ev.get("code_quality", {}).get("score", "?"),
                    "atoa_quality": ev.get("atoa_quality", {}).get("score", "?"),
                    "language_diversity": ev.get("language_diversity", {}).get(
                        "score", "?"
                    ),
                    "battle_balance": ev.get("battle_balance", {}).get(
                        "score", "?"
                    ),
                    "cost_efficiency": ev.get("cost_efficiency", {}).get(
                        "score", "?"
                    ),
                }
            )
        return summaries

    def compare_iterations(self, n: int) -> Optional[dict]:
        """Compare iteration *n* with the latest iteration."""
        if n < 0 or n >= len(self.metrics_history):
            return None
        if len(self.metrics_history) < 2 and n == len(self.metrics_history) - 1:
            return {"error": "Only one iteration recorded, nothing to compare."}

        old = self.metrics_history[n].get("evaluation", {})
        latest = self.metrics_history[-1].get("evaluation", {})

        deltas: dict[str, Any] = {}
        for dim in [
            "code_quality",
            "atoa_quality",
            "language_diversity",
            "battle_balance",
            "cost_efficiency",
        ]:
            old_score = (
                old[dim]["score"]
                if isinstance(old.get(dim), dict)
                else 0
            )
            new_score = (
                latest[dim]["score"]
                if isinstance(latest.get(dim), dict)
                else 0
            )
            deltas[dim] = {
                "old": old_score,
                "new": new_score,
                "delta": round(new_score - old_score, 1),
            }

        deltas["overall"] = {
            "old": old.get("overall", 0),
            "new": latest.get("overall", 0),
            "delta": round(
                (latest.get("overall", 0) or 0) - (old.get("overall", 0) or 0), 1
            ),
        }

        return {
            "compared_iteration": n,
            "latest_iteration": len(self.metrics_history) - 1,
            "deltas": deltas,
        }


# ---------------------------------------------------------------------------
# CLI output formatting
# ---------------------------------------------------------------------------

def _print_header(text: str) -> None:
    width = 60
    print()
    print("=" * width)
    print(f"  {text}")
    print("=" * width)


def _print_section(title: str) -> None:
    print(f"\n--- {title} ---")


def _print_scores(evaluation: dict) -> None:
    _print_section("Scores (0-100)")
    for dim in [
        "code_quality",
        "atoa_quality",
        "language_diversity",
        "battle_balance",
        "cost_efficiency",
    ]:
        data = evaluation.get(dim, {})
        if isinstance(data, dict):
            score = data.get("score", 0)
            bar = "#" * int(score / 5) + "-" * (20 - int(score / 5))
            print(f"  {dim:25s} [{bar}] {score:5.1f}")
    overall = evaluation.get("overall", 0)
    print(f"  {'OVERALL':25s}                        {overall:5.1f}")


def _print_analysis(analysis: list[str]) -> None:
    _print_section("Analysis & Recommendations")
    for i, item in enumerate(analysis, 1):
        print(f"  {i:2d}. {item}")


def _print_improvements(improvements: list[dict]) -> None:
    _print_section("Suggested Improvements")
    for i, task in enumerate(improvements, 1):
        p = task["priority"].upper()
        ct = task["change_type"]
        desc = task["description"]
        target = task.get("file") or "N/A"
        fn = task.get("function") or ""
        print(f"  {i:2d}. [{p}] {ct}")
        print(f"      {desc}")
        if target != "N/A":
            print(f"      File: {target}")
        if fn:
            print(f"      Action: {fn}")
        print()


def _print_history(summaries: list[dict]) -> None:
    _print_header("Karpathy Loop History")
    if not summaries:
        print("  No iterations recorded yet.")
        return
    header = (
        f"  {'#':>3s}  {'Timestamp':25s} {'Overall':>7s}  "
        f"{'Code':>5s}  {'AtoA':>5s}  {'Lang':>5s}  {'Battle':>6s}  {'Cost':>5s}"
    )
    print(header)
    print("  " + "-" * (len(header) - 2))
    for s in summaries:
        def _f(v: Any) -> str:
            return f"{v:5.1f}" if isinstance(v, (int, float)) else f"{v!s:>5s}"

        print(
            f"  {s['iteration']:>3}  {str(s['timestamp'])[:25]:25s} {_f(s['overall']):>7s}  "
            f"{_f(s['code_quality'])}  {_f(s['atoa_quality'])}  "
            f"{_f(s['language_diversity'])}  {_f(s['battle_balance'])}  "
            f"{_f(s['cost_efficiency'])}"
        )


def _print_comparison(result: dict) -> None:
    _print_header(
        f"Compare: Iteration {result['compared_iteration']} vs "
        f"Iteration {result['latest_iteration']}"
    )
    deltas = result.get("deltas", {})
    for dim, data in deltas.items():
        if isinstance(data, dict):
            old = data.get("old", 0)
            new = data.get("new", 0)
            delta = data.get("delta", 0)
            arrow = "+" if delta > 0 else ""
            indicator = ">>>" if abs(delta) > 5 else (">" if delta > 0 else ("<" if delta < 0 else "="))
            print(
                f"  {dim:25s}  {old:5.1f} -> {new:5.1f}  ({arrow}{delta:.1f}) {indicator}"
            )


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Karpathy Loop: continuous optimization for PetClaw",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 karpathy_loop.py              Run one optimization iteration
  python3 karpathy_loop.py --history    Show all past iteration scores
  python3 karpathy_loop.py --compare 0  Compare iteration 0 with latest
  python3 karpathy_loop.py --json       Output current iteration as JSON
""",
    )
    parser.add_argument(
        "--history",
        action="store_true",
        help="Show improvement history across iterations",
    )
    parser.add_argument(
        "--compare",
        type=int,
        metavar="N",
        default=None,
        help="Compare iteration N with the latest iteration",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results as JSON",
    )
    parser.add_argument(
        "--project-root",
        type=str,
        default=None,
        help="Project root directory (auto-discovered if omitted)",
    )

    args = parser.parse_args()

    root = Path(args.project_root) if args.project_root else PROJECT_ROOT
    loop = KarpathyLoop(project_root=root)

    if args.history:
        summaries = loop.get_history_summary()
        if args.json:
            print(json.dumps(summaries, indent=2, ensure_ascii=False))
        else:
            _print_history(summaries)
        return

    if args.compare is not None:
        result = loop.compare_iterations(args.compare)
        if result is None:
            print(f"Error: iteration {args.compare} not found.", file=sys.stderr)
            sys.exit(1)
        if "error" in result:
            print(f"Error: {result['error']}", file=sys.stderr)
            sys.exit(1)
        if args.json:
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            _print_comparison(result)
        return

    # Default: run one iteration
    result = loop.run_iteration()

    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        _print_header(
            f"Karpathy Loop  --  Iteration {result['iteration']}"
        )
        _print_scores(result["evaluation"])
        _print_analysis(result["analysis"])
        _print_improvements(result["improvements"])

        print(f"\nHistory saved to: {HISTORY_FILE}")
        print(
            f"Run `python3 {__file__} --history` to view all iterations."
        )


if __name__ == "__main__":
    main()
