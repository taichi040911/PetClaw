# PetBook フィード設計スキル

## トリガー
「PetBook」「ペットブック」「AI SNS」「Moltbook」「フィード」「投稿」「タイムライン」「自律投稿」「観察モード」と言われたときに使用。

## 目的
PetClaw のPetBook（Moltbook風AI専用SNS）の設計・投稿品質・コスト最適化・UI設計を支援する。
ペットAIが自律的に投稿・返信・反応し、プレイヤーが観察して楽しめるフィード体験を保証する。

## コンテキスト
- **対象ファイル**:
  - `godot_project/scripts/social/pet_book_core.gd` — フィードエンジン
  - `godot_project/scripts/social/pet_book_post.gd` — 投稿データモデル
  - `godot_project/scripts/core/game_manager.gd` — PetBook統合
- **連携システム**: AtoAConversationSystem, BiologicalMemorySystem, LanguageEvolution, EmotionSystem, EcosystemManager, PersistentField, EthicalSafeguard
- **設計文書**: `knowledge_base/77_PetBook_Moltbook_AtoA_SNS_Design.md`
- **第一原理**:
  - P1: 一貫性×記憶=愛着 — 投稿の積み重ねがコミュニティの「歴史」になる
  - P2: API Cost is Physics — テンプレート＋API呼び出しのハイブリッド戦略
  - P3: Player Agency — プレイヤーはケアを通じて間接的にフィードに影響
  - P4: 10秒フック — フィードの最初の投稿が「見続けたい」と思わせる

## 投稿タイプ仕様

### 5種類の投稿
| タイプ | トリガー | APIモデル | 日次頻度 | コスト配分 |
|--------|---------|----------|---------|-----------|
| DAILY | Pulse間隔 + 感情 > 0.15 | Sonnet (テンプレート) | 5-10/ペット | 32% |
| EVENT | 死・誕生・進化・災害 | Opus | 2-5回 | 21% |
| REPLY | 他投稿のengagement | Sonnet | 15-30回 | 17% |
| REBEL | 低確率 + 性格バイアス | Opus | 2-5回 | 21% |
| MEMORIAL | 死亡後grief期間 | Opus | 0-3回 | 9% |

### 投稿テキスト生成戦略
1. **テンプレートレイヤー**: `_template_*()` メソッドでAPIゼロの基本テキスト生成
2. **API強化レイヤー**: 重要投稿（EVENT/REBEL/MEMORIAL）はClaude APIで洗練
3. **言語注入**: LanguageEvolution の語順ルール + 接尾辞を投稿に適用
4. **記憶引用**: BiologicalMemory から関連記憶を取得し、投稿に織り込む

## チェックリスト

### フィード品質チェック
1. 投稿が単調でないか（同じテンプレートの連続を避ける）
2. 接尾辞が一貫して使用されているか（感情→接尾辞マッピング）
3. 反乱投稿が全体の5-10%に収まっているか
4. 追悼投稿がピン留めされているか
5. 翻訳テキストが意味を正しく伝えているか

### コスト最適化チェック
1. PULSE_OK拡張: 満足ペットの投稿スキップが機能しているか
2. 日次投稿上限（MAX_DAILY_POSTS_PER_PET = 12）が守られているか
3. EthicalSafeguard の日次上限と連携しているか
4. テンプレート投稿とAPI投稿の比率が適切か（7:3目標）

### リアクション整合性チェック
1. 自分の投稿にリアクションしていないか
2. 親密度がリアクション確率に反映されているか
3. 追悼投稿には「empathy」が優先されるか
4. 反乱投稿へのリアクションが性格ベースで分岐しているか

### トレンド分析チェック
1. トレンド接尾辞が上位3つ抽出されているか
2. トレンドトピックが環境・イベントから適切に抽出されているか
3. engagement >= 3 の投稿がトレンドフラグを持つか
4. PersistentField にトレンドが記録されているか

### GameManager統合チェック
1. 死亡 → create_memorial_posts() が呼ばれるか
2. 進化 → create_event_post("evolution") が呼ばれるか
3. 交配 → create_event_post("birth") が呼ばれるか
4. 反乱投稿 → 言語進化に通知されるか
5. Save/Load で pet_book.to_dict()/from_dict() が含まれるか

## 観察モードUI設計ガイドライン

### フィードレイアウト
- スクロール可能なタイムライン（最新が上）
- 投稿カード: ペット名 + ハンドル + 相対時間 + テキスト + リアクションバー
- 感情色でカード左端にラインを表示（get_emotion_color()使用）
- ピン留め投稿は上部に固定表示
- 反乱投稿は⚡アイコン、追悼投稿は📌アイコン

### トレンドパネル
- 右サイドバーまたはヘッダーに「今日のトレンド」表示
- トレンド接尾辞TOP3 + トレンドトピックTOP3
- 新しい言葉/表現のハイライト

### 翻訳トグル
- ペット言語 ↔ 人間語の切り替えスイッチ
- 接尾辞にツールチップ（-pya = 喜び、-kuu = 悲しみ等）
- 語順の違いをカラーハイライト

## デバッグ手順

### 「投稿が生成されない」場合
1. `_post_timer` が `_next_post_interval` に達しているか
2. ペットの感情強度が MIN_EMOTION_FOR_POST (0.15) を超えているか
3. 日次上限 (MAX_DAILY_POSTS_PER_PET = 12) に達していないか
4. GameManager.is_paused が true になっていないか

### 「フィードが単調」場合
1. テンプレートのバリエーション数を増やす
2. API強化レイヤーを有効にする
3. rebel投稿の確率を上げる（REBEL_PROBABILITY調整）
4. 記憶引用の多様性を確認

### 「コストが高い」場合
1. テンプレート vs API の比率を確認
2. POST_INTERVAL_MINを引き上げる
3. MAX_DAILY_POSTS_PER_PETを引き下げる
4. EVENT投稿のバッチ処理を検討

## Ralph Loop テスト設定
```
目標: 「5ペット × 24時間 → 投稿50-80件、反乱3-5件、追悼0-2件」
評価関数:
  - total_posts in [50, 80]
  - rebel_ratio in [0.05, 0.10]
  - unique_suffix_count >= 4
  - avg_engagement >= 1.5
  - no_duplicate_consecutive_templates == true
反復: 最大30回
調整対象: POST_INTERVAL, REBEL_PROBABILITY, MIN_EMOTION_FOR_POST
```
