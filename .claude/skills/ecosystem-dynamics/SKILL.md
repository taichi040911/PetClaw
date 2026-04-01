# 生物生態系ダイナミクススキル

## トリガー
「生態系」「ecosystem」「環境影響」「体調変化」「生き死に」「交配」「breeding」「climate」「死」「death」「食物連鎖」「population」と言われたときに使用。

## 目的
PetClaw の生態系全体（環境 × 体調 × 生死 × 交配 × コミュニティ）の設計・バランス調整・シミュレーションを支援する。
個々のサブシステム（Care, Lifecycle, Breeding, Ecosystem）が有機的に連動し、プレイヤーに「生きている世界」を感じさせることを保証する。

## コンテキスト
- **対象ファイル**:
  - `godot_project/scripts/ecosystem/ecosystem_manager.gd`
  - `godot_project/scripts/breeding/breeding_system.gd`
  - `godot_project/scripts/life/pet_lifecycle_fsm.gd`
  - `godot_project/scripts/care/care_action_system.gd`
  - `godot_project/scripts/core/game_manager.gd`
  - `godot_project/scripts/autonomy/pet_autonomy_system.gd`
- **第一原理**:
  - P1: 一貫性×記憶=愛着 — 生態系の変化が記憶に刻まれ、ペットとの絆を深める
  - P3: Player Agency — プレイヤーのケアが生態系全体に波及する実感
  - P4: 10秒フック — 環境変化・死・誕生は即座にドラマチックに演出

## 生態系モデル

### 4つの力学
```
1. 環境力学（Climate Dynamics）
   天候・季節・災害 → 全ペットの体調・気分に影響
   ├── 日照時間 → energy回復率
   ├── 気温 → hunger消費率
   ├── 降水 → mood（雨好き/嫌い性格で分岐）
   └── 災害 → health/fear に大きな影響

2. 体調力学（Health Dynamics）
   ケア + 環境 + 年齢 → 体調の恒常的変化
   ├── 栄養: hunger → health（長期低hunger → health低下）
   ├── ストレス: fear/sadness蓄積 → health低下
   ├── 老化: ELDER段階 → health自然低下
   └── 免疫: 過去の病気経験 → 耐性（BiologicalMemory参照）

3. 生死力学（Life-Death Dynamics）
   体調 + 年齢 + ケアミス → 生死判定
   ├── 自然死: ELDER + age > threshold + health < 0.1
   ├── 病死: health = 0 が持続
   ├── ケアミス死: care_miss > critical_threshold
   ├── 突然死: disaster + low health（極低確率）
   └── 永遠: ETERNAL形態への到達（redemption path）

4. 繁殖力学（Breeding Dynamics）
   関係性 + 環境 + 健康 → 交配・子ペット生成
   ├── 相性: personality類似度 + 感情共鳴度
   ├── 環境条件: 春/秋 + 十分な食糧 + 安全な環境
   ├── 健康条件: 両親health > 0.6
   └── 遺伝: 性格・形態の遺伝 + ランダム変異
```

### 力学間の相互作用
```
環境 ──→ 体調 ──→ 生死
  │         │        │
  │         │        └──→ コミュニティ grief → AtoA grief会話
  │         │
  │         └──→ 繁殖 ──→ 新ペット（遺伝+変異）
  │                        │
  └──→ 繁殖条件            └──→ 環境への影響（population圧）
```

## チェックリスト

### 環境→体調の連動
1. 気候イベント（climate_event）が全ペットの stats に影響するか
2. 環境トピック（EcosystemManager.topics）が AtoA 会話に注入されるか
3. PetAutonomySystem の Resonance が環境変化に反応するか
4. 季節変化が進化条件（environment_time）に累積されるか

### 体調→生死の連動
1. health = 0 の持続時間をカウントしているか
2. PetLifecycleFSM に DEAD 状態遷移のトリガーがあるか
3. 死亡時に BiologicalMemory に grief 記憶が全コミュニティペットに追加されるか
4. 死亡時に AtoA grief リアクション会話が発動するか
5. PersistentField に死亡イベントが記録されるか

### 交配の整合性
1. BreedingSystem が両親の personality を適切にブレンドしているか
2. 子ペットの初期感情が「両親の平均 + ランダム変異」で決まるか
3. 遺伝形質が EvolutionTree の Stage 0-1 分岐に影響するか
4. 交配成功時に joy_revival リアクション会話が発動するか
5. 人口過多時のブレーキ（max_population チェック）があるか

### 死の重み（P1準拠）
1. 死亡は取り消し不可能か（DEAD状態からの復帰なし、ETERNALは別パス）
2. 死亡ペットの記憶が他のペットに永続的に残るか
3. 死亡通知がプレイヤーに明確に伝わるか（VisualFX演出）
4. 死亡後のグリーフ期間（他ペットの sadness 上昇）が適切な長さか
5. Moltbook風スケールでも個別の死が「意味を持つ」設計になっているか

## シミュレーション手順

### バランステスト（手動）
1. ペット5匹を生成、完全放置（ケアなし）→ 何分で最初の死が発生するか（目標: 15-20分）
2. ペット5匹を生成、最適ケア → 全員がELDERに到達するか（目標: 8-12時間）
3. ペット10匹 + 環境災害 → コミュニティの回復力テスト
4. 交配5回 → 子ペットの性格分布が正規分布に近いか

### 自動テスト（Ralph Loop統合）
```
Ralph Loop設定:
- 目標: 「10ペット × 24時間シミュレーション → 2-4匹が死亡、1-2匹が交配」
- 評価関数: death_rate(0.2-0.4) AND breeding_rate(0.1-0.2) AND avg_lifespan(6-10h)
- 調整対象: decay_rates, care_miss_threshold, breeding_conditions
- 反復: 最大50回
```

## アンチパターン
- 全ペットが同時に死亡する「大量死」→ 環境ダメージの上限設定が必要
- 交配が無限ループする → population上限 + クールダウン期間
- 環境変化が急すぎて適応不可能 → 変化速度にイージングを適用
- 死が軽い（すぐ忘れられる）→ grief期間の最低保証 + 墓標システム検討
