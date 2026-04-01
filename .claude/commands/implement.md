---
allowed-tools: TeammateTool
---

# /implement — PetClaw機能実装オーケストレーション

ユーザーが指定した機能をマルチエージェントで実装する。

## オーケストレーション手順

### Step 1: チーム作成
```
spawnTeam: "implement"
```

### Step 2: 設計フェーズ（並列）
```
spawnTeammate: architect
  prompt: |
    agents/architect.md の指示に従い、ユーザーが要求した機能の設計を行う。
    - 影響を受けるシステムの特定
    - シグナル設計
    - 依存関係の確認
    設計結果を gdscript-engineer と a2a-designer にメッセージで共有すること。

spawnTeammate: evolution-specialist  (進化関連の場合のみ)
  prompt: |
    agents/evolution-specialist.md の指示に従い、進化システムへの影響を分析。
    結果を architect にメッセージで共有。
```

### Step 3: 実装フェーズ（設計完了後）
```
spawnTeammate: gdscript-engineer
  prompt: |
    agents/gdscript-engineer.md の指示に従い、architect の設計に基づいてGDScript実装。
    実装完了後、code-reviewer にメッセージで変更内容を共有すること。

spawnTeammate: a2a-designer  (会話/感情/言語関連の場合)
  prompt: |
    agents/a2a-designer.md の指示に従い、AtoA/感情/言語の実装。
    変更箇所を gdscript-engineer と code-reviewer に共有。
```

### Step 4: レビューフェーズ
```
spawnTeammate: code-reviewer
  prompt: |
    agents/code-reviewer.md の指示に従い、実装されたコードをレビュー。
    - クロスシステム整合性
    - GDScript品質
    - PetClaw固有ルール
    問題を発見したら gdscript-engineer にメッセージで修正依頼。
    最終結果を Lead にレポート。
```

### Step 5: Lead統合
- 全 teammate のレポートを統合
- アーキテクチャ文書の更新を確認
- 知識ベースへの記録
