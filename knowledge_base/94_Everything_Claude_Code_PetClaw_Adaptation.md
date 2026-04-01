# KB94: Everything Claude Code (ECC) — PetClaw活用ガイド

## リポジトリ概要

**Everything Claude Code (ECC)** — https://github.com/affaan-m/everything-claude-code
- Anthropicハッカソン受賞、50K+スター、6K+フォーク
- 147プロダクションスキル + 36専門エージェント + 68コマンド + 20+フック
- 12言語エコシステム対応（TypeScript, Python, Go, Rust, C++等）
- Claude Code / Cursor / OpenCode / Codex 等マルチハーネス対応

---

## PetClawへの活用ポイント

### 1. スキルファースト・ワークフロー（最重要）

ECC v1.9はコマンドからスキルへ移行中。PetClawもスキルを中心に据えるべき。

**ECC → PetClaw マッピング:**

| ECC スキル | PetClaw 相当 | 用途 |
|-----------|-------------|------|
| continuous-learning-v2 | biological-memory | セッション間の学習蓄積 |
| autonomous-loops | Ralph Loop統合 | 自律改善ループ |
| security-scan | evolution-validator | 進化ツリー22形態検証 |
| cost-aware-llm-pipeline | P2コスト管理 | $0.50/日会話予算 |
| mcp-server-patterns | PetClaw Quality MCP | カスタムMCPサーバー設計 |
| agent-harness-construction | Agent Teams | 6エージェント構成 |
| tdd-workflow | GDScriptテスト | テスト駆動開発 |

### 2. フック戦略（品質ゲート自動化）

ECC式のhooks.jsonパターンをPetClawに適用：

```json
{
  "PreToolUse": [
    {
      "matcher": "Write && path contains 'scripts/'",
      "hooks": [{
        "type": "command",
        "command": "node scripts/petclaw-class-name-check.js",
        "async": false
      }],
      "id": "pre:write:class-name-enforce",
      "description": "GDScriptファイルにclass_nameが必ず宣言されているか検証"
    },
    {
      "matcher": "Edit && path contains 'save'",
      "hooks": [{
        "type": "command",
        "command": "node scripts/petclaw-save-load-validator.js",
        "async": true,
        "timeout": 10
      }],
      "id": "post:edit:save-load-validation",
      "description": "to_dict/from_dict整合性チェック"
    }
  ]
}
```

**ECC Tips:**
- `ECC_DISABLED_HOOKS` 環境変数でテスト時にフックを無効化可能
- `async: true` + `timeout: 10` で非同期フックがブロックしない
- PreToolUse（事前防止）とPostToolUse（事後検証）を組み合わせる

### 3. エージェント構成の高度化

ECC は28+専門エージェントを持つ。PetClawの6エージェントに適用：

**推奨アップグレード:**
- `gdscript-engineer` → ECC式にYAMLフロントマター付き `.md` で定義
- `code-reviewer` → ECC の `code-reviewer` + `security-reviewer` パターンを参考
- `architect` → ECC の `planner` + `architect` 分離パターン
- 新規追加候補: `loop-operator`（Ralph Loop監視）、`doc-updater`（KB自動更新）

**エージェント定義テンプレート（ECC式）:**

```markdown
---
name: gdscript-engineer
description: GDScript実装専門。型注釈・class_name・シグナル設計を厳守
model: sonnet
tools: [Read, Write, Edit, Bash, Grep, Glob]
memory: project
---

## 役割
GDScriptコードの実装・修正・最適化を担当。

## 制約
- 全クラスに class_name を宣言
- 型注釈を必ず使用
- GameManager.instance 経由でシステム参照
- to_dict() / from_dict() でセーブ/ロード対応
- シグナルベースの疎結合設計

## 品質基準
- P2: API Cost is Physics を常に意識
- P5: Complexity is Debt — 不要な抽象化を避ける
```

### 4. MCP サーバーパターン

ECC の27+ MCP設定を参考に、PetClaw専用MCPを強化：

```json
{
  "petclaw-game-state": {
    "command": "python",
    "args": ["tools/quality/petclaw_mcp_server.py"],
    "description": "ペット状態・進化ツリー・会話履歴をクエリ"
  },
  "petclaw-evolution-validator": {
    "command": "python",
    "args": ["tools/quality/evolution_validator_mcp.py"],
    "description": "22形態の到達可能性・ケアパス整合性を検証"
  },
  "petclaw-cost-tracker": {
    "command": "python",
    "args": ["tools/quality/cost_tracker_mcp.py"],
    "description": "API使用量・日次予算残高をリアルタイム監視"
  }
}
```

### 5. ルール整理（rules/）

ECC の言語別ルール構成を PetClaw に適用：

```
.claude/rules/petclaw/
  gdscript.md         — class_name, 型注釈, シグナル設計
  save-load.md        — to_dict/from_dict, atomic write, GameManager
  a2a-protocol.md     — AtoA会話形式, トークン予算, コスト追跡
  emotion-system.md   — 感情状態制約, リフレクションメカニクス
  evolution-tree.md   — 22形態到達可能性, ケア vs ダークパス
  memory-storage.md   — 生物模倣記憶, Hebbian学習, ストレージ原子性
  ecosystem-rules.md  — ペット相互作用, 環境影響, 交配
  language-evolution.md — 文法ルール, 構文進化, コミュニケーションギャップ
  ui-animation.md     — スプライト要件, フレーム数, パーティクル
  security.md         — APIキー管理, 環境変数, .gitignore
```

### 6. Continuous Learning（セッション間学習）

ECC の `continuous-learning-v2` スキルの核心：

- セッション終了時にパターンを自動抽出
- 新しいスキルファイルとして保存
- 次回セッションで自動適用

**PetClaw実装:**
```
# セッション後に実行
/evolve

# 自動キャプチャ対象:
- うまく機能したAtoAプロンプト構造
- 感情リフレクションの有効パターン
- 進化パスのエッジケース
- メモリストレージの最適化結果
- 言語創発の新パターン
```

### 7. コンテキスト予算管理

ECC の `token-budget-advisor` パターンをPetClawに：

```
## PetClawセッション別トークン配分

| 作業領域 | トークン予算 | 備考 |
|---------|------------|------|
| AtoA会話生成 | 8K | プロンプト+レスポンス |
| 感情リフレクション | 3K | 状態評価+更新 |
| 進化検証 | 2K | ツリー整合性チェック |
| 記憶検索 | 2K | Hebbian検索+登録 |
| UI/スプライト反復 | 5K | ビジュアル調整 |
| テスト・検証 | 4K | 品質ゲート |
| 合計 | ~24K/セッション | |
```

### 8. Conventional Commits（バージョン管理）

ECC の commitlint パターン：

```javascript
// commitlint.config.js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [2, 'always', [
      'a2a', 'emotion', 'evolution', 'memory',
      'breeding', 'ui', 'save-load', 'economy',
      'petbook', 'language', 'ecosystem', 'lifecycle'
    ]],
    'type-enum': [2, 'always', [
      'feat', 'fix', 'refactor', 'docs',
      'test', 'chore', 'perf', 'validate'
    ]]
  }
};

// コミット例:
// feat(a2a): implement multi-turn conversation history
// fix(emotion): correct reflection loop bias
// validate(evolution): add 22-form reachability test
// perf(petbook): optimize PostCard object pool
```

---

## すぐに試せるアクション

### A. ECC インストール（Code側）
```bash
claude plugin install everything-claude-code
```
→ 147スキル+36エージェント+フック群がプロジェクトに追加される

### B. PetClaw用にカスタマイズ
```text
everything-claude-codeプラグインをインストールした上で、
PetClawプロジェクト専用にカスタマイズしてください。
特にGDScript用のルール、AtoA会話用のスキル、進化検証用のフックを設定。
```

### C. Ralph Loop + ECC の組み合わせ
```text
everything-claude-codeのautonomous-loopsスキルとRalph Loopを統合して、
PetBookの投稿品質を自動改善するループを設定してください。
--max-iterations 10 --completion-promise "PETBOOK_QUALITY_LOOP_DONE"
```

### D. Hooks 導入
```text
everything-claude-codeのhooksパターンを参考に、PetClaw用のhooks.jsonを作成してください。
GDScriptのclass_name検証、to_dict/from_dict整合性チェック、APIキー漏洩防止を含めて。
```

---

## ECC リポジトリ内の必読ファイル

| ファイル | 内容 | PetClaw関連度 |
|---------|------|-------------|
| the-shortform-guide.md | Tips集（スキル・コマンド・フック・MCP・ルール・メモリ） | ★★★ |
| the-longform-guide.md | トークン最適化・メモリ永続化・検証ループ・並列化 | ★★★ |
| the-security-guide.md | 攻撃ベクトル・サンドボックス・APIキー管理 | ★★ |
| skills/autonomous-loops/ | 自律ループ設計パターン | ★★★ |
| skills/continuous-learning-v2/ | セッション間学習 | ★★★ |
| skills/mcp-server-patterns/ | カスタムMCPサーバー設計 | ★★ |
| agents/ | 36エージェント定義の参考実装 | ★★ |
| hooks/hooks.json | 20+フック定義の完全例 | ★★★ |
| examples/CLAUDE.md | プロジェクトレベルCLAUDE.mdテンプレート | ★★ |

---

> ECC は PetClaw の Agent Teams / Ralph Loop / カスタムスキル / フック / MCP を
> プロダクションレベルに引き上げるための最良の参考実装。
> 「設計はCowork、実装はCode + ECC」が最強パターン。
