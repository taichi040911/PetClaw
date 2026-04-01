# 59. 生物模倣記憶システム 詳細設計

## 1. コンセプト

生物の記憶は単なるデータ保存ではなく、時間・感情・経験によって動的に変化する。
これをAIペットに模倣することで「本物のペットらしい」自然な記憶と関係性を表現する。

### 神経科学ベースの主要要素

| 要素 | 生物学的メカニズム | PetClaw適用 |
|------|-------------------|-------------|
| Ebbinghaus忘却曲線 | 記憶は時間とともに指数関数的に減衰（最初は急激、後半は緩やか） | 感情減衰・記憶重要度の減衰関数 |
| 海馬 (Hippocampus) | エピソード記憶の形成と一時保存 | 短期記憶バッファ（数分〜数時間） |
| シナプス可塑性 (Hebbian Learning) | 「一緒に発火するニューロンはつながる」 | 関連記憶同士の重要度相互強化 |
| アミグダラ (Amygdala) | 強い感情体験は記憶定着を促進（フラッシュバルブ記憶） | emotion_intensity × 定着率の乗算 |
| 長期記憶の階層化 | 短期 → 中期 → 長期（海馬から大脳皮質へ移行） | hippocampus → cortex 移行ロジック |
| 前頭前野 (Prefrontal Cortex) | ワーキングメモリ、注意・計画・感情調整 | 性格フィルタによる記憶検索バイアス |
| 睡眠中の記憶再活性化 | オフライン時に記憶が整理・強化される | オフライン時のAtoA会話で記憶再評価 |
| 記憶の動的再構築 | 思い出すたびに少し変化する | retrieve時のstrength微変動 |

## 2. 記憶データ構造

```gdscript
# 記憶アイテムの標準構造
var memory_item: Dictionary = {
    "id": int,                    # 一意ID
    "event_type": String,         # care/conversation/evolution/battle/environment
    "content": Dictionary,        # イベント詳細データ
    "importance": float,          # 0.0〜1.0 重要度（減衰対象）
    "emotion_tag": String,        # 形成時の支配的感情
    "emotion_intensity": float,   # 形成時の感情強度
    "timestamp": float,           # 形成時刻（Unix時間）
    "last_recalled": float,       # 最後に想起された時刻
    "recall_count": int,          # 想起回数（Hebbian強化用）
    "linked_memories": Array[int],# 関連記憶のIDリスト
    "context_tags": Array[String] # 検索用タグ（環境・相手・話題）
}
```

## 3. 忘却曲線の数式

### Ebbinghaus基本式
```
R(t) = e^(-t/S)
```
- R(t): 時刻tでの記憶保持率
- S: 記憶強度（感情・反復で増加）

### PetClaw拡張式
```
importance(t) = initial_importance × e^(-t / (base_half_life × strength_multiplier))
strength_multiplier = 1.0 + emotion_intensity × 0.7 + recall_count × 0.2
```

### 減衰パラメータ
| 記憶タイプ | base_half_life | 説明 |
|-----------|---------------|------|
| 短期（海馬） | 1800秒（30分） | 日常の些細な出来事 |
| 中期 | 86400秒（1日） | 重要だが反復なし |
| 長期（皮質） | 604800秒（7日） | 高感情 or 高反復 |

## 4. 海馬→大脳皮質 移行条件

記憶が短期から長期に昇格する条件:
1. `importance > 0.75` — 形成時から高重要度
2. `recall_count >= 3` — 3回以上想起された
3. `emotion_intensity > 0.8` — フラッシュバルブ記憶（即時昇格）
4. AtoA会話で言及された — 共有体験として強化

## 5. Hebbian Learning（関連記憶の相互強化）

```
# 同時に想起された記憶ペアの重要度を相互強化
delta_strength = 0.1 × similarity(mem_a, mem_b)
mem_a.importance = min(1.0, mem_a.importance + delta_strength)
mem_b.importance = min(1.0, mem_b.importance + delta_strength)
```

関連性スコアの計算:
- 同じevent_type: +0.2
- 同じemotion_tag: +0.3
- 共通context_tags: +0.15 per tag
- 時間的近接（1時間以内）: +0.2

## 6. AtoA会話との連携

### 記憶呼び出しフロー
1. AtoA会話開始時、トピックに関連する記憶を検索
2. importance上位3件をClaude APIプロンプトに含める
3. 会話中に言及された記憶のrecall_count++、importance微増
4. 新しい共有体験は両ペットの記憶に格納

### Claude APIプロンプトへの記憶注入例
```
あなたは{name}。最近の記憶:
- {memory_1.content}（{time_ago}前、感情: {emotion_tag}、重要度: {importance}）
- {memory_2.content}（...）
この記憶を自然に会話に織り込んでください。
```

## 7. 視覚反映

| 記憶状態 | 視覚効果 |
|---------|---------|
| 記憶想起中 | 頭上に淡い光の粒子（想起色 = emotion_tagのHSV） |
| フラッシュバルブ記憶形成 | 画面フラッシュ + 大粒子バースト |
| 忘却（importance < 0.1） | 灰色の小さな粒子が消える演出 |
| Hebbian強化 | 2体間に光の線（synapse的） |

## 8. コスト最適化

- 長期記憶はローカルJSON優先（Claude API不要）
- 記憶要約: cortex_memoryが50件超えたらClaude APIで圧縮要約
- AtoA会話に含める記憶は最大3件（トークン節約）
- オフライン時はローカル忘却曲線のみ処理
