# 60. 神経科学記憶モデル 詳細適用ガイド

## 1. 神経科学モデル → PetClaw マッピング

### 脳領域とシステム対応表

| 脳領域 | 機能 | PetClawシステム | 実装クラス |
|--------|------|----------------|-----------|
| 海馬 (Hippocampus) | エピソード記憶の形成・一時保存 | hippocampus_memory配列 | BiologicalMemorySystem |
| 大脳皮質 (Cortex) | 長期記憶の最終保存 | cortex_memory配列 | BiologicalMemorySystem |
| アミグダラ (Amygdala) | 感情による記憶強化 | consolidation_strength計算 | BiologicalMemorySystem × EmotionSystem |
| 前頭前野 (PFC) | ワーキングメモリ・注意制御 | retrieve時の性格フィルタ | BiologicalMemorySystem × PetEntity.personality |
| シナプス (LTP) | Hebbian学習・記憶間結合強化 | strengthen_related_memories() | BiologicalMemorySystem |

### 2026年神経科学トレンドの反映

1. **アミグダラ-海馬回路の新発見**: 感情と記憶の双方向フィードバック
   - PetClaw実装: 記憶想起時に関連感情が再活性化（`recall → emotion boost`）

2. **睡眠中の記憶再活性化**: オフライン時に記憶が整理される
   - PetClaw実装: アプリ非アクティブ時に`process_offline_consolidation()`実行

3. **記憶の動的再構築**: 思い出すたびに微妙に変化
   - PetClaw実装: retrieve時に`importance`に±0.02のランダム変動

## 2. 記憶処理パイプライン

```
イベント発生
    │
    ▼
┌─────────────┐
│ アミグダラ判定 │ ← emotion_intensity計算
│ (感情強度評価) │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  海馬に格納   │ ← hippocampus_memory.append()
│ (短期記憶化)  │
└──────┬──────┘
       │ importance > 0.75 or recall_count >= 3
       ▼
┌─────────────┐
│ 大脳皮質移行  │ ← cortex_memory.append()
│ (長期記憶化)  │
└──────┬──────┘
       │ 定期的
       ▼
┌─────────────┐
│ Ebbinghaus   │ ← apply_ebbinghaus_decay()
│ 忘却処理     │
└──────┬──────┘
       │ AtoA会話時
       ▼
┌─────────────┐
│ Hebbian強化  │ ← strengthen_related_memories()
│ (関連記憶結合)│
└─────────────┘
```

## 3. 感情-記憶フィードバックループ

### 記憶形成時（アミグダラ効果）
```
consolidation_strength = base(0.3) + emotion_intensity × amygdala_factor(0.7)
```

### 記憶想起時（感情再活性化）
```
recalled_emotion_boost = memory.emotion_intensity × recall_decay_factor × 0.3
→ EmotionSystem.stimulate(memory.emotion_tag, recalled_emotion_boost)
```

### 性格バイアス（前頭前野フィルタ）
| 性格特性 | 記憶検索バイアス |
|---------|---------------|
| brave高い | battle/train記憶を優先的に想起 |
| curious高い | 新しい環境/発見記憶を優先 |
| calm高い | 穏やかな日常記憶を優先 |
| affectionate高い | 他ペットとの交流記憶を優先 |
| playful高い | play/fun記憶を優先 |

## 4. LTP（長期増強）シミュレーション

### Hebbian Learning パラメータ
```
# 関連記憶を同時に想起した場合
hebbian_delta = 0.1 × similarity_score
# 上限キャップ
max_importance = 1.0
# 減衰（使われない結合は弱まる）
link_decay_rate = 0.005 / day
```

### 類似度計算
```gdscript
func calculate_similarity(mem_a: Dictionary, mem_b: Dictionary) -> float:
    var score := 0.0
    if mem_a.event_type == mem_b.event_type:
        score += 0.2
    if mem_a.emotion_tag == mem_b.emotion_tag:
        score += 0.3
    # context_tagsの共通要素
    var shared_tags = count_shared(mem_a.context_tags, mem_b.context_tags)
    score += shared_tags * 0.15
    # 時間的近接
    var time_diff = abs(mem_a.timestamp - mem_b.timestamp)
    if time_diff < 3600.0:  # 1時間以内
        score += 0.2
    return clampf(score, 0.0, 1.0)
```

## 5. オフライン記憶整理（睡眠模倣）

アプリ非アクティブ時間が1時間以上の場合:
1. hippocampus_memoryの全記憶にEbbinghaus減衰を一括適用
2. importance > 0.6 かつ recall_count >= 2 の記憶を cortex に昇格
3. cortex_memory内で関連性の高いペアをHebbian強化（+0.05）
4. importance < 0.05 の記憶を完全削除（忘却）

## 6. AtoA会話での記憶活用戦略

### プロンプト構築
- 最大3件の関連記憶をコンテキストに含める
- 記憶のimportance順でソート
- 性格バイアスでフィルタリング後に選択

### 会話後の記憶更新
- 言及された記憶: recall_count++, importance += 0.1
- 新しい共有体験: 両ペットのhippocampusに追加
- 感情的な会話: アミグダラ効果で高importance記憶を生成
