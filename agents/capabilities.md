---
name: capabilities
---

# PetClaw Agent Teams -- 拡張エージェント ディスパッチ戦略

## エージェント一覧

### コアチーム（.claude/agents/）
既存の6エージェント。プロジェクト全体の実装・レビュー・設計を担当。

| エージェント | model | memory | 得意領域 |
|-------------|-------|--------|---------|
| **gdscript-engineer** | sonnet | project | GDScript実装、GameManager統合、セーブ/ロード |
| **code-reviewer** | sonnet | project | クロスシステム整合性、GDScript品質、PetClaw固有ルール |
| **a2a-designer** | opus | project | AtoA会話設計、言語進化、感情モデル、プロンプト設計 |
| **evolution-specialist** | sonnet | project | 進化ツリー、ケアシステム、ダーク進化、ライフサイクル |
| **ui-artist** | sonnet | project | UIプロトタイプ、スプライト、アニメーション、UX |
| **architect** | opus | project | システム統合、アーキテクチャ文書、第一原理、技術選定 |

### 専門チーム（agents/）
ゲームプレイ固有の専門エージェント。ペットAI、バトル、言語評価、ビジュアルテスト、最適化を担当。

| エージェント | model | memory | 得意領域 |
|-------------|-------|--------|---------|
| **pet-brain** | sonnet | project | ペットAI脳、性格、言語進化、会話戦略、感情応答 |
| **battle-orchestrator** | sonnet | -- | バトル進行、勝敗判定、スコアリング、バランス管理 |
| **language-judge** | haiku | -- | 言語品質リアルタイム評価、接尾辞/語彙/文法スコアリング |
| **visual-tester** | sonnet | -- | MCP駆動UI検証、スクリーンショットベースのテスト |
| **karpathy-optimizer** | opus | project | Karpathy Loop最適化、メトリクス分析、パラメータチューニング |

## ディスパッチ判断フロー

```
タスクを受け取る
  |
  +-- ペットの発話・行動に関する？ ------> pet-brain
  |
  +-- バトルシステムに関する？ ----------> battle-orchestrator + pet-brain x2 + language-judge
  |
  +-- 言語品質の評価が必要？ -----------> language-judge
  |
  +-- UI/画面の視覚的検証？ ------------> visual-tester
  |
  +-- メトリクス分析・最適化？ ----------> karpathy-optimizer
  |
  +-- GDScript実装？ ------------------> gdscript-engineer (.claude/agents/)
  |
  +-- コードレビュー？ -----------------> code-reviewer (.claude/agents/)
  |
  +-- AtoA/言語設計の議論？ ------------> a2a-designer (.claude/agents/)
  |
  +-- 進化/ケア/生死？ -----------------> evolution-specialist (.claude/agents/)
  |
  +-- UI実装？ -------------------------> ui-artist (.claude/agents/)
  |
  +-- アーキテクチャ判断？ --------------> architect (.claude/agents/)
  |
  +-- 大規模タスク？ -------------------> /ultrawork (全エージェント動員)
```

## チーム間連携パターン

### パターン1: 会話品質改善ループ
```
karpathy-optimizer (メトリクス分析)
  -> a2a-designer (プロンプト修正方針)
  -> pet-brain (会話生成テスト)
  -> language-judge (品質スコアリング)
  -> karpathy-optimizer (効果検証)
```

### パターン2: バトルシステム開発
```
architect (設計)
  -> gdscript-engineer (実装)
  -> battle-orchestrator (バトルロジック検証)
  -> language-judge (スコアリング検証)
  -> visual-tester (バトルUI検証)
  -> code-reviewer (コードレビュー)
```

### パターン3: 新ペット性格追加
```
a2a-designer (性格設計)
  -> pet-brain (行動パターン定義)
  -> gdscript-engineer (実装)
  -> language-judge (言語出力検証)
  -> karpathy-optimizer (バランス検証)
```

### パターン4: UI刷新
```
ui-artist (デザイン)
  -> gdscript-engineer (実装)
  -> visual-tester (ビジュアル検証)
  -> code-reviewer (コードレビュー)
```

## モデル選択の根拠

| model | 用途 | 理由 |
|-------|------|------|
| **opus** | karpathy-optimizer, a2a-designer, architect | 複雑な分析・設計判断、長期記憶が必要 |
| **sonnet** | pet-brain, battle-orchestrator, visual-tester, gdscript-engineer 等 | 実装・検証のバランス、コスト効率 |
| **haiku** | language-judge | リアルタイム評価、低レイテンシ必須、コスト最小化 |
