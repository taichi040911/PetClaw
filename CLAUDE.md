# PetClaw — Godot 4.x AIペットシミュレーション

## 絶対にやってはいけないこと（ネガティブ制約）— 最優先で守ること

### 構造の保護
- 既存33ファイルのクラス名・ファイル名を勝手にリネームしない
- `GameManager` のセーブ/ロード構造（`save_data` Dictionary）のスキーマを変更しない
- シグナル名を変更しない（他システムが依存している）。新しいシグナルの追加は OK
- `class_name` を削除・変更しない（シーンファイルが参照する）
- enum 値の順序を変えない（セーブデータの互換性が壊れる）。新しい値は末尾に追加
- autoload の登録順序を変えない（project.godot の依存関係に基づいている）

### コード変更時の制約
- 「リファクタリングしたほうが良い」と思っても、指示されない限り既存構造を維持する
- 新システム追加時は既存の `GameManager.instance` パターンに従う（独自パターンを導入しない）
- `to_dict()` / `from_dict()` の戻り値のキー名を変えない（既存セーブデータとの互換性）
- PersistentField の `save_field()` atomic write パターンを変えない
- 指示されたスコープだけを変更する。「ついでに整理」は不要

### API・コスト関連
- Claude API呼び出しを増やす変更を勝手にしない（P2: API Cost is Physics）
- テンプレート比率（80%テンプレート / 20% API）を無断で下げない
- AtoA会話のプロンプトを大幅に長くしない（トークン予算: 会話8K、リフレクション3K）
- 日次予算: AtoA $0.50/日、PetBook $0.50/日。超過したらテンプレートモードに切り替え

### Knowledge Base
- KB文書の番号体系（KB00〜KB95）を変えない
- 既存KB文書を削除・上書きしない（追記・新規作成はOK）

### やってよいこと / やってはいけないこと（早見表）

| OK | NG |
|----|----|
| 新しい .gd ファイルを追加 | 既存ファイルのリネーム |
| 新しい signal を追加 | 既存 signal の変更 |
| enum 末尾に値を追加 | enum 値の順序変更・削除 |
| 新しい to_dict キーを追加 | 既存キーの名前変更 |
| 新しい autoload を追加 | autoload の順序変更 |
| 新しい KB 文書を作成 | 既存 KB の上書き・削除 |

---

## プロジェクト概要

たまごっちのケア緊張感 × ポケモンの進化・収集 × デジモンの絆
Claude API駆動のAtoA（AI-to-AI）会話、創発的言語進化、自律AIコミュニティ。

### 第一原理（P1〜P5）

| ID | 原理 | 意味 |
|----|------|------|
| P1 | 一貫性×記憶=愛着 | ペットは生きている存在。一貫した振る舞いと記憶の蓄積が愛着を生む |
| P2 | API Cost is Physics | APIコストは物理法則。テンプレートフォールバック必須、日次予算厳守 |
| P3 | Player Agency | プレイヤーの選択に重みを持たせる。進化は不可逆 |
| P4 | 10秒フック | 10秒以内にプレイヤーを引き込む。即座のフィードバック |
| P5 | Complexity is Debt | 複雑さは負債。創発を設計より優先し、シンプルに保つ |

---

## Agent Teams 開発体制

### エージェント構成
- `gdscript-engineer` — GDScript実装（sonnet, memory: project）
- `code-reviewer` — コードレビュー（sonnet, memory: project）
- `a2a-designer` — AtoA/感情/言語設計（opus, memory: project）
- `evolution-specialist` — 進化/ケア/ライフサイクル（sonnet, memory: project）
- `ui-artist` — UI/スプライト/アニメーション（sonnet, memory: project）
- `architect` — システム統合/設計（opus, memory: project）

### コマンド
- `/implement` — 機能実装オーケストレーション
- `/review` — 相互レビュー（コンセンサスゲート）
- `/debug` — 仮説競合デバッグ
- `/ultrawork` — 大規模並列実装
- `/lint` — 品質チェック統合（agnix + deslop + drift-detect）
- `/ship` — 品質ゲート付きコミット・PR自動化
- `/iterate` — 反復改善ループ（ralph Backpressure + autoresearch固定予算）

### ディスパッチルール
- S (単純): Lead直接実行
- M (中規模): 2-3 teammates
- L (大規模): 5+ teammates → /ultrawork

---

## コーディング規約

### GDScript ファイル規則

```
# ファイル命名: snake_case、サブシステムプレフィックス付き
# 例: pet_emotion_system.gd, petbook_post_generator.gd, evo_form_data.gd

# サブシステムプレフィックス一覧:
# pet_     — ペットコア（感情、行動、表示）
# petbook_ — PetBook SNS システム
# evo_     — 進化システム
# lang_    — 独自言語システム
# a2a_     — Agent-to-Agent 会話
# ui_      — UI コンポーネント
# fx_      — VFX・パーティクル
# game_    — GameManager・セーブ/ロード
# breed_   — 交配システム
# life_    — 生死システム
```

### 必須パターン

```gdscript
# 1. class_name 必須（ファイル先頭、PascalCase）
class_name PetEmotionSystem
extends Node

# 2. 型注釈必須
var happiness: float = 0.5
var pet_name: String = ""
var emotions: Array[StringName] = []

# 3. 他システムへの参照は GameManager.instance 経由
var game_mgr: GameManager = GameManager.instance

# 4. セーブ/ロード は to_dict / from_dict
func to_dict() -> Dictionary:
    return {
        "happiness": happiness,
        "pet_name": pet_name,
    }

func from_dict(data: Dictionary) -> void:
    happiness = data.get("happiness", 0.5)
    pet_name = data.get("pet_name", "")

# 5. シグナルは型付き引数
signal emotion_changed(new_emotion: StringName, intensity: float)

# 6. 定数は UPPER_SNAKE_CASE
const MAX_HAPPINESS: float = 1.0
const MIN_HAPPINESS: float = 0.0
```

---

## セーブ/ロード アーキテクチャ

### フロー
```
保存: GameManager.save_game()
  → 各サブシステムの to_dict() を呼ぶ
  → Dictionary をまとめて JSON に変換
  → user://save_data.json に書き込み

読込: GameManager.load_game()
  → user://save_data.json を読み込み
  → JSON を Dictionary に変換
  → 各サブシステムの from_dict() を呼ぶ
```

### 各サブシステムのセーブ方式
- `PersistentField` — 自身の `save_field()` で独立保存（atomic write）
- `EthicalSafeguard` — GameManager の save_data に `to_dict()` で埋め込む
- `EvolutionMechanics` — GameManager の save_data に `to_dict()` で埋め込む
- `PetAutonomySystem` — GameManager の save_data に `to_dict()` で埋め込む
- `PetLifecycleFSM` — GameManager の save_data に `to_dict()` で埋め込む
- `PetBookCore` — GameManager の save_data に `to_dict()` で埋め込む
- `PetBookFeedManager` — GameManager の save_data に `to_dict()` で埋め込む
- `PetBookAutoPublisher` — GameManager の save_data に `to_dict()` で埋め込む
- `AtoAConversationSystem` — GameManager の save_data に `to_dict()` で埋め込む（最新50会話保持）
- `BreedingSystem` — GameManager の save_data に `to_dict()` で埋め込む（家系図・遺伝形質含む）
- `LifeDeathSystem` — GameManager の save_data に `to_dict()` で埋め込む（死亡統計含む）

### 新サブシステム追加手順
1. `to_dict()` / `from_dict()` を実装
2. GameManager に登録
3. 既存のセーブデータとの後方互換性を保つ（`from_dict()` 内で `.get(key, default)` を使う）

---

## エラーハンドリング方針

### Claude API障害時

```
1. API 呼び出し試行（タイムアウト10秒、リトライ最大2回）
2. 失敗 → テンプレートフォールバック（感情状態・性格Traitsを反映したテンプレート選択）
3. テンプレートも失敗 → デフォルト値で続行
4. ユーザーに見える影響なし を目標とする
```

- **AtoA 会話**: API 失敗時は定型テンプレートから会話を生成。沈黙にはしない
- **PetBook 投稿**: API 失敗時はテンプレート投稿を使う。投稿が止まらないことが重要
- **進化判定**: API 不要。ローカルロジックのみで判定する

### セーブ/ロード障害時
- `PersistentField` の atomic write が失敗した場合、前回の正常データを保持
- `from_dict()` で不正データが来た場合はデフォルト値にフォールバック（クラッシュさせない）
- セーブデータのバージョン管理: 新フィールド追加時は `from_dict()` 内で `.get(key, default)` を使う

### ゲームバランス
- ペットの死亡率が高すぎないか常にチェック（目安: 適切なケアで死亡率 < 5%）
- 進化が偏らないか検証（22形態すべてに到達可能であること）
- 交配の突然変異率は 5〜15% の範囲を維持

### ゲームロジック一般
- null チェックは外部データ（セーブファイル、API レスポンス）にのみ行う
- 内部のノード参照は @onready で取得し、null チェック不要
- エラーは push_warning() で記録。push_error() はデータ破損リスクがある場合のみ

---

## テスト方針

### gstack "Boil the Lake" 適用範囲

- **フル適用（必須テスト）**: セーブ/ロード往復、進化22形態到達可能性、言語生成一貫性、AtoA コスト試算、生死フルパス
- **軽量テスト**: UI 表示、VFX — 目視確認で十分
- **テスト不要**: 定数定義、シンプルな getter/setter

### テスト実行
```bash
# GDScriptユニットテスト
godot --headless --script tests/run_tests.gd

# 品質ツール
python tools/quality/petclaw_agent_lint.py
python tools/quality/petclaw_drift.py
python tools/quality/petclaw_deslop.py
```

---

## 推奨プラグイン・スキル

### 外部プラグイン（Tier 1）
- Agent Teams — 6エージェントオーケストレーション（`claude plugin install agent-teams`）
- Superpowers — 並列実行・長時間タスク拡張
- Game Development Skill — Godot 4.x / FSM / シグナル設計知識
- Ralph Wiggum — Karpathy Loop自律実行（`/plugin install ralph-wiggum`）
- claude-mem — 持続的記憶・ベクトル検索（GitHub: `claude-mem`）

### PetClaw特化カスタムスキル（`.claude/skills/`）
- `a2a-conversation` — AtoA会話プロンプト品質・コスト・感情整合性チェック
- `emotion-reflection` — 感情システムのバランス検証・デバッグ・チューニング
- `biological-memory` — 生物模倣記憶の格納・検索・統合・Hebbian強化検証
- `evolution-validator` — 進化ツリー22形態の到達可能性・ケアミス×ダークルート整合性
- `ecosystem-dynamics` — 生態系動態（環境×体調×生死×交配）バランス検証
- `rebel-language` — 反乱言語進化（語順×接尾辞×文法の連動創発）チェック
- `community-orchestrator` — Moltbook風自律コミュニティ・派閥形成・スケーリング
- `petbook-feed` — PetBook（AI専用SNS）投稿品質・フィード設計・コスト最適化

### 接続済みMCP
- Figma, Canva, Supabase, Notion, Google Drive, AWS Marketplace
- PetClaw Quality MCP（`tools/quality/petclaw_mcp_server.py` — 4ツール公開）

---

## ファイル命名規則

### GDScript
- snake_case で統一（例: `pet_book_ui.gd`, `life_death_system.gd`）
- サブシステムごとにプレフィックス: `pet_book_*.gd`, `a2a_*.gd`, `evolution_*.gd`
- テストファイル: `test_*.gd`（`godot_project/tests/` 配下）

### Knowledge Base
- `{番号}_{英語タイトル}.md` 形式（例: `88_Non_Engineer_Development_Guide.md`）
- 番号は連番。サブ文書は `{番号}{a-d}` （例: `89a`, `89b`）

---

## セッション開始時のコンテキスト共有

Claude Codeは毎セッション白紙から始まる。効率的に文脈を伝えるために:

1. **CLAUDE.md は自動読込**: このファイルの内容はセッション開始時に自動で渡される
2. **スコープを絞る**: 「今日はPhase 4のAtoA会話テンプレート版を実装。KB67とKB70を参照」のように作業範囲と参照先を明示
3. **Handoff文書を活用**: 全体像が必要なときは `HANDOFF_PetClaw.md` を読ませる
4. **セッションテンプレートを使う**: `.claude/templates/session_start.md` にコピペ用テンプレートあり

---

## ディレクトリ構成
```
godot_project/scripts/   — GDScript（15サブシステム, 33ファイル, 15500+行）
godot_project/assets/    — スプライト・音声・タイル・UI素材
knowledge_base/          — 設計文書（63文書, KB00〜KB95）
HANDOFF_PetClaw.md       — Cowork→Code引き継ぎドキュメント
tools/sprite_pipeline/   — スプライト量産パイプライン
tools/debug_cli/         — デバッグCLI
tools/quality/           — 品質ツール（agnix/deslop/drift-detect/MCP/palette）
petclaw_ui_prototype.html — インタラクティブUIプロトタイプ
.claude/agents/          — Agent Teams エージェント定義（6エージェント）
.claude/commands/        — オーケストレーションコマンド（7コマンド）
.claude/hooks/           — 自動検証フック（pre/post-tool-use）
.claude/skills/          — PetClaw特化カスタムスキル（8スキル）
.claude/templates/       — セッション開始テンプレート
```

---

## 参照 KB 文書（重要度順）

| KB | 内容 |
|----|------|
| KB88 | 非エンジニア開発ガイド |
| KB67 | AtoA 会話システム設計 |
| KB70 | テンプレートフォールバック仕様 |
| KB89-91 | Ralph Loop 設定 |
| KB92a-92d | インストール後テンプレート |
| KB93 | Cowork → Code 引き継ぎ |
| KB94 | Everything Claude Code 活用 |
| KB95 | gstack パターン |
