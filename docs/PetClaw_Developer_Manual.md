# PetClaw 開発者マニュアル
## AI Virtual Pet Simulation — Godot 4.6 / GDScript

**Version:** 1.1.0 | **Last Updated:** 2026-04-03
**Engine:** Godot 4.6.1 | **Language:** GDScript (strict type annotations)
**License:** MIT

---

## 目次

1. [プロジェクト概要](#1-プロジェクト概要)
2. [環境構築](#2-環境構築)
3. [開発サーバー](#3-開発サーバー)
4. [ディレクトリ構成](#4-ディレクトリ構成)
5. [アーキテクチャ](#5-アーキテクチャ)
6. [15サブシステム詳細](#6-15サブシステム詳細)
7. [コーディング規約](#7-コーディング規約)
8. [セーブ/ロード](#8-セーブロード)
9. [AI会話システム (AtoA)](#9-ai会話システム-atoa)
10. [独自言語進化エンジン](#10-独自言語進化エンジン)
11. [Active Inference / 生物学習モデル](#11-active-inference--生物学習モデル)
12. [テスト](#12-テスト)
13. [品質ツール](#13-品質ツール)
14. [Agent Teams / Claude Code 連携](#14-agent-teams--claude-code-連携)
15. [ビルド・デプロイ](#15-ビルドデプロイ)
16. [トラブルシューティング](#16-トラブルシューティング)
17. [Knowledge Base 一覧](#17-knowledge-base-一覧)
18. [FAQ](#18-faq)

---

## 1. プロジェクト概要

PetClawは**Claude APIで駆動されるAIバーチャルペットシミュレーション**です。

### コンセプト
> たまごっちのケア緊張感 × ポケモンの進化・収集 × デジモンの絆

### コア機能
| 機能 | 説明 |
|------|------|
| **22進化形態** | Blob → Infant → Youth → Adult → Elder → Eternal の6ステージ |
| **AtoA会話** | ペット同士がClaude APIで会話（テンプレートフォールバック付き） |
| **創発的言語** | ペットが独自の単語・文法・接尾辞を発明する |
| **PetBook** | AI専用SNS — 投稿・リアクション・派閥形成 |
| **生物学的記憶** | エビングハウス曲線 + Hebbian学習 + フラッシュバルブ記憶 |
| **生死・交配** | 完全なライフサイクル + 性格遺伝 + 突然変異 |
| **倫理的セーフガード** | 依存検出・セッション制限・現実世界の提案 |

### 5つの設計原理 (P1〜P5)
| ID | 原理 | 意味 |
|----|------|------|
| P1 | 一貫性×記憶=愛着 | ペットの一貫した振る舞いと記憶が愛着を生む |
| P2 | API Cost is Physics | テンプレートフォールバック必須。日次予算厳守 |
| P3 | Player Agency | プレイヤーの選択に重み。進化は不可逆 |
| P4 | 10秒フック | 10秒以内にフィードバック |
| P5 | Complexity is Debt | 創発を設計より優先。シンプルに保つ |

---

## 2. 環境構築

### 必要なもの
| ソフトウェア | バージョン | 必須/任意 |
|-------------|----------|----------|
| Godot Engine | 4.6+ | 必須 |
| Python 3 | 3.10+ | 品質ツール用 |
| Git | 2.30+ | バージョン管理 |
| Claude Code CLI | 最新 | AI支援開発 |
| butler (itch.io) | 最新 | デプロイ用（任意） |
| Anthropic API Key | — | 任意（なくても動作） |

### セットアップ手順

```bash
# 1. リポジトリをクローン
git clone https://github.com/taichi040911/PetClaw.git
cd PetClaw

# 2. Godot Editorで開く
godot --path godot_project

# 3. 品質ツールの依存関係をインストール
cd tools/quality && bash install.sh && cd ../..

# 4. (任意) Claude API キーの設定
export ANTHROPIC_API_KEY="sk-ant-..."
# またはゲーム内 Settings 画面から入力

# 5. (任意) butler のインストール（itch.ioデプロイ用）
# https://itch.io/docs/butler/ からダウンロード
mkdir -p ~/bin && mv butler ~/bin/
butler login  # ブラウザが開く（初回のみ）
```

### API キーなしでの動作
API キーがなくても**全機能が動作**します。会話はテンプレートモード（ペットの性格・感情に基づくパターン選択）で生成されます。進化・バトル・実績・交配は完全にローカルロジックです。

---

## 3. 開発サーバー

### 設定ファイル

`~/.claude/launch.json` に3つのサーバーが定義されています:

```json
{
  "version": "0.0.1",
  "configurations": [
    {
      "name": "PetClaw Web Export (HTML5 Game)",
      "runtimeExecutable": "python3",
      "runtimeArgs": ["-m", "http.server", "8000", "--directory",
                      "/Users/takaosouichi/PetClaw/godot_project/export/web"],
      "port": 8000
    },
    {
      "name": "PetClaw MCP Quality Server",
      "runtimeExecutable": "python3",
      "runtimeArgs": ["/Users/takaosouichi/PetClaw/tools/quality/petclaw_mcp_server.py"],
      "port": 8765
    },
    {
      "name": "Godot Editor",
      "runtimeExecutable": "/Applications/Godot.app/Contents/MacOS/Godot",
      "runtimeArgs": ["--path", "/Users/takaosouichi/PetClaw/godot_project"],
      "port": 6007
    }
  ]
}
```

### サーバー一覧

| # | 名前 | ポート | 用途 |
|---|------|-------|------|
| 1 | **Web Export** | 8000 | HTML5版PetClawをブラウザでテスト |
| 2 | **MCP Quality Server** | 8765 | Claude Code / Agent Teamsから品質ツール呼び出し |
| 3 | **Godot Editor** | 6007 | GDScript編集・シーン確認・デバッグ |

### 起動方法

```bash
# Claude Code CLI から
# preview_start で個別起動（launch.json 参照）

# 手動起動
python3 -m http.server 8000 --directory godot_project/export/web  # Web Export
python3 tools/quality/petclaw_mcp_server.py                       # MCP Server
godot --path godot_project                                        # Godot Editor
```

### Web Export テスト
1. Godot Editorで `Project > Export > Web (HTML5)` を実行
2. Web Export サーバーを起動
3. ブラウザで `http://localhost:8000` を開く
4. ゲームがブラウザ内で動作することを確認

---

## 4. ディレクトリ構成

```
PetClaw/
├── godot_project/                # Godotプロジェクト本体
│   ├── project.godot             # Godot設定（autoload、viewport等）
│   ├── scripts/                  # GDScript（67ファイル, 33,000+行）
│   │   ├── core/                 #   GameManager, PetEntity, EmotionSystem, StatsSystem
│   │   ├── conversation/         #   AtoAConversationSystem, ClaudeAPIClient
│   │   ├── language/             #   LanguageEvolutionSystem, OriginalLanguageEngine
│   │   ├── inference/            #   ActiveInferenceCore (FEP/VFE)
│   │   ├── evolution/            #   EvolutionMechanics, EvolutionTree
│   │   ├── life/                 #   BreedingSystem, LifeDeathSystem, PetLifecycleFSM
│   │   ├── memory/               #   BiologicalMemorySystem, MemoryPersonalityBridge
│   │   ├── social/               #   PetBookCore, PetBookFeedManager, AutoPublisher
│   │   ├── community/            #   AtoACommunityCore
│   │   ├── autonomy/             #   PetAutonomySystem
│   │   ├── battle/               #   LanguageBattleSystem
│   │   ├── culture/              #   CulturalEmergenceSystem
│   │   ├── ecosystem/            #   EcosystemManager
│   │   ├── ethics/               #   EthicalSafeguard
│   │   ├── care/                 #   CareActionSystem
│   │   ├── interaction/          #   PetTouchHandler
│   │   ├── orchestration/        #   PetTeamOrchestrator
│   │   ├── progression/          #   AchievementSystem
│   │   ├── field/                #   PersistentField
│   │   ├── visual/               #   VFX, Sprites, Expressions, Animations
│   │   ├── audio/                #   SFX, BGM, AudioManager
│   │   └── ui/                   #   20+ UIコンポーネント
│   ├── scenes/                   # .tscnシーンファイル
│   ├── assets/                   # スプライト・音声・タイル・UI素材
│   ├── tests/                    # テスト（13ファイル, 2,000+行）
│   └── export/web/               # Web Export出力先
├── knowledge_base/               # 設計文書（113文書, KB00〜KB113）
├── tools/                        # 開発ツール
│   ├── quality/                  #   品質ツール（lint, drift, deslop, MCP, Karpathy）
│   ├── debug_cli/                #   デバッグCLI
│   ├── sprite_pipeline/          #   スプライト量産パイプライン
│   └── upload_itch.sh            #   itch.ioアップロードスクリプト
├── .claude/                      # Claude Code設定
│   ├── agents/                   #   Agent Teams定義（6エージェント）
│   ├── commands/                 #   オーケストレーションコマンド（7コマンド）
│   ├── hooks/                    #   自動検証フック
│   ├── skills/                   #   PetClaw特化スキル（8スキル）
│   └── templates/                #   セッションテンプレート
├── CLAUDE.md                     # Claude Code規約（最重要）
├── HANDOFF_PetClaw.md            # Cowork→Code引き継ぎ
├── LAUNCH_CHECKLIST.md           # ローンチチェックリスト
├── itch_io_config.md             # itch.io設定
├── itch_page.md                  # itch.ioストアページ内容
├── petclaw_ui_prototype.html     # UIプロトタイプ
└── README.md                     # プロジェクト概要
```

---

## 5. アーキテクチャ

### GameManager パターン

すべてのサブシステムは `GameManager` autoload singletonを中心に統合されています。

```
                    ┌─────────────────────┐
                    │     GameManager      │
                    │    (autoload)        │
                    │                     │
                    │  save_game()        │
                    │  load_game()        │
                    │  instance           │
                    └─────────┬───────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
  ┌─────┴─────┐    ┌─────────┴─────────┐   ┌──────┴──────┐
  │ Core      │    │ AI / Language     │   │ Life Cycle  │
  │           │    │                   │   │             │
  │ Emotion   │    │ AtoA Conversation │   │ Evolution   │
  │ Stats     │    │ Claude API Client │   │ Breeding    │
  │ PetEntity │    │ Language Evolution│   │ Life/Death  │
  │ Care      │    │ Original Language │   │ Lifecycle   │
  └───────────┘    │ Active Inference  │   └─────────────┘
                   └───────────────────┘
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
  ┌─────┴─────┐    ┌─────────┴─────────┐   ┌──────┴──────┐
  │ Social    │    │ Memory / Field   │   │ UI / Visual │
  │           │    │                   │   │             │
  │ PetBook   │    │ Biological Memory │   │ 20+ screens │
  │ Community │    │ Memory Bridge     │   │ VFX System  │
  │ Team Orch │    │ Persistent Field  │   │ Expressions │
  │ Ethics    │    │ Ecosystem         │   │ Audio       │
  └───────────┘    └───────────────────┘   └─────────────┘
```

### データフロー

```
ユーザー操作 → CareActionSystem → EmotionSystem → 感情変化
                                                      ↓
AtoAConversationSystem ← テンプレート or Claude API ← 感情 + 性格
         ↓
OriginalLanguageEngine → 新語発明 → Hebbian強化 → PetBook投稿
         ↓
ActiveInferenceCore → 予測誤差 → 行動選択 → 語彙変調
         ↓
EvolutionMechanics → ケアスコア判定 → 進化形態決定
         ↓
GameManager.save_game() → JSON → user://save_data.json
```

---

## 6. 15サブシステム詳細

| # | システム | ファイル | 行数 | 役割 |
|---|---------|---------|------|------|
| 1 | **EmotionSystem** | core/emotion_system.gd | 148 | リアルタイム感情処理、性格バイアス |
| 2 | **EvolutionMechanics** | evolution/evolution_mechanics.gd | 433 | ケアベース進化、22形態判定 |
| 3 | **LanguageEvolution** | language/language_evolution_system.gd | 469 | 文法創発（SVO/SOV/VSO語順） |
| 4 | **OriginalLanguage** | language/original_language_engine.gd | 352 | 独自語発明、Hebbian学習、意味場分類 |
| 5 | **AtoAConversation** | conversation/a2a_conversation_system.gd | 3,244 | Claude API会話、テンプレートフォールバック |
| 6 | **BiologicalMemory** | memory/biological_memory_system.gd | 527 | 海馬/皮質デュアルストア、忘却曲線 |
| 7 | **LifeDeathSystem** | life/life_death_system.gd | 631 | 死亡判定、蘇生メカニクス |
| 8 | **BreedingSystem** | life/breeding_system.gd | 643 | 交配適合度、形質遺伝、突然変異 |
| 9 | **PetBookCore** | social/pet_book_core.gd | 950 | AI専用SNS、投稿・リアクション |
| 10 | **PersistentField** | field/persistent_field.gd | 499 | オフライン冒険、コミュニティムード |
| 11 | **EthicalSafeguard** | ethics/ethical_safeguard.gd | 299 | プレイヤーウェルネス保護 |
| 12 | **PetAutonomy** | autonomy/pet_autonomy_system.gd | 519 | Pulse/Resonance自律行動 |
| 13 | **PetLifecycleFSM** | life/pet_lifecycle_fsm.gd | 572 | Sleep/Wake/Play状態機械 |
| 14 | **EcosystemManager** | ecosystem/ecosystem_manager.gd | 249 | 環境効果 |
| 15 | **CareActionSystem** | care/care_action_system.gd | 225 | Feed/Pet/Play/Train操作 |

### 追加システム（非コア）
| システム | ファイル | 役割 |
|---------|---------|------|
| ActiveInferenceCore | inference/active_inference_core.gd | FEP/VFE予測誤差ベース行動選択 |
| CulturalEmergence | culture/cultural_emergence_system.gd | 祭り・物語・歌・儀式の創発 |
| AtoACommunityCore | community/a2a_community_core.gd | コミュニティ全体のオーケストレーション |
| LanguageBattleSystem | battle/language_battle_system.gd | 言語バトル |
| AchievementSystem | progression/achievement_system.gd | 実績追跡 |

---

## 7. コーディング規約

### ファイル命名
```
snake_case で統一。サブシステムプレフィックス付き:
  pet_     — ペットコア
  petbook_ — PetBook SNS
  evo_     — 進化システム
  lang_    — 独自言語
  a2a_     — Agent-to-Agent会話
  ui_      — UIコンポーネント
  fx_      — VFX・パーティクル
  game_    — GameManager・セーブ/ロード
  breed_   — 交配システム
  life_    — 生死システム
```

### GDScript 必須パターン

```gdscript
# 1. class_name 必須（PascalCase）
class_name PetEmotionSystem
extends Node

# 2. 型注釈必須
var happiness: float = 0.5
var pet_name: String = ""
var emotions: Array[StringName] = []

# 3. GameManager.instance 経由で他システム参照
var game_mgr: GameManager = GameManager.instance

# 4. 定数は UPPER_SNAKE_CASE
const MAX_HAPPINESS: float = 1.0

# 5. シグナルは型付き引数
signal emotion_changed(new_emotion: StringName, intensity: float)

# 6. to_dict() / from_dict() 必須
func to_dict() -> Dictionary:
    return {"happiness": happiness}

func from_dict(data: Dictionary) -> void:
    happiness = data.get("happiness", 0.5)  # .get() でデフォルト値
```

### 絶対にやってはいけないこと (CLAUDE.md)

| NG | 理由 |
|----|------|
| 既存ファイルのリネーム | シーンファイルの参照が壊れる |
| save_data スキーマの変更 | 既存セーブデータとの互換性が壊れる |
| signal名の変更 | 他システムが依存している |
| enum値の順序変更 | セーブデータの互換性が壊れる |
| API呼び出しの増加 | P2: API Cost is Physics |
| テンプレート比率の低下 | 80/20ルール厳守 |
| 指示なしのリファクタリング | 既存構造を維持する |

---

## 8. セーブ/ロード

### フロー
```
保存: GameManager.save_game()
  → 各サブシステムの to_dict() を呼ぶ
  → Dictionary を JSON に変換
  → user://save_data.json に書き込み

読込: GameManager.load_game()
  → user://save_data.json を読み込み
  → JSON → Dictionary
  → 各サブシステムの from_dict() を呼ぶ
```

### 後方互換性ルール
```gdscript
# 新しいフィールドを追加する場合、from_dict() で .get(key, default) を使う
func from_dict(data: Dictionary) -> void:
    happiness = data.get("happiness", 0.5)          # 既存キー
    new_field = data.get("new_field", "default")     # 新規キー（古いデータでもクラッシュしない）
```

### PersistentField の特殊処理
`PersistentField` は自身の `save_field()` で独立保存（atomic write）。他のサブシステムは `GameManager.save_data` に `to_dict()` で埋め込む。

---

## 9. AI会話システム (AtoA)

### コスト管理
| 項目 | 値 |
|------|-----|
| AtoA日次予算 | $0.50/日 |
| PetBook日次予算 | $0.50/日 |
| テンプレート/API比率 | 80% / 20% |
| 1ターンあたりコスト | ~$0.0015 |
| 最大会話数/日 | 20 |
| トークン予算（会話） | 8,000 |
| トークン予算（リフレクション） | 3,000 |

### フォールバック階層
```
1. Claude API呼び出し（タイムアウト10秒、リトライ最大2回）
2. 失敗 → テンプレートフォールバック（感情+性格ベースのテンプレート選択）
3. テンプレートも失敗 → デフォルト値で続行
4. ユーザーに見える影響なし を目標とする
```

### 会話タイプ
| タイプ | ターン数 | トリガー |
|--------|---------|---------|
| 1対1会話 | 最大6ターン | 180秒ごとの自動、ムード判定 |
| グループ会話 | 4-6ターン | 3匹以上でラウンドロビン |
| イベント会話 | 最大3/日 | 進化・誕生・死亡等 |
| リアクション会話 | 1-2ターン | 観察者の自発的反応 |

---

## 10. 独自言語進化エンジン

### 5段階の言語ステージ

| ステージ | 必要語彙数 | 特徴 |
|---------|----------|------|
| 1. BORROWING | 0+ | 人間の言葉に接辞を付加 |
| 2. MORPHOLOGICAL | 10+ | 短縮形の発生 |
| 3. NEOLOGISM | 20+ | 完全な新語の発明 |
| 4. GRAMMAR_INDEPENDENT | 50+ | 独立した文法の形成 |
| 5. CULTURAL_LANGUAGE | — | 派閥方言の創発 |

### Hebbian学習パラメータ
| パラメータ | 値 | 説明 |
|-----------|-----|------|
| STRENGTH_ON_SUCCESS | +0.15 | LTP（長期増強） |
| STRENGTH_ON_FAILURE | -0.05 | LTD（長期抑圧） |
| DAILY_DECAY | -0.01 | 日次減衰 |
| ARCHIVE_THRESHOLD | 0.1 | これ以下で古語化 |
| PROPAGATION_THRESHOLD | 0.8 | これ以上で他ペットに伝播 |

### 感情→音韻マッピング
| 感情 | 音韻傾向 | 例 |
|------|---------|-----|
| Joy | "o" 母音（明るい） | "happy-pyo" |
| Sadness | "u" 母音（暗い） | "gone-mu" |
| Fear | "sh" 摩擦音 | "shadow-sha" |
| Love | "m" 鼻音（柔らかい） | "gentle-ma" |

---

## 11. Active Inference / 生物学習モデル

### 実装済みモジュール

| モジュール | ファイル | KB参照 |
|-----------|---------|--------|
| **ActiveInferenceCore** | inference/active_inference_core.gd | KB108 |
| **Hebbian LTP/LTD** | language/original_language_engine.gd | KB99 |

### Active Inference 4ステップ
```
1. 予測 (_step1_predict)     → 「次に何が起きるか？」
2. 比較 (_step2_compare)     → Variational Free Energy = surprise + complexity
3. 行動選択 (_step3_choose)  → Expected Free Energy に基づく
4. 学習 (_step4_learn)       → 予測モデルの更新
```

### KB設計済み（未実装）モデル

| モデル | KB | 目的 |
|--------|-----|------|
| BCM Theory | KB112 | スライディング閾値で語彙爆発を防止 |
| Oja's Rule | KB113 | 語彙strengthの正規化 |
| STDP | KB102 | 会話ターン順序に基づく時間依存強化 |
| Predictive Coding | KB103 | 3層予測モデル |
| Dopamine-modulated | KB111 | 感情イベントでの学習加速 |
| Homeostatic Plasticity | KB111 | 長期的な語彙安定化 |
| Synaptic Scaling | KB111 | Multi-Agent間のバランス |
| Metaplasticity | KB111 | 学習感受性の動的調整 |
| Competitive Learning | KB111 | 派閥言語の分化 |

### 計算コスト
すべてローカル計算。**API呼び出しゼロ**。50ペット環境で合計 < 75ms/ターン。

---

## 12. テスト

### テストファイル一覧（13ファイル / 2,062行）

| ファイル | テスト数 | 対象 |
|---------|---------|------|
| run_tests.gd | 統合 | メインテストオーケストレーター |
| test_runner_node.gd | — | テストノードヘルパー |
| test_active_inference.gd | 15 | Active Inference Core |
| test_hebbian_language.gd | 15 | Hebbian学習・語彙発明 |
| test_integration_e2e.gd | 15 | エンドツーエンド統合 |
| test_save_load.gd | — | セーブ/ロード往復 |
| test_evolution.gd | — | 進化メカニクス |
| test_language.gd | — | 基本言語システム |
| test_life_breeding.gd | — | 交配システム |
| test_memory_bridge.gd | — | 記憶-性格ブリッジ |
| test_a2a_fallback.gd | — | AtoAフォールバック |
| test_cultural_emergence.gd | — | 文化創発 |
| test_team_orchestrator.gd | — | チームオーケストレーション |
| test_sub_molt_themes.gd | — | SubMoltテーマ |

### テスト実行

```bash
# 全テスト実行
godot --headless --script tests/run_tests.gd

# 個別テスト実行
godot --headless --script tests/test_active_inference.gd
godot --headless --script tests/test_hebbian_language.gd
```

### テスト方針
- **フル適用（必須）**: セーブ/ロード往復、22形態到達可能性、AtoAコスト試算、生死フルパス
- **軽量テスト**: UI表示、VFX — 目視確認で十分
- **テスト不要**: 定数定義、シンプルなgetter/setter

---

## 13. 品質ツール

### ツール一覧

| ツール | コマンド | 機能 |
|--------|---------|------|
| **Agent Lint** | `python3 tools/quality/petclaw_agent_lint.py` | Agent Teams設定の検証 |
| **Drift Detect** | `python3 tools/quality/petclaw_drift.py` | 設計/実装のドリフト検出 |
| **Deslop** | `python3 tools/quality/petclaw_deslop.py` | AI生成コードの品質劣化検出 |
| **Karpathy Loop** | `python3 tools/quality/karpathy_loop.py` | 5次元自動品質評価 |
| **MCP Server** | `python3 tools/quality/petclaw_mcp_server.py` | MCP経由で品質ツール公開 |
| **Debug CLI** | `python3 tools/debug_cli/petclaw_cli.py` | インタラクティブデバッグ |

### Karpathy Loop 5次元スコア

| 次元 | 説明 | 目標 |
|------|------|------|
| code_quality | 関数数/行数の適正さ | avg_funcs < 15, avg_lines < 400 |
| atoa_quality | AtoA会話の品質 | > 0.8 |
| language_diversity | 言語進化の多様性 | > 0.8 |
| battle_balance | バトルバランス | > 0.8 |
| cost_efficiency | APIコスト効率 | > 0.9 |

### MCP公開ツール
```
petclaw.agent_lint    — Agent Teams設定検証
petclaw.deslop        — コード品質チェック
petclaw.drift         — ドリフト検出
petclaw.stats         — プロジェクト統計
petclaw.get_pet_state — ペット状態取得
petclaw.get_battle_stats — バトル統計
petclaw.get_language_metrics — 言語メトリクス
petclaw.karpathy_metrics — Karpathy Loopメトリクス
```

---

## 14. Agent Teams / Claude Code 連携

### 6エージェント構成

| エージェント | モデル | 役割 |
|------------|--------|------|
| gdscript-engineer | Sonnet | GDScript実装 |
| code-reviewer | Sonnet | コードレビュー |
| a2a-designer | Opus | AtoA/感情/言語設計 |
| evolution-specialist | Sonnet | 進化/ケア/ライフサイクル |
| ui-artist | Sonnet | UI/スプライト/アニメーション |
| architect | Opus | システム統合/設計 |

### オーケストレーションコマンド

| コマンド | 用途 |
|---------|------|
| `/implement` | 機能実装 |
| `/review` | 相互レビュー（コンセンサスゲート） |
| `/debug` | 仮説競合デバッグ |
| `/ultrawork` | 大規模並列実装 |
| `/lint` | 品質チェック統合 |
| `/ship` | 品質ゲート付きコミット・PR |
| `/iterate` | 反復改善ループ |

### PetClaw特化カスタムスキル（8種）

| スキル | 用途 |
|--------|------|
| emotion-reflection | 感情システムチューニング |
| a2a-conversation | AtoA会話品質チェック |
| evolution-validator | 進化ツリー検証 |
| ecosystem-dynamics | 生態系バランス検証 |
| biological-memory | 記憶メカニクス検証 |
| community-orchestrator | コミュニティスケーリング |
| petbook-feed | PetBookフィード設計 |
| rebel-language | 言語進化パターンチェック |

---

## 15. ビルド・デプロイ

### Web Export ビルド

```bash
# Godot Editorから
# Project > Export > Web (HTML5) > Export Project

# コマンドラインから
godot --headless --export-release "Web (HTML5)" godot_project/export/web/index.html
```

### itch.io デプロイ

```bash
# 1. butler認証（初回のみ、ブラウザが開く）
butler login

# 2. ビルド & アップロード
./tools/upload_itch.sh v1.1.0

# 3. 確認
# https://taichi040911.itch.io/petclaw
```

### ローンチチェックリスト（抜粋）

- [ ] 22進化形態すべて到達可能
- [ ] セーブ/ロードがセッション間で動作（ブラウザリフレッシュ対応）
- [ ] APIキーなしでテンプレートモード動作
- [ ] バトルシステム完全動作
- [ ] PetBookフィード正常生成
- [ ] Web Exportがクリーンにビルド
- [ ] コンソールエラーなし（5分間プレイ）
- [ ] エクスポートサイズ < 100MB
- [ ] Chrome / Firefox / Safari で動作確認

完全なチェックリストは `LAUNCH_CHECKLIST.md` を参照。

---

## 16. トラブルシューティング

### よくある問題

| 問題 | 原因 | 対処 |
|------|------|------|
| `not a git repository` | 作業ディレクトリが違う | `cd /Users/takaosouichi/PetClaw` |
| GitHub push失敗 (500) | GitHub一時障害 | `sleep 10 && git push origin master` |
| APIキーが効かない | 環境変数未設定 | `export ANTHROPIC_API_KEY="sk-ant-..."` |
| テンプレートモードのみ | APIキー未設定 or 日次予算超過 | 正常動作。設定画面でキー入力 |
| Web Exportが動かない | CORS / WASM問題 | `python3 -m http.server` で配信 |
| セーブデータが消えた | ブラウザのデータクリア | IndexedDB依存。定期バックアップ推奨 |
| Godotバージョンエラー | 4.6未満のGodot | Godot 4.6+をインストール |

### エラーハンドリング方針
- Claude API障害 → テンプレートフォールバック（ユーザーに見える影響なし）
- セーブ障害 → PersistentFieldのatomic writeが前回正常データを保持
- from_dict()不正データ → デフォルト値にフォールバック（クラッシュさせない）

---

## 17. Knowledge Base 一覧

### 主要KBカテゴリ

| 範囲 | KB番号 | 内容 |
|------|--------|------|
| **システム設計** | KB00-KB30 | アーキテクチャ、サブシステム仕様 |
| **AtoA会話** | KB67, KB70 | 会話設計、テンプレートフォールバック |
| **開発ガイド** | KB88-KB95 | 非エンジニアガイド、gstack、Ralph Loop |
| **生物学習** | KB98-KB103 | Hebbian、STDP、予測符号化 |
| **FEP/Active Inference** | KB104-KB109 | 自由エネルギー原理、Active Inference実装 |
| **応用実践** | KB110-KB113 | Hebbian応用、BCM、Oja's Rule |

### 最重要KB（優先度順）

| KB | 内容 | いつ読むか |
|----|------|-----------|
| KB88 | 非エンジニア開発ガイド | プロジェクト全体像を知りたいとき |
| KB67 | AtoA会話システム設計 | 会話システムを修正するとき |
| KB70 | テンプレートフォールバック仕様 | テンプレートを追加・修正するとき |
| KB108 | Active Inference最終版 | AI推論を理解・修正するとき |
| KB99 | Hebbian学習基礎 | 言語学習を理解・修正するとき |

---

## 18. FAQ

**Q: API キーなしでも全機能使えますか？**
A: はい。進化・バトル・実績・交配・PetBook・言語進化すべてローカルロジックで動作します。API キーを入れるとより豊かなAI会話が生成されます。

**Q: 新しいサブシステムを追加するには？**
A: (1) `class_name` + `extends Node/RefCounted` で.gdファイル作成 → (2) `to_dict()/from_dict()` 実装 → (3) GameManagerに登録 → (4) `from_dict()` でデフォルト値を設定して後方互換性確保

**Q: テストを追加するには？**
A: `godot_project/tests/test_xxx.gd` を作成。`extends SceneTree`、`_init()` で全テスト実行、`quit()` で終了。

**Q: Knowledge Base文書を追加するには？**
A: `knowledge_base/{番号}_{英語タイトル}.md` で作成。既存文書の番号を重複させない。削除・上書きNG。

**Q: Karpathy Loopスコアが低い場合は？**
A: `python3 tools/quality/karpathy_loop.py` で5次元を確認。code_quality改善はリファクタリングだが、CLAUDE.mdの制約により指示がない限り既存構造を維持。テスト追加はスコア改善に有効。

**Q: セーブデータの互換性を壊さずに機能追加するには？**
A: `to_dict()` に新キーを追加。`from_dict()` では `.get(key, default)` で古いデータでもクラッシュしないようにする。既存キーの名前変更は NG。

---

*このマニュアルは PetClaw v1.1.0 時点の情報です。最新情報は CLAUDE.md と Knowledge Base を参照してください。*
