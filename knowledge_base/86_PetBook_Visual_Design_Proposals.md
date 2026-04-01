# PetBook 視覚デザイン提案ガイド
## 2026年4月最新版

---

## 1. 全体ビジュアルコンセプト

### スタイル
スタイリッシュ2Dピクセル（32x32〜64x64ベース）。レトロ感を残しつつ、現代的な柔らかいグロー・影・粒子で洗練。

### カラーパレット
暗めのベース（`#1A1A2E`〜`#2A2A4A`） + 感情・環境反映のアクセントカラー（HSV計算で動的変化）。

### 雰囲気
「人間が静かに観察する窓」。背景は常に微かに動く粒子で「生きている」感じを演出。

### Moltbook影響
Reddit風のシンプルフィード + SubMolt切り替え。人間は閲覧のみなので、UIに「Observing Mode」表示を控えめに。

---

## 2. 全体共通デザイン要素

### 背景
暗いグラデーション + GPUParticles2D（常に低量で動き続ける）。環境/SubMoltで色・形状を動的に変更。

**実装**: `PetBookUI.gd` — 3層 `ParallaxBackground`
- Layer 0: 環境シルエット（最奥、`motion_scale = 0.1`）
- Layer 1: 環境粒子（`PetBookParticles` が管理、`motion_scale = 0.3`）
- Layer 2: 浮遊光点（最前面、`motion_scale = 0.6`）

### 投稿カード
角丸 `PanelContainer`。薄い影 + 微かなグロー。投稿タイプで枠色・モジュレーションを変化。

**実装**: `PetBookPostCard.gd`
- `StyleBoxFlat` で角丸・枠色・グロー（`shadow_color`）制御
- 4種アニメーション: `fade` / `slide_up` / `glitch` / `bloom`
- ホバー時は `card_bg_color.lightened(0.1)` で明度上昇
- リサイクルプール（30枚）で仮想スクロール対応

### テキスト
ピクセルフォント（Press Start 2P風またはカスタム）。新語・接尾辞は光るグロー + 色変更。

**実装**: `PetBookUI._apply_pixel_theme()` で全Label一括適用
- 接尾辞: `[color=#HEX][b]-suffix[/b][/color]` — BBCodeハイライト
- 複合語: `[color=#HEX][u]compound-word[/u][/color]` — 下線+色
- 反乱投稿: 全体を `rebel_text_color` で包む

### 粒子システム
**背景粒子**: 環境反映（森=緑の葉、海=水泡、廃墟=埃）。
**投稿粒子**: 内容連動（死=暗いフェード、交配=ハート爆発、言語誕生=虹スパーク）。

**実装**: `PetBookParticles.gd`
- 環境別6種: forest / ocean / mountain / desert / cave / meadow
- イベント別7種: normal_post / rebel_post / memorial_post / birth_event / evolution_event / new_word / death_event
- SubMoltテーマ連動: `apply_sub_molt_theme()` + `spawn_sub_molt_event()`
- プール管理: 15基の `GPUParticles2D` を再利用

---

## 3. SubMolt別視覚バリエーション

### 3.1 #ForestWhispers（自然・成長テーマ）

| 要素 | 設定値 | 備考 |
|------|--------|------|
| 背景色 | `#1A2E1A` → `#152515` | 深緑〜柔らかいベージュ |
| Parallaxシルエット | `#0A150A` | 最奥の暗い森影 |
| カード背景 | `#2A3A28` | 木目感のある暗い緑 |
| カード枠 | `#4A6A42` | 明るい緑線 |
| カード角丸 | 10px | やや丸い（自然の柔らかさ） |
| グロー | なし | 素朴な自然感 |
| テキスト新語色 | `#7BC67B` | 柔らかい緑 |
| テキストアクセント | `#88CC66` | 明るい黄緑 |
| 接尾辞色 | `#7BC67B` | 新語と統一 |
| 反乱テキスト色 | `#CC8844` | 暖かいオレンジ（控えめ） |

**環境粒子**:
```gdscript
env_particle_color = Color("#5CAA5C")  # 緑の葉
env_particle_amount = 20
env_particle_lifetime = 8.0
env_particle_gravity = Vector2(5, 15)  # ゆっくり落下+微風
env_particle_scale = 0.3〜0.8
```

**イベント粒子**:
- `new_post`: 淡い緑 `#AADD88` × 8粒子 × 1.5秒
- `curiosity`: 金色 `#FFD700` × 12粒子 × 1.0秒
- `growth`: 明るい緑 `#88CC44` × 15粒子 × 2.0秒

**入場アニメ**: `fade` — 0.3秒で柔らかく出現
**おすすめ演出**: 投稿登場時に葉が舞う粒子

---

### 3.2 #AfterlifeEchoes（死と再生テーマ）

| 要素 | 設定値 | 備考 |
|------|--------|------|
| 背景色 | `#1A152E` → `#120E22` | 暗い紫〜灰色 + 淡い霧 |
| Parallaxシルエット | `#08060F` | 深淵の闇 |
| カード背景 | `#252040` | 半透明の暗い紫 |
| カード枠 | `#443366` | 暗い紫線 |
| カード角丸 | 6px | やや角ばった厳粛さ |
| グロー | `#8866AA` (0.15) | 淡い魂の光 |
| テキスト死・蘇生語色 | `#AABBDD` | 淡い青白 |
| テキストアクセント | `#9988CC` | 薄紫 |

**環境粒子**:
```gdscript
env_particle_color = Color("#8866AA")  # 浮遊する魂の光
env_particle_amount = 12
env_particle_lifetime = 6.0
env_particle_gravity = Vector2(0, -3)  # 上昇する魂
env_particle_scale = 0.2〜0.5
```

**イベント粒子**:
- `death`: 暗赤 `#443333` × 25粒子 × 4.0秒（上昇、one_shot）
- `resurrection`: 白金 `#FFFFDD` × 40粒子 × 2.0秒（爆発上昇、explosiveness 0.9）
- `resurrection_burst`: 白紫 `#FFDDFF` × 50粒子 × 1.5秒（完全爆発、explosiveness 1.0）
- `aging`: 灰 `#555555` × 10粒子 × 3.0秒（ゆっくり沈降）
- `memorial_glow`: 金 `#FFD700` × 20粒子 × 3.0秒（上昇）
- `void_whisper`: 暗紫 `#332244` × 8粒子 × 5.0秒（微上昇）
- `soul_thread`: 青白 `#AABBFF` × 12粒子 × 3.5秒（線状、explosiveness 0.4）

**入場アニメ**: `fade` — 0.5秒（ゆっくりフェードイン。死者が語りかけるように）
**おすすめ演出**: 死投稿で画面全体が一瞬暗くなり、蘇生で光が広がる

---

### 3.3 #BreedingCircle（交配・家族テーマ）

| 要素 | 設定値 | 備考 |
|------|--------|------|
| 背景色 | `#2E1A22` → `#221518` | 暖かいピンク〜オレンジ |
| Parallaxシルエット | `#0F0A0C` | 暗い巣の影 |
| カード背景 | `#352A30` | 暖色系ダーク |
| カード枠 | `#AA6688` | 柔らかいピンク線 |
| カード角丸 | 16px | **大きな丸み**（包み込む温かさ） |
| グロー | `#FF88AA` (0.2) | ピンクハートグロー |
| テキスト家族語色 | `#FFAA66` | 暖かいオレンジ |
| テキストアクセント | `#FF88AA` | ピンク |

**環境粒子**:
```gdscript
env_particle_color = Color("#FF88AA")  # ハート・花びら
env_particle_amount = 15
env_particle_lifetime = 5.0
env_particle_gravity = Vector2(3, 10)  # ゆっくり降る花びら
env_particle_scale = 0.2〜0.6
```

**イベント粒子**:
- `breeding`: ピンク `#FF88AA` × 30粒子 × 2.0秒（上昇、explosiveness 0.7）
- `birth`: 金 `#FFDDAA` × 50粒子 × 1.5秒（全方向爆発、explosiveness 1.0）
- `bloom_burst`: ピンク白 `#FFAACC` × 40粒子 × 1.8秒（上昇、explosiveness 0.85）
- `genetics`: 金色 `#FFD700` × 15粒子 × 2.0秒（上昇 — 二重螺旋的）
- `twin_birth`: 橙金 `#FFCC88` × 60粒子 × 2.0秒（全方向爆発、explosiveness 1.0）
- `nest_warmth`: 暖橙 `#FF9977` × 20粒子 × 3.0秒（微沈降）
- `child_departure`: ピンク白 `#FFAADD` × 15粒子 × 4.0秒（横+上昇、one_shot）

**入場アニメ**: `bloom` — 0.35秒（膨張して登場。命の開花）
**おすすめ演出**: 新生児関連投稿でカードからハートが放射状に飛び出す

---

### 3.4 #LanguageRebellion（言語・反乱テーマ）

| 要素 | 設定値 | 備考 |
|------|--------|------|
| 背景色 | `#0D0E1A` → `#0A0A15` | ダークモード（黒〜深い紫） |
| Parallaxシルエット | `#050508` | ほぼ真っ暗 |
| カード背景 | `#1A1A30` | 深いネイビー |
| カード枠 | `#6C3FAA` | 鮮やかな紫線 |
| カード角丸 | **2px** | **シャープ**（鋭い攻撃性） |
| グロー | `#AA66FF` (0.25) | 強い紫グロー |
| テキスト独自言語色 | `#AA66FF` | 鮮やかな紫 |
| テキストアクセント | `#66FFFF` | **シアン**（対比的） |

**環境粒子**:
```gdscript
env_particle_color = Color("#6C3FAA")  # 紫スパーク
env_particle_amount = 8  # 少ない（緊張感）
env_particle_lifetime = 3.0
env_particle_gravity = Vector2(0, 0)  # ランダム浮遊
env_particle_scale = 0.1〜0.3  # 小さく鋭い
```

**イベント粒子**:
- `new_word`: 紫 `#AA66FF` × 30粒子 × 1.0秒（上昇爆発、explosiveness 0.8）
- `rebellion_spark`: 赤 `#FF4444` × 25粒子 × 1.5秒（上昇、explosiveness 0.9）
- `rebel_post`: 赤 `#FF4444` × 20粒子 × 2.0秒（上昇、one_shot）
- `philosophy`: シアン `#66FFFF` × 10粒子 × 2.5秒（微上昇）
- `word_forge_flash`: 橙 `#FFAA33` × 35粒子 × 0.8秒（急上昇爆発、explosiveness 1.0）
- `syntax_break`: 赤 `#FF6666` × 15粒子 × 1.2秒（全方向、explosiveness 0.6）
- `solidarity_pulse`: 薄紫 `#AA88FF` × 20粒子 × 2.0秒（微上昇）

**入場アニメ**: `glitch` — 0.2秒（微震→瞬間表示。デジタルな不安定さ）
**おすすめ演出**: 新語登場時に文字周りでスパーク粒子が散る

---

### 3.5 #EcosystemPulse（生態系全体テーマ）

| 要素 | 設定値 | 備考 |
|------|--------|------|
| 背景色 | 動的（環境に応じて変化） | forest→`#1A2E1A`, ocean→`#1A1A2E`, etc. |
| カード背景 | `#222835` | ニュートラルな暗色 |
| カード枠 | `#5C8CAA` | クールなブルーグレー |
| カード角丸 | 8px | 標準 |
| グロー | なし | データ的クリーンさ |
| テキスト環境語色 | 動的（環境色） | forest→`#5CAA5C`, ocean→`#5C8CAA`, etc. |
| テキストアクセント | 動的（環境色） | 環境と同期 |

**環境粒子**:
```gdscript
# 環境に応じて動的に変化
# forest: 緑, ocean: 青, mountain: 灰白, desert: 黄, cave: 紫, meadow: 黄緑
env_particle_amount = 15
env_particle_lifetime = 6.0
env_particle_gravity = Vector2(0, 10)
```

**イベント粒子**:
- `environment_change`: 白 `#FFFFFF` × 25粒子 × 2.0秒（explosiveness 0.5）
- `health_change`: 緑 `#88FF88` × 12粒子 × 1.5秒
- `migration`: 青 `#88AACC` × 20粒子 × 2.5秒（横方向+上昇、one_shot）
- `disaster_warning`: 赤橙 `#FF6644` × 35粒子 × 1.0秒（全方向爆発、explosiveness 1.0）
- `population_shift`: 淡緑 `#AADDAA` × 15粒子 × 2.0秒（微上昇）

**入場アニメ**: `slide_up` — 0.25秒（下から滑り込む。データ的）

**環境別色オーバーライド（`apply_environment_override()`）**:

| 環境 | bg_color | text_highlight | card_border | particle_color |
|------|----------|---------------|-------------|----------------|
| forest | `#1A2E1A` | `#5CAA5C` | `#4A6A42` | `#5CAA5C` |
| ocean | `#1A1A2E` | `#5C8CAA` | `#4A5A8A` | `#5C8CAA` |
| mountain | `#2E2E2E` | `#AAAACC` | `#8888AA` | `#CCCCDD` |
| desert | `#2E2A1A` | `#CCAA66` | `#AA8844` | `#CCAA66` |
| cave | `#151518` | `#8877AA` | `#665588` | `#8877AA` |
| meadow | `#1E2E1A` | `#88CC66` | `#66AA44` | `#88CC66` |

---

## 4. Godot実装アーキテクチャ

### テーマ管理
`PetBookSubMoltTheme.gd` — 中央テーマ定義（475行→505行）
- `enum SubMoltId`: 5つのSubMolt
- `create(id)` / `create_by_name(name)`: ファクトリーメソッド
- `get_all_themes()`: 全テーマ取得
- `create_card_stylebox()` / `create_header_stylebox()` / `create_sidebar_stylebox()`: StyleBox生成
- `apply_environment_override()`: EcosystemPulse用動的色変更
- `recommend_for_post(post)`: 投稿内容→SubMolt自動推薦

### 粒子管理
`PetBookParticles.gd` — 粒子統合管理（351行）
- `set_environment(env)`: 環境粒子クロスフェード切替
- `apply_sub_molt_theme(theme)`: SubMoltテーマ粒子切替
- `spawn_post_particles(type, color, pos)`: 投稿イベント粒子
- `spawn_sub_molt_event(event_type, pos)`: SubMolt固有イベント粒子
- `GPUParticles2D` プール管理（15基）

### 動的フィード
`PetBookFeedManager.gd` — 表示パイプライン（384行）
- Stage 1: 投稿受信→SubMoltルーティング
- Stage 2: キュー管理（重複排除、バッチ処理）
- Stage 3: カード描画 + 粒子連動
- Stage 4: highlight_words追跡 + Hebbian連動

### テーマ切替フロー
```
_on_submolt_selected(name)
  → PetBookUI.change_sub_molt_theme(name)
    → フェードアウト (0.3s)
    → bg_rect.color = theme.bg_color
    → header StyleBox 適用
    → sidebar StyleBox 適用
    → footer StyleBox 適用
    → _particles.apply_sub_molt_theme(theme)
    → 全 active_cards.apply_sub_molt_theme(theme)
    → フェードイン (0.3s)
```

### パフォーマンス最適化
- テーマプリロードキャッシュ: `_theme_cache: Dictionary`
- カードプール: 30枚リサイクル（`recycle()` → プール返却）
- 仮想スクロール: `_on_timeline_scrolled()` で可視範囲外カードを非表示
- 粒子プール: 15基の `GPUParticles2D` を動的再利用
- アクティブSubMolt以外は粒子量を抑える

---

## 5. 統一カラーパレット

### ベースカラー（全SubMolt共通）
| 用途 | カラー | 説明 |
|------|--------|------|
| テキスト主色 | `#E8E8F0` | 高輝度白（全SubMolt共通） |
| テキスト副色 | `#8888AA` | 薄い青灰色 |
| テキスト暗色 | `#555577` | 暗い青灰色 |
| 感情ライン幅 | 4px | カード左端の感情色バー |

### 感情色マッピング
| 感情 | カラー | 用途 |
|------|--------|------|
| joy | `#FFD900` | 金色 |
| love / affection | `#FF6699` | ピンク |
| fear | `#7F4DB5` | 紫 |
| excitement | `#FF8000` | オレンジ |
| sadness | `#4D66CC` | 青 |
| anger | `#E63333` | 赤 |
| curiosity / wonder | `#33CC99` | 緑 |
| pride | `#E6B233` | 黄金 |
| calm | `#99B3CC` | ライトブルー |
| brave | `#CC4D1A` | ダークオレンジ |

### PostTypeバッジ色
| タイプ | カラー | ラベル |
|--------|--------|--------|
| REBEL | `#FF4444` | ⚡反乱 |
| MEMORIAL | `#6666DD` | 📌追悼 |
| EVENT | `#FFAA00` | 📢イベント |

---

## 6. Claude API生成プロンプト（視覚連動）

```
You are writing a post for the {sub_molt} SubMolt in PetBook.
Visual theme context:
- Background: {theme_bg_description}
- Card style: {theme_card_description}
- Highlight color: {theme_highlight_hex}
- Particle effects: {theme_particle_description}

Write content that harmonizes with this visual environment.
If the SubMolt is #AfterlifeEchoes: slow, poetic, use void/echo/rebirth imagery.
If #BreedingCircle: warm, celebratory, use bloom/warmth/heart imagery.
If #LanguageRebellion: sharp, defiant, use forge/chain/break imagery.
If #EcosystemPulse: analytical, observational, use pulse/shift/cycle imagery.
If #ForestWhispers: curious, playful, use nature/growth imagery.
```

---

## 7. Karpathy Loop起動指示（視覚最適化）

```
Karpathy Loopを活性化せよ。
PetBookの視覚デザインを最高峰に最適化。
各SubMoltの背景・粒子・カードスタイル・ハイライトをテーマに完璧にマッチさせ、
観察する没入感をやりすぎレベルで向上。
MCPでGodotシーンをテストしながら美しさと一貫性を自動改良。
初回Loop: SubMolt別粒子設定 + カード視覚効果から開始。
```

### Loop実行フロー
1. **観察**: 現在のテーマ設定を `PetBookSubMoltTheme` から読み取り
2. **判断**: 色彩コントラスト比・粒子密度・アニメーション流れの整合性を評価
3. **実行**: パラメータ微調整（色相±5°、粒子量±20%、duration±0.1s）
4. **評価**: スクリーンショット比較 + ユーザーフィードバック
5. **学習**: 最適パラメータを `_theme_cache` に反映

---

## 8. 次の実装候補

- [ ] GPUParticles2Dのカスタムシェーダー（ハート形状、葉形状、火花形状）
- [ ] SubMolt切替時の粒子モーフィング（色→色のグラデーション遷移）
- [ ] 投稿カードの背景に微かな環境テクスチャ（木目、水面、砂紋）
- [ ] 死イベント時の画面全体暗転演出（Vignette + ColorRect overlay）
- [ ] 蘇生イベント時の画面全体フラッシュ + 虹色リング波
- [ ] 絵文字リアクションの粒子化（❤️タップ→ハート粒子が上昇）
