---
allowed-tools: TeammateTool
---

# /debug — PetClaw仮説競合デバッグ

バグを複数エージェントの「仮説競合パターン」で特定する。
o-m-cc記事の「debugger × 2-3 で仮説競合、偏りを排除」を適用。

## オーケストレーション手順

### Step 1: チーム作成
```
spawnTeam: "debug"
```

### Step 2: 仮説生成（並列）
```
spawnTeammate: gdscript-engineer
  prompt: |
    バグの原因仮説を3つ以上立てる。
    コードを読んで各仮説の根拠を示す。
    他の teammate にメッセージで仮説を共有。

spawnTeammate: architect
  prompt: |
    システム統合の観点からバグの原因仮説を立てる。
    シグナル設計、依存関係、データフローのどこで問題が起きうるか。
    他の teammate にメッセージで仮説を共有。
```

### Step 3: 仮説検証・議論
- 両者が互いの仮説をメッセージで議論
- 矛盾する仮説は根拠を比較して絞り込む
- petclaw_cli.py の debug CLI で状態を検証

### Step 4: 修正
```
spawnTeammate: gdscript-engineer  (必要に応じて追加spawn)
  prompt: |
    合意された原因に基づいて修正を実装。
    修正後は code-reviewer に共有。
```

### Step 5: Lead確認
- 修正が正しいことを確認
- 再発防止策（テスト追加、ドキュメント更新）を検討
