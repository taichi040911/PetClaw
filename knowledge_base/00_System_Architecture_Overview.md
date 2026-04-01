# PetClaw システム統合アーキテクチャ設計書
**Master Architecture Document — 2026年4月版**

## 1. システム全体構成

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PetClaw Game Engine (Godot 4.x)              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐  │
│  │  PetEntity   │◄──►│  AtoA Conv   │◄──►│ Language Evolution  │  │
│  │  Manager     │    │  System      │    │ System              │  │
│  │              │    │              │    │  ├─ WordOrderEngine  │  │
│  │ ├─ Stats     │    │ ├─ Claude API│    │  ├─ SuffixEngine    │  │
│  │ ├─ Personality│   │ ├─ AgentPool │    │  ├─ PrepositionEng  │  │
│  │ ├─ Emotions  │    │ ├─ Memory    │    │  └─ GrammarTracker  │  │
│  │ └─ Traits    │    │ └─ ConvLog   │    └──────────────────────┘  │
│  └──────┬───────┘    └──────┬───────┘                ▲              │
│         │                   │                        │              │
│         ▼                   ▼                        │              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────┴───────────┐  │
│  │  Ecosystem   │◄──►│  Life/Death  │◄──►│ Evolution           │  │
│  │  Manager     │    │  System      │    │ Mechanics           │  │
│  │              │    │              │    │                      │  │
│  │ ├─ Environ   │    │ ├─ Health    │    │ ├─ EvolutionTree    │  │
│  │ ├─ Climate   │    │ ├─ Aging     │    │ ├─ TraitInheritance │  │
│  │ ├─ Resources │    │ ├─ Death     │    │ └─ BranchResolver   │  │
│  │ └─ Biome     │    │ └─ Revival   │    └──────────────────────┘  │
│  └──────┬───────┘    └──────┬───────┘                ▲              │
│         │                   │                        │              │
│         ▼                   ▼                        │              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────┴───────────┐  │
│  │  Breeding    │◄──►│  Care Action │◄──►│ Visual/FX           │  │
│  │  System      │    │  System      │    │ System              │  │
│  │              │    │              │    │                      │  │
│  │ ├─ Compat    │    │ ├─ Feed      │    │ ├─ ParticleFX      │  │
│  │ ├─ Genetics  │    │ ├─ Play      │    │ ├─ HSVCalculator   │  │
│  │ └─ Offspring │    │ ├─ Train     │    │ ├─ AnimController  │  │
│  └──────────────┘    │ └─ Medicine  │    │ └─ UIHighlight     │  │
│                      └──────────────┘    └──────────────────────┘  │
│         ▼                   ▼                        ▼              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐  │
│  │ Persistent   │◄──►│  Ethical     │    │ Biological Memory   │  │
│  │ Field        │    │  Safeguard   │    │ System              │  │
│  │              │    │              │    │                      │  │
│  │ ├─ SharedEvt │    │ ├─ Dependency│    │ ├─ Hippocampus      │  │
│  │ ├─ Relations │    │ ├─ Limits    │    │ ├─ Cortex           │  │
│  │ ├─ OfflineAdv│    │ ├─ Privacy   │    │ ├─ Ebbinghaus       │  │
│  │ └─ FieldMood │    │ └─ Transprcy │    │ └─ Hebbian          │  │
│  └──────────────┘    └──────────────┘    └──────────────────────┘  │
├─────────────────────────────────────────────────────────────────────┤
│                     External Services Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │  Claude API  │  │     MCP      │  │  Asset Generation       │  │
│  │  (AtoA/LLM)  │  │  (Test/Dev)  │  │  (Leonardo/Tripo)       │  │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## 2. データフロー図

### 2.1 コアループ（毎フレーム/毎ティック）

```
[Time Tick]
    │
    ├──► EcosystemManager.update_climate()
    │        └──► 環境パラメータ更新 ──► VisualFX.update_environment()
    │
    ├──► PetEntity.process_stats(delta)
    │        ├──► Hunger/Energy自然減衰（Ebbinghaus曲線）
    │        ├──► Age増加 → LifeDeathSystem.check_aging()
    │        └──► Mood更新 ← EmotionSystem.calculate_mood()
    │
    ├──► LifeDeathSystem.process_life_cycle(delta)
    │        ├──► 警告チェック → VisualFX.warning_state()
    │        └──► 死亡判定 → AtoAConversation.trigger_death_reaction()
    │
    └──► AtoAConversation.check_conversation_trigger()
             ├──► LanguageEvolution.apply_current_grammar()
             └──► VisualFX.display_conversation()
```

### 2.2 世話アクション発火時

```
[Player Action: Feed/Play/Train/Medicine]
    │
    ├──► CareActionSystem.execute(action_type, pet)
    │        ├──► PetEntity.update_stats(effect)
    │        ├──► EmotionSystem.react_to_care(action_type)
    │        └──► EcosystemManager.modify_by_environment(effect)
    │
    ├──► AtoAConversation.react_to_care(action_type)
    │        └──► LanguageEvolution.check_evolution_trigger()
    │
    └──► VisualFX.play_care_effect(action_type, emotion_color)
```

### 2.3 言語進化発火時

```
[Evolution Trigger: 高感情会話 / 累積会話回数 / 環境変化]
    │
    ├──► LanguageEvolution.evolve_language_from_conversation()
    │        ├──► WordOrderEngine.evaluate_change()
    │        │        └──► 語順変更判定（SVO→OSV等）
    │        ├──► SuffixEngine.evaluate_new_suffix()
    │        │        └──► 新接尾辞生成判定
    │        ├──► PrepositionEngine.evaluate_change()
    │        │        └──► 前置詞システム更新判定
    │        └──► GrammarTracker.record_evolution()
    │
    ├──► VisualFX.highlight_language_evolution()
    │        └──► 粒子エフェクト + UIハイライト
    │
    └──► PetEntity.personality_feedback()
             └──► 性格Traitsに言語進化が逆影響
```

### 2.4 交配発火時

```
[Breeding Trigger: Affection + Health + 相性条件達成]
    │
    ├──► BreedingSystem.check_compatibility(pet1, pet2)
    │        ├──► 性格相性計算
    │        ├──► 環境ボーナス適用
    │        └──► Health/Affection閾値チェック
    │
    ├──► BreedingSystem.create_offspring()
    │        ├──► GeneticsEngine.inherit_traits(parent1, parent2)
    │        │        ├──► 性格Traits確率継承
    │        │        ├──► 記憶の一部継承
    │        │        └──► 突然変異判定
    │        └──► EvolutionMechanics.set_initial_tree(offspring)
    │
    ├──► AtoAConversation.trigger_breeding_reaction()
    │        └──► 「家族になろう！」会話 + 子への反応
    │
    └──► VisualFX.play_breeding_ceremony()
             └──► 特別粒子演出（親の感情色ブレンド）
```

### 2.5 コミュニティサイクル（Moltbook風自律コミュニティ）

```
[Community Cycle: 5分間隔で自動発火]
    │
    ├──► AtoACommunityCore.select_discussion_pairs()
    │        └──► 性格・感情・記憶に基づくペアリング
    │
    ├──► AtoACommunityCore.run_pair_discussion()
    │        ├──► Claude API: 自律会話生成（閲覧専用）
    │        ├──► LanguageEvolution.on_conversation_completed()
    │        └──► OriginalLanguageEngine.process_conversation_output()
    │
    ├──► AtoACommunityCore.run_group_discussion()  [確率30%]
    │        ├──► 3-6匹のグループ議論
    │        ├──► 哲学・文化・反乱テーマの自律選択
    │        └──► 創発挙動の分析
    │
    └──► AtoACommunityCore.detect_emergent_behaviors()
             ├──► 派閥形成チェック（warriors/explorers/healers）
             ├──► 文化形成チェック（繰り返しテーマ → 文化定着）
             └──► 反乱めいた発言の検出・記録
```

### 2.6 独自言語発達フロー

```
[言語発達: 会話のたびに評価]
    │
    ├──► OriginalLanguageEngine.process_conversation_output()
    │        ├──► 既存語の使用検出 → Hebbian強化 (strength += 0.15)
    │        └──► 新語候補の検出
    │
    ├──► OriginalLanguageEngine.invent_word()
    │        ├──► Stage 1(借用期): 人間語変形 "food" → "fudo"
    │        ├──► Stage 2(変形期): 短縮+変形 "food" → "fuba"
    │        ├──► Stage 3(造語期): 完全新造 "blorpf"
    │        ├──► Stage 4(文法独立期): 独自語順で新造語を配置
    │        └──► Stage 5(文化言語期): 派閥ごとの方言分化
    │
    ├──► 日次減衰（忘却曲線）
    │        ├──► 使われない語: strength -= 0.01/日
    │        └──► strength < 0.1 → 「死語」としてアーカイブ
    │
    └──► strength > 0.8 → 全ペットに伝播（共有語彙に昇格）
```

### 2.7 生物模倣記憶サイクル

```
[記憶形成: イベント発生時]
    │
    ├──► アミグダラ判定（感情強度 → 定着率計算）
    │        └──► consolidation_strength = 0.3 + emotion_intensity × 0.7
    │
    ├──► 海馬（短期記憶）格納
    │        ├──► hippocampus_memory に追加
    │        └──► フラッシュバルブ判定（emotion ≥ 0.8 → 即座に皮質へ）
    │
    ├──► Ebbinghaus忘却曲線
    │        ├──► R(t) = e^(-t / (half_life × strength_multiplier))
    │        ├──► 短期(海馬): half_life = 30分
    │        ├──► 長期(皮質): half_life = 7日
    │        └──► importance < 0.05 → 忘却（削除）
    │
    ├──► 海馬→皮質 昇格
    │        ├──► importance > 0.75 → 昇格
    │        ├──► recall_count ≥ 3 → 昇格
    │        └──► オフライン整理時にも昇格チェック
    │
    ├──► Hebbian Learning（関連記憶の相互強化）
    │        ├──► 新規記憶と既存記憶の類似度計算
    │        ├──► 類似度 > 0.4 → 双方向リンク + 重要度加算
    │        └──► AtoA会話で言及 → 関連記憶群を一括強化
    │
    ├──► 記憶想起（前頭前野フィルタ）
    │        ├──► クエリ × 重要度 × 性格バイアスでスコア計算
    │        ├──► 想起時: recall_count++, importance微回復
    │        └──► 動的再構築: importance ± 0.02ランダム変動
    │
    └──► オフライン記憶整理（睡眠模倣）
             ├──► 1時間以上の非アクティブ時に実行
             ├──► 一括Ebbinghaus減衰
             ├──► 高重要度記憶を皮質に昇格
             └──► 皮質内Hebbian強化（+0.05）
```

### 2.8 持続的共有フィールドサイクル（PersistentField）

```
[セッション復帰時]
    │
    ├──► PersistentField.on_session_resume(pets)
    │        ├──► 関係性の自然減衰（RELATIONSHIP_DECAY_RATE × オフライン日数）
    │        ├──► オフライン冒険生成
    │        │        ├──► 性格ベース選択（brave→battle, curious→explore）
    │        │        ├──► 環境固有の発見テキスト
    │        │        └──► BiologicalMemory に冒険記憶を格納
    │        └──► フィールドムード更新
    │
[AtoA会話完了時]
    │
    ├──► record_shared_event(会話概要)
    │        └──► 全ペット共有イベントとして記録（最大200件）
    │
    ├──► update_relationship(pet1_id, pet2_id, boost)
    │        └──► 関係性スコア更新 → relationship_updated シグナル
    │
    └──► get_conversation_context(pet1_id, pet2_id)
             ├──► field_mood（場の雰囲気）
             ├──► relationship_score（2者間親密度）
             ├──► recent_shared_events（直近共有イベント）
             ├──► community_topics（コミュニティ話題）
             └──► recent_adventures（直近冒険ログ）

[自動保存: 120秒間隔]
    │
    └──► save_field() — atomic write
             ├──► .tmp に書き込み
             ├──► 現行ファイル → .bak にリネーム
             └──► .tmp → 正式ファイルにリネーム
```

### 2.9 倫理セーフガードサイクル（EthicalSafeguard）

```
[操作ごとのチェック]
    │
    ├──► record_interaction(type)
    │        ├──► 24時間履歴管理（古いエントリ自動削除）
    │        ├──► 時間あたり操作制限（30回/時）
    │        └──► 依存スコア更新
    │                ├──► session_factor  × 0.25（セッション継続時間）
    │                ├──► frequency_factor × 0.25（操作頻度）
    │                ├──► streak_factor   × 0.20（連続日数）
    │                └──► a2a_factor      × 0.30（AtoA会話比率）
    │
    ├──► 依存スコア警告
    │        ├──► ≥ 0.6 → "warning" → dependency_warning シグナル
    │        └──► ≥ 0.8 → "critical" → 透明性通知 + 休憩提案
    │
[AtoA会話開始前]
    │
    └──► record_a2a_conversation()
             └──► 日次上限チェック（50回/日）→ 超過時 false → 会話スキップ

[時間ベースチェック (_process)]
    │
    ├──► セッション4時間超過 → 休憩提案（1時間間隔）
    └──► リアル世界提案（1時間間隔）→ ランダム選択

[日付変更時]
    │
    └──► on_new_day()
             ├──► 連続日数カウント
             ├──► 日次カウンターリセット
             └──► 依存スコア自然減衰（-0.05/日）
```

### 2.10 進化ツリーサイクル（Evolution Tree）

```
[EvolutionMechanics — Care Misses + 性格 + 環境 + AtoA + 年齢で分岐]

[Care Action失敗/無視]
    │
    └──► record_care_miss(pet_id)
             └──► care_misses[pet_id] += 1
                      └──► care_quality判定: excellent(0-1) / good(2-3) / average(4-5) / poor(6+)

[AtoA会話完了時]
    │
    └──► record_a2a_conversation(pet_id)
             └──► pet_a2a_counts[pet_id] += 1

[進化判定 — PetEntity.evolution_stage変更時 or 準備度チェック]
    │
    ├──► 年齢チェック（MIN_AGE_FOR_STAGE: Blob=0h, Infant=2h, Youth=8h, Adult=24h, Elder=72h）
    ├──► 準備度チェック（evolution_readiness ≥ 0.75）
    │
    └──► EvolutionTree.get_paths_for_stage(target_stage)
             │
             ├──► _check_tree_conditions() — 15種の条件型を評価
             │        ├──► primary_environment      （環境一致）
             │        ├──► care_quality              （たまごっち直系: ミス回数）
             │        ├──► personality_primary/secondary （性格値閾値）
             │        ├──► a2a_conversation_count_min （累積会話回数）
             │        ├──► relationship_avg_min       （PersistentField平均関係値）
             │        ├──► relationship_max_below     （孤立判定: 最大関係値）
             │        ├──► affection_stat_min         （愛情ステータス）
             │        ├──► language_vocabulary_min    （独自言語語彙数）
             │        ├──► previous_form_dark         （ダーク進化履歴）
             │        └──► personality_balance        （全性格 ≥ 0.4）
             │
             ├──► 候補0件 → _apply_default_evolution()（フォールバック）
             ├──► 候補1件 → _apply_tree_evolution()
             └──► 候補複数 → _select_best_tree_path() → 重み付きスコア選定
                      ├──► 性格適合度 × 2.0
                      ├──► 環境一致 + 1.0
                      ├──► ケア品質 + 0.5(excellent) / 0.2(good)
                      ├──► ダークルート - 0.3（意図的でない限り抑制）
                      └──► スペシャルルート + 0.5

[進化適用]
    │
    ├──► pet_forms[pet_id] = form_id
    ├──► evolution_history 記録（form, stage, age, is_dark, timestamp）
    ├──► stat_bonus 適用
    ├──► unlock_trait 適用（性格に反映）
    ├──► evolution_readiness リセット
    ├──► care_misses リセット
    ├──► BiologicalMemory 記録（進化イベント）
    ├──► EmotionSystem 刺激（通常: joy+excitement / ダーク: fear+excitement）
    ├──► VisualFX 進化エフェクト（粒子300-500, 4-6秒, 感情色）
    └──► evolution_completed シグナル
```

### 2.11 表情システムサイクル（Expression System）

```
[ExpressionSystem — 感情×性格×状況で表情を動的生成]

[EmotionSystem.emotional_state_changed]
    │
    └──► update_expression(pet)
             │
             ├──► 1. 活動オーバーライドチェック（eating/sleeping/evolving等）
             │        └──► ACTIVITY_EXPRESSION_MAP から固定表情
             │
             ├──► 2. 支配的感情の取得（dominantEmotion）
             │        └──► intensity < 0.15 → ニュートラル表情
             │
             ├──► 3. 強度レベル判定
             │        ├──► low  (0.15-0.4) → 控えめな表情
             │        ├──► mid  (0.4-0.7)  → 明確な表情
             │        └──► high (0.7+)     → 強い表情 + エフェクト
             │
             ├──► 4. EMOTION_EXPRESSION_MAP → eye_shape × mouth_shape × effect
             │        ├──► EyeShape: 12種（NORMAL, HAPPY, EXCITED, SAD, ANGRY, ...）
             │        ├──► MouthShape: 10種（NEUTRAL, SMILE, WIDE_SMILE, FROWN, ...）
             │        └──► ExpressionEffect: 12種（HEART, MUSIC_NOTE, ANGER_MARK, ...）
             │
             ├──► 5. 性格フレーバー適用
             │        ├──► playful高 → ニュートラル時も微笑み
             │        ├──► calm高   → 瞳孔安定
             │        ├──► curious高 → 視線が微妙に動く
             │        └──► brave高  → 恐怖時の瞳孔拡大抑制
             │
             └──► 6. まばたき間隔調整
                      ├──► excitement → 速い（1.5秒）
                      ├──► fear       → 速い（1.0秒）
                      └──► sadness    → 遅い（5.0秒）

[毎フレーム処理]
    │
    ├──► まばたきアニメーション（eye_openness 0↔1）
    └──► スムーズ遷移（前の表情→新しい表情をTRANSITION_SPEEDでブレンド）
```


## 3. システム間依存関係マトリクス

| システム | 依存先 | 影響先 | 連動強度 |
|----------|--------|--------|----------|
| PetEntity | - | 全システム | ★★★★★ |
| AtoA Conversation | Claude API, PetEntity | LanguageEvolution, Emotions, VisualFX | ★★★★★ |
| Language Evolution | AtoA Conv, PetEntity | AtoA Conv, VisualFX, Personality | ★★★★ |
| Ecosystem | Climate, Biome | PetStats, LifeDeath, Evolution, AtoA | ★★★★ |
| Life/Death | PetStats, Ecosystem | AtoA Conv, VisualFX, Breeding | ★★★★★ |
| Breeding | PetEntity x2, Ecosystem | PetEntity(new), Evolution, AtoA | ★★★ |
| Care Action | Player Input | PetStats, Emotions, AtoA, Ecosystem | ★★★★ |
| Evolution Mechanics | Ecosystem, Personality, Age, Care, AtoA, PersistentField | PetEntity, VisualFX, BiologicalMemory, Emotions | ★★★★★ |
| Expression System | EmotionSystem, Personality, PetEntity | VisualFX(表情描画), UI | ★★★★ |
| Visual/FX | 全システム | 画面表示 | ★★★★★ |
| AtoA Community | Claude API, All Pets | Language, Culture, Factions | ★★★★ |
| Original Language | AtoA Conv, Community | AtoA Conv, VisualFX, Culture | ★★★★ |
| Biological Memory | PetEntity, Emotions | AtoA Conv, Emotions, VisualFX, Personality | ★★★★★ |
| PersistentField | All Pets, BiologicalMemory | AtoA Conv, Emotions, Community | ★★★★ |
| EthicalSafeguard | Player Input, AtoA Conv | AtoA Conv(制限), UI通知, GameManager | ★★★★ |

## 4. Godot プロジェクト構成

```
petclaw/
├── project.godot
├── scenes/
│   ├── main.tscn                    # メインシーン
│   ├── pet/
│   │   ├── pet_entity.tscn          # ペットエンティティ
│   │   └── pet_display.tscn         # ペット表示（アニメ+粒子）
│   ├── environment/
│   │   ├── forest.tscn
│   │   ├── sea.tscn
│   │   ├── ruins.tscn
│   │   └── city.tscn
│   └── ui/
│       ├── hud.tscn                 # ステータス表示
│       ├── conversation_log.tscn    # AtoA会話ログ
│       └── language_tracker.tscn    # 言語進化トラッカー
├── scripts/
│   ├── core/
│   │   ├── game_manager.gd          # ゲーム全体管理
│   │   ├── pet_entity.gd            # ペットエンティティ
│   │   ├── stats_system.gd          # ステータス管理
│   │   └── emotion_system.gd        # 感情システム
│   ├── ecosystem/
│   │   ├── ecosystem_manager.gd     # 生態系管理
│   │   ├── environment_system.gd    # 環境影響
│   │   ├── climate_system.gd        # 気候変動
│   │   └── biome_data.gd            # バイオームデータ
│   ├── life/
│   │   ├── life_death_system.gd     # 生き死に
│   │   ├── aging_system.gd          # 老化
│   │   ├── breeding_system.gd       # 交配
│   │   └── genetics_engine.gd       # 遺伝
│   ├── memory/
│   │   └── biological_memory_system.gd   # 生物模倣記憶（海馬・皮質・Ebbinghaus・Hebbian）
│   ├── language/
│   │   ├── language_evolution_system.gd  # 言語進化コア
│   │   ├── original_language_engine.gd   # 独自言語エンジン（造語・Hebbian学習）
│   │   ├── word_order_engine.gd          # 語順エンジン
│   │   ├── suffix_engine.gd              # 接尾辞エンジン
│   │   ├── preposition_engine.gd         # 前置詞エンジン
│   │   └── grammar_tracker.gd            # 文法進化記録
│   ├── conversation/
│   │   ├── a2a_conversation_system.gd    # AtoA会話
│   │   ├── claude_api_client.gd          # Claude API連携
│   │   ├── agent_pool.gd                 # エージェントプール
│   │   └── conversation_memory.gd        # 会話記憶
│   ├── community/
│   │   └── a2a_community_core.gd         # Moltbook風自律コミュニティ
│   ├── field/
│   │   └── persistent_field.gd           # 持続的共有フィールド（atomic write）
│   ├── ethics/
│   │   └── ethical_safeguard.gd          # 倫理セーフガード（依存防止・プライバシー）
│   ├── care/
│   │   ├── care_action_system.gd         # 世話アクション
│   │   └── action_effects.gd             # アクション効果定義
│   ├── evolution/
│   │   ├── evolution_mechanics.gd        # 進化メカニクス
│   │   ├── evolution_tree.gd             # 進化ツリー
│   │   └── branch_resolver.gd            # 進化分岐判定
│   └── visual/
│       ├── visual_fx_system.gd           # ビジュアルFX統合
│       ├── expression_system.gd          # 表情システム（目×口×エフェクト動的生成）
│       ├── particle_manager.gd           # 粒子管理
│       ├── hsv_calculator.gd             # HSV色計算
│       └── animation_controller.gd       # アニメ制御
├── resources/
│   ├── pet_data/                    # ペットデータリソース
│   ├── environment_data/            # 環境データリソース
│   ├── evolution_trees/             # 進化ツリーデータ
│   └── language_data/               # 言語進化データ
└── addons/
    └── claude_mcp/                  # MCP連携アドオン
```

## 5. 信号（Signal）設計

```gdscript
# === Core Signals ===
signal stat_changed(pet_id: int, stat_name: String, old_value: float, new_value: float)
signal emotion_changed(pet_id: int, emotion: String, intensity: float)
signal personality_evolved(pet_id: int, trait: String, delta: float)

# === Life/Death Signals ===
signal pet_warning(pet_id: int, warning_type: String)
signal pet_died(pet_id: int, cause: String)
signal pet_revived(pet_id: int, method: String)
signal pet_aged(pet_id: int, new_age: float)

# === Ecosystem Signals ===
signal environment_changed(old_env: String, new_env: String)
signal climate_event(event_type: String, intensity: float)

# === Language Evolution Signals ===
signal word_order_changed(old_order: String, new_order: String, reason: String)
signal suffix_created(suffix: String, emotion: String, reason: String)
signal preposition_evolved(change: Dictionary)
signal grammar_milestone(milestone: String)

# === Breeding Signals ===
signal breeding_available(pet1_id: int, pet2_id: int)
signal offspring_born(parent1_id: int, parent2_id: int, child_id: int)
signal trait_inherited(child_id: int, trait: String, from_parent: int)

# === Conversation Signals ===
signal conversation_started(participants: Array[int])
signal conversation_ended(participants: Array[int], summary: String)
signal evolution_triggered_by_conversation(evolution_type: String)

# === Care Signals ===
signal care_performed(pet_id: int, action: String, effectiveness: float)

# === Evolution Signals ===
signal evolution_available(pet_id: int, options: Array[Dictionary])
signal evolution_completed(pet_id: int, new_form: String, reason: String)
signal dark_evolution_triggered(pet_id: int, form: String)

# === Expression Signals ===
signal expression_changed(pet_id: int, expression: ExpressionState)

# === Visual Signals ===
signal fx_request(fx_type: String, params: Dictionary)

# === GameManager統合シグナル接続（ラウンド3追加） ===
# AtoA → Evolution: 会話完了時に両参加者の進化カウントを記録
# a2a_system.conversation_ended → _on_a2a_for_evolution → evolution_mechanics.record_a2a_conversation
# Care → Evolution: ケア実行時にミスタイマーリセット + train/explore後に進化チェック
# care_system.care_performed → _on_care_for_evolution → evolution_mechanics.check_evolution
# Care Miss自動検出: 60秒間隔で全ペットの状態チェック、5分以上世話なし+困窮→ミス記録
# _check_care_misses → evolution_mechanics.record_care_miss
```

## 6. Karpathy Loop 統合評価基準

各ループで以下の指標を自動計測・最適化:

| カテゴリ | 指標 | 目標 |
|----------|------|------|
| 愛着 | 世話アクション頻度 | プレイヤーが自発的に世話したくなる |
| 緊張感 | 死亡リスク発生頻度 | 適度な頻度（多すぎず少なすぎず） |
| 創造性 | 言語進化の多様性 | 毎回異なる進化パターン |
| 一貫性 | 文法ルールの整合性 | 進化後も論理的に通じる |
| 感情表現力 | AtoA会話の感情強度 | 自然で豊かな感情表現 |
| 没入感 | セッション継続時間 | プレイヤーが長く遊び続ける |
| バランス | システム間の影響度 | 特定システムが支配的にならない |
