---
allowed-tools: Bash, Read, Glob, Grep
---

# /lint — PetClaw品質チェック統合コマンド

agentsys /agnix + /deslop + /drift-detect のPetClaw版。
3つの品質ツールを順番に実行し、統合レポートを生成する。

## 実行手順

### Step 1: Agent Lint（agnix相当）
```bash
python3 tools/quality/petclaw_agent_lint.py --project-root . --json
```
エージェント定義・コマンド定義・CLAUDE.mdの整合性を検証。

### Step 2: GDScript Deslop（deslop相当）
```bash
python3 tools/quality/petclaw_deslop.py --project-root . --json
```
AI生成GDScriptの品質劣化パターンを3フェーズで検出。

### Step 3: Design Drift（drift-detect相当）
```bash
python3 tools/quality/petclaw_drift.py --project-root . --json
```
設計文書と実装の乖離を検出。

### Step 4: 統合レポート
3ツールの結果を統合し、以下のフォーマットで報告:

```
## PetClaw Quality Report
### Agent Configuration: X/Y rules passed
### Code Quality: X files, Y issues (Z FAIL)
### Design Drift: X checks, Y drifts detected
### Overall: PASS / NEEDS ATTENTION / CRITICAL
```

FAIL が1つでもあれば CRITICAL、WARN のみなら NEEDS ATTENTION、なければ PASS。
