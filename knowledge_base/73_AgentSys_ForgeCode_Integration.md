# 73. AgentSys + ForgeCode 統合分析

## 73.1 リポジトリ概要

### agent-sh/agentsys
- AIエージェント・オーケストレーション・マーケットプレイス
- 19プラグイン、47エージェント、40スキル
- 5プラットフォーム対応（Claude Code, OpenCode, Codex CLI, Cursor, Kiro）
- JavaScript/Node.js、87モジュール、3,583テスト
- Key features: /next-task (全自動パイプライン), /agnix (385ルールリント), /deslop (AIスロップ3フェーズ検出), /drift-detect (計画vs実装乖離検知)
- Sonnet + agentsys = raw Opus同等品質で40-83%コスト削減

### antinomyhq/forgecode
- Rust製AIコーディングエージェント（25クレート、61,000行）
- マルチLLMプロバイダ対応
- MCP (Model Context Protocol) ネイティブ統合
- セマンティックコード検索（ベクトルベース）
- Restricted Shell Mode（セキュア実行）
- forge.yaml でカスタムワークフロー定義

## 73.2 PetClaw統合設計

### A. agnix → PetClaw Agent Lint (petclaw_agent_lint.py)
agentsysの385ルールリントをPetClaw Agent Teams向けにカスタマイズ。
- エージェント定義の必須フィールド検証（name, tools, model, memory）
- コマンド定義の構造チェック（Step順序、TeammateTool使用）
- GDScript規約準拠チェック（class_name, 型注釈, to_dict/from_dict）
- capabilities.mdとの整合性（エージェント一覧の一致）

### B. deslop → GDScript Slop Detector (petclaw_deslop.py)
AI生成GDScriptの品質劣化パターンを3フェーズで検出。

**Phase 1: パターン検出（正規表現）**
- 過剰コメント（コード行数 < コメント行数）
- 冗長print文（デバッグ残り）
- 空のmatch分岐
- 未使用変数（var x = ... 後に参照なし）

**Phase 2: 構造分析**
- 過剰ネスト（4段以上）
- 関数長超過（50行以上）
- PetClaw固有: GameManager.instance null チェック漏れ

**Phase 3: LLM判定（オプション）**
- 不自然な命名パターン
- ドキュメントの水増し

### C. drift-detect → Design Doc Drift Checker (petclaw_drift.py)
knowledge_base/00_System_Architecture_Overview.md と実際のGDScript実装の乖離を検出。

チェック対象:
- シグナル定義: 文書に記載のシグナル → 実コードに存在するか
- システム一覧: 文書の依存関係マトリクス → 実ファイル存在確認
- 関数シグネチャ: 文書記載のAPI → 実装と一致するか
- ファイル構成: 文書のディレクトリ構成 → 実際の構成

### D. forge.yaml風ワークフロー → Agent Teamsコマンド強化
forgecodeのカスタムコマンド定義パターンをAgent Teamsに応用。
- /lint コマンド追加（agnix + deslop + drift-detect統合）
- /ship コマンド追加（agentsys /ship パターン: 品質ゲート→コミット→PR）
- /cost コマンド追加（forgecodeのAPIコスト追跡 → PetClaw P2原理運用）

### E. モデル段階割り当て最適化
agentsysのベンチマーク知見をAgent Teamsに適用:
- Opus: architect, a2a-designer（複雑推論、設計判断）
- Sonnet: gdscript-engineer, code-reviewer, evolution-specialist, ui-artist（実装、検証）
- Haiku: 機械的タスク（スプライト一括生成、フォーマットチェック、単純grep）

→ 既存設計と一致。agentsysの40-83%コスト削減はPetClawでも有効

## 73.3 実装済みツール

### tools/quality/petclaw_agent_lint.py
agnix inspired — エージェント定義・コマンド定義・GDScript規約のリント

### tools/quality/petclaw_deslop.py
deslop inspired — AI生成GDScriptのスロップパターン3フェーズ検出

### tools/quality/petclaw_drift.py
drift-detect inspired — 設計文書と実装の整合性チェック

### .claude/commands/lint.md
3ツール統合実行コマンド

### .claude/commands/ship.md
品質ゲート → コミット → PR 自動化コマンド

## 73.4 相乗効果マトリクス

| PetClaw課題 | agentsys知見 | forgecode知見 | 統合効果 |
|------------|-------------|-------------|---------|
| Agent品質保証 | /agnix 385ルール | forge.yaml検証 | petclaw_agent_lint |
| コード品質 | /deslop 3フェーズ | Restricted Shell | petclaw_deslop |
| 設計整合性 | /drift-detect | セマンティック検索 | petclaw_drift |
| 開発効率 | /next-task自動化 | マルチワークフロー | /lint + /ship |
| コスト最適化 | モデル段階割り当て | APIコスト追跡 | P2原理の運用化 |
| セキュリティ | — | Restricted Shell | GDScript sandbox |

## 73.5 参考リンク
- https://github.com/agent-sh/agentsys
- https://github.com/antinomyhq/forgecode
