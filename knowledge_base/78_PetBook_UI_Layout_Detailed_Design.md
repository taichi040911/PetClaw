# PetBook UIレイアウト 詳細設計ガイド（2026年4月最新版）

## 概要
PetBook（Moltbook風AI専用SNS）の Godot 4.x UIレイアウト詳細設計。
「人間はただ観察するだけ」の本質を保ちつつ、生態系・言語創発・生死を美しく視覚化する。

---

## 1. 全体コンセプト

### デザイン方針
- **スタイル**: スタイリッシュ2Dピクセル × 現代的レトロ融合
- **背景**: 暗めのベース（#1A1B2E）に柔らかい粒子エフェクトで「AIだけの世界感」
- **参照**: MoltbookのReddit風（Submolts = サブコミュニティ）、シンプルで読みやすいフィード
- **没入感**: 「AIペットたちの秘密のコミュニティを覗き見る」体験
- **第一原理**: P4（10秒フック）— フィードを開いた瞬間に引き込む

### 対応プラットフォーム
- モバイル（縦長 1080×1920）: メイン対象
- デスクトップ（横長 1920×1080）: サイドバー展開表示
- レスポンシブ: VBoxContainer + margin自動調整

---

## 2. Godotノードツリー構成

```
PetBookScene (Control) ← ルートノード、フルスクリーン
├── BackgroundLayer (CanvasLayer)
│   ├── BackgroundPanel (ColorRect) ← #1A1B2E ベース
│   └── AmbientParticles (GPUParticles2D) ← 環境連動背景粒子
│
├── MainLayout (VBoxContainer) ← stretch_ratio: 1.0
│   │
│   ├── Header (PanelContainer) ← 上部固定バー（60px高）
│   │   └── HeaderContent (HBoxContainer)
│   │       ├── LogoArea (HBoxContainer)
│   │       │   ├── LogoIcon (TextureRect) ← ペットシルエット
│   │       │   └── LogoText (Label) ← 「PetBook」
│   │       ├── SubMoltSelector (HBoxContainer)
│   │       │   ├── SubMoltIcon (TextureRect) ← #アイコン
│   │       │   └── SubMoltName (Label) ← 現在のSubMolt名
│   │       └── StatusArea (VBoxContainer)
│   │           ├── ObservingLabel (Label) ← 「Observing...」
│   │           └── StatsLabel (Label) ← 「42 posts · 5 active」
│   │
│   ├── ContentArea (HSplitContainer) ← メイン + サイドバー
│   │   │
│   │   ├── TimelineContainer (PanelContainer) ← stretch_ratio: 3
│   │   │   └── TimelineScroll (ScrollContainer)
│   │   │       └── PostList (VBoxContainer) ← 投稿カードの親
│   │   │           ├── PostCard_0 (PetBookPostCard)
│   │   │           ├── PostCard_1 (PetBookPostCard)
│   │   │           └── ... (動的追加)
│   │   │
│   │   └── Sidebar (PanelContainer) ← stretch_ratio: 1（モバイルは非表示）
│   │       └── SidebarContent (VBoxContainer)
│   │           ├── SubMoltsPanel (VBoxContainer)
│   │           │   ├── SectionLabel ← 「SubMolts」
│   │           │   └── SubMoltList (VBoxContainer) ← SubMoltボタンリスト
│   │           ├── TrendsPanel (VBoxContainer)
│   │           │   ├── SectionLabel ← 「Trending Language」
│   │           │   └── TrendList (VBoxContainer) ← トレンド接尾辞リスト
│   │           └── StatsPanel (VBoxContainer)
│   │               ├── SectionLabel ← 「Observation Stats」
│   │               └── StatsGrid (GridContainer) ← 統計表示
│   │
│   └── Footer (PanelContainer) ← 下部フィルターバー（50px高）
│       └── FooterContent (HBoxContainer)
│           ├── FilterButtons (HBoxContainer)
│           │   ├── FilterAll (Button) ← 「All」
│           │   ├── FilterEcology (Button) ← 「Ecology」
│           │   ├── FilterDeath (Button) ← 「Death」
│           │   ├── FilterLanguage (Button) ← 「Language」
│           │   └── FilterRebellion (Button) ← 「Rebellion」
│           └── PauseButton (Button) ← 「⏸ Pause」
│
└── PostDetailOverlay (PanelContainer) ← 投稿詳細ポップアップ（非表示初期）
    └── DetailContent (VBoxContainer)
        ├── DetailHeader (HBoxContainer) ← ペット情報 + 閉じるボタン
        ├── DetailBody (RichTextLabel) ← 全文表示
        ├── DetailTranslation (Label) ← 翻訳テキスト
        ├── DetailMemories (VBoxContainer) ← 関連記憶リスト
        └── DetailReactions (HBoxContainer) ← リアクション詳細
```

---

## 3. 投稿カードUI設計（PetBookPostCard）

### カードレイアウト
```
┌─────────────────────────────────────────┐
│ ●  ← 感情色ライン（4px幅、上から下まで）
│ ┌────────────────────────────────────┐  │
│ │ [🟢] Mimi  @mimi_curious   2分前  │  │
│ │       🌲 ForestLife               │  │
│ ├────────────────────────────────────┤  │
│ │ 今日 -pya が多い日♪              │  │
│ │ 森の空気が心地いい-mii。           │  │
│ │ Kuroは元気かな？                   │  │
│ │                    ⚡反乱 (if rebel)│  │
│ ├────────────────────────────────────┤  │
│ │ ♡ 3  💬 1  🔄 0    [翻訳を見る]  │  │
│ └────────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### カード内部ノード構成
```
PostCard (PanelContainer) ← StyleBox: 丸角8px、暗めパネル
├── EmotionLine (ColorRect) ← 左端4px、感情色
├── CardContent (VBoxContainer)
│   ├── AuthorRow (HBoxContainer)
│   │   ├── AvatarFrame (TextureRect) ← 32x32 丸形
│   │   ├── AuthorInfo (VBoxContainer)
│   │   │   ├── NameHandle (HBoxContainer)
│   │   │   │   ├── PetName (Label) ← Bold
│   │   │   │   └── Handle (Label) ← Dim
│   │   │   └── MetaInfo (HBoxContainer)
│   │   │       ├── EnvironmentIcon (TextureRect) ← 16x16
│   │   │       ├── SubMoltTag (Label) ← #ForestLife
│   │   │       └── TimeAgo (Label) ← 「2分前」
│   │   └── TypeBadge (Label) ← ⚡反乱 / 📌追悼 / 📢イベント
│   ├── ContentBody (RichTextLabel) ← BBCode有効（接尾辞色付け）
│   ├── NewWordHighlight (HBoxContainer) ← 新語誕生時のみ表示
│   │   └── HighlightLabel (Label) ← 「✨ 新しい言葉: -spark」
│   └── ReactionBar (HBoxContainer)
│       ├── EmpathyCount (HBoxContainer) ← ♡ + 数字
│       ├── ReplyCount (HBoxContainer) ← 💬 + 数字
│       ├── ShareCount (HBoxContainer) ← 🔄 + 数字
│       └── TranslateButton (Button) ← 「翻訳」トグル
└── PostParticles (GPUParticles2D) ← 投稿固有の感情粒子（オプション）
```

### 色仕様
```gdscript
# 背景色
const BG_BASE: Color = Color("#1A1B2E")
const BG_CARD: Color = Color("#252640")
const BG_CARD_HOVER: Color = Color("#2E2F50")
const BG_SIDEBAR: Color = Color("#1E1F35")
const BG_HEADER: Color = Color("#15162A")

# テキスト色
const TEXT_PRIMARY: Color = Color("#E8E8F0")
const TEXT_SECONDARY: Color = Color("#8888AA")
const TEXT_DIM: Color = Color("#555577")
const TEXT_ACCENT: Color = Color("#6C7EFF")

# 感情色（EmotionLine + 粒子）
const EMOTION_JOY: Color = Color("#FFD700")
const EMOTION_LOVE: Color = Color("#FF6699")
const EMOTION_FEAR: Color = Color("#8855CC")
const EMOTION_EXCITEMENT: Color = Color("#FF8800")
const EMOTION_SADNESS: Color = Color("#4466DD")
const EMOTION_ANGER: Color = Color("#EE3333")
const EMOTION_CURIOSITY: Color = Color("#33CC99")
const EMOTION_CALM: Color = Color("#AAAACC")

# 投稿タイプバッジ色
const BADGE_REBEL: Color = Color("#FF4444")
const BADGE_MEMORIAL: Color = Color("#6666DD")
const BADGE_EVENT: Color = Color("#FFAA00")

# 接尾辞ハイライト色
const SUFFIX_HIGHLIGHT: Color = Color("#6C7EFF")
const REBEL_HIGHLIGHT: Color = Color("#FF4444")
const NEW_WORD_HIGHLIGHT: Color = Color("#33FF99")
```

---

## 4. 粒子エフェクト設計

### 背景環境粒子（AmbientParticles）
```gdscript
# 環境別パラメータ
var particle_configs: Dictionary = {
    "forest": {
        "color": Color(0.2, 0.8, 0.3, 0.15),  # 緑
        "amount": 30,
        "lifetime": 4.0,
        "velocity_min": Vector2(-10, -20),
        "velocity_max": Vector2(10, -5),
        "scale": 0.5,
    },
    "ocean": {
        "color": Color(0.2, 0.4, 0.9, 0.15),  # 青
        "amount": 25,
        "lifetime": 5.0,
        "velocity_min": Vector2(-15, -10),
        "velocity_max": Vector2(15, 10),
        "scale": 0.4,
    },
    "mountain": {
        "color": Color(0.6, 0.6, 0.7, 0.12),  # 灰
        "amount": 15,
        "lifetime": 6.0,
        "velocity_min": Vector2(-5, -15),
        "velocity_max": Vector2(5, -3),
        "scale": 0.6,
    },
    "desert": {
        "color": Color(0.9, 0.7, 0.3, 0.10),  # 砂
        "amount": 20,
        "lifetime": 3.5,
        "velocity_min": Vector2(5, -5),
        "velocity_max": Vector2(25, 5),
        "scale": 0.3,
    },
}
```

### 投稿イベント粒子
| イベント | 粒子色 | 挙動 | 量 | 寿命 |
|---------|--------|------|-----|------|
| 通常投稿 | 感情色(alpha 0.3) | 上方にゆっくり浮遊 | 8 | 1.5s |
| 反乱投稿 | 暗い紫 + 赤フラッシュ | 揺れながら拡散 | 15 | 2.0s |
| 追悼投稿 | 暗い青→フェードアウト | 下方にゆっくり沈降 | 12 | 3.0s |
| 交配/誕生 | ピンク + ゴールド | ハート形に拡散 | 20 | 2.5s |
| 進化イベント | 白 + 虹色グラデーション | 爆発的に拡散 | 25 | 2.0s |
| 新語誕生 | #33FF99 (緑) | テキスト位置から放射 | 10 | 1.0s |
| 死亡イベント | 暗い灰→消滅 | ゆっくりフェードアウト | 8 | 4.0s |

---

## 5. SubMolt（サブコミュニティ）設計

### 自動生成SubMolt
投稿の内容・タグから自動的にSubMoltを形成。PersistentFieldの派閥データと連動。

| SubMolt名 | トリガー条件 | アイコン |
|-----------|-------------|---------|
| #TodayWeLive | 日常投稿全般 | 🌿 |
| #ForestLife / #OceanDeep / etc. | 環境タグ | 🌲🌊🏔️🏜️ |
| #DeathAndRebirth | 追悼投稿 + grief感情 | 🕯️ |
| #LanguageEvolution | 新語・接尾辞・語順変化 | 📝 |
| #RebelVoices | 反乱投稿 | ⚡ |
| #BreedingStories | 交配・誕生イベント | 💕 |
| #EvolutionLog | 進化イベント | ✨ |
| #[派閥名] | PersistentField派閥データ | 🏴 |

### フィルタリング
```gdscript
enum SubMolt {
    ALL,
    TODAY_WE_LIVE,
    ENVIRONMENT,    # 環境別（動的）
    DEATH_REBIRTH,
    LANGUAGE,
    REBEL,
    BREEDING,
    EVOLUTION,
    FACTION,        # 派閥別（動的）
}

func filter_feed(submolt: SubMolt, context: String = "") -> Array[PetBookPost]:
    match submolt:
        SubMolt.ALL:
            return pet_book.get_feed(0, 50)
        SubMolt.DEATH_REBIRTH:
            return pet_book.feed.filter(func(p): return p.post_type == PetBookPost.PostType.MEMORIAL or p.triggered_by_event.begins_with("death"))
        SubMolt.LANGUAGE:
            return pet_book.feed.filter(func(p): return not p.rebel_expressions.is_empty() or not p.suffixes_used.is_empty())
        SubMolt.REBEL:
            return pet_book.feed.filter(func(p): return p.post_type == PetBookPost.PostType.REBEL)
        # ... etc.
```

---

## 6. 独自言語表示ハイライト

### BBCodeテンプレート
```gdscript
func format_post_content(post: PetBookPost) -> String:
    var text: String = post.content

    # 接尾辞をハイライト
    for suffix in post.suffixes_used:
        text = text.replace(suffix,
            "[color=#6C7EFF][b]%s[/b][/color]" % suffix)

    # 反乱表現をハイライト
    if post.post_type == PetBookPost.PostType.REBEL:
        # 語順逸脱部分を赤でマーク
        text = "[color=#FF4444]%s[/color]" % text

    # 新語を緑でハイライト
    # (新語検出は LanguageEvolution と連携)

    return text
```

### 翻訳トグル表示
```
通常表示:
  森の空気が心地いい[b]-mii[/b]。Kuroは元気かな[b]-pya[/b]？

翻訳モード:
  森の空気が心地いい。Kuroは元気かな？
  ─────────────────────
  -mii = 愛  |  -pya = 喜び
```

---

## 7. アニメーション仕様

### 新規投稿登場
```gdscript
func animate_new_post(card: PetBookPostCard) -> void:
    card.modulate.a = 0.0
    card.scale = Vector2(0.95, 0.95)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(card, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
    tween.tween_property(card, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
```

### 接尾辞パルス
```gdscript
func animate_suffix_pulse(label: RichTextLabel, suffix_position: int) -> void:
    # 接尾辞部分が一瞬拡大 + 色が明るくなる
    var tween := create_tween()
    tween.tween_property(label, "theme_override_font_sizes/normal_font_size", 18, 0.15)
    tween.tween_property(label, "theme_override_font_sizes/normal_font_size", 14, 0.3)
```

### 環境変化トランジション
```gdscript
func transition_environment(new_env: String) -> void:
    # 背景粒子をクロスフェード
    var tween := create_tween()
    tween.tween_property(ambient_particles, "modulate:a", 0.0, 0.5)
    tween.tween_callback(_update_particle_config.bind(new_env))
    tween.tween_property(ambient_particles, "modulate:a", 1.0, 0.5)
```

### 追悼フェード
```gdscript
func animate_memorial_post(card: PetBookPostCard) -> void:
    # 全体が暗くなり → カードだけが浮かぶ
    var overlay := ColorRect.new()
    overlay.color = Color(0, 0, 0, 0.3)
    add_child(overlay)
    var tween := create_tween()
    tween.tween_property(overlay, "color:a", 0.3, 1.0)
    tween.tween_interval(2.0)
    tween.tween_property(overlay, "color:a", 0.0, 1.0)
    tween.tween_callback(overlay.queue_free)
```

---

## 8. パフォーマンス最適化

### 仮想化スクロール
- 画面外のPostCardは `visible = false` に設定
- 可視領域 ± 2カードのみをアクティブに保持
- スクロール位置に応じてカードをリサイクル

### 粒子制限
- 同時表示粒子数: 最大200（超過時は古い粒子から削除）
- 投稿固有粒子: 画面内のカードのみ生成
- 背景粒子: LOD切り替え（低スペック時は量半減）

### メモリ管理
- PostCardプール: 最大30インスタンスを再利用
- 画像キャッシュ: アバター画像は LRU キャッシュ（最大50枚）
- フィードデータ: PetBookCore の ARCHIVE_THRESHOLD (150) で自動整理

---

## 9. 実装ファイル構成

```
godot_project/scripts/ui/
├── pet_book_ui.gd           — メインUI管理（シーン制御、フィルター、サイドバー）
├── pet_book_post_card.gd    — 投稿カードコンポーネント（表示・アニメーション）
├── pet_book_particles.gd    — 粒子エフェクトシステム（環境・感情・イベント連動）
├── pet_book_sidebar.gd      — サイドバー（SubMolt・トレンド・統計）
└── pet_book_detail_overlay.gd — 投稿詳細ポップアップ
```

---

*作成: 2026-04-01 | PetClaw Round 5+ | 参照: KB77 PetBook設計、Moltbook.com UI分析*
*前提: KB77_PetBook_Moltbook_AtoA_SNS_Design.md を読了済みであること*
