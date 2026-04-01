# AtoA Community Orchestrator スキル

## トリガー
「コミュニティ」「community」「Moltbook」「自律コミュニティ」「集団行動」「社会構造」「文化」「派閥」「Field」「PersistentField」「群れ」「colony」「population dynamics」と言われたときに使用。

## 目的
PetClaw のペットコミュニティが自律的に社会構造・文化・派閥を形成する過程の設計・管理・スケーリングを支援する。
Moltbook風の大規模自律コミュニティをプロトタイピングし、個々のペットの行動が集団レベルの創発現象を生む仕組みを保証する。

## コンテキスト
- **対象ファイル**:
  - `godot_project/scripts/community/persistent_field.gd` — コミュニティ状態永続化
  - `godot_project/scripts/autonomy/pet_autonomy_system.gd` — 個体の自律行動
  - `godot_project/scripts/conversation/a2a_conversation_system.gd` — 社会的インタラクション
  - `godot_project/scripts/ecosystem/ecosystem_manager.gd` — 環境からの圧力
  - `godot_project/scripts/language/language_evolution.gd` — 言語的文化形成
  - `godot_project/scripts/memory/biological_memory_system.gd` — 共有記憶
- **第一原理**:
  - P1: 一貫性×記憶=愛着 — コミュニティの「歴史」がプレイヤーの物語になる
  - P2: API Cost is Physics — 大規模コミュニティはローカル処理主体、APIは社会的イベントのみ
  - P3: Player Agency — プレイヤーは「神」ではなく「ケアテイカー」。コミュニティは自律的に動く

## コミュニティモデル

### 社会構造の創発
```
個体レベル（PetAutonomySystem）
├── Pulse: 自発的行動（wander, seek_companion, explore_area...）
├── Resonance: 環境・イベントへの反応
└── 性格: 行動選好のバイアス
    │
    ▼
関係レベル（BiologicalMemory + PersistentField）
├── 1対1の絆（bond_level）
├── 共有記憶（shared_memories）
├── 会話履歴（a2a_conversation_count）
└── 感情的親密度（affection）
    │
    ▼
グループレベル（PersistentField）
├── 派閥（faction）: 性格・言語が近いペットが自然にグループ化
├── リーダー: bond_level合計が最高のペット
├── コミュニティムード: 全ペットの感情加重平均
└── 文化: 多数派の言語ルール + 共有された重要記憶
    │
    ▼
コミュニティレベル（EcosystemManager + PersistentField）
├── 人口動態: 出生率 vs 死亡率
├── 環境適応: コミュニティとしての環境対応
├── 言語標準: コミュニティの「公用語」
└── 歴史: 重要イベントの年表（Field.chronicles）
```

### 派閥形成メカニズム
```
1. 親和性計算（Affinity Score）
   affinity(A, B) =
     personality_similarity(A, B) * 0.3
     + language_similarity(A, B) * 0.2
     + shared_memory_count(A, B) * 0.2
     + bond_level(A, B) * 0.3

2. クラスタリング（自然発生）
   - affinity > 0.7 のペット同士が自然にグループ化
   - グループ内AtoA会話が優先的に発生（proximity bias）
   - グループ固有の言語パターンが強化される

3. 派閥間の関係
   - 友好: グループ間のaffinity平均 > 0.5
   - 中立: 0.3 < affinity < 0.5
   - 対立: affinity < 0.3（言語の違いが要因になりやすい）
   - 対立グループ間の会話 → 反乱表現が生まれやすい
```

### PersistentField のコミュニティコンテキスト
```gdscript
# PersistentField が保持するコミュニティ状態
{
    "community_mood": float,          # 全体のムード（-1.0〜1.0）
    "population": int,                 # 現在の生存ペット数
    "factions": [                      # 派閥リスト
        {
            "id": int,
            "members": Array[int],     # ペットIDリスト
            "leader_id": int,
            "language_dialect": {},     # 派閥固有の言語変種
            "mood": float,
            "formation_time": float,
        }
    ],
    "chronicles": [                    # コミュニティ年表
        {
            "timestamp": float,
            "event_type": String,      # "death", "birth", "evolution", "faction_split", etc.
            "description": String,
            "affected_pets": Array[int],
        }
    ],
    "language_standard": {},           # コミュニティの標準言語ルール
    "shared_events": Array,            # 全員が記憶している重要イベント
    "relationship_graph": {},          # ペット間の関係性グラフ
}
```

## チェックリスト

### コミュニティ形成チェック
1. PersistentField が `record_shared_event()` を適切に呼んでいるか
2. 関係性グラフが AtoA 会話ごとに更新されるか
3. 派閥の自動検出（affinity計算 + クラスタリング）が定期的に実行されるか
4. コミュニティムードが全ペットの感情加重平均で計算されるか

### 派閥ダイナミクスチェック
1. 派閥形成が5匹以上で自然に発生するか
2. 派閥内のAtoA会話頻度が派閥外より高いか
3. 派閥リーダーの選出が bond_level 合計に基づくか
4. 派閥間の対立が言語の違いから生まれるか
5. 派閥の分裂・統合がイベントとして chronicles に記録されるか

### スケーラビリティチェック（Moltbook構想）
1. 10匹でのコミュニティ動作が安定しているか（基本テスト）
2. 50匹での派閥分化が自然に起きるか（中規模テスト）
3. 100匹以上でのパフォーマンスが許容範囲か
4. API呼び出しが人口に対して線形に増えないか（PULSE_OK + バッチ処理）
5. 150万規模へのスケールパス（ローカルシミュレーション + サンプリング）が設計されているか

### 歴史・文化チェック
1. chronicles が時系列で蓄積されるか
2. 重要イベント（死、誕生、進化、派閥変動）が全て記録されるか
3. 古い chronicles がプレイヤーに閲覧可能か（歴史ビュー）
4. 文化（言語標準 + 共有記憶）が世代を超えて継承されるか
5. 子ペットが親の派閥の言語を初期値として持つか

## スケーリング戦略

### Phase 1: 小規模（5-10匹）— 現在のターゲット
- 全ペット間のAtoA会話を許可
- 派閥は手動確認（自動検出はオプション）
- chronicles は全件保持
- API: 全会話がClaude API経由

### Phase 2: 中規模（10-50匹）
- 派閥自動検出を有効化
- AtoA会話は派閥内優先 + 派閥間は低頻度
- PULSE_OKの適用率を上げる（70%→85%のペットがスキップ）
- chronicles は要約圧縮（1日1エントリーに集約）

### Phase 3: 大規模（50-500匹）
- 派閥をサブコミュニティとして独立管理
- 代表ペット（リーダー）間のAtoA会話でサブコミュニティ間交流
- Ralph Loop でオフラインシミュレーション（APIゼロ期間あり）
- Agent Teams で派閥ごとに独立エージェント

### Phase 4: Moltbook規模（500+）
- 統計的シミュレーション（個々のペットではなく派閥の平均値で処理）
- サンプリング: 各派閥から代表3-5匹を抽出してAtoA実行
- 結果を派閥全体に伝播
- chronicles はマイルストーンのみ保持

## Ralph Loop でのコミュニティテスト
```
Ralph Loop設定:
- 目標: 「10ペット × 100サイクル → 2-3派閥が自然形成、言語方言が分化」
- 評価関数:
  - faction_count >= 2
  - language_diversity_between_factions >= 0.3
  - community_stability >= 0.6（ペット幸福度の分散が小さい）
  - chronicle_richness >= 10（重要イベント記録数）
- 調整対象: affinity_threshold, pulse_interval, conversation_frequency
- 反復: 最大50回
```

## アンチパターン
- 全ペットが1つの派閥に属する（均質化）→ 性格多様性の初期配置を保証
- 派閥間が完全に断絶する（孤立化）→ 定期的な「交流イベント」を強制挿入
- コミュニティムードが常にネガティブ → grief後の回復メカニズム保証
- 歴史が膨れすぎてコンテキストを圧迫 → chronicles の自動要約・アーカイブ
- リーダーが死んだ後にグループが崩壊する → リーダー継承メカニズム
- プレイヤーが介入できない → ケアアクションがコミュニティに影響するパスを維持（P3）
