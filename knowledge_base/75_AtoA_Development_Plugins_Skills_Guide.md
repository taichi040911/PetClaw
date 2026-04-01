# AtoA サービス開発 プラグイン・スキル徹底ガイド

## 概要
Claude Cowork + Claude Code を活用した PetClaw AtoA サービス開発に必要なプラグイン・スキル・MCP サーバーの包括的ガイド。2026年3月調査時点の情報をベースに、PetClaw プロジェクトの実態に合わせて整理。

---

## 1. 優先度別プラグイン・スキル一覧

### Tier 1: 必須（★★★★★）

#### Agent Teams プラグイン
- **目的**: 複数AIエージェントのオーケストレーション
- **PetClaw適用**: 6エージェント体制（gdscript-engineer, code-reviewer, a2a-designer, evolution-specialist, ui-artist, architect）
- **現状**: `.claude/agents/` に6エージェント定義済み、`.claude/commands/` に7コマンド定義済み
- **インストール**: `claude plugin install agent-teams`
- **活用ポイント**:
  - `/implement` でディスパッチルール（S/M/L）に沿った自動振り分け
  - `/ultrawork` で大規模並列実装（5+ teammates）
  - `/review` でコンセンサスゲート付き相互レビュー

#### Superpowers（Claude Code拡張）
- **目的**: Claude Codeの限界突破 — 並列実行、長時間タスク、高度なファイル操作
- **PetClaw適用**: 22ファイル/7500+行の大規模GDScriptプロジェクトでの一括操作
- **インストール**: `claude plugin install superpowers`
- **活用ポイント**:
  - 複数ファイル同時編集（GameManager ↔ サブシステム間の整合性維持）
  - 長時間ランニングタスク（sprite_pipeline バッチ処理等）

#### Game Development Skill
- **目的**: ゲーム開発特化の知識・パターン提供
- **PetClaw適用**: Godot 4.x / GDScript の最適パターン、FSM設計、シグナル設計
- **インストール**: `claude skill install game-development`
- **活用ポイント**:
  - PetLifecycleFSM の状態遷移最適化
  - PetAutonomySystem の Pulse/Resonance パターン検証
  - エフェクト・アニメーションシステム設計

### Tier 2: 強く推奨（★★★★☆）

#### Memory Plugins（記憶管理）
- **目的**: 会話間の文脈保持、プロジェクト知識の永続化
- **PetClaw適用**: BiologicalMemorySystem のメタ設計、32文書の知識ベース管理
- **現状**: `.auto-memory/` に自動メモリシステム稼働中
- **活用ポイント**:
  - 第一原理（P1-P5）の一貫した適用
  - サブシステム間依存関係の記憶
  - 進化条件・ケアミス閾値等のドメイン知識保持

#### MCP Servers（外部サービス連携）
- **目的**: 外部サービスとの動的ツール連携
- **PetClaw適用**: `tools/quality/petclaw_mcp_server.py` で品質ツール公開済み
- **現在接続済みMCP**:
  - Figma（UI/スプライトデザイン）
  - Canva（アセット生成）
  - Supabase（バックエンド・データ管理）
  - Notion（プロジェクト管理・ドキュメント）
  - Google Drive（ファイル共有）
  - AWS Marketplace（インフラ）
- **未接続だが有用**:
  - Context7（LLM向け最新ドキュメント取得 — Godot 4.x ドキュメント参照に有用）
- **カスタムMCP**: `petclaw_mcp_server.py` が4ツール公開
  - `agent_lint`: エージェント設定検証（26チェック）
  - `deslop`: スロップ検出（13パターン、3フェーズ）
  - `drift`: ドリフト検出（設計↔実装乖離）
  - `stats`: プロジェクト統計

### Tier 3: 推奨（★★★★）

#### Frontend/UI Design Skill
- **目的**: UI/UX設計の知識・レビュー
- **PetClaw適用**: `petclaw_ui_prototype.html` のインタラクティブUI設計
- **活用ポイント**:
  - ペットステータス表示のUX最適化
  - AtoA会話バブルUIデザイン
  - 進化演出のビジュアルフィードバック

---

## 2. PetClaw 既存カスタムツール（自前構築済み）

公開MCP Registryに適切なものが見つからなかったため、以下はすべてプロジェクト内でカスタム構築済み。

### 品質ツール群（`tools/quality/`）
| ツール | 元パターン | 機能 |
|--------|-----------|------|
| `petclaw_agent_lint.py` | agentsys /agnix | 26検証チェック、Agent Teams設定バリデーション |
| `petclaw_deslop.py` | agentsys /deslop | 13パターン3フェーズ、スロップ検出 |
| `petclaw_drift.py` | agentsys /drift-detect | シグナル/システム/ファイル/依存性ドリフト検出 |
| `petclaw_mcp_server.py` | teams-ai-agent MCP | JSON-RPC stdio、4ツール公開 |
| `palette_generator.py` | ui-avatars | Material Design、22形態対応パレット生成 |

### スプライトパイプライン（`tools/sprite_pipeline/`）
- ペット22形態のスプライト量産自動化

### デバッグCLI（`tools/debug_cli/`）
- ゲーム状態のリアルタイム検査・操作

---

## 3. コスト最適化戦略（P2: API Cost is Physics）

### Claude API利用の最適化
- **PULSE_OK パターン**: ペットが満足状態（content）の場合、自律行動のAPI呼び出しをスキップ
- **EthicalSafeguard**: AtoA会話の日次上限管理（API乱用防止）
- **モデル配分**:
  - Opus: a2a-designer, architect（高品質判断が必要な場面）
  - Sonnet: gdscript-engineer, code-reviewer, evolution-specialist, ui-artist（コスト効率）
  - Haiku: バリデーション、lint等の繰り返しタスク

### Cowork セッションでのコスト意識
- `/iterate` コマンドの固定予算ループ（autoresearch-mlx パターン）
- ralph Backpressure Gates で品質ゲート不合格時の無駄な継続を防止
- Disk Is State: メモリではなくファイルに状態を保持し、コンテキストウィンドウ圧迫を回避

---

## 4. 統合アーキテクチャ図

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Cowork Session                  │
│                                                           │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │ Agent Teams  │  │ Superpowers  │  │ Game Dev Skill │  │
│  │ (6 agents)   │  │ (並列/長時間) │  │ (Godot 4.x)   │  │
│  └──────┬──────┘  └──────┬───────┘  └───────┬────────┘  │
│         │                │                   │            │
│  ┌──────┴────────────────┴───────────────────┴──────┐    │
│  │              PetClaw Orchestration                 │    │
│  │  /implement  /review  /ultrawork  /iterate        │    │
│  │  /lint       /ship    /debug                      │    │
│  └──────┬────────────────┬───────────────────┬──────┘    │
│         │                │                   │            │
│  ┌──────┴──────┐  ┌─────┴──────┐  ┌────────┴────────┐  │
│  │ Quality MCP  │  │ Memory     │  │ External MCPs    │  │
│  │ (4 tools)    │  │ (.auto-mem)│  │ Figma/Notion/    │  │
│  │ lint/deslop/ │  │ + Bio Mem  │  │ Supabase/Canva   │  │
│  │ drift/stats  │  │            │  │                   │  │
│  └─────────────┘  └────────────┘  └──────────────────┘  │
│                                                           │
│  ┌───────────────────────────────────────────────────┐   │
│  │                 Hooks (自動検証)                     │   │
│  │  pre-tool-use.sh: class_name検証                    │   │
│  │  post-tool-use.sh: GameManager参照チェック           │   │
│  └───────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│              Godot 4.x Project (16 subsystems)           │
│                                                           │
│  GameManager ─┬─ AtoAConversation ─── ClaudeAPIClient    │
│               ├─ EmotionSystem                            │
│               ├─ LanguageEvolution                        │
│               ├─ EvolutionMechanics ─── EvolutionTree     │
│               ├─ CareActionSystem                         │
│               ├─ BiologicalMemory                         │
│               ├─ PersistentField                          │
│               ├─ PetAutonomySystem (Pulse/Resonance)      │
│               ├─ PetLifecycleFSM (10-state)               │
│               ├─ EthicalSafeguard                         │
│               ├─ EcosystemManager                         │
│               ├─ BreedingSystem                           │
│               ├─ VisualFXSystem                           │
│               └─ SpriteAnimator                           │
└─────────────────────────────────────────────────────────┘
```

---

## 5. PetClaw特化カスタムスキル計画

公開プラグインでカバーできないPetClaw固有の領域に対して、カスタムスキルを作成する。

### 5.1 AtoA会話デザインスキル（`a2a-conversation`）
- **目的**: AtoA会話プロンプトの品質保証・テンプレート管理
- **機能**:
  - 会話プロンプトのP1-P5準拠チェック
  - 感情→言語マッピングの一貫性検証
  - 文法進化ルール適用の自動検査
  - 会話ログ分析（トーン・多様性・創発性スコアリング）

### 5.2 感情リフレクションスキル（`emotion-reflection`）
- **目的**: 感情システムの設計・デバッグ・チューニング支援
- **機能**:
  - EmotionSystem パラメータのバランス検証
  - ケアアクション→感情変化のシミュレーション
  - 感情→性格進化の長期トレンド予測
  - 「感情が死んでいる」状態の検出・修正提案

### 5.3 生物模倣記憶スキル（`biological-memory`）
- **目的**: BiologicalMemorySystem の設計・テスト・最適化
- **機能**:
  - 海馬→大脳皮質の記憶固定化パス検証
  - Hebbian強化の適切性チェック
  - 記憶検索の関連度スコアリング精度評価
  - 睡眠時記憶統合のシミュレーション

### 5.4 進化条件バリデータスキル（`evolution-validator`）
- **目的**: EvolutionTree の22形態・15条件の整合性保証
- **機能**:
  - 到達不可能な進化パスの検出
  - ケアミス条件とダークルートの整合性チェック
  - 進化条件バランスの統計分析
  - プレイヤー体験シミュレーション（平均到達時間推定）

---

## 6. 推奨セットアップ手順

### Step 1: プラグインインストール（Claude Code）
```bash
# Tier 1
claude plugin install agent-teams
claude plugin install superpowers
claude skill install game-development

# Tier 2（必要に応じて）
claude plugin install memory-enhanced
```

### Step 2: MCP サーバー起動
```bash
# PetClaw品質MCP
cd tools/quality && python petclaw_mcp_server.py

# Context7（Godot 4.x ドキュメント参照用、インストール後）
# npx -y @context7/mcp
```

### Step 3: カスタムスキル配置
```
.claude/skills/
├── a2a-conversation/
│   └── SKILL.md
├── emotion-reflection/
│   └── SKILL.md
├── biological-memory/
│   └── SKILL.md
└── evolution-validator/
    └── SKILL.md
```

### Step 4: フック有効化確認
```bash
# pre-tool-use: class_name検証
chmod +x .claude/hooks/pre-tool-use.sh

# post-tool-use: GameManager参照チェック
chmod +x .claude/hooks/post-tool-use.sh
```

---

## 7. 今後の拡張方針

1. **カスタムMCPサーバー拡張**: 品質ツール以外に、AtoA会話分析ツール、進化シミュレーターもMCPとして公開
2. **Notion連携深化**: 設計文書（knowledge_base）をNotionと双方向同期
3. **Supabase活用**: ペットデータ・会話ログのクラウドバックアップ、マルチプレイヤー基盤
4. **Figma連携**: UIプロトタイプ ↔ GDScript UIコード自動同期
5. **スケジュールタスク**: 定期的な品質チェック（/lint）の自動実行

---

*作成: 2026-04-01 | PetClaw Round 5 | 参照元: ユーザー調査資料（2026年3月最新）+ MCP Registry調査結果*
