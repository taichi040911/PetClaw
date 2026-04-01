---
allowed-tools: TeammateTool
---

# /ultrawork — PetClaw大規模並列実装

大きな機能やバッチ作業を5+エージェントで並列実行する。
o-m-cc の「大規模並列パターン」 + agent-orchestrator の「issue単位隔離」を適用。

## オーケストレーション手順

### Step 1: チーム作成 + タスク登録
```
spawnTeam: "ultrawork"
TaskCreate で全タスクを登録、依存関係を設定
```

### Step 2: 設計フェーズ
```
spawnTeammate: architect
  prompt: |
    全タスクの設計概要と依存関係を整理。
    各担当エージェントへの作業指示を作成。
    完了したら Lead にメッセージ。
```

### Step 3: 並列実装フェーズ
```
# 独立タスクは全て同時 spawn
spawnTeammate: gdscript-engineer
  prompt: 担当タスクのGDScript実装。完了したら Lead にメッセージ。

spawnTeammate: a2a-designer
  prompt: AtoA/感情/言語関連タスクの実装。完了したら Lead にメッセージ。

spawnTeammate: evolution-specialist
  prompt: 進化/ケア/ライフサイクル関連タスクの実装。完了したら Lead にメッセージ。

spawnTeammate: ui-artist
  prompt: UI/スプライト/アニメーション関連タスクの実装。完了したら Lead にメッセージ。
```

### Step 4: 統合レビュー
```
spawnTeammate: code-reviewer
  prompt: |
    全実装のクロスシステム整合性レビュー。
    問題を発見したら該当 teammate にメッセージで修正依頼。
    最終結果を Lead にレポート。
```

### Step 5: Lead完了判定
- 全タスク完了を確認
- アーキテクチャ文書の更新を確認
- 知識ベースへの記録
