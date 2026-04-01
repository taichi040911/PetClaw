# 進化条件バリデータスキル

## トリガー
「進化」「evolution」「EvolutionTree」「進化条件」「進化パス」「ダークルート」「ケアミス」「進化形態」と言われたときに使用。

## 目的
PetClaw の EvolutionTree（5段階・22+形態・15条件タイプ）と EvolutionMechanics の整合性を保証する。
到達不可能な進化パスの検出、ケアミス×ダークルートの整合性、プレイヤー体験バランスの検証を行う。

## コンテキスト
- **対象ファイル**:
  - `godot_project/scripts/evolution/evolution_tree.gd` — 進化ツリー定義
  - `godot_project/scripts/evolution/evolution_mechanics.gd` — 進化判定ロジック
  - `godot_project/scripts/core/game_manager.gd` — Care Miss Detection、シグナル接続
  - `godot_project/scripts/care/care_action_system.gd` — ケアアクションの進化影響
- **第一原理**:
  - P1: 一貫性×記憶=愛着 — 進化が過去のケア履歴を反映する実感
  - P2: API Cost is Physics — 進化判定はローカル処理（APIゼロ）
  - P3: Player Agency — プレイヤーの選択が進化を決定する
  - P4: 10秒フック — 進化演出は印象的で即座に
  - P5: Complexity is Debt — 条件は直感的に理解可能であること

## 進化ツリー構造

### 5段階進化
```
Stage 0: EGG
Stage 1: BABY（1形態 → 基本形）
Stage 2: CHILD（3形態 → 性格傾向で分岐）
Stage 3: TEEN（7形態 → ケア履歴+性格+環境で分岐）
Stage 4: ADULT（8形態 → 全条件総合判定）
Stage 5: ELDER/ETERNAL（3形態 → 最終到達形態）
= 合計 22+ 形態
```

### 15条件タイプ
```
1.  affection_threshold    — 愛着度が閾値以上
2.  personality_dominant   — 支配的な性格特性
3.  personality_threshold  — 特定性格が閾値以上
4.  care_miss_count        — ケアミス回数（ダークルート）
5.  care_miss_max          — ケアミス回数が閾値以下（ライトルート）
6.  a2a_conversation_count — AtoA会話回数
7.  evolution_readiness    — 進化準備度が閾値以上
8.  environment_time       — 特定環境での累計時間
9.  training_count         — 訓練回数
10. explore_count          — 探索回数
11. age_min                — 最低年齢
12. health_avg             — 平均健康度
13. emotion_dominant       — 支配的な感情
14. bond_level             — 絆レベル（関係性スコア）
15. special_event          — 特殊イベント達成
```

## チェックリスト

### 到達可能性チェック
1. **全22+形態に到達可能なパスが存在するか**
   - Stage N の各形態から Stage N+1 の各形態への経路を列挙
   - 条件の組み合わせが矛盾しないか（例: affection > 0.8 AND care_miss > 5 は通常矛盾）
   - 特殊条件（special_event）に到達手段が存在するか
2. **デッドエンドがないか**
   - 特定形態から次ステージへの進化が全く不可能にならないか
   - 「どの ADULT 形態にも行けない TEEN」が存在しないか
3. **ダークルート到達可能性**
   - ケアミス条件を満たすために必要な放置時間が現実的か
   - ダークルートからの復帰パス（redemption）が存在するか

### ケアミス×ダークルート整合性
1. **Care Miss Detection**（GameManager）:
   - `CARE_MISS_CHECK_INTERVAL`: 60秒間隔
   - `CARE_MISS_THRESHOLD`: 300秒（5分）放置
   - hunger < 0.3 OR health < 0.4 OR energy < 0.2 で判定
2. **record_care_miss()** が EvolutionMechanics に正しく通知されるか
3. care_miss_count の累積がセーブ/ロードで永続化されるか
4. ダークルートの care_miss 閾値が:
   - 低すぎない（1-2回の不注意でダークルートはP3違反）
   - 高すぎない（達成不可能はコンテンツの無駄）
   - 推奨: CHILD→TEEN ダーク: 5回以上、TEEN→ADULT ダーク: 8回以上

### AtoA会話×進化の連携
1. `record_a2a_conversation(pet_id)` が会話終了時に呼ばれるか
2. a2a_conversation_count が進化判定で参照されるか
3. 会話回数条件を持つ形態:
   - 社交的形態（a2a_count >= 10）は180秒間隔で10回 = 30分プレイで到達可能
   - 孤独形態（a2a_count <= 2）はペット1匹飼育で自然に到達

### 進化判定タイミング
1. `check_evolution(pet)` が以下のタイミングで呼ばれるか:
   - ケアアクション（train, explore）後
   - AtoA会話終了後（全参加者）
   - 自律行動（explore_area, practice_language, seek_companion）後
2. 進化判定がフレーム内処理（APIゼロ）であるか → P2準拠
3. 進化演出がトリガーされるか（VisualFX連携）

### セーブ/ロード整合性
1. EvolutionMechanics の以下が GameManager.save_data に含まれるか:
   - care_miss 累計
   - a2a_conversation 累計
   - evolution_readiness
   - 現在の進化ステージ・形態
2. `to_dict()` / `from_dict()` が全フィールドをカバーしているか

## 進化バランス分析ガイドライン

### 平均到達時間の目安
```
EGG → BABY: 即時（チュートリアル）
BABY → CHILD: 10-15分のプレイ
CHILD → TEEN: 30-60分のプレイ（分岐が見え始める）
TEEN → ADULT: 2-4時間のプレイ（明確な個性が確立）
ADULT → ELDER: 8-12時間のプレイ（長期の絆）
ELDER → ETERNAL: 特殊条件（redemption path、20時間+）
```

### バランスチェック観点
1. **形態の人気偏り**: 特定の進化先が圧倒的に容易でないか
2. **隠し形態の発見率**: 特殊条件形態の発見が不可能に近くないか
3. **ダークルートの緊張感**: ケアミスの恐怖が適度か（多すぎ→ストレス、少なすぎ→緊張感なし）
4. **環境依存形態**: 特定環境でしか進化できない形態の環境時間条件が現実的か

## デバッグ手順

### 「進化しない」場合
1. `evolution_readiness` の現在値を確認 → 閾値に達しているか？
2. 全15条件のうちどれが未達か特定
3. care_miss が意図せず溜まっていないか（ダークルート条件でブロック）
4. age_min を満たしているか
5. 対処: `evolution_mechanics.check_evolution(pet)` を手動呼び出しし、返り値の条件判定結果を確認

### 「意図しないダーク進化」場合
1. care_miss_count の値を確認
2. GameManager の `_check_care_misses()` が過剰にトリガーされていないか
3. `CARE_MISS_THRESHOLD` (300s) が短すぎないか確認
4. hunger/health/energy の閾値が厳しすぎないか
5. 対処: ケアミス判定の閾値調整 or care_miss_count のリセット機能追加
