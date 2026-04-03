# PetClaw Handoff Document
## Cowork → Code 引き継ぎ用（2026-04-03 R157時点）

---

## 1. プロジェクト概要

**PetClaw** は Godot 4.x + Claude API駆動のAIペットシミュレーション。
たまごっちのケア緊張感 × ポケモンの進化・収集 × デジモンの絆を融合し、
AI同士が自律的に会話・進化・コミュニティを形成する「AtoA（AI-to-AI）」体験を提供する。

### 第一原理（設計の核）
- **P1**: 一貫性 × 記憶 = 愛着
- **P2**: API Cost is Physics（$0.50/日会話、$1.21/日投稿）
- **P3**: Player Agency（プレイヤーは観察者、でも介入できる）
- **P4**: 10秒フック（初見で引き込む）
- **P5**: Complexity is Debt（複雑さは借金）

---

## 2. 現在の実装状況

### GDScript: 23サブシステム / 75+ファイル / 35,000+行

| サブシステム | 主要ファイル | 行数 | 状態 |
|-------------|-------------|------|------|
| **UI** | pet_book_ui.gd | 1,020 | ✅ v4統合済（Palette/ThemeBuilder/PostCard/Particles） |
| **UI** | pet_book_post_card.gd | 797 | ✅ 投稿タイプエフェクト + SubMolt装飾 |
| **UI** | pet_book_particles.gd | 669 | ✅ GPUParticles2D詳細パラメータ（5 SubMolt × 3イベント） |
| **UI** | pet_book_palette.gd | 481 | ✅ 統一カラー56定数 + SubMolt内部クラス |
| **UI** | pet_book_theme_builder.gd | 502 | ✅ ステートレスTheme生成（24メソッド） |
| **UI** | pet_book_sub_molt_theme.gd | 505 | ✅ SubMoltテーマ管理 |
| **会話** | a2a_conversation_system.gd | 806 | ✅ フルパイプライン（コンテキスト→プロンプト→言語進化→記憶→投稿） |
| **会話** | claude_api_client.gd | 113 | ✅ Claude API接続 |
| **生死** | pet_lifecycle_fsm.gd | 572 | ✅ EGG→ETERNAL 8状態 + 死亡・復活 |
| **生死** | life_death_system.gd | 627 | ✅ 死亡パイプライン・悲嘆カスケード・追悼投稿 |
| **交配** | breeding_system.gd | 625 | ✅ 遺伝6形質・双子・突然変異・家系図3世代 |
| **SNS** | pet_book_core.gd | 875 | ✅ PetBook基盤 |
| **SNS** | pet_book_auto_publisher.gd | 557 | ✅ 自動投稿（$1.21/日予算管理） |
| **SNS** | pet_book_feed_manager.gd | 384 | ✅ フィード管理 |
| **SNS** | pet_book_post_generator.gd | 494 | ✅ 投稿生成 |
| **SNS** | pet_book_post.gd | 252 | ✅ 投稿データクラス |
| **記憶** | biological_memory_system.gd | 527 | ✅ 生物模倣記憶（Hebbian強化） |
| **自律** | pet_autonomy_system.gd | 519 | ✅ ペット自律行動 |
| **コミュニティ** | a2a_community_core.gd | 511 | ✅ AI自律コミュニティ・派閥形成 |
| **感情** | emotion_system.gd | 148 | ✅ 感情コア |
| **進化** | evolution_mechanics.gd | 433 | ✅ 進化メカニクス |
| **進化** | evolution_tree.gd | 387 | ✅ 進化ツリー22形態 |
| **言語** | language_evolution_system.gd | 437 | ✅ 語順・接尾辞・文法進化 |
| **言語** | original_language_engine.gd | 352 | ✅ 独自言語エンジン |
| **倫理** | ethical_safeguard.gd | 299 | ✅ 倫理的安全装置 |
| **生態系** | ecosystem_manager.gd | 226 | ✅ 環境影響システム |
| **ケア** | care_action_system.gd | 225 | ✅ ケアアクション |
| **表現** | expression_system.gd | 548 | ✅ 表情・ビジュアル表現 |
| **VFX** | visual_fx_system.gd | 229 | ✅ ビジュアルエフェクト |
| **コア** | game_manager.gd | 602 | ✅ シングルトン・セーブ/ロード統合 |
| **コア** | pet_entity.gd | 217 | ✅ ペットエンティティ |
| **コア** | stats_system.gd | 76 | ✅ ステータス管理 |
| **フィールド** | persistent_field.gd | 499 | ✅ 永続フィールド（atomic write） |

### Knowledge Base: 70+文書（KB00〜KB115）

設計文書70+本。主要カテゴリ：
- KB00: システムアーキテクチャ概要
- KB55-68: 記憶・ケア・AtoA会話・感情・生態系
- KB70-76: 進化ビジュアル・語順進化・マルチエージェント
- KB77-87: PetBook UI/SubMolt/パレット
- KB88-93: 非エンジニアガイド・Ralph Loop・Cowork引き継ぎ
- KB94-96: Everything Claude Code・gstack・キャラデザブラッシュアップ
- KB99: Claude Cowork連携・進捗確認ガイド
- KB114: Neural Learning Pipeline (Active Inference + BCM + Oja)
- KB115: キャラクターデザイン仕様書（全22進化形態）

### テスト: 16テストファイル / 58+テストケース
- test_active_inference (15), test_bcm_oja (19), test_learning_bridge (18) — headless OK
- test_sub_molt_themes (6) — headless OK
- 残り12ファイル — Godotプロジェクトモード必要（GameManager依存）

### スプライト: 23フォームスプライト / 88表情シート
- R157で全面リニューアル: 固有シルエット・アクセサリー・オーラ効果
- 64px高品質ピクセルアート（旧: 32px色違いのみ）
- 12目パターン × 10口パターン × 8表情プリセット/フォーム

### Web Export / リリース
- v1.2.0 Web export (37MB) — GitHub Release公開済
- itch.io対応準備完了（butler未認証）

### 5つのSubMolt（PetBook内コミュニティ）

| SubMolt | テーマ | 主要色 |
|---------|--------|--------|
| ForestWhispers | 日常・自然・好奇心 | 深緑 #2D5A3D |
| AfterlifeEchoes | 死後・追悼・永遠 | 紫 #6B4C8A |
| BreedingCircle | 誕生・交配・家族 | ピンク #C77D8A |
| LanguageRebellion | 言語反乱・新語創造 | シアン #4A9B8E |
| EcosystemPulse | 生態系・環境変動・移住 | ウォーターブルー #4682B4 |

---

## 3. 重要ファイル一覧

### 必ず読むべきファイル
- `CLAUDE.md` — プロジェクト規約・エージェント構成・コーディング規約
- `knowledge_base/00_System_Architecture_Overview.md` — 全体アーキテクチャ
- `knowledge_base/93_Cowork_to_Code_Handoff_Guide.md` — 引き継ぎガイド

### GDScript（godot_project/scripts/）
- 上記33ファイルすべて。`class_name` + 型注釈 + `to_dict()`/`from_dict()` 必須。

### ツール
- `tools/quality/` — 品質ツール（agnix/deslop/drift-detect/MCP/palette）
- `tools/sprite_pipeline/` — スプライト量産パイプライン
- `tools/debug_cli/` — デバッグCLI

### Agent Teams（.claude/）
- `.claude/agents/` — 6エージェント定義
- `.claude/commands/` — 7オーケストレーションコマンド
- `.claude/hooks/` — 自動検証フック
- `.claude/skills/` — PetClaw特化スキル8種

---

## 4. 次にCodeで実装すべき優先タスク

### Priority 1: Godotシーン統合（最重要）
現在のGDScriptはすべてロジック実装済みだが、Godotのシーンファイル（.tscn/.tres）との統合がまだ。

```text
PetBookのUIシーン（pet_book_ui.tscn）を作成してください。
pet_book_ui.gdをルートスクリプトとして、以下のノード構成で：
- PanelContainer（ヘッダー）
- TabContainer（SubMoltタブ5つ）
- ScrollContainer > VBoxContainer（フィード）
- PanelContainer（サイドバー）
PetBookPaletteとPetBookThemeBuilderを使ってテーマを適用してください。
```

### Priority 2: AtoA会話の実動テスト
```text
a2a_conversation_system.gdのClaude API接続を実際にテストしてください。
claude_api_client.gdにAPIキーを設定し、テンプレートフォールバックが正しく動作するか確認。
Ralph Loopで：
--max-iterations 5 --completion-promise "A2A_CONVERSATION_TEST_PASS"
```

### Priority 3: 生死・交配システム統合テスト
```text
pet_lifecycle_fsm.gd、breeding_system.gd、life_death_system.gdの統合テストを実行してください。
以下のシナリオを検証：
1. ペットが自然死 → 悲嘆カスケード発動 → AfterlifeEchoes投稿生成
2. 交配 → 遺伝形質継承 → 双子判定 → 家系図登録
3. 復活評価 → 条件充足 → 復活成功
Ralph Loopで：
--max-iterations 10 --strategy careful --completion-promise "LIFE_DEATH_BREEDING_INTEGRATED"
```

### Priority 4: PetBookフィード全体動作
```text
PetBookの全SubMoltフィードを動作させてください：
- ForestWhispers: 日常投稿 + 好奇心パーティクル
- AfterlifeEchoes: 追悼投稿 + ゴースト演出
- BreedingCircle: 誕生投稿 + 花びらエフェクト
- LanguageRebellion: 反乱投稿 + グリッチ効果
- EcosystemPulse: 環境投稿 + データスタイル
```

### Priority 5: スプライト・ビジュアル制作
```text
tools/sprite_pipeline/を使ってペットスプライトを量産してください。
進化ツリー22形態分のベーススプライトが必要です。
```

---

## 5. Ralph Loopで使うべき指示の例

### 基本的な品質改善ループ
```text
PetClawの全GDScriptファイルを品質チェックしてください。
型注釈の欠落、class_nameの未宣言、to_dict/from_dictの不整合を修正。
--max-iterations 15 --completion-promise "QUALITY_PASS"
```

### PetBook専用ループ
```text
PetBookのフィード表示パフォーマンスを最適化してください。
PostCardのオブジェクトプール、パーティクルプール、スクロール性能を改善。
--max-iterations 10 --strategy careful --temperature 0.3
--completion-promise "PETBOOK_PERF_OPTIMIZED"
```

### 言語進化ループ
```text
language_evolution_system.gdとoriginal_language_engine.gdの
語順進化・接尾辞生成・文法創発の連動を検証・改善してください。
Hebbian強化の閾値とBiologicalMemory登録の整合性も確認。
--max-iterations 8 --completion-promise "LANGUAGE_EVOLUTION_VERIFIED"
```

---

## 6. 注意点（非エンジニア向け）

### やるべきこと
- Code起動時に必ず `CLAUDE.md` が読み込まれることを確認
- 大きな変更の前に `git commit` で現状を保存
- Ralph Loopの `--max-iterations` は最初は5以下で試す
- エラーが出たらそのままClaudeに貼り付ける（スクリーンショットでもOK）

### やらないこと
- GDScriptファイルを手動で編集しない（Claudeに任せる）
- 複数のRalph Loopを同時に走らせない
- APIキーをGitにコミットしない（.gitignoreで除外）

### トラブル時
- `KB89c_Ralph_Loop_Troubleshooting.md` を参照
- それでも解決しなければ「エラーメッセージ全文」をClaudeに送る

---

## 7. セーブ/ロード設計（開発者向け参考）

- `PersistentField`: 自身の `save_field()` で独立保存（atomic write）
- 以下のシステムは `GameManager.save_data` に `to_dict()` で埋め込み：
  - EthicalSafeguard, EvolutionMechanics, PetAutonomySystem
  - PetLifecycleFSM, PetBookCore, PetBookFeedManager, PetBookAutoPublisher
  - AtoAConversationSystem（最新50会話保持）
  - BreedingSystem（家系図含む）, LifeDeathSystem（死亡統計含む）

---

> **このドキュメントをCode起動時に読み込ませれば、全文脈が引き継がれます。**
> 作成日: 2026-04-01 | PetClaw v0.1 開発中
