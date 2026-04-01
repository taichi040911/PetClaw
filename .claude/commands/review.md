---
allowed-tools: TeammateTool
---

# /review — PetClaw相互レビュー

変更されたコードを複数のエージェントで相互レビューする。
o-m-cc の「相互レビューパターン」 + claude-octopus の「コンセンサスゲート」を適用。

## オーケストレーション手順

### Step 1: チーム作成
```
spawnTeam: "review"
```

### Step 2: 並列レビュー
```
spawnTeammate: code-reviewer
  prompt: |
    agents/code-reviewer.md の指示に従い、GDScriptコードの品質レビュー。
    発見した問題を architect teammate にもメッセージで共有。

spawnTeammate: architect
  prompt: |
    agents/architect.md の指示に従い、アーキテクチャ整合性レビュー。
    - シグナル設計の正しさ
    - 依存関係マトリクスとの一致
    - 第一原理との整合
    発見した問題を code-reviewer teammate にもメッセージで共有。
```

### Step 3: 議論・合意
- code-reviewer と architect が互いの発見をメッセージで議論
- 矛盾がある場合は議論して合意に到達する
- コンセンサス: 両者が PASS なら OK、どちらかが FAIL なら修正要

### Step 4: Lead統合
- 両者のレポートを統合して最終レビュー結果を作成
- FAIL がある場合は修正箇所を明示
