# 感情リフレクションスキル

## トリガー
「感情」「emotion」「感情システム」「EmotionSystem」「感情バランス」「パラメータチューニング」「ペットの気持ち」と言われたときに使用。

## 目的
PetClaw の感情システム全体の設計・デバッグ・チューニングを支援する。
ケアアクション→感情→性格→進化の因果連鎖が健全であることを保証する。

## コンテキスト
- **対象ファイル**:
  - `godot_project/scripts/emotion/emotion_system.gd`
  - `godot_project/scripts/care/care_action_system.gd`（感情影響源）
  - `godot_project/scripts/autonomy/pet_autonomy_system.gd`（感情参照）
  - `godot_project/scripts/life/pet_lifecycle_fsm.gd`（ライフステージ別感情修正）
- **感情タイプ**: joy, love, fear, excitement, sadness, anger（予定）, curiosity（予定）
- **第一原理**:
  - P1: 一貫性×記憶=愛着 — 感情の一貫した変化がプレイヤーの愛着を生む
  - P3: Player Agency — プレイヤーのケアが感情に直接影響する実感
  - P4: 10秒フック — 感情変化がビジュアルに即座に反映される

## 感情フロー分析

### 入力源（何が感情を変えるか）
```
CareActionSystem.perform_action()
├── feed   → joy: +0.2, love: +0.1
├── play   → joy: +0.3, excitement: +0.25
├── train  → excitement: +0.15
├── medicine → fear: +0.1, love: +0.15
├── clean  → joy: +0.15, love: +0.1
├── pet    → love: +0.25, joy: +0.15
└── explore → excitement: +0.3, fear: +0.05

AtoAConversationSystem
├── speaker → joy: +0.05
└── listener → joy: +0.03

PetAutonomySystem (Pulse actions)
├── wander → 環境依存
├── seek_companion → love系
└── meditate → calm系

外部イベント
├── climate_event → 環境ストレス
├── death_event → grief
└── evolution_event → excitement/joy
```

### 出力先（感情が何に影響するか）
```
感情 →
├── AtoA会話プロンプト（dominant_emotion, emotion_intensity）
├── PetAutonomySystem（Pulse行動選択の重み）
├── EvolutionMechanics（進化条件の一部）
├── VisualFX（感情カラー、パーティクル）
├── LanguageEvolution（会話時の文法変化コンテキスト）
└── PersistentField（フィールド全体のムード影響）
```

## チェックリスト

### バランスチェック
1. **感情飽和防止**: 同じ感情が1.0に張り付かないか
   - 各感情は自然減衰（decay）が設定されているか
   - ケアアクションの加算値が減衰を大幅に上回らないか
2. **感情死亡防止**: すべての感情が0.0に張り付かないか
   - 自律行動（Pulse）による微量な感情刺激があるか
   - 環境イベントによる定期的な感情変化があるか
3. **ネガティブ感情の適切さ**: fear/sadness が支配的にならないか
   - medicine の fear (+0.1) は love (+0.15) で相殺されるか
   - explore の fear (+0.05) は excitement (+0.3) に対して十分小さいか

### 性格進化との整合性
1. personality 変化量（0.003〜0.01）は感情変化量（0.05〜0.3）の1/10以下か
2. 性格進化の方向がアクションの意味と一致しているか
   - play → playful (+0.005), curious (+0.003) ✓
   - train → brave (+0.008), calm (+0.003) ✓
   - pet → affectionate (+0.005) ✓
3. 性格→自律行動の選好が循環しないか
   - curious → explore → curious↑ のフィードバックループが過剰でないか

### ライフステージ修正
1. BABY: hunger/affection が 2x で変動するか
2. TEEN: emotion が 1.5x で変動するか
3. SLEEPING: recovery が 3x だが感情は凍結されるか
4. ELDER: 全体的に穏やかな変動か

### ビジュアルフィードバック
1. `get_emotion_color()` が各感情に適切な色を返すか
2. ケアエフェクト（`_play_care_visuals`）が感情変化を視覚化しているか
3. 感情変化のアニメーション遅延が10秒以内か（P4準拠）

## デバッグ手順

### 「感情が死んでいる」場合
1. `pet.emotions` の全値を確認 → すべて < 0.1 か？
2. decay レートが stimulate を上回っていないか確認
3. `_care_last_action_time` を確認 → ケアミスが連続していないか
4. PetAutonomySystem の PULSE_OK が常時 true になっていないか
5. 対処: `emotion_system.stimulate(pet, "joy", 0.2, "debug_recovery")` で蘇生テスト

### 「感情が暴走している」場合
1. 特定の感情が > 0.9 で固定されていないか
2. AtoA会話が高頻度で発生していないか（EthicalSafeguard日次上限チェック）
3. ケアアクションの連打による加算チェック
4. 対処: decay レート調整 or stimulate のクランプ値見直し

## パラメータチューニングガイドライン
- 感情 stimulate 値: 0.02（微量）〜 0.3（大量）の範囲
- 性格 evolve 値: 0.001（微量）〜 0.01（大量）の範囲
- decay レート: 1フレームあたり 0.001〜0.005 が適正
- ケアアクション頻度: プレイヤーは平均30秒に1回 → 感情加算は60秒で自然減衰分を補う量が理想
