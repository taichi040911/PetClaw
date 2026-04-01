# AtoA感情モデル 詳細分析

Claude Cowork連携用 — 性格・記憶・感情減衰・HSV色計算・粒子エフェクトの統合分析。

---

## 1. 感情モデルの全体像（第一原理ベース）

### 第一原理:
- 感情は「一時的な気分」、性格は「長期的な個性」→ 感情は減衰し、性格にフィードバック
- 感情の価値は「変化」にある → 常に同じ感情では愛着が生まれない
- AtoA会話の自然さは感情反映の深さで決まる
- 視覚・聴覚との連動が没入感を決める → HSV色計算、粒子エフェクト、アニメ速度

### 現在のモデル構成:
- **基本感情6種**: excitement, calm, anger, curiosity, fear, affection（0.0〜1.0）
- **性格連動**: Traits（brave, curious, cautious, loyal, playful, affectionate）
- **記憶連動**: BiologicalMemorySystemから関連記憶を取得、感情にフィードバック
- **減衰ロジック**: 時間経過 + 性格による速度調整
- **HSV統合**: 感情が色相・彩度・明度に影響
- **粒子/演出連動**: 感情値で粒子量・色・強度を動的変化

---

## 2. 強み・弱み・リスク分析

### 強み:
- **自然な変化**: 減衰 + 性格連動で感情が固定化しない
- **AtoA会話の豊かさ**: 感情がトーン・提案内容に反映
- **視覚表現力**: HSV + 粒子で感情が直感的に伝わる
- **進化連動**: 感情蓄積が進化トリガーに

### 弱み:
- **計算コスト**: 毎会話Claude API呼び出しのレイテンシ
- **感情矛盾リスク**: 短期感情 vs 長期性格の衝突
- **一貫性維持**: 減衰不足だと急変動、「この子らしさ」喪失
- **観客化リスク**: AtoA会話過多でプレイヤーエージェンシー低下

### リスク:
- 感情モデルが複雑すぎて「重い」「予測不能」
- APIコスト爆発
- 感情偏りでペットが「不安定」に見える

---

## 3. 感情減衰ロジック詳細

### 基本減衰式（emotion_system.gd）

```gdscript
# 感情値の自然減衰（毎秒）
func _decay_emotions(pet: PetEntity, delta: float) -> void:
    var base_rates := {
        "excitement": 0.015,
        "calm": 0.005,
        "anger": 0.012,
        "curiosity": 0.010,
        "fear": 0.020,
        "affection": 0.003,  # 愛情は最も減衰が遅い
        "sadness": 0.008,
    }

    # 性格による減衰速度調整
    var calm_mod: float = pet.personality.get("calm", 0.5)

    for emotion in pet.emotions:
        var rate: float = base_rates.get(emotion, 0.01)
        # calm性格が高い → 負の感情は早く減衰、正の感情は遅く減衰
        if emotion in ["anger", "fear", "sadness"]:
            rate *= (1.0 + calm_mod * 0.5)  # calmが高いほど早く落ち着く
        elif emotion in ["excitement", "curiosity"]:
            rate *= (1.0 - calm_mod * 0.3)  # calmが高いと興奮も穏やか

        pet.emotions[emotion] = max(0.0, pet.emotions[emotion] - rate * delta)
```

### 性格依存の減衰速度表

| 感情 | base rate | calm=0.2の実効 | calm=0.8の実効 |
|---|---|---|---|
| excitement | 0.015 | 0.014 | 0.011 |
| anger | 0.012 | 0.013 | 0.017 |
| fear | 0.020 | 0.022 | 0.028 |
| affection | 0.003 | 0.003 | 0.003 |
| curiosity | 0.010 | 0.009 | 0.008 |

---

## 4. HSV色計算との連動

### 感情 → HSV マッピング

| 感情 | Hue影響 | Saturation | Brightness |
|---|---|---|---|
| excitement | 黄方向 (+30°) | +0.2 | +0.15 |
| calm | 青方向 (+200°) | -0.1 | 0 |
| anger | 赤方向 (0°) | +0.3 | -0.05 |
| fear | 紫方向 (+270°) | +0.1 | -0.1 |
| affection | ピンク方向 (+330°) | +0.15 | +0.1 |
| curiosity | 緑方向 (+120°) | +0.1 | +0.1 |
| sadness | 青灰方向 (+220°) | -0.2 | -0.15 |

### 実装方針（visual_fx_system.gd）
```gdscript
func get_emotion_color(emotions: Dictionary) -> Color:
    var h := 0.0
    var s := 0.6
    var v := 0.8
    var total_weight := 0.0

    for emotion in emotions:
        var intensity: float = emotions[emotion]
        if intensity < 0.1:
            continue
        total_weight += intensity
        match emotion:
            "excitement": h += 60.0 * intensity; s += 0.2 * intensity; v += 0.15 * intensity
            "anger": h += 0.0 * intensity; s += 0.3 * intensity
            "fear": h += 270.0 * intensity; v -= 0.1 * intensity
            "affection": h += 330.0 * intensity; s += 0.15 * intensity; v += 0.1 * intensity
            "curiosity": h += 120.0 * intensity; v += 0.1 * intensity
            "sadness": h += 220.0 * intensity; s -= 0.2 * intensity; v -= 0.15 * intensity

    if total_weight > 0:
        h = fmod(h / total_weight, 360.0)
    s = clampf(s, 0.2, 1.0)
    v = clampf(v, 0.3, 1.0)
    return Color.from_hsv(h / 360.0, s, v)
```

---

## 5. 粒子エフェクト連動

| 感情強度 | 粒子反応 |
|---|---|
| < 0.3 | 粒子なし（静か） |
| 0.3 - 0.5 | 微量の ambient粒子（感情色） |
| 0.5 - 0.7 | 中程度の粒子（ハート/星/泡） |
| 0.7 - 0.9 | 活発な粒子（複数タイプ混合） |
| > 0.9 | 爆発的パーティクル（フラッシュバルブ対応） |

---

## 6. 改善提案

1. **感情の階層化**: 短期感情（会話時）と長期傾向（性格フィードバック）を明確分離
2. **減衰速度の性格依存強化**: calmが高いペットは感情が早く落ち着くなど
3. **HSV変化の閾値設定**: 0.7以上でのみ顕著に変化（過剰派手さ防止）
4. **感情矛盾検出**: anger + affection が同時に高い場合の調停ロジック
5. **MCPテスト**: 感情変化後の会話 + 粒子を視覚評価
