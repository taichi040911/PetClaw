---
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, TeammateTool
---

# /iterate — 反復改善コマンド（ralph-orchestrator + autoresearch-mlx）

## 概要

固定予算（時間 + API呼び出し）で反復改善ループを実行。
実装 → 品質ゲート → (PASS: keep/commit | FAIL: discard/reset → 再実装)

ralph-orchestratorのBackpressure Gates + Fresh Context Per Iterationと、
autoresearch-mlxの固定予算反復パターンをPetClaw Agent Teamsに統合。

## Ralph Tenets 適用

- **Fresh Context Per Iteration**: 各イテレーションでCLAUDE.md + architecture doc再読み込み
  - ドキュメント更新が即座にエージェントの判断に反映される

- **Backpressure Gates**: 品質ゲート通過 → keep | 不通過 → discard & retry
  - lint (GDScript品質) / test (カバレッジ) / review (コンセンサス) / drift-detect

- **Hat System**: 各エージェントが専門ペルソナを宣言
  - gdscript-engineer / code-reviewer / evolution-specialist / ui-artist / architect

- **Disk Is State, Git Is Memory**: ファイルシステムが真実 / Gitが操作履歴

- **Agent Waves**: scatter-gatherパターンの並列処理

## 設定パラメータ

### 必須
- **task** (string): 実装タスク説明

### オプション（デフォルト値）
- **max_iterations**: 3 (最大反復回数)
- **timeout_minutes**: 15 (全体タイムボックス)
- **quality_gates**: ["lint", "test"] (実行するゲート)
- **parallel_agents**: 5 (scatter時の並列数)
- **cost_budget_usd**: 25.0 (API予算)

## オーケストレーション手順

### Step 1: 初期化
```
✓ Fresh Context ロード: CLAUDE.md + 01_System_Architecture.md再読み込み
✓ git stash で現在の変更を退避（ロールバック時の安全性）
✓ max_iterations / timeout 設定
✓ API予算初期化
```

### Step 2: イテレーション Nループ（autoresearch style）
```
WHILE iteration < max_iterations AND elapsed_time < timeout_minutes AND api_cost < budget:

  [Fresh Context再ロード]
  Read CLAUDE.md
  Read 01_System_Architecture.md
  Read 74_Round4_Integration_Analysis.md（新機能は参照）

  [Scatter フェーズ - 5エージェント並列]
  SPAWN gdscript-engineer: コード実装（Fresh Contextを使用）
  SPAWN code-reviewer: 初期レビュー
  SPAWN evolution-specialist: 進化ロジック検証
  SPAWN ui-artist: アニメーション検証
  SPAWN architect: 統合点検証
  WAIT_ALL

  [Gather フェーズ - 結果集約]
  Merge 5エージェント出力 → 統合コード

  [Backpressure Gates実行 - 品質ゲート]
  └─ IF all gates PASS:
     ├─ git add + git commit "[iterate] iteration {n}"
     ├─ iteration += 1
     └─ Continue (or break if goal_met)

  └─ ELSE (1つ以上FAIL):
     ├─ git reset --hard HEAD  # discard
     ├─ Collect error feedback
     └─ Continue next iteration

[Time/Budget Check]
IF remaining_time < 1min OR api_cost >= budget:
  FORCE_EXIT with current_state
```

### Step 3: 完了報告
```json
{
  "success": true/false,
  "iterations_used": N,
  "iterations_max": M,
  "final_commit": "hash",
  "quality_scores": {
    "lint": 98,
    "test": 100,
    "review": 95,
    "drift": 92
  },
  "total_time_seconds": T,
  "api_cost_usd": C,
  "files_modified": [...]
}
```

## Backpressure Gates詳細

### Gate 1: lint (GDScript Linting)
```bash
python3 tools/quality/agnix.py <file>
```
失敗条件: 構文エラー / 命名規約 / 複雑度 > 10 / 未使用変数

### Gate 2: test (GUnit + Coverage)
```bash
godot -s addons/gunit/bin/gunit.py <test>
```
失敗条件: テスト失敗 / カバレッジ < 70%

### Gate 3: review (Agent Consensus)
5エージェント投票 → ≥66% (≥4/5) 承認必要

### Gate 4: drift-detect (Design Drift)
```bash
python3 tools/quality/drift-detect.py --threshold=0.7
```
失敗条件: CLAUDE.md vs 実装の乖離 > 30%

## Waves対応（scatter-gather）

独立タスク複数の場合:
```
[Scatter]
SPAWN gdscript-engineer  # Task A: 実装
SPAWN evolution-specialist  # Task B: 進化ロジック
SPAWN ui-artist  # Task C: スプライト
WAIT_ALL

[Gather]
code-reviewer: 3つを統合レビュー → consensus check
```

## コマンド例

```bash
# デフォルト（3イテレーション、15分、lint+test）
/iterate task="PetAutonomySystem実装"

# 厳密品質（全ゲート有効、2イテレーション）
/iterate \
  task="pet_lifecycle_fsm完成形" \
  max_iterations=2 \
  quality_gates=["lint", "test", "review", "drift-detect"]

# 高速確認（1イテレーション、lintのみ）
/iterate \
  task="expression_system追加" \
  max_iterations=1 \
  timeout_minutes=5 \
  quality_gates=["lint"]
```
