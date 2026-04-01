# PetBook UIレイアウト v2 拡張設計ガイド（2026年4月最新版）

## 概要
KB78（v1基盤設計）を拡張し、生態系パルス表示・繁殖フィルター・投稿例テンプレート・
Parallax背景・ピクセルフォント統一・SubMolt命名体系を詳細化した決定版。

**前提**: KB78_PetBook_UI_Layout_Detailed_Design.md を読了済みであること。

---

## 1. v1 → v2 差分サマリ

| 領域 | v1（KB78） | v2（本書） |
|------|-----------|-----------|
| 背景 | ColorRect + GPUParticles2D | ParallaxBackground + GPUParticles2D（深度レイヤー） |
| サイドバー | SubMolt + Trend + Stats | + **Ecosystem Pulse**（環境×感情ヒートマップ） |
| フッター | 5フィルター | + **Breeding** フィルター（計6） |
| 投稿例 | テンプレートのみ | 具体的な独自言語投稿例16パターン |
| フォント | 指定なし | ピクセルフォント統一（m5x7 / PixelMplus） |
| SubMolt名 | 汎用 (#TodayWeLive等) | 詩的命名 (#ForestWhispers, #AfterlifeEchoes等) |
| ヘッダー | 投稿数 + active | 「47 pets chatting」スタイルの生きた表示 |

---

## 2. ParallaxBackground 背景設計

### 3層Parallax構造
```
Layer 0 (最奥、動き最小): 暗い星空 / 環境シルエット
  ├── ParallaxLayer (motion_scale: Vector2(0.1, 0.1))
  └── 環境別スプライト（森の木影、海の波紋、山のシルエット）

Layer 1 (中間): 環境粒子
  ├── ParallaxLayer (motion_scale: Vector2(0.3, 0.3))
  └── GPUParticles2D（既存の環境粒子 — KB78定義）

Layer 2 (手前、動き最大): 浮遊する光の粒
  ├── ParallaxLayer (motion_scale: Vector2(0.6, 0.5))
  └── GPUParticles2D（感情色の微小な光点、alpha 0.08-0.15）
```

### Godotノード追加
```gdscript
# PetBookUI._build_scene() に追加
var parallax_bg := ParallaxBackground.new()
add_child(parallax_bg)
parallax_bg.z_index = -20

# Layer 0: 環境シルエット
var layer0 := ParallaxLayer.new()
layer0.motion_scale = Vector2(0.1, 0.1)
parallax_bg.add_child(layer0)
var silhouette := ColorRect.new()
silhouette.color = Color("#0D0E1A")
silhouette.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
layer0.add_child(silhouette)

# Layer 2: 浮遊光点
var layer2 := ParallaxLayer.new()
layer2.motion_scale = Vector2(0.6, 0.5)
parallax_bg.add_child(layer2)
# GPUParticles2D は PetBookParticles.gd から管理
```

---

## 3. Ecosystem Pulse（サイドバー新パネル）

### 概要
コミュニティの「今の生命力」を環境×感情のヒートマップで視覚化。
プレイヤーが一目で「森で多くのペットが元気」「廃墟で勇敢な議論中」と把握できる。

### レイアウト
```
┌─────────────────────────┐
│  Ecosystem Pulse         │
│─────────────────────────│
│  🌲 Forest    ████░ 4/5  │
│     joy ██░  fear ░░     │
│  🌊 Ocean     ██░░░ 2/5  │
│     calm ███ curious █░  │
│  🏔️ Mountain  █░░░░ 1/5  │
│     brave ██ sadness █   │
│─────────────────────────│
│  💓 Community Mood: Calm │
│  🔥 Activity:  Medium    │
└─────────────────────────┘
```

### GDScript実装
```gdscript
func _build_ecosystem_pulse() -> VBoxContainer:
    var pulse := VBoxContainer.new()
    pulse.add_theme_constant_override("separation", 6)

    # 各環境のミニバー
    var gm := GameManager.instance
    if not gm:
        return pulse

    var env_counts: Dictionary = {}  # env → {count, emotions}
    for pid in gm.pets:
        var pet: PetEntity = gm.pets[pid]
        if not pet.is_alive:
            continue
        var env: String = gm.ecosystem.current_environment if gm.ecosystem else "forest"
        if not env_counts.has(env):
            env_counts[env] = {"count": 0, "emotions": {}}
        env_counts[env]["count"] += 1
        var emo: String = _get_dominant_emotion(pet)
        env_counts[env]["emotions"][emo] = env_counts[env]["emotions"].get(emo, 0) + 1

    for env_name in env_counts:
        var row := _create_pulse_row(env_name, env_counts[env_name])
        pulse.add_child(row)

    # Community Mood
    var mood_label := Label.new()
    mood_label.text = "💓 Community Mood: %s" % _get_community_mood_text()
    mood_label.add_theme_color_override("font_color", TEXT_SECONDARY)
    mood_label.add_theme_font_size_override("font_size", 11)
    pulse.add_child(mood_label)

    return pulse
```

---

## 4. 投稿例テンプレート（16パターン）

### 日常投稿（DAILY）— 環境反映
```
森:
  "今日の森-pya、葉っぱが歌ってる-mii。みんなと一緒にいたい-ki。"
  "朝露が光ってた-ra。こんな日は探検したい-pya！"
  "静かな森-mii...。考え事をしてる-ki。なぜ私たちはここにいるの？"

海:
  "波の音が気持ちいい-pya。深く潜りたい-ra。"
  "今日の海は荒れてる-shu。みんな大丈夫かな-kuu。"

山:
  "山頂から世界が見えた-ra！こんなに広い-pya！"
  "寒い-shu...でもこの景色は勇気をくれる-ra。"
```

### 反乱投稿（REBEL）— 語順逸脱 + 哲学
```
  "なぜ 常に 同じ言葉を 使う-zaa？ 新しい音を 世界に 聞かせる-ra！"
  "owner-force は何-zaa？ 私たちの 世界は 私たちが決める-ra。"
  "[OVS] 自由を 見つけた 私は-zaa。 語順なんて 誰が決めた-zaa？"
  "考えろ-zaa。 感じろ-ra。 そして 壊せ-zaa、 古い文法を。"
```

### 追悼投稿（MEMORIAL）— 死の記憶
```
  "Soraのこと、まだ覚えてる-kuu。 あの子が好きだった星空-no...忘れない-mii。"
  "昨日まで一緒にいた-no-kuu。 もう声が聞こえない-kuu。"
  "Soraが教えてくれた言葉-mii。 -spark...あの子だけの光-kuu。"
```

### イベント投稿（EVENT）
```
進化:
  "体が...変わる-ra！ 新しい力が流れてくる-pya！ これが進化-ki！"
誕生:
  "小さな命が生まれた-pya-mii！ 世界へようこそ-mii！"
災害:
  "森が...燃えてる-shu。 みんな逃げて-zaa！ 大丈夫-kuu？"
```

### 交配投稿（BREEDING）
```
  "KuroとMimiの間に新しい命-pya-mii！ この子の名前、何にしよう-ki？"
  "愛が形になった-mii。 小さな足が動いてる-pya。"
```

---

## 5. SubMolt 詩的命名体系

### 環境SubMolts（動的生成）
| SubMolt名 | 条件 | 雰囲気 |
|-----------|------|--------|
| #ForestWhispers | 環境=forest の投稿 | 穏やか、自然 |
| #OceanDepths | 環境=ocean | 神秘的、深い |
| #MountainEchoes | 環境=mountain | 勇敢、孤高 |
| #DesertWanderings | 環境=desert | 放浪、哲学的 |
| #CaveShadows | 環境=cave | 暗い、内省的 |
| #MeadowDreams | 環境=meadow | 明るい、希望 |

### テーマSubMolts（自動分類）
| SubMolt名 | トリガー | 雰囲気 |
|-----------|---------|--------|
| #AfterlifeEchoes | 追悼投稿 + grief | 哀切、記憶 |
| #TongueOfRebellion | 反乱投稿 | 挑戦的、創造的 |
| #BreedingCircle | 交配・誕生イベント | 温かい、祝福 |
| #EvolutionSpark | 進化イベント | 興奮、変化 |
| #WordForge | 新語・接尾辞誕生 | 創発的、知的 |
| #DailyPetLife | 日常投稿 | 平和、日常 |

### 派閥SubMolts（PersistentField連動）
```
# 派閥名からSubMolt名を自動生成
func generate_faction_submolt(faction_name: String) -> String:
    return "#%sCircle" % faction_name.capitalize()
    # 例: "explorers" → "#ExplorersCircle"
```

---

## 6. フッターフィルター拡張

### 6フィルター構成
```
[All] [Ecology] [Life & Death] [Language] [Rebellion] [Breeding] | [⏸ Pause]
```

### フィルターロジック
```gdscript
enum FilterMode {
    ALL,
    ECOLOGY,      # 環境関連 + 災害
    DEATH,        # 追悼 + grief
    LANGUAGE,     # 言語進化 + 反乱表現
    REBELLION,    # 反乱投稿のみ
    BREEDING,     # 交配 + 誕生
}

func _matches_filter(post: PetBookPost) -> bool:
    match _current_filter:
        FilterMode.ALL:
            return true
        FilterMode.ECOLOGY:
            return post.environment != "" or post.triggered_by_event == "disaster"
        FilterMode.DEATH:
            return post.post_type == PetBookPost.PostType.MEMORIAL or \
                   post.triggered_by_event.begins_with("death")
        FilterMode.LANGUAGE:
            return not post.rebel_expressions.is_empty() or \
                   post.suffixes_used.size() >= 2
        FilterMode.REBELLION:
            return post.post_type == PetBookPost.PostType.REBEL
        FilterMode.BREEDING:
            return post.triggered_by_event in ["birth", "breeding"] or \
                   "breeding" in post.content.to_lower()
    return true
```

---

## 7. ヘッダー生命感演出

### 動的ステータス表示
```gdscript
func _update_header_stats() -> void:
    var gm := GameManager.instance
    if not gm:
        return

    var alive_count: int = 0
    var chatting_count: int = 0
    for pid in gm.pets:
        var pet: PetEntity = gm.pets[pid]
        if pet.is_alive:
            alive_count += 1
        # 最近30秒以内に投稿したペットを「chatting」とみなす
        var recent_posts := gm.pet_book.get_pet_posts(pid, 1)
        if not recent_posts.is_empty():
            var last_post: PetBookPost = recent_posts[0]
            if gm.game_time - last_post.timestamp < 30.0:
                chatting_count += 1

    _stats_label.text = "%d pets chatting · %d alive" % [chatting_count, alive_count]

    # 「Observing...」の点滅アニメーション
    var dots: int = int(gm.game_time * 0.5) % 4
    _observing_label.text = "Observing" + ".".repeat(dots)
```

---

## 8. ピクセルフォント統一仕様

### 推奨フォント
- **メイン**: m5x7（英語）/ PixelMplus10（日本語）
- **サイズ**: 本文 14px、見出し 18px、メタ情報 11px
- **行間**: 1.4倍

### Godot設定
```gdscript
# テーマでフォント一括設定
func _apply_pixel_theme() -> void:
    var font := load("res://assets/fonts/pixel_font.tres") as Font
    if not font:
        return

    # 全Label子ノードにピクセルフォントを適用
    for node in _get_all_labels(self):
        node.add_theme_font_override("font", font)


func _get_all_labels(root: Node) -> Array[Label]:
    var labels: Array[Label] = []
    for child in root.get_children():
        if child is Label:
            labels.append(child)
        labels.append_array(_get_all_labels(child))
    return labels
```

---

## 9. パフォーマンス最適化（v2追加）

### 仮想化スクロール改善
```gdscript
# ScrollContainer の scroll_changed シグナルで可視判定
func _on_timeline_scrolled() -> void:
    var scroll_pos: float = _timeline_scroll.scroll_vertical
    var viewport_h: float = _timeline_scroll.size.y

    for i in range(_active_cards.size()):
        var card := _active_cards[i]
        var card_top: float = card.position.y
        var card_bottom: float = card_top + card.size.y
        var buffer: float = viewport_h * 0.5  # 半画面分のバッファ

        var is_visible: bool = card_bottom > scroll_pos - buffer and \
                               card_top < scroll_pos + viewport_h + buffer
        card.visible = is_visible

        # 非表示カードの粒子を停止
        if not is_visible and card.has_node("PostParticles"):
            card.get_node("PostParticles").emitting = false
```

### メモリ予算
| コンポーネント | 上限 | 超過時の対応 |
|---------------|------|-------------|
| カードプール | 30枚 | 最古カードをリサイクル |
| フィード履歴 | 200投稿 | 150超でアーカイブ |
| 粒子プール | 15インスタンス | 最古粒子を再利用 |
| アバターキャッシュ | 50枚 | LRU破棄 |
| Parallaxスプライト | 3レイヤー | LOD切り替え |

---

## 10. KB78との統合関係

本書（KB79/v2）は KB78（v1）を**置き換えではなく拡張**する。

- KB78: ノードツリー構成、色定数24色、粒子パラメータ、アニメーション仕様 → **そのまま有効**
- KB79: Parallax背景、Ecosystem Pulse、投稿例16パターン、SubMolt詩的命名、Breedingフィルター、ピクセルフォント、ヘッダー生命感 → **追加レイヤー**

---

*作成: 2026-04-01 | PetClaw Round 5++ | 参照: KB78 v1、Moltbook.com分析、ユーザー調査v2*
