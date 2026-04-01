---
allowed-tools: Bash, Read, Edit, Glob, Grep, TeammateTool
---

# /ship — PetClaw品質ゲート付きコミット・PRコマンド

agentsys /ship パターン + forgecode コスト意識をPetClawに適用。
品質チェック → コミット → PR作成を自動化。

## オーケストレーション手順

### Step 1: 品質ゲート
/lint コマンドの3ツールを実行。
- CRITICAL → 停止、修正を促す
- NEEDS ATTENTION → 警告表示、続行可能
- PASS → そのまま続行

### Step 2: 変更確認
```bash
git status
git diff --stat
```
変更内容のサマリーを確認。

### Step 3: コミット
変更内容に基づいてコミットメッセージを自動生成。
PetClaw規約: `[system] description` フォーマット。
例: `[evolution] Add care miss auto-detection in GameManager`

### Step 4: PR作成（オプション）
ユーザーが要求した場合のみ。
```bash
gh pr create --title "..." --body "..."
```

### Step 5: コスト報告（P2原理）
推定トークン使用量を報告:
- この実装セッションで使用した推定トークン数
- Opus vs Sonnet vs Haiku のモデル使用比率
