# PetBook UIを Ralph Loop で作るカスタム指示集

## はじめに

このドキュメントは、PetClaw の中核 SNS 機能「**PetBook**」のUI を **Ralph Wiggum** の Karpathy Loop を使ってゼロから構築するための詳細な指示集です。

### 対象者
- ドキュメント 92a で基本的な開発環境が整った人
- Superpowers + Ralph Wiggum がインストール済み
- Godot 4.x の基本知識がある人（UI ノードの配置、シグナル接続）

### Loop方針
- **各 Phase は独立した実行ユニット** — 1つの `/ralph-loop` コマンドで完成
- **非エンジニアでも理解できる説明** を織り交ぜながら実装
- **Completion Promise** で完了を自動判定
- **Temperature** と **max-iterations** でバランスを調整

### 全体スケジュール
| Phase | 内容 | 所要時間 | 難易度 |
|-------|------|--------|------|
| 1 | フィード基本レイアウト | 30-45 分 | ★★☆ |
| 2 | 投稿カードデザイン | 40-50 分 | ★★★ |
| 3 | SubMolt テーマ切替 | 35-45 分 | ★★★ |
| 4 | 粒子エフェクト統合 | 45-60 分 | ★★★ |
| 5 | 投稿テンプレート生成 | 40-50 分 | ★★☆ |
| 6 | Karpathy Loop 統合 | 60-90 分 | ★★★★ |
| 7 | 統合テスト + 最適化 | 45-60 分 | ★★★ |

**全体**: 4.5-6 時間の集中実装

---

## Phase 1: フィード基本レイアウト

### 目的
PetBook の「タイムラインフィード」の骨組みを作成。ScrollContainer による仮想スクロール対応。

### ビジュアルゴール
```
┌─────────────────────────────────┐
│  SubMolt1 SubMolt2 Sub3 Sub4 Sub5│
├─────────────────────────────────┤
│                                 │
│  [投稿カード 1]                  │
│                                 │
│  [投稿カード 2]                  │
│                                 │
│  [投稿カード 3]                  │  ← ScrollContainer
│                                 │
│  [投稿カード 4]                  │
│                                 │
│                                 │
│                Observing Mode ► │
└─────────────────────────────────┘
```

### Ralph Loop コマンド（Phase 1）

```
/ralph-loop "
【Task】PetBook のタイムラインフィード基本レイアウトを Godot 4.x で構築

【最終ゴール】
以下の構造を持つ Godot シーンを完成させる：

1. **フィード全体コンテナ**
   - ノード名: PetBookFeed
   - 型: Control（フルスクリーン）
   - 背景色: #1A1A2E（濃いグレーブルー）

2. **上部: SubMolt タブバー**
   - ノード名: SubMoltTabBar
   - 型: HBoxContainer（横並び）
   - 5つのボタン: «All», «Herbivore», «Omnivore», «Carnivore», «Synthetic»
   - 背景色: #0F0F1E（さらに濃い）
   - 高さ: 60px

3. **中央: タイムラインフィード（スクロール可能）**
   - ノード名: TimelineFeed
   - 型: ScrollContainer
   - 内部: VBoxContainer（垂直配置）
   - スクロールバー: 右側に薄く表示（フェード可能）
   - 背景色: #1A1A2E

4. **フィードの中身**
   - 投稿カード: 5個のダミー Control ノード
   - 各カードサイズ: 幅 100%、高さ 120px
   - カード背景色: #FFFFFF（白）
   - 角丸: BorderRadius = 8px（Godot では StyleBox で実現）
   - マージン: 上下左右 10px

5. **右下: Observing Mode ラベル**
   - ノード名: ObservingModeLabel
   - テキスト: 「Observing Mode」
   - フォントサイズ: 14px
   - 色: #888888（グレー）
   - 位置: 右下から 15px 内側

【実装の流れ】
1. PetBookFeed シーンを新規作成 → Control ノード
2. 背景色を #1A1A2E に設定
3. 子ノード構造を作成（TabBar → TimelineFeed → Cards）
4. CSS 風スタイルシート（StyleBox）でカード装飾
5. スクリプト（GDScript）で最小限の制御（初期化のみ）

【GDScript 要件】
- class_name PetBookFeed
- extends Control
- func _ready(): で UI 初期化
- シグナル: tab_selected(submolt_name: String)
- シグナル: feed_scrolled(position: float)

【ファイル保存先】
- シーン: godot_project/scenes/ui/petbook_feed.tscn
- スクリプト: godot_project/scripts/ui/petbook_feed.gd

【パフォーマンス要件】
- ScrollContainer は「Virtual Scrolling」を有効化
  （Godot 4.x では自動。大量カードでも 60fps 維持）

【説明はわかりやすく】
非エンジニアにも理解できるよう、以下の点を説明してください：
- 「ScrollContainer = スマホと同じスクロール機能」
- 「VBoxContainer = ラッパー（カードを縦に積み重ねる）」
- 「StyleBox = CSS みたいなスタイル指定」
- 「Observing Mode = AI が見守っている状態」

【完成時の確認項目】
✓ PetBookFeed が Godot エディタで表示される
✓ フィードが画面いっぱいに広がっている
✓ 背景が #1A1A2E（濃いグレー）に見える
✓ 上部に 5 つのタブが横並びで表示されている
✓ 5 つの投稿カードが白背景で表示されている
✓ マウスホイール / タッチでスクロールできる
✓ 右下に「Observing Mode」ラベルが見えている
✓ エラーが出ていない（Output ウィンドウ）

実装が完了したら、以下の内容を報告してください：
1. ファイルパス（.tscn と .gd）
2. 動作確認の結果（上の 8 つすべて ✓？）
3. 工夫した点（あれば）
4. 次の Phase への質問（あれば）
" \
--max-iterations 8 \
--completion-promise "FEED_LAYOUT_DONE" \
--temperature 0.6
```

### Phase 1 後の確認プロンプト

実装完了後、以下を実行してください：

```
上記の Phase 1（PetBook フィード基本レイアウト）が完了しました。
以下の確認を実施してください：

【ビジュアル確認】
1. Godot エディタで、scenes/ui/petbook_feed.tscn を開く
2. シーン画面（Scene tree）で以下が見えているか：
   - PetBookFeed (root)
     ├── SubMoltTabBar (5 つのボタン)
     ├── TimelineFeed (ScrollContainer)
     │   └── VBoxContainer (5 つのダミーカード)
     └── ObservingModeLabel
3. 2D ビューポートで背景が暗い、カードが白く見えるか

【機能確認】
1. 再生ボタン（▶）を押して、シーンを実行
2. マウスホイールでスクロールが動くか
3. カードが滑らかにスクロールするか（遅延がないか）

【コード品質確認】
1. petbook_feed.gd を開いて：
   - class_name PetBookFeed が宣言されているか
   - extends Control になっているか
   - _ready() メソッドがあるか
   - シグナル定義（signal tab_selected 等）があるか

【問題が見つかった場合】
詳しく説明してください：
- どのステップで問題が起きたか
- エラーメッセージ（あれば）
- スクリーンショット（あれば）

すべて ✓ なら、Phase 2 に進みます。
```

---

## Phase 2: 投稿カードデザイン

### 目的
投稿カードの詳細デザイン。感情ラインを示す棒グラフ、BBCode による Text 要素、リアクションボタン（いいね、リプライ、シェア）。

### カード内部構造
```
┌──────────────────────────────┐
│ [アイコン] ペット名 🌟 Lv.5   │ 16px
├──────────────────────────────┤
│                              │
│ 「今日のログは、僕の心の     │
│  言葉です。」                │
│                              │
├──────────────────────────────┤
│ Happiness  ████░░ 74%        │
│ Energy     ██░░░░ 32%        │
│ Hunger     ███░░░ 51%        │
├──────────────────────────────┤
│  ❤ 234  💬 12  🔄 8         │
└──────────────────────────────┘
```

### Ralph Loop コマンド（Phase 2）

```
/ralph-loop "
【Task】PetBook の投稿カードデザインを完成させる

【最終ゴール】
Phase 1 の「ダミーカード」を、以下の要素を持つ本格的な投稿カードに変更：

1. **ヘッダー部分（16px 高）**
   - ペットアイコン（16×16px、左側）
   - ペット名（太字、14px）
   - レベル表示（🌟 Lv.5）
   - 投稿時刻（「5分前」など、グレー、11px）
   - 背景: 薄いグレー #F5F5F5

2. **投稿テキスト部分（可変高さ）**
   - テキスト内容: BBCode 対応（色、太字、イタリック可）
   - フォント: Noto Sans JP, 14px
   - 行間: 1.4
   - パディング: 10px
   - 最大幅: カード幅 - 20px（折り返し対応）

3. **ステータスバー部分（3行、各 20px）**
   - 3つの指標: Happiness, Energy, Hunger
   - 各行: ラベル（12px）+ ProgressBar（8px 高）+ パーセント（11px）
   - 色: 
     * Happiness: #FF69B4（ピンク）
     * Energy: #FFD700（ゴールド）
     * Hunger: #8B4513（ブラウン）
   - パディング: 左右 10px

4. **リアクションボタン部分（32px 高）**
   - 3つのボタン: ❤（いいね）、💬（リプライ）、🔄（シェア）
   - 各ボタン: 数字カウント付き（「❤ 234」）
   - ボタンクリックで数字が増える（ローカル状態）
   - ホバー時: ボタン背景が薄く光る
   - パディング: 8px

5. **カード全体**
   - 背景色: #FFFFFF
   - 枠線: 1px #CCCCCC
   - 角丸: 8px
   - 影: offset (0, 2), blur 4px, color #00000020
   - マージン: 上下左右 10px

【GDScript 実装】
新規クラス: PetBookCard
- extends PanelContainer
- func update_post(post_data: Dictionary) — 投稿データで UI 更新
  * post_data 形式:
    ```gdscript
    {
      "pet_name": String,
      "pet_level": int,
      "pet_icon": String (Texture path),
      "text_content": String (BBCode),
      "happiness": int (0-100),
      "energy": int (0-100),
      "hunger": int (0-100),
      "reactions": {"love": int, "reply": int, "share": int}
    }
    ```
- シグナル: card_reacted(reaction_type: String, post_id: String)
- func set_pet_data(pet: PetLifecycleFSM) — FSM から直接値を取得

【HTML/CSS 想定（イメージ）】
```
┌─ PetBookCard ──────────────────────┐
│ ┌─ CardHeader ─────────────────┐  │
│ │ [icon] Name 🌟 Lv.5  5m ago  │  │
│ └──────────────────────────────┘  │
│                                   │
│ ┌─ CardContent ────────────────┐  │
│ │ "投稿テキスト..."             │  │
│ └──────────────────────────────┘  │
│                                   │
│ ┌─ CardStats ──────────────────┐  │
│ │ Happiness ████░░ 74%          │  │
│ │ Energy    ██░░░░ 32%          │  │
│ │ Hunger    ███░░░ 51%          │  │
│ └──────────────────────────────┘  │
│                                   │
│ ┌─ CardReactions ───────────────┐ │
│ │  ❤ 234   💬 12   🔄 8        │ │
│ └──────────────────────────────┘ │
└───────────────────────────────────┘
```

【ファイル保存先】
- シーン: godot_project/scenes/ui/petbook_card.tscn
- スクリプト: godot_project/scripts/ui/petbook_card.gd

【テスト用ダミーデータ】
実装時、以下のダミー投稿を 3～5 個、TimelineFeed に入れてテスト：

```gdscript
var dummy_posts = [
  {
    \"pet_name\": \"Luna\",
    \"pet_level\": 5,
    \"pet_icon\": \"res://assets/pets/luna_icon.png\",
    \"text_content\": \"[color=ff69b4]今日も楽しい一日[/color]だった！\",
    \"happiness\": 74,
    \"energy\": 32,
    \"hunger\": 51,
    \"reactions\": {\"love\": 234, \"reply\": 12, \"share\": 8}
  },
  # ... more
]
```

【説明要件】
非エンジニアに対して：
- 「ProgressBar = HP バー（ゲーム的）」
- 「BBCode = インスタグラムの太字・色付け機能」
- 「リアクション = Twitter のいいね・リツイート」

【完成時の確認項目】
✓ PetBookCard が Godot で表示される
✓ ペット名とレベルが表示されている
✓ 投稿テキストが表示されている
✓ 3つのステータスバーが色付きで表示されている
✓ リアクションボタンが 3 つ表示されている
✓ ボタンをクリックするとカウンタが増える
✓ ボタンホバーで背景が光って見える
✓ TimelineFeed に複数カードを配置して、スクロールで全部が見える
✓ エラーが出ていない

報告内容：
1. ファイルパス
2. 動作確認結果（上の 9 つすべて ✓？）
3. 工夫した点
4. 気になる点（あれば）
" \
--max-iterations 9 \
--completion-promise "CARD_DESIGN_DONE" \
--temperature 0.65
```

### Phase 2 後の確認プロンプト

```
Phase 2（投稿カードデザイン）が完了しました。
以下を確認してください：

【レイアウト確認】
1. petbook_card.tscn を開く
2. 以下の子ノードが存在するか：
   - CardHeader (HBoxContainer)
   - CardContent (RichTextLabel or Label)
   - CardStats (VBoxContainer) ← 3×ProgressBar
   - CardReactions (HBoxContainer) ← 3×Button

【スタイル確認】
1. 2D ビューで：
   - カード背景が白に見えるか
   - 角丸が 8px に見えるか（四隅が丸い）
   - 影が見えるか（カード下部が少し暗い）
   - 各 ProgressBar が異なる色（ピンク、ゴールド、ブラウン）か

【機能確認】
1. TimelineFeed にダミーカード 3-5 個を配置
2. 再生して：
   - すべてのカードが同じ高さで見えるか
   - スクロールで上下に移動できるか
   - ボタンをクリックしてカウンタが増えるか
   - 複数カード間でリアクションが独立しているか（カード A のボタンがカード B に影響しない）

【トラブル: ボタンが反応しない】
- Button ノードの pressed シグナルが GDScript に接続されているか確認
- 接続例:
  ```gdscript
  func _ready():
    %LoveButton.pressed.connect(_on_love_pressed)
  ```

すべて ✓ なら Phase 3 へ！
```

---

## Phase 3: SubMolt テーマ切替

### 目的
5つの SubMolt（クラン）ごとにカラースキームを切り替える機能。

### SubMolt リスト
| 名前 | テーマ色 | キャラ |
|------|---------|------|
| All | グレー #888888 | 全部 |
| Herbivore | 緑 #2ECC71 | 草食性 |
| Omnivore | 黄 #F39C12 | 雑食性 |
| Carnivore | 赤 #E74C3C | 肉食性 |
| Synthetic | 紫 #9B59B6 | 人工生命 |

テーマが切り替わる要素：
- ProgressBar の色
- リアクションボタンのホバー色
- ページ背景のアクセント色（微細）
- タブ自体のボーダー色

### Ralph Loop コマンド（Phase 3）

```
/ralph-loop "
【Task】PetBook の SubMolt テーマシステムを構築

【最終ゴール】
5 つの SubMolt ごとにカラースキームを切り替える機能を実装：

1. **色定義の構造化**
   新規クラス: ThemeManager (singleton)
   - extends Node
   - 変数 current_submolt: String = \"All\"
   - func get_submolt_color(submolt: String, element: String) → Color
     * element の種類:
       - \"primary\" (メイン色)
       - \"progress_happiness\" (Happiness バー)
       - \"progress_energy\" (Energy バー)
       - \"progress_hunger\" (Hunger バー)
       - \"button_hover\" (ボタンホバー)
       - \"accent\" (背景アクセント)

2. **色データベース**
   ```gdscript
   var submolt_colors = {
     \"All\": {
       \"primary\": Color.html(\"#888888\"),
       \"progress_happiness\": Color.html(\"#888888\"),
       \"progress_energy\": Color.html(\"#888888\"),
       \"progress_hunger\": Color.html(\"#888888\"),
       \"button_hover\": Color.html(\"#CCCCCC\"),
       \"accent\": Color.html(\"#1A1A2E\")
     },
     \"Herbivore\": {
       \"primary\": Color.html(\"#2ECC71\"),
       \"progress_happiness\": Color.html(\"#F1C40F\"),
       \"progress_energy\": Color.html(\"#27AE60\"),
       \"progress_hunger\": Color.html(\"#16A085\"),
       \"button_hover\": Color.html(\"#D5F4E6\"),
       \"accent\": Color.html(\"#0B5345\")
     },
     # ... その他 3 つの SubMolt
   }
   ```

3. **SubMolt タブの動作**
   - PetBookFeed 内の SubMoltTabBar を更新
   - 各ボタンをクリック → ThemeManager.set_current_submolt(name)
   - シグナル: submolt_changed(new_submolt: String)

4. **PetBookCard への反映**
   - PetBookCard._process() または submolt_changed シグナルで動的に色更新
   - ProgressBar.modulate の色を変更
   - ボタンのホバー StyleBox を変更

5. **スムーズなトランジション**
   - 色変更時に Tween アニメーション（0.3 秒）
   - 各要素が段階的にフェードイン

【GDScript 実装詳細】

ThemeManager (autoload 登録):
```gdscript
class_name ThemeManager
extends Node

var current_submolt: String = \"All\"

func set_current_submolt(submolt: String) -> void:
  if submolt not in submolt_colors:
    push_error(\"Unknown submolt: %s\" % submolt)
    return
  current_submolt = submolt
  submolt_changed.emit(submolt)

func get_submolt_color(submolt: String, element: String) -> Color:
  if submolt not in submolt_colors:
    return Color.WHITE
  var colors = submolt_colors[submolt]
  return colors.get(element, Color.WHITE)

signal submolt_changed(submolt: String)

var submolt_colors = { ... }  # 上記のデータ
```

PetBookCard での使用例:
```gdscript
func _ready():
  ThemeManager.submolt_changed.connect(_on_theme_changed)

func _on_theme_changed(submolt: String) -> void:
  var color = ThemeManager.get_submolt_color(submolt, \"progress_happiness\")
  var tween = create_tween()
  tween.set_trans(Tween.TRANS_QUAD)
  tween.set_ease(Tween.EASE_OUT)
  tween.tween_property(%HappinessBar, \"self_modulate\", color, 0.3)
```

6. **ファイル保存先**
   - スクリプト: godot_project/scripts/managers/theme_manager.gd
   - Autoload 登録: project.godot に以下を追加
     ```ini
     [autoload]
     ThemeManager=\"res://scripts/managers/theme_manager.gd\"
     ```

【非エンジニア向け説明】
- 「ThemeManager = 色の中央管理（一か所で全部の色を変更できる）」
- 「Tween = 色が徐々に変わる効果（Netflix 的なスムーズさ）」
- 「Autoload = ゲーム全体で使える共通機能」

【完成時の確認項目】
✓ ThemeManager が project.godot に登録されている
✓ PetBookFeed のタブをクリックするとテーマが切り替わる
✓ タブ切り替え時に全カードの色が一瞬で変わる（または滑らかに変わる）
✓ 5 つすべての SubMolt で異なる色スキームが見える
✓ Herbivore は緑系、Carnivore は赤系に見える
✓ ProgressBar の色が SubMolt ごとに異なっている
✓ ボタンホバーの色も SubMolt ごとに変わっている
✓ 複数カードが同時に色更新される
✓ エラーが出ていない

報告内容：
1. ThemeManager ファイルパス
2. project.godot の autoload セクション
3. 動作確認結果（上の 9 つすべて ✓？）
4. 実装での工夫点
" \
--max-iterations 8 \
--completion-promise "SUBMOLT_THEME_DONE" \
--temperature 0.65
```

### Phase 3 後の確認プロンプト

```
Phase 3（SubMolt テーマ切替）が完了しました。

【コード確認】
1. theme_manager.gd を開いて：
   - class_name ThemeManager が宣言されているか
   - submolt_colors ディクショナリに 5 つのキーがあるか
   - set_current_submolt() メソッドがあるか
2. project.godot で [autoload] に ThemeManager が登録されているか

【動作確認】
1. Godot を再起動（autoload 反映のため）
2. PetBookFeed を再生
3. タブをクリック → テーマが切り替わるか
4. 別の SubMolt に切り替え → 色が変わるか
5. 複数回クリック → スムーズに動作するか

【最適化チェック】
- タブ切り替えが「瞬時」か「0.3 秒でアニメーション」か確認
- 遅延や janky な感じがないか

問題なく全部 ✓ なら、Phase 4 へ！
```

---

## Phase 4: 粒子エフェクト統合

### 目的
各 SubMolt の視覚的アイデンティティを強化するために、背景に粒子エフェクト（GPUParticles2D）を統合。タブ切り替え時にエフェクトも切り替わる。

### エフェクト設計
- **Herbivore**: 葉が舞う / 緑の粒子
- **Omnivore**: 虹色の小さな光 / 黄色系
- **Carnivore**: 赤い火花 / 上昇気流
- **Synthetic**: 紫の電子パルス / グリッド状
- **All**: 淡白な白い粒子 / ゆっくり

### Ralph Loop コマンド（Phase 4）

```
/ralph-loop "
【Task】PetBook に粒子エフェクト（GPUParticles2D）を統合

【最終ゴール】
各 SubMolt のテーマに合わせた粒子エフェクトを背景に表示し、
タブ切り替え時にエフェクトも切り替わる：

1. **粒子エフェクトシーン設計**
   新規シーン: petbook_particle_effect.tscn
   - ノード: GPUParticles2D
   - 設定：
     * Emitter Shape: Rectangle (フルスクリーン)
     * Amount: 100（軽く保つ）
     * Lifetime: 3.0 sec
     * Emission Rate: 30/sec
     * Gravity: 小さい値（-100, -100）— ゆっくり落ちる / 上昇
     * Initial Velocity: 50-100（ランダム方向）
     * Damping: 20（徐々に遅くなる）
     * Color Ramp: SubMolt ごと

2. **SubMolt ごとのパラメータセット**

   【All (グレー)】
   - Particle Color: #FFFFFF
   - Alpha: 0.2
   - Size: 2-4px
   - Lifetime: 4.0 sec
   - Emission Rate: 20/sec

   【Herbivore (緑)】
   - Particle Color: #2ECC71
   - Alpha: 0.3
   - Size: 3-6px (葉っぽく)
   - Shape Offset: 少し左右に揺らす
   - Rotation: +/- 180° ランダム

   【Omnivore (黄)】
   - Particle Color: Mix of #F39C12 and #FFFFFF
   - Alpha: 0.4
   - Size: 2-5px
   - Flash/Burst: ランダムに明滅

   【Carnivore (赤)】
   - Particle Color: #E74C3C
   - Alpha: 0.35
   - Size: 2-4px
   - Initial Velocity: 上方向を強調（gravity マイナス）
   - Trail: 軌跡表示（optional）

   【Synthetic (紫)】
   - Particle Color: #9B59B6
   - Alpha: 0.25
   - Size: 1-3px (小さく)
   - Emission Pattern: グリッド状（各エミッタが小区画）
   - Anim Speed: 高速（電子的な動き）

3. **PetBookFeed への統合**
   - PetBookFeed ノード構造に ParticleEffectContainer (Node2D) を追加
   - TimelineFeed の背後に配置
   - z-index: -1（背後）

4. **動的エフェクト切り替え**
   ThemeManager 拡張:
   ```gdscript
   func get_particle_config(submolt: String) -> Dictionary:
     return particle_configs[submolt]

   var particle_configs = {
     \"All\": { ... },
     \"Herbivore\": { ... },
     # ...
   }
   ```

   PetBookFeed 内:
   ```gdscript
   func _on_theme_changed(submolt: String) -> void:
     var config = ThemeManager.get_particle_config(submolt)
     _apply_particle_config(%ParticleEffect, config)
   ```

5. **パフォーマンス最適化**
   - 粒子数: 100 以下に制限（モバイル対応）
   - GPUParticles2D: Godot 4.x ネイティブ（CPU よりも高速）
   - TimelineFeed スクロール時: パーティクルは固定（背景として）
   - オプション: \"低パフォーマンスモード\" で粒子を非表示

【ファイル保存先】
- シーン: godot_project/scenes/effects/petbook_particle_effect.tscn
- 設定: theme_manager.gd に particle_configs 追加

【非エンジニア向け説明】
- 「GPUParticles = グラフィックボードを使った効果（魔法のような見た目）」
- 「粒子 = ほこり、火花、光の小さな粒」
- 「Lifetime = 粒が消えるまでの時間」
- 「Gravity = 重力（粒がどう動くか）」

【完成時の確認項目】
✓ petbook_particle_effect.tscn が作成されている
✓ PetBookFeed 再生時、背景に粒子が見える
✓ Herbivore タブ: 緑の粒子が見える
✓ Carnivore タブ: 赤の粒子が上昇/舞う
✓ Synthetic タブ: 紫の細かい粒子が動く
✓ タブ切り替えで粒子の色がスムーズに変わる
✓ フレームレート: 60fps を維持（Profiler で確認）
✓ パーティクル設定の違いが視覚的に明確
✓ エラーが出ていない

報告内容：
1. petbook_particle_effect.tscn のパス
2. theme_manager.gd の particle_configs セクション
3. 動作確認結果（上の 9 つすべて ✓？）
4. 各 SubMolt のビジュアル説明（「Herbivore は葉が舞う感じ」等）
5. パフォーマンス測定結果（FPS）
" \
--max-iterations 10 \
--completion-promise "PARTICLE_EFFECT_DONE" \
--temperature 0.65
```

### Phase 4 後の確認プロンプト

```
Phase 4（粒子エフェクト統合）が完了しました。

【パフォーマンス確認】
1. Godot の Profiler を開く（上部メニュー → Debug → Profiler）
2. PetBookFeed を再生
3. FPS が 60 fps を維持しているか確認
4. GPU Load が正常範囲か確認（50% 以下が理想）

【ビジュアル確認】
1. 各タブを順番にクリック
2. 粒子の色と動きが 5 つ異なっているか
3. Herbivore は落ち着いた動き、Carnivore は激しい動き、Synthetic は細かい動きが見えるか

【トラブル: 粒子が見えない】
- GPUParticles2D の Visible が true か確認
- Emitting が true か確認
- Z-index が負（背後）か確認

【トラブル: FPS が落ちている】
- Particle Amount を 50-75 に減らす
- Lifetime を短くする（2.0 sec → 1.5 sec）

すべて ✓ なら Phase 5 へ！
```

---

## Phase 5: 投稿テンプレート生成

### 目的
AI が自動で生成する投稿のテンプレート機構。API 呼び出しなし（ローカル処理）で、複数の投稿パターンを用意。

### テンプレート例
```
「今日も {emotion} 気分！」
「{pet_name} の {hobby} は最高だ。」
「{energy_status} だから、{action} をしよう。」
```

### Ralph Loop コマンド（Phase 5）

```
/ralph-loop "
【Task】PetBook の投稿テンプレート生成システムを実装

【最終ゴール】
ローカル（API なし）で、ペットの状態に基づいて投稿テンプレートを生成：

1. **投稿テンプレートクラス**
   新規クラス: PostGenerator
   - extends Node
   - func generate_post(pet: PetLifecycleFSM) → Dictionary
   - 出力フォーマット:
     ```gdscript
     {
       \"text\": String (BBCode サポート),
       \"happiness\": int,
       \"energy\": int,
       \"hunger\": int,
       \"submolt\": String
     }
     ```

2. **テンプレートデータベース**
   感情別テンプレート:

   【Happy (Happiness > 70)】
   - 「今日も {pet_name} は [color=ff69b4]幸せ[/color]だ！」
   - 「一日中 {hobby} で遊んでいた。楽しい！」
   - 「{pet_name}：こんな日が毎日続いたら...」

   【Neutral (30 ≤ Happiness ≤ 70)】
   - 「今日も{pet_name}は普通の一日。」
   - 「{time_of_day}だから、{action}をしよう。」
   - 「疲れたけど、やることがある。」

   【Sad (Happiness < 30)】
   - 「{pet_name}：寂しい...誰か来てほしい...」
   - 「{problem_status}、どうしよう。」

   その他パターン: SubMolt 別（Herbivore / Carnivore 等）

3. **動的値の埋め込み**
   ```gdscript
   var template_variables = {
     \"pet_name\": pet.pet_name,
     \"hobby\": _get_hobby(pet),
     \"time_of_day\": _get_time_of_day(),
     \"action\": _get_action(pet),
     \"problem_status\": _get_problem(pet),
     \"emotion\": _get_emotion(pet.happiness)
   }
   ```

4. **ローカル生成ロジック**
   ```gdscript
   func generate_post(pet: PetLifecycleFSM) -> Dictionary:
     var happiness = pet.current_state.happiness
     var templates = []

     if happiness > 70:
       templates = happy_templates
     elif happiness < 30:
       templates = sad_templates
     else:
       templates = neutral_templates

     var template = templates[randi() % templates.size()]
     var text = template
     for var_name in template_variables.keys():
       text = text.replace(\"{%s}\" % var_name, template_variables[var_name])

     return {
       \"text\": text,
       \"happiness\": pet.current_state.happiness,
       \"energy\": pet.current_state.energy,
       \"hunger\": pet.current_state.hunger,
       \"submolt\": pet.submolt
     }
   ```

5. **ファイル保存先**
   - スクリプト: godot_project/scripts/petbook/post_generator.gd
   - 登録: GameManager に PostGenerator インスタンス

【テンプレート設計原則】
- 最大 50 字（BBCode タグ除く）
- ペットの「想い」を表現（一人称視点）
- SubMolt の特性を反映（Herbivore は優しく、Carnivore は激しく）
- 日本語らしい自然な文体

【BBCode での装飾例】
```
[color=ff69b4]幸せ[/color]  — 単語を色付け
[b]食べたい[/b]              — 太字
[i]ずっと[/i]                — イタリック
```

【非エンジニア向け説明】
- 「PostGenerator = AIが投稿文を自動作成する機械」
- 「テンプレート = 「___は___だ」みたいな空白を埋める文型」
- 「動的値 = ペットの名前とか気分とか、毎回変わる値」

【完成時の確認項目】
✓ PostGenerator が GameManager に登録されている
✓ ペットの幸福度に応じてテンプレートが異なる
✓ 同じペットで複数回生成するとテキストが違う（ランダム）
✓ BBCode が正しくレンダリングされている（色付き等）
✓ テンプレート変数（{pet_name} など）が正しく埋め込まれている
✓ 生成されたテキストが 50 字以内
✓ API 呼び出しが発生していない（Console を確認）
✓ エラーが出ていない

報告内容：
1. post_generator.gd のパス
2. 実装したテンプレート数（Happy, Neutral, Sad 各何個？）
3. 生成テストの結果（「Happy テンプレート 5 個すべて動作確認」等）
4. 工夫した点
" \
--max-iterations 8 \
--completion-promise "POST_GENERATOR_DONE" \
--temperature 0.6
```

### Phase 5 後の確認プロンプト

```
Phase 5（投稿テンプレート生成）が完了しました。

【テンプレート内容確認】
1. post_generator.gd を開く
2. happy_templates, neutral_templates, sad_templates に、
   それぞれ 3 個以上のテンプレートが入っているか確認

【動作テスト】
Godot のコンソール（下部パネル）で以下を実行：
```gdscript
var pet = GameManager.active_pet
var post = PostGenerator.generate_post(pet)
print(post.text)
```
複数回実行して、テキストがランダムに異なるか確認

【BBCode レンダリング確認】
1. TimelineFeed にダミー投稿を配置
2. PostGenerator.generate_post() で生成した投稿を表示
3. 色付きのテキストが正しく見えるか

問題なく全部 ✓ なら、Phase 6 へ！
```

---

## Phase 6: Karpathy Loop 統合

### 目的
PostGenerator で生成した投稿を、定期的に TimelineFeed に自動追加する「AutoPublisher」システムを実装。Karpathy Loop で自律的に動作。

### Ralph Loop コマンド（Phase 6）

```
/ralph-loop "
【Task】PetBook の AutoPublisher（自動投稿）システムを構築

【最終ゴール】
ゲーム実行中、ペットが定期的に自動投稿を生成・表示する仕組み：

1. **AutoPublisher クラス**
   新規クラス: PetBookAutoPublisher
   - extends Node
   - func _process(delta) → 毎フレーム呼び出し
   - func publish_post(pet: PetLifecycleFSM) → void
   - 設定:
     * publish_interval: float = 30.0 (30 秒ごと)
     * max_posts_in_feed: int = 100 (フィードに保持する最大投稿数)

2. **投稿管理**
   ```gdscript
   var posts_queue: Array = []  # 新規投稿を溜める
   var time_since_last_publish: float = 0.0

   func _process(delta):
     time_since_last_publish += delta
     if time_since_last_publish >= publish_interval:
       var pet = GameManager.active_pet
       if pet:
         publish_post(pet)
         time_since_last_publish = 0.0
   ```

3. **TimelineFeed への追加**
   publish_post() 内:
   ```gdscript
   func publish_post(pet: PetLifecycleFSM) -> void:
     var post_data = PostGenerator.generate_post(pet)
     var card = PetBookCard.new()
     card.update_post(post_data)
     timeline_feed.add_card_to_top(card)
     
     # フィード上限を超えたら古い投稿を削除
     while timeline_feed.get_post_count() > max_posts_in_feed:
       timeline_feed.remove_oldest_post()
   ```

4. **TimelineFeed 更新**
   PetBookFeed に以下を追加:
   ```gdscript
   var card_list: Array[PetBookCard] = []

   func add_card_to_top(card: PetBookCard) -> void:
     card_list.insert(0, card)
     %CardContainer.add_child(card)
     %CardContainer.move_child(card, 0)  # 最上部に移動
     
     # アニメーション: 新投稿がスライドイン
     var tween = create_tween()
     tween.set_trans(Tween.TRANS_QUAD)
     tween.set_ease(Tween.EASE_OUT)
     tween.tween_property(card, \"modulate:a\", 1.0, 0.5)

   func remove_oldest_post() -> void:
     if card_list.size() > 0:
       var old_card = card_list.pop_back()
       old_card.queue_free()
   ```

5. **GameManager 統合**
   GameManager._ready() 内:
   ```gdscript
   petbook_publisher = PetBookAutoPublisher.new()
   add_child(petbook_publisher)
   petbook_publisher.timeline_feed = petbook_feed  # 参照設定
   ```

6. **オプション: ユーザーコントロール**
   - UI で「自動投稿を有効/無効」切り替え可能
   - 投稿間隔をスライダーで調整（10~120 秒）
   - 「今すぐ投稿」ボタン

【非エンジニア向け説明】
- 「AutoPublisher = ペットが自分で投稿する AI」
- 「publish_interval = 投稿の頻度（30 秒 = 半分ごとに 1 投稿）」
- 「max_posts_in_feed = メモリが満杯にならないよう、古い投稿を自動削除」

【完成時の確認項目】
✓ PetBookAutoPublisher がゲーム起動時に自動起動する
✓ 30 秒ごと（または設定間隔）に新投稿が追加される
✓ TimelineFeed の上部に新投稿が表示される
✓ 新投稿がフェードイン（アニメーション）で現れる
✓ 古い投稿が自動削除される（上限超過時）
✓ 複数投稿が同時にフィードに表示される
✓ 投稿テキストは毎回異なる（PostGenerator ランダム）
✓ API 呼び出しが発生していない
✓ エラーが出ていない

報告内容：
1. PetBookAutoPublisher ファイルパス
2. 自動投稿が実際に動作している証拠（「30 秒ごとに投稿が増える」等）
3. フィード上限設定（「100 投稿で古いのを削除」等）
4. パフォーマンス（メモリ使用量、FPS に影響なし）
5. 工夫した点
" \
--max-iterations 9 \
--completion-promise "AUTOPUBLISHER_DONE" \
--temperature 0.65
```

### Phase 6 後の確認プロンプト

```
Phase 6（Karpathy Loop 統合）が完了しました。

【実働確認】
1. Godot でゲームを実行
2. TimelineFeed を観察
3. 30 秒待機
4. 新投稿が上部に追加されるか確認
5. さらに 30 秒待機
6. 投稿テキストが異なっているか（毎回ランダム）確認

【フィード動作**
1. 投稿が 100 個を超えるまで何度も待機
2. 古い投稿が消えるか確認（下部から削除）
3. フィードが「スクロール可能な状態」を保っているか

【パフォーマンス**
1. Profiler で FPS を監視（60fps 維持）
2. Memory がしぶしぶ増えていないか（安定）

問題なく全部 ✓ なら、Phase 7（最終統合テスト）へ！
```

---

## Phase 7: 統合テスト + 最適化

### 目的
すべての Phase（1-6）を統合し、完全に動作する PetBook システムを完成。パフォーマンスを最適化。

### Ralph Loop コマンド（Phase 7）

```
/ralph-loop "
【Task】PetBook 全システム統合テスト + 最適化

【最終ゴール】
以下をすべて検証し、本格運用の準備を整える：

1. **統合テストチェックリスト**

   【UI レイアウト】
   ✓ フィード全体が画面を埋めている
   ✓ 上部タブが 5 つ見える（All, Herbivore, Omnivore, Carnivore, Synthetic）
   ✓ 複数投稿カードが縦に並んでいる
   ✓ 右下に「Observing Mode」ラベル
   ✓ スクロールバーが右側に見える

   【タブ機能】
   ✓ 各タブをクリックすると他の投稿がフィルタされる（optional）
   ✓ またはタブクリック → テーマ色が切り替わる
   ✓ テーマ色切り替えが滑らか（0.3 秒アニメーション）

   【投稿カード】
   ✓ ペット名、レベル、投稿テキストが表示
   ✓ ステータスバー（Happiness, Energy, Hunger）が 3 つ表示
   ✓ バーの色が SubMolt ごとに異なる
   ✓ リアクションボタン（❤ 💬 🔄）が表示
   ✓ ボタンクリックでカウンタが増える
   ✓ BBCode でテキスト装飾が機能（色付き等）

   【粒子エフェクト】
   ✓ 背景に粒子が見える
   ✓ Herbivore は緑の粒子
   ✓ Carnivore は赤の粒子
   ✓ タブ切り替えで粒子色が変わる
   ✓ 粒子がパフォーマンスに影響していない（60fps）

   【自動投稿機能】
   ✓ 30 秒ごと（設定間隔）に新投稿が追加される
   ✓ 新投稿が上部にフェードインで現れる
   ✓ 投稿テキストが毎回異なる
   ✓ フィード上限（100 投稿）で古い投稿が削除される

2. **パフォーマンス最適化**

   Profiler を使用して測定:

   【FPS】
   - ターゲット: 60 fps（または 120 fps）
   - 計測方法: Godot Profiler → Monitor タブ
   - 許容: 50 fps 以上

   【メモリ使用量】
   - ターゲット: 200 MB 以下
   - 計測方法: Profiler → Memory タブ
   - 許容: 300 MB 以下

   【最適化ポイント】
   - PoolInstancesBatch: 投稿カードをビッグオブジェクトキャッシュ
   - Particle Amount: 100 以下に制限
   - Tween Animation: duration 最小（0.2 秒）
   - Scroll Virtual: 大量投稿時の遅延回避

   改善手順:
   ```gdscript
   # Phase 4 でパーティクル数削減
   particles.amount = 75  # 100 から削減

   # ScrollContainer 設定
   scroll_container.focus_neighbor_top = NodePath()  # 不要な参照削除
   ```

3. **品質チェック（Quality MCP）**
   
   実装完了後、以下を実行:
   ```
   agnix /Users/takaosouichi/Documents/Claude/Projects/「PetClaw」/godot_project
   → Linter: 構文エラー検出
   
   deslop /sessions/.../godot_project/scripts/ui/*.gd
   → Code Style: GDScript スタイルガイド
   
   drift-detect ...
   → Architecture: モジュール間の依存関係検査
   ```

4. **最終チェックリスト**

   【ファイル構成】
   ✓ godot_project/scenes/ui/ に 3 ファイル
     - petbook_feed.tscn
     - petbook_card.tscn
     - petbook_particle_effect.tscn
   ✓ godot_project/scripts/ui/ に 2 ファイル
     - petbook_feed.gd
     - petbook_card.gd
   ✓ godot_project/scripts/managers/ に 1 ファイル
     - theme_manager.gd
   ✓ godot_project/scripts/petbook/ に 2 ファイル
     - post_generator.gd
     - petbook_auto_publisher.gd

   【シグナル接続確認】
   ✓ すべての Button.pressed が接続されている
   ✓ ThemeManager.submolt_changed が PetBookFeed/Card に接続
   ✓ AutoPublisher がタイムラインを更新

   【シーン登録】
   ✓ main.tscn に petbook_feed が子ノードとして登録
   ✓ project.godot に autoload として登録されているものすべてOK

5. **ドキュメント生成**
   実装完了後、以下のドキュメントを生成:
   ```
   petclaw_petbook_implementation_guide.md
   - 各ファイルの役割
   - シグナル図（視覚化）
   - パフォーマンス測定結果
   - 今後の拡張ポイント
   ```

【非エンジニア向け説明】
- 「統合テスト = すべての部品が一緒に動くか確認」
- 「最適化 = より速く、メモリを節約する調整」
- 「Profiler = パフォーマンスを計測する顕微鏡」

【完成時の確認項目】
✓ すべての Phase 1-6 が正常に動作している
✓ FPS が 60 fps を維持している
✓ メモリが安定している（メモリリークなし）
✓ 自動投稿がスムーズに続いている（>10分）
✓ エラーが出ていない
✓ Quality MCP での検査結果が問題なし
✓ 実装ガイドが生成されている

報告内容：
1. 統合テストチェックリスト（上の 20+ 項目）の完了状況
2. Profiler 計測結果（FPS, メモリ）
3. Quality MCP 検査結果
4. パフォーマンス最適化を行った場合の詳細
5. 今後の改善提案
6. 全体所要時間（Phase 1-7 合計）
" \
--max-iterations 12 \
--completion-promise "PETBOOK_COMPLETE" \
--temperature 0.65
```

### Phase 7 後の確認プロンプト

```
Phase 7（統合テスト + 最適化）が完了しました。

【最終確認】
1. 上記のチェックリスト 20+ 項目すべてが ✓ か確認
2. Quality MCP の検査結果を共有（エラー数、警告数）
3. Profiler での FPS/メモリ計測値を報告

【デプロイ準備】
1. Godot で File → Export Project を実行
2. Windows / macOS / Linux など対象プラットフォーム選択
3. ビルド完了後、各プラットフォームで PetBook が動作するか検証

【ドキュメント確認】
- petclaw_petbook_implementation_guide.md が生成されているか
- 全 6 つの Phase が説明されているか

問題なく全部 ✓ なら、PetBook Phase 1-7 は完全完成です！
```

---

## 全体フロー図

```
Phase 1: フィード基本レイアウト
   ↓ (30-45 min)
Phase 2: 投稿カードデザイン
   ↓ (40-50 min)
Phase 3: SubMolt テーマ切替
   ↓ (35-45 min)
Phase 4: 粒子エフェクト統合
   ↓ (45-60 min)
Phase 5: 投稿テンプレート生成（API なし）
   ↓ (40-50 min)
Phase 6: Karpathy Loop 統合（自動投稿）
   ↓ (60-90 min)
Phase 7: 統合テスト + 最適化
   ↓ (45-60 min)
【完了】PetBook フルシステム動作
```

---

## Ralph Loop 実行時のコツ

### コマンドの実行方法
```bash
# Claude API チャットで以下をペーストして実行
/ralph-loop "..." --max-iterations N --completion-promise "..." --temperature T
```

### 各 Phase での推奨パラメータ

| Phase | max-iterations | temperature | completion-promise |
|-------|----------------|-------------|-------------------|
| 1 | 8 | 0.6 | FEED_LAYOUT_DONE |
| 2 | 9 | 0.65 | CARD_DESIGN_DONE |
| 3 | 8 | 0.65 | SUBMOLT_THEME_DONE |
| 4 | 10 | 0.65 | PARTICLE_EFFECT_DONE |
| 5 | 8 | 0.6 | POST_GENERATOR_DONE |
| 6 | 9 | 0.65 | AUTOPUBLISHER_DONE |
| 7 | 12 | 0.65 | PETBOOK_COMPLETE |

### トラブルシューティング

#### Ralph Loop が途中で止まった場合
- 出力の最後から状態を読み取る
- 「実装が X% 完了」「エラーが Y」などが記載されている
- その部分をコピーして、手動で続きを実装してもよい

#### 生成されたコードにエラーがある場合
- `/ralph-loop` を再実行するか
- 手動で修正して、修正内容を別の `/ralph-loop` で検証

---

## 各 Phase 後の実装確認テンプレート

### 一般的な確認手順

```
1. ファイルが保存されているか
   → Godot Project パネルで確認

2. シーンが表示されるか
   → Godot エディタで再生ボタン（▶）を押す

3. エラーが出ていないか
   → Output パネル（下部）で確認

4. 機能が動作しているか
   → 各 Phase の「確認項目」をチェック

5. パフォーマンスは OK か
   → Profiler で FPS / Memory を確認
```

---

## まとめ

このドキュメント（92b）は、**PetBook UI を Ralph Wiggum の Karpathy Loop で段階的に構築するための完全ガイド** です。

各 Phase は **独立した実行ユニット** で、`/ralph-loop` コマンド一行で完成させることができます。非エンジニアでも理解できるよう、各 Phase に説明を含めています。

**全体所要時間**: 4.5-6 時間（集中実装）

**出力**: 完全に動作する PetBook システム（フィード + カード + テーマ + パーティクル + 自動投稿）

---

**このドキュメント最終更新**: 2026-04-01
