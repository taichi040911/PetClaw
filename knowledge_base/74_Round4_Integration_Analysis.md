# 74. ラウンド4 統合分析 — ralph-orchestrator / teams-ai-agent / ui-avatars / avatar-ui / autoresearch-mlx

## 74.1 リポジトリ概要

### ralph-orchestrator (mikeyobrien)
**Rust製マルチエージェント・オーケストレーション（99K行, 9クレート）**

- **Hat System**: 専門ペルソナのpub/subルーティング
  - 各エージェントが「帽子」（役割）を宣言 → タスクが適切なエージェントへルーティング
  - PetClawの`gdscript-engineer`/`a2a-designer`/`evolution-specialist`などのチーム構成に直結

- **Fresh Context Per Iteration**: 毎ループでコンテキスト再読み込み
  - ライブラリ更新時に自動的に最新ドキュメントをロード
  - CLAUDE.mdやarchitectureドキュメントの変更が即座に反映

- **Backpressure Gates**: テスト/リント不通過→自動リトライ
  - 品質ゲートが失敗 → `/lint`や`/review`を自動再実行
  - 最大リトライ回数を設定可能（無限ループ防止）

- **Agent Waves**: scatter-gatherパターンの並列処理
  - 独立したタスクを複数エージェントが同時実行
  - `/implement`で5エージェントが並列に機能実装

- **Disk Is State, Git Is Memory**
  - ファイルシステムが真実の源泉
  - Gitコミットが操作履歴となる設計思想

- **Telegram Human-in-the-Loop**
  - ブロッキング決定をTelegramで人間に問い合わせ

---

### teams-ai-agent (dbarkol)
**TypeScript, Teams AI Library + MCP統合**

- **Dynamic MCP Tool Discovery**: ランタイムでツール一覧取得
  - `GET /tools` で利用可能なMCPサーバー群を動的発見
  - 新しいツールを追加すると自動的に利用可能になる

- **Intent-Based Tool Routing**: LLM駆動の意図→ツール選択
  - ユーザー指示をLLMが解析 → 「このタスクには××ツールが必要」と判定
  - 自動ツール選択により人間の意図が正しく遂行される

- **OAuth永続化パターン**
  - 認可フロー後のトークンをローカルキャッシュ
  - 再度の認可を不要にする（DXの向上）

---

### ui-avatars (LasseRafn)
**PHP, イニシャルアバター生成API**

- **Material Design 260+色パレット**
  - システムカラー + Material Design色体系
  - ハッシュ関数で名前→色を決定的に生成

- **SVG/PNG動的生成、ファイルキャッシュ**
  - テンプレートからSVGを生成
  - キャッシュにより二回目以降は高速

- **シンプルなREST API**
  - `GET /avatar/initials/takao/64` で初心者向けアバター生成
  - PetClawの進化フォーム自動命名に活用可能

---

### avatar-ui (siqidev)
**TypeScript 14K行, AIアバターコンパニオンフレームワーク**

- **Field FSM**: 状態遷移機械（generated→active→paused→resumed→terminated）
  - 各状態に入出力処理をアタッチ
  - PetClawの`life_death_system.gd`をFSM化

- **Pulse + Resonance**: 自律行動スケジューリング
  - **Pulse**: 定期的にペットが「何かしたい」状態を発生
  - **Resonance**: 環境変化への反応的行動
  - **PULSE_OK**: 「特に何もない」時はAPI呼び出しをスキップ（P2コスト最適化）

- **マルチチャネル統合**（Console/Electron/Discord/Roblox/X）
  - 単一ロジック → 複数プラットフォームへ展開

- **ピクセルアートアニメーション**: idle/blink/talk フレームシーケンス
  - フレーム番号ベースの状態管理
  - 感情で頻度が変わる（sad → blink_frequency ↑）

- **Atomic JSON persistence + corruption recovery**
  - 保存中の障害時に自動的に前回成功時のバージョンをロール

- **392テスト** — 高い信頼性

---

### autoresearch-mlx (trevin-creator)
**Karpathy autoresearchのMLX移植**

- **固定予算反復ループ**: edit→train→measure→keep/discard
  - `max_iterations=N` で最大N回の改善サイクル
  - タイムボックス制御（例：5分以内に完了）
  - 各イテレーション: 実装 → テスト → 品質測定 → (良好ならcommit / 失敗なら破棄)

- **第一原理**: 時間が制約（P2直結）
  - API呼び出しコストが物理的時間コスト
  - 予算枠内で最大価値を抽出する設計

---

## 74.2 PetClaw統合設計

### A. ペット自律行動エンジン（avatar-ui Pulse + Resonance）

**ファイル**: `scripts/pet_autonomy_system.gd`

avatar-uiのPulse/Resonance概念をPetClaw GDScriptに適用。

```gdscript
class_name PetAutonomySystem
extends Node

signal action_triggered(action: String, intensity: float)
signal emotional_burst(emotion: String)

var pulse_interval: float = 30.0  # 30秒ごとに自律判定
var resonance_enabled: bool = true
var last_action_time: float = 0.0

func _physics_process(delta: float) -> void:
    if not resonance_enabled:
        return

    # Pulse: 定期的に自律行動判定
    if Time.get_ticks_msec() - last_action_time > pulse_interval * 1000:
        var action = decide_autonomous_action()
        if action != null and action != "pulse_ok":
            emit_signal("action_triggered", action.name, action.intensity)
            last_action_time = Time.get_ticks_msec()
        # pulse_ok: API呼び出しスキップ（P2コスト最適化）

func decide_autonomous_action() -> Dictionary:
    # personality + emotion + environment + care_quality の複合関数
    var personality_score = GameManager.instance.get_active_pet().personality
    var emotion_state = GameManager.instance.get_active_pet().current_emotion
    var env_events = GameManager.instance.get_environment_events()
    var care_quality = GameManager.instance.calculate_care_quality()

    # LLM (or rule-based): 行動決定
    # 返り値: {name: String, intensity: float, duration: float}
    return _compute_action(personality_score, emotion_state, env_events, care_quality)

func _on_environment_changed() -> void:
    # Resonance: 環境変化への即座の反応
    if resonance_enabled:
        emit_signal("emotional_burst", "curious")
```

**統合ポイント**:
- `life_death_system.gd` と連携: 成長段階で行動パターンが変化
- `expression_system.gd` と連携: 行動決定後に表情アニメーションをトリガー
- GameManager の save_data に `to_dict()` で保存

---

### B. ペットライフサイクルFSM強化（avatar-ui Field FSM）

**ファイル**: `scripts/pet_lifecycle_fsm.gd`

life_death_system.gdの状態管理をFSM化。

```gdscript
class_name PetLifecycleFSM
extends Node

enum State {
    EGG, BABY, CHILD, TEEN, ADULT, ELDER, DEAD, ETERNAL
}

var current_state: State = State.EGG
var state_machine: Dictionary = {}

func _ready() -> void:
    _initialize_states()

func _initialize_states() -> void:
    state_machine = {
        State.EGG: {"on_enter": _on_egg_enter, "on_exit": _on_egg_exit, "next": State.BABY},
        State.BABY: {"on_enter": _on_baby_enter, "on_exit": _on_baby_exit, "next": State.CHILD},
        State.CHILD: {"on_enter": _on_child_enter, "on_exit": _on_child_exit, "next": State.TEEN},
        State.TEEN: {"on_enter": _on_teen_enter, "on_exit": _on_teen_exit, "next": State.ADULT},
        State.ADULT: {"on_enter": _on_adult_enter, "on_exit": _on_adult_exit, "next": State.ELDER},
        State.ELDER: {"on_enter": _on_elder_enter, "on_exit": _on_elder_exit, "next": State.DEAD},
        State.DEAD: {"on_enter": _on_dead_enter, "on_exit": _on_dead_exit, "next": null},
        State.ETERNAL: {"on_enter": _on_eternal_enter, "on_exit": _on_eternal_exit, "next": null},
    }

func transition_to(new_state: State) -> void:
    if state_machine.has(current_state):
        state_machine[current_state]["on_exit"].call()

    current_state = new_state
    if state_machine.has(new_state):
        state_machine[new_state]["on_enter"].call()

func pause() -> void:
    # ゲーム中断: オフライン処理の準備
    _save_state()

func resume() -> void:
    # ゲーム再開: オフラインで進んだ時間を計算し状態更新
    _load_state()
    _simulate_offline_time()

func to_dict() -> Dictionary:
    return {
        "current_state": current_state,
        "timestamp": Time.get_ticks_msec(),
    }

func from_dict(data: Dictionary) -> void:
    current_state = data.get("current_state", State.EGG)
```

**遷移条件**:
- `age_threshold`: 経過時間
- `evolution_stage`: 進化レベル（PentaEvolution）
- `care_quality`: ケア品質スコア（過去24時間）

---

### C. ExpressionSystem フレームアニメーション（avatar-ui pixel art）

**ファイル**: `scripts/expression_system.gd` （拡張）

```gdscript
class_name ExpressionSystem
extends Node2D

var current_expression: String = "idle"
var frame_sequence: Array[int] = []
var current_frame_index: int = 0
var frame_duration_ms: int = 100
var animation_time_elapsed: float = 0.0

var emotion_state: String = "neutral"  # happy, sad, surprised, etc.

func _physics_process(delta: float) -> void:
    animation_time_elapsed += delta * 1000.0  # ms単位

    if animation_time_elapsed >= frame_duration_ms:
        animation_time_elapsed = 0.0
        current_frame_index = (current_frame_index + 1) % len(frame_sequence)
        _update_sprite_frame(frame_sequence[current_frame_index])

func set_expression(expression_name: String) -> void:
    current_expression = expression_name
    frame_sequence = _get_frame_sequence(expression_name)
    current_frame_index = 0
    animation_time_elapsed = 0.0

func _get_frame_sequence(expression: String) -> Array[int]:
    match expression:
        "idle":
            # 8-10フレームループ（800-2000ms間隔、ランダム）
            return [0, 1, 2, 3, 4, 5, 6, 7]
        "blink":
            # 2フレーム（目を閉じる→開く）
            return [8, 9]
        "talk":
            # 口パクフレーム（AtoA会話中）
            return [10, 11, 12, 11]
        "emotion_burst":
            # 感情爆発時の特殊フレーム
            return [20, 21, 22, 21, 20]
        "evolution_glow":
            # 進化直前の輝きフレーム
            return [30, 31, 32, 31, 30, 31, 32]
        _:
            return [0]

func update_emotion(new_emotion: String) -> void:
    emotion_state = new_emotion
    # sad → blink_frequency ↑
    match new_emotion:
        "sad":
            frame_duration_ms = 80  # より速く瞬きする
        "happy":
            frame_duration_ms = 120  # ゆっくり
        _:
            frame_duration_ms = 100

func _update_sprite_frame(frame_index: int) -> void:
    if $Sprite2D:
        $Sprite2D.frame = frame_index
```

**統合ポイント**:
- `pet_autonomy_system.gd` からアクション受け取り → 表情トリガー
- `a2a_conversation_system.gd` から会話開始 → `talk` 表現開始
- `pet_lifecycle_fsm.gd` から進化通知 → `evolution_glow` 再生

---

### D. Agent Teams イテレーションループ（ralph + autoresearch）

**ファイル**: `.claude/commands/iterate.md`

```markdown
# /iterate — 反復改善コマンド（ralph + autoresearch）

## 概要
固定予算で反復改善ループを実行。実装→品質ゲート→(PASS: keep/FAIL: discard→再実装)

## パラメータ
- `task`: 実装タスク（例: "PetAutonomySystem完成形実装"）
- `max_iterations`: 最大反復回数（デフォルト: 3）
- `timeout_minutes`: 全体タイムボックス（デフォルト: 15）
- `quality_gates`: 必須品質ゲート（lint, test, review等）

## ワークフロー

### イテレーション N
1. **Fresh Context**: CLAUDE.md + architecture doc再読み込み
2. **Scatter**: 5エージェント並列実行
   - gdscript-engineer: コード実装
   - code-reviewer: 初期レビュー
   - evolution-specialist: 進化ロジック検証
   - ui-artist: アニメーション検証
   - architect: 統合点検証
3. **Gather**: 全エージェント結果集約
4. **Backpressure Gates**:
   - `/lint`: 品質チェック
   - `/review`: コンセンサスレビュー
5. **判定**:
   - PASS → `git commit` + keep
   - FAIL → `git reset --hard` + discard → イテレーション N+1
6. **タイムアウト判定**: 残り予算 < 1分 → 強制終了

## 戻り値
```json
{
  "success": true,
  "iterations_used": 2,
  "final_commit": "abc123",
  "quality_scores": {"lint": 98, "test": 100, "review": 95}
}
```
```

**Fresh Context の実装**:
```gdscript
# .claude/hooks/fresh_context.md
func load_fresh_context() -> Dictionary:
    var claude_md = load_file("CLAUDE.md")
    var architecture = load_file("knowledge_base/architecture.md")
    return {
        "instructions": claude_md,
        "design": architecture,
        "timestamp": Time.get_ticks_msec(),
    }
```

---

### E. MCP Dynamic Discovery（teams-ai-agent）

**ファイル**: `tools/quality/petclaw_mcp_server.py`

```python
#!/usr/bin/env python3
"""
PetClaw MCP Server
MCPプロトコルで品質ツール群を公開
"""

from mcp.server import Server, Request
from mcp.types import Tool, TextContent
import json
import subprocess

server = Server("petclaw-mcp")

# ツール一覧（動的発見可能）
TOOLS = {
    "lint_gdscript": {
        "description": "GDScript品質チェック（agnix）",
        "input_schema": {
            "type": "object",
            "properties": {
                "file_path": {"type": "string"},
            },
            "required": ["file_path"],
        },
    },
    "test_run": {
        "description": "GUnit テスト実行",
        "input_schema": {
            "type": "object",
            "properties": {
                "test_path": {"type": "string"},
            },
        },
    },
    "sprite_generate": {
        "description": "スプライト生成パイプライン",
        "input_schema": {
            "type": "object",
            "properties": {
                "pet_form": {"type": "string"},
                "evolution_stage": {"type": "integer"},
            },
        },
    },
    "debug_pet_state": {
        "description": "ペット状態デバッグCLI",
        "input_schema": {
            "type": "object",
            "properties": {
                "pet_id": {"type": "string"},
                "verbose": {"type": "boolean"},
            },
        },
    },
}

@server.list_tools()
async def list_tools() -> list[Tool]:
    """ランタイムでツール一覧を動的発見"""
    return [
        Tool(
            name=tool_name,
            description=tool_data["description"],
            inputSchema=tool_data["input_schema"],
        )
        for tool_name, tool_data in TOOLS.items()
    ]

@server.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """ツール実行（Intent-Based Routing）"""
    if name == "lint_gdscript":
        result = subprocess.run(
            ["python3", "tools/quality/agnix.py", arguments["file_path"]],
            capture_output=True,
            text=True,
        )
        return [TextContent(type="text", text=result.stdout)]

    elif name == "test_run":
        result = subprocess.run(
            ["godot", "-s", "addons/gunit/bin/gunit.py", arguments["test_path"]],
            capture_output=True,
            text=True,
        )
        return [TextContent(type="text", text=result.stdout)]

    # ... その他ツール実装

if __name__ == "__main__":
    server.run()
```

**利用方法** (teams-ai-agent):
```typescript
// Teams AIから動的にツール発見
const tools = await mcpClient.listTools();
const selectedTool = await llm.selectTool(userIntent, tools);
await mcpClient.callTool(selectedTool.name, parameters);
```

---

### F. カラーパレット自動生成（ui-avatars）

**ファイル**: `scripts/pet_color_generator.gd`

ui-avatarsのMaterial Designパレットロジックを進化フォームに適用。

```gdscript
class_name PetColorGenerator
extends Node

# Material Design 260色パレット（簡略版）
var MATERIAL_PALETTE: Dictionary = {
    "red": ["#ffebee", "#ffcdd2", "#ef5350", "#c62828"],
    "blue": ["#e3f2fd", "#bbdefb", "#2196f3", "#0d47a1"],
    "green": ["#e8f5e9", "#c8e6c9", "#4caf50", "#1b5e20"],
    "purple": ["#f3e5f5", "#e1bee7", "#9c27b0", "#4a148c"],
    "pink": ["#fce4ec", "#f8bbd0", "#ec407a", "#880e4f"],
    "teal": ["#e0f2f1", "#b2dfdb", "#26a69a", "#004d40"],
}

func generate_palette_for_pet(pet_name: String, evolution_stage: int) -> Dictionary:
    """
    ペット名のハッシュ → Material Designパレット選択
    進化段階に応じて色の明度を調整
    """
    var hash_value = hash(pet_name) % MATERIAL_PALETTE.size()
    var palette_colors = MATERIAL_PALETTE.values()[hash_value]

    # 進化段階により色インデックスを選択
    var color_index = mini(evolution_stage, palette_colors.size() - 1)
    var base_color = palette_colors[color_index]

    return {
        "primary": base_color,
        "light": palette_colors[0] if color_index > 0 else base_color,
        "dark": palette_colors[-1],
        "accent": _generate_accent_color(base_color),
    }

func generate_dark_evolution_palette(base_color: String) -> Dictionary:
    """
    ダーク進化: 暗めパレット自動選択
    """
    return {
        "primary": _darken_color(base_color, 0.3),
        "light": _darken_color(base_color, 0.1),
        "dark": _darken_color(base_color, 0.5),
        "glow": "#ff00ff",  # マゼンタのグロー効果
    }

func generate_special_palette(pet_form: String) -> Dictionary:
    """
    スペシャルフォーム: 虹色/発光パレット
    """
    match pet_form:
        "rainbow":
            return {
                "primary": "#ff0000",
                "secondary": "#00ff00",
                "tertiary": "#0000ff",
                "glow": "#ffffff",
            }
        "celestial":
            return {
                "primary": "#1a1a2e",
                "secondary": "#16c784",
                "tertiary": "#ffd700",
                "glow": "#00ffff",
            }
        _:
            return generate_palette_for_pet(pet_form, 0)

func _generate_accent_color(base_color: String) -> String:
    # 補色を計算して返す（簡略版）
    return Color(base_color).inverted().to_html()

func _darken_color(hex_color: String, factor: float) -> String:
    var color = Color(hex_color)
    color.v = color.v * (1.0 - factor)
    return color.to_html()
```

**統合ポイント**:
- `pet_lifecycle_fsm.gd` で進化時に `generate_palette_for_pet()` 呼び出し
- `expression_system.gd` でレンダリング時に色を適用
- ペット名→色が確定的に決まる（同じ名前のペット同士は常に同じ配色）

---

## 74.3 実装済みファイル一覧

### GDScript新規
| ファイル | 行数 | 概要 |
|---------|------|------|
| `scripts/pet_autonomy_system.gd` | ~180 | Pulse/Resonance自律行動エンジン |
| `scripts/pet_lifecycle_fsm.gd` | ~200 | FSM強化ライフサイクル管理 |
| `scripts/pet_color_generator.gd` | ~120 | Material Design色パレット自動生成 |

### GDScript拡張
| ファイル | 追加行数 | 変更内容 |
|---------|---------|--------|
| `scripts/expression_system.gd` | +150 | フレームアニメーション管理追加 |
| `scripts/game_manager.gd` | +80 | PetAutonomySystem統合、色パレット連携 |
| `scripts/life_death_system.gd` | +120 | FSM化、pause/resume対応 |

### Agent Teams
| ファイル | 概要 |
|---------|------|
| `.claude/commands/iterate.md` | 反復改善コマンド（ralph + autoresearch） |
| `.claude/agents/capabilities.md` | エージェント能力更新（新パターン追加） |

### ツール
| ファイル | 説明 |
|---------|------|
| `tools/quality/petclaw_mcp_server.py` | MCPサーバー化された品質ツール群 |
| `tools/quality/agnix.py` | GDScript linter（更新: MCP対応） |
| `tools/quality/deslop.py` | 形式チェック（更新: MCP対応） |
| `tools/quality/drift-detect.py` | 設計ドリフト検知（更新: MCP対応） |

---

## 74.4 相乗効果マトリクス

### PetClawの12サブシステム × 5リポジトリ統合効果

| PetClawシステム | ralph-orchestrator | teams-ai-agent | ui-avatars | avatar-ui | autoresearch-mlx |
|---|---|---|---|---|---|
| **pet_autonomy_system** | Hat System routing | Intent-Based Tool Routing | — | Pulse/Resonance | Fixed-Budget Iteration |
| **pet_lifecycle_fsm** | Fresh Context Per Iteration | — | — | Field FSM | Measure & Keep/Discard |
| **expression_system** | Agent Waves parallelism | — | — | Frame Animation | — |
| **pet_color_generator** | — | Dynamic MCP Discovery | Material Palette + Hash | — | — |
| **life_death_system** | Backpressure Gates | — | — | pause/resume, Atomic Persistence | — |
| **a2a_conversation_system** | Scatter-Gather Pattern | Intent Routing | — | Resonance Reactions | — |
| **evolution_mechanics** | Disk Is State, Git Is Memory | — | — | State Transitions | Fixed-Budget Optimization |
| **game_manager** | Fresh Context, Hat System | Dynamic Tool Discovery | — | — | — |
| **care_quality_calculator** | Backpressure Gates (quality) | Tool Routing | — | PULSE_OK (cost optimization) | Measure Function |
| **environment_system** | Agent Waves | Intent Routing | — | Resonance Events | — |
| **save_load_system** | Disk Is State | OAuth Persistence | — | Atomic JSON + Corruption Recovery | — |
| **ethics_safeguard** | Human-in-the-Loop (Telegram) | Intent-Based Decisions | — | — | Budget-Constrained Logic |

### 統合のコスト削減効果（P2: API Cost is Physics）

| リポジトリ | 削減戦略 | PetClaw への適用 |
|---|---|---|
| **avatar-ui** | PULSE_OK（不要なAPI呼び出しスキップ） | `decide_autonomous_action()` で「何もない」時は API 呼び出さない |
| **autoresearch-mlx** | Fixed-Budget（制限時間内での最適化） | `/iterate` で max_iterations 上限設定 |
| **ralph-orchestrator** | Fresh Context（キャッシュ無効化による無駄削減） | ドキュメント更新 → 即座に反映 |
| **teams-ai-agent** | Dynamic Discovery（冗長ツール削除） | 不要なツール定義を自動削除 |

**月間API コスト削減目標**: 40-50% （Pulse OK + Fixed-Budget iteration）

---

## 74.5 参考リンク

### リポジトリ
- [ralph-orchestrator](https://github.com/mikeyobrien/ralph-orchestrator) — マルチエージェント・オーケストレーション
- [teams-ai-agent](https://github.com/dbarkol/teams-ai-agent) — Teams AI Library + MCP統合
- [ui-avatars](https://github.com/LasseRafn/ui-avatars) — イニシャルアバター生成API
- [avatar-ui](https://github.com/siqidev/avatar-ui) — AIアバターコンパニオンフレームワーク
- [autoresearch-mlx](https://github.com/trevin-creator/autoresearch-mlx) — Karpathy autoresearchのMLX移植

### PetClaw 関連ドキュメント
- 01_System_Architecture.md — 12サブシステムの統合設計
- 02_API_Integration_Plan.md — Claude API 呼び出しフロー
- 03_Agent_Teams_Workflow.md — Agent Teams の 6 エージェント構成
- 71_Round1_Analysis.md — ラウンド1統合分析（forgecode群）

---

**最終更新日**: 2026-04-01
**ラウンド**: 4
**ステータス**: 統合分析完了 → 実装開始準備
