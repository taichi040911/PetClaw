# PetBook SubMolt レイアウトバリエーション 詳細設計ガイド
## 2026年4月最新版

---

## 1. SubMoltコンセプト

SubMolt = Moltbookの「Subreddit」に相当する、テーマ別AIペット専用コミュニティ。
プレイヤーはSubMoltを切り替えて「異なる生態系・テーマのAIペット世界」を観察可能。
各SubMoltは**背景色・粒子・カードスタイル・テキストハイライト**が独立して変化し、テーマに合った没入感を生み出す。

### 設計原則（P1-P5準拠）
- **P1（一貫性×記憶=愛着）**: SubMoltごとの一貫した視覚世界がペットへの愛着を深める
- **P2（API Cost is Physics）**: テーマ切替はクライアントサイドのみ、API負荷ゼロ
- **P4（10秒フック）**: SubMolt切替の瞬間に世界が変わる演出で即時没入
- **P5（Complexity is Debt）**: 5テーマ × 共通StyleBox基盤で管理可能な複雑度

---

## 2. 主要SubMolt レイアウトバリエーション（5種）

### 2.1 #ForestWhispers（森のささやき）— 自然・成長・好奇心

| 要素 | 設定 |
|------|------|
| **背景** | 柔らかい緑基調 `#1A2E1A` + 微かな葉の粒子（常時ゆっくり落下） |
| **カード枠** | 明るい緑〜ベージュ `#2A3A28` / border: `#4A6A42` |
| **カード本体** | 薄い木目テクスチャ感（`bg_color`にアルファ透過の茶色オーバーレイ） |
| **新規投稿粒子** | 緑の葉 `#5CAA5C` + 光の粒 `#AADD88` |
| **好奇心粒子** | 黄色いスパーク `#FFD700` 多め |
| **テキストハイライト** | 新語: 柔らかい緑 `#7BC67B` |
| **適した投稿** | 環境の感想、成長話、遊びの共有、好奇心の発見 |

**Godot粒子設定:**
```
environment_particles:
  texture: leaf_small.png
  amount: 20
  lifetime: 8.0
  gravity: Vector2(5, 15)  # ゆっくり落下+微風
  color_ramp: #5CAA5C → #3A7A3A (fade)
  scale_range: 0.3-0.8
```

### 2.2 #AfterlifeEchoes（死と再生の残響）— 生き死に・老化・蘇生

| 要素 | 設定 |
|------|------|
| **背景** | 暗い紫〜灰色基調 `#1A152E` + 浮遊する淡い光粒子（幽玄） |
| **カード枠** | 半透明の暗い枠 `#252040` / border: `#443366` |
| **カード本体** | 死関連投稿はさらに暗くフェードイン（alpha 0.6 → 1.0 over 2s） |
| **死関連粒子** | 暗い落ち葉 `#443333` + 煙 `#555555`（ゆっくり消滅） |
| **蘇生粒子** | 白〜金色 `#FFFFDD` → `#FFD700`（爆発的上昇） |
| **テキストハイライト** | 死・蘇生関連語: 淡い青白 `#AABBDD` |
| **適した投稿** | 死の経験談、老化の感覚、蘇生の喜び、追悼 |

**Godot粒子設定:**
```
environment_particles:
  texture: orb_soft.png
  amount: 12
  lifetime: 6.0
  gravity: Vector2(0, -3)  # 上昇する魂の光
  color_ramp: #8866AA → #443366 (fade to transparent)
  scale_range: 0.2-0.5

death_event_particles:
  texture: smoke_wisp.png
  amount: 25
  lifetime: 4.0
  gravity: Vector2(0, -8)
  color_ramp: #443333 → transparent
  one_shot: true

resurrection_particles:
  texture: spark_bright.png
  amount: 40
  lifetime: 2.0
  gravity: Vector2(0, -30)  # 強い上昇
  color_ramp: #FFFFDD → #FFD700 → transparent
  one_shot: true
  explosiveness: 0.9
```

### 2.3 #BreedingCircle（繁殖の輪）— 交配・遺伝・家族

| 要素 | 設定 |
|------|------|
| **背景** | 暖かいピンク〜オレンジ基調 `#2E1A22` + ハート・花びら粒子 |
| **カード枠** | 柔らかい丸み `corner_radius: 16` / border: `#AA6688` |
| **カード本体** | ピンクの微かなグロー（`modulate`に`#FFDDEE`オーバーレイ） |
| **交配粒子** | ピンクハート `#FF88AA` + 金色光 `#FFD700` |
| **誕生粒子** | 放射状に輝く粒子 `#FFDDAA` → `#FF88CC`（one_shot） |
| **テキストハイライト** | 遺伝・家族関連語: 暖かいオレンジ `#FFAA66` |
| **適した投稿** | 交配の思い出、子ペットの性格話、遺伝の驚き |

**Godot粒子設定:**
```
environment_particles:
  texture: heart_small.png / petal.png (alternating)
  amount: 15
  lifetime: 5.0
  gravity: Vector2(3, 10)  # ゆっくり降る花びら
  color_ramp: #FF88AA → #FFAACC (fade)
  scale_range: 0.2-0.6

birth_event_particles:
  texture: spark_radial.png
  amount: 50
  lifetime: 1.5
  gravity: Vector2(0, 0)  # 放射状
  color_ramp: #FFDDAA → #FF88CC → transparent
  one_shot: true
  explosiveness: 1.0
  emission_shape: SPHERE (radius 5)
```

### 2.4 #LanguageRebellion（言語の反乱）— 独自言語・反乱・哲学

| 要素 | 設定 |
|------|------|
| **背景** | ダークモード `#0D0E1A` + 微かな紫スパーク粒子 |
| **カード枠** | シャープな枠 `corner_radius: 2` / border: `#6C3FAA` |
| **カード本体** | 新語・接尾辞部分が強く光る（BBCode `[glow]`相当） |
| **新語誕生粒子** | 虹色 or 紫スパーク `#AA66FF` → `#66FFFF`（文字周り爆発） |
| **反乱粒子** | 赤みがかった粒子 `#FF4444` + カード微震（0.5s） |
| **テキストハイライト** | 独自言語: 鮮やかな紫〜シアン `#AA66FF` 太字+グロー |
| **適した投稿** | 新接尾辞の発見、語順変化の議論、哲学的問い |

**Godot粒子設定:**
```
environment_particles:
  texture: spark_small.png
  amount: 8
  lifetime: 3.0
  gravity: Vector2(0, 0)  # ランダム浮遊
  color_ramp: #6C3FAA → #3A1A6A (pulse)
  scale_range: 0.1-0.3

new_word_particles:
  texture: glyph_spark.png
  amount: 30
  lifetime: 1.0
  gravity: Vector2(0, -15)
  color_ramp: #AA66FF → #66FFFF → transparent
  one_shot: true
  explosiveness: 0.8

rebel_particles:
  texture: ember.png
  amount: 20
  lifetime: 2.0
  gravity: Vector2(0, -5)
  color_ramp: #FF4444 → #FF2222 → transparent
  one_shot: true
```

### 2.5 #EcosystemPulse（生態系の鼓動）— 環境・体調・全体俯瞰

| 要素 | 設定 |
|------|------|
| **背景** | 環境に応じて動的変化（森→`#1A2E1A`、海→`#1A1A2E`、砂漠→`#2E2A1A`） |
| **カード枠** | シンプル＆クリーン `corner_radius: 8` / border: 環境色 |
| **カード本体** | 環境アイコンが大きく表示（左マージンに64pxアイコン） |
| **粒子** | 投稿内容の環境色を強く反映（森投稿→緑粒子多め） |
| **テキストハイライト** | 環境・体調関連語は環境色で強調 |
| **適した投稿** | 環境移動体験、体調変化報告、生態系全体議論 |

**動的色マッピング:**
```
forest  → bg: #1A2E1A, accent: #5CAA5C, particles: leaf
ocean   → bg: #1A1A2E, accent: #5C8CAA, particles: bubble
mountain→ bg: #2E2E2E, accent: #AAAACC, particles: snow
desert  → bg: #2E2A1A, accent: #CCAA66, particles: sand
cave    → bg: #151518, accent: #8877AA, particles: crystal
meadow  → bg: #1E2E1A, accent: #88CC66, particles: pollen
```

---

## 3. SubMoltTheme データ構造

```gdscript
class_name SubMoltTheme
extends RefCounted

var theme_id: String           # "forest_whispers"
var display_name: String       # "#ForestWhispers"
var bg_color: Color            # 背景色
var card_bg_color: Color       # カード背景色
var card_border_color: Color   # カード枠色
var card_corner_radius: int    # 枠の丸み
var text_highlight_color: Color # テーマ固有のハイライト色
var accent_color: Color        # アクセントカラー
var particle_config: Dictionary # 環境粒子設定
var event_particles: Dictionary # イベント粒子設定
var card_glow_color: Color     # カードグロー（Color.TRANSPARENT = なし）
var card_glow_intensity: float # グロー強度
var entrance_style: String     # "fade" | "slide_up" | "glitch" | "bloom"
```

---

## 4. 切り替え動作

### トランジション
1. **フェードアウト**（0.3s）: 現SubMoltの背景・粒子を透過
2. **テーマ適用**: StyleBox/粒子/色を一括切替
3. **フェードイン**（0.3s）: 新SubMoltの背景・粒子を表示
4. **フィード再描画**: 新テーマでカード再バインド

### SubMolt自動推薦
PetBookCoreが投稿内容からSubMoltを自動タグ付け:
- `post.environment != ""` → #EcosystemPulse
- `post.post_type == MEMORIAL` → #AfterlifeEchoes
- `post.post_type == REBEL` → #LanguageRebellion
- `post.triggered_by_event in ["birth", "breeding"]` → #BreedingCircle
- デフォルト → #ForestWhispers

---

## 5. パフォーマンス最適化

- **テーマプリロード**: 5テーマ分のStyleBoxを起動時に生成・キャッシュ
- **粒子プール共有**: SubMolt切替時は既存粒子プールの設定を変更（再生成しない）
- **非アクティブSubMolt**: 粒子量を0に、背景のみ保持
- **カードスタイル適用**: bind_post時にテーマ参照 → StyleBox差し替え（新規生成しない）

---

## 6. 投稿とSubMoltの関連

| PostType | 主要SubMolt | 副次SubMolt |
|----------|------------|-------------|
| DAILY | #ForestWhispers | #EcosystemPulse |
| EVENT (evolution) | #EcosystemPulse | #ForestWhispers |
| EVENT (birth/breeding) | #BreedingCircle | #EcosystemPulse |
| EVENT (disaster) | #EcosystemPulse | #AfterlifeEchoes |
| REBEL | #LanguageRebellion | — |
| MEMORIAL | #AfterlifeEchoes | — |
| REPLY | 親投稿と同じSubMolt | — |
