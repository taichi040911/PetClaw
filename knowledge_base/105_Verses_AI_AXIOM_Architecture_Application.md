# KB105: Verses AI AXIOMアーキテクチャの詳細とPetClawへの応用ガイド
## Active eXpanding Inference with Object-centric Models × PetClaw統合
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams
**前提知識:** KB104 (FEP応用), KB103 (予測符号化), KB102 (STDP), KB99 (Hebbian実装), KB98 (独自言語進化)

---

## 1. Verses AI AXIOMアーキテクチャ概要

### 1.1 AXIOMとは

AXIOM（Active eXpanding Inference with Object-centric Models）は、Verses AIが開発した
Active Inferenceベースの次世代AIアーキテクチャ。Karl Friston（FEP提唱者）をChief Scientistに迎え、
従来のTransformer/DRLとは根本的に異なる「デジタル脳」として設計されている。

### 1.2 発展経緯

| 年 | マイルストーン | PetClawへの示唆 |
|----|-------------|----------------|
| 2020 | Verses AI設立 | Active Inferenceの産業応用開始 |
| 2022 | Karl Friston参画 | FEPの実装アーキテクチャ開発 |
| 2023 | AXIOM初期論文 | Object-centricモデルの有効性実証 |
| 2024 | Gameworld 10k ベンチマーク | DeepMindモデルを大幅に上回る |
| 2025 | AXIOM v2 + ロボティクス応用 | Pre-trainingなしでリアルタイム適応 |
| 2026 | IEEE Spatial Web標準連携 | マルチエージェント環境への拡張 |

### 1.3 AXIOMの4コアモジュール

```
  ┌─────────────────────────────────────────────────┐
  │                AXIOM Architecture                 │
  │                                                   │
  │  入力（ピクセル/センサー）                          │
  │       │                                           │
  │       ▼                                           │
  │  ┌──── sMM ────────────────────────────────────┐ │
  │  │  Slot Mixture Model                          │ │
  │  │  視覚入力をオブジェクト中心の「スロット」に分解 │ │
  │  │  例: ペットA, 木, 食べ物 → 各スロットに割り当て │ │
  │  └──┬───────────────────────────────────────────┘ │
  │     │                                             │
  │     ▼                                             │
  │  ┌──── iMM ────────────────────────────────────┐ │
  │  │  Identity Mixture Model                      │ │
  │  │  オブジェクトの「種類」を識別・一般化           │ │
  │  │  例: 「これは猫型ペット」「これは食べ物」       │ │
  │  └──┬───────────────────────────────────────────┘ │
  │     │                                             │
  │     ▼                                             │
  │  ┌──── tMM ────────────────────────────────────┐ │
  │  │  Transition Mixture Model                    │ │
  │  │  オブジェクトの動き・変化のプロトタイプ学習    │ │
  │  │  例: 落下, 跳ね返り, 成長, 進化              │ │
  │  └──┬───────────────────────────────────────────┘ │
  │     │                                             │
  │     ▼                                             │
  │  ┌──── rMM ────────────────────────────────────┐ │
  │  │  Recurrent Mixture Model                     │ │
  │  │  オブジェクト間の因果関係をスパースにモデル化  │ │
  │  │  例: 「ペットAが食べた→満腹度↑→幸福度↑」     │ │
  │  └──────────────────────────────────────────────┘ │
  │                                                   │
  │  出力: 行動選択（Active Inference）               │
  │        + 内部モデル更新                           │
  └─────────────────────────────────────────────────┘
```

### 1.4 AXIOMの核心的強み

| 特性 | 従来DL (Transformer/DRL) | AXIOM | PetClawでの利点 |
|------|-------------------------|-------|----------------|
| **学習効率** | 大量データが必要 | 少数サンプルで学習 | テンプレート80%でも効果的な言語進化 |
| **解釈可能性** | ブラックボックス | オブジェクト中心で透明 | デバッグ容易、ペット行動の説明可能性 |
| **適応性** | 再学習が必要 | リアルタイム適応 | 環境変化・イベントへの即座の反応 |
| **構成可能性** | モノリシック | モジュール拡張 | 新システム追加が容易 |
| **因果推論** | 相関ベース | 因果関係モデル | ケアミス→結果の正確な追跡 |
| **マルチエージェント** | 独立学習 | 社会的Active Inference | AtoA会話での自然な協調 |

---

## 2. PetClaw AtoAへのAXIOM応用マッピング

### 2.1 AXIOM 4モジュール → PetClawシステム対応

| AXIOMモジュール | PetClawでの実装 | 管理対象 |
|----------------|----------------|---------|
| **sMM (Slot)** | `PetSlotModel` | ペット・環境要素をスロットとして管理 |
| **iMM (Identity)** | `PetIdentityModel` | ペットの種類・性格・進化形態の識別 |
| **tMM (Transition)** | `TransitionDynamicsModel` | 進化・成長・死亡の遷移パターン |
| **rMM (Recurrent)** | `CausalRelationModel` | ペット間関係・環境因果の追跡 |

### 2.2 AXIOM風スロット構造

```
PetClaw世界のスロット分解:

  Slot[0]: Pet "Mimi"
    ├── identity: {species: "cat", personality: {brave: 0.7, curious: 0.8}}
    ├── state: {hunger: 0.6, health: 0.9, emotion: "joy"}
    ├── dynamics: {growing, exploring}
    └── vocabulary: {happy-spark: 0.8, brave-force: 0.5}

  Slot[1]: Pet "Kuro"
    ├── identity: {species: "dog", personality: {gentle: 0.9, timid: 0.3}}
    ├── state: {hunger: 0.4, health: 1.0, emotion: "love"}
    ├── dynamics: {resting}
    └── vocabulary: {love-mu: 0.9, friend-ba: 0.7}

  Slot[2]: Environment "Forest"
    ├── identity: {type: "biome", danger: 0.2}
    ├── state: {weather: "sunny", time: "afternoon"}
    ├── dynamics: {day_night_cycle, seasonal_change}
    └── effects: {healing: +0.01/tick, energy: -0.005/tick}

  Slot[3]: Event "Conversation"
    ├── identity: {type: "social", participants: [0, 1]}
    ├── state: {turn: 3, mood: "warm", topic: "friendship"}
    ├── dynamics: {escalating_intimacy}
    └── language: {active_words: ["happy-spark", "friend-ba"]}

  Slot[4]: Event "Death" (upcoming)
    ├── identity: {type: "lifecycle", target: null}
    ├── state: {probability: 0.02, triggers: ["old_age", "neglect"]}
    └── dynamics: {dormant → imminent → occurred → memorial}
```

### 2.3 Object-Centric言語進化モデル

```
従来のPetClaw:
  テキスト → 語彙マッチ → Hebbian強化
  （フラットな処理）

AXIOM統合後:
  テキスト → スロット分解 → オブジェクト間関係抽出 → 因果モデル更新
  → Active Inferenceで次の発言を計画 → Hebbian/STDP/FEPで語彙強化

例: "Mimi said brave-force to Kuro while it was raining"
  → Slot[Mimi].vocabulary["brave-force"].strength ↑
  → CausalRelation[Mimi→Kuro].intimacy ↑
  → Transition[rain].effect_on_language → 「雨の日に強い言葉を使う」パターン学習
```

---

## 3. GDScript実装

### 3.1 スロットモデル（sMM簡易版）

```gdscript
## PetSlotModel — AXIOM sMM のPetClaw簡易実装
## 世界のエンティティをオブジェクト中心のスロットで管理
## KB105: Verses AI AXIOM Architecture Application

class_name PetSlotModel
extends RefCounted

# === スロット構造 ===
# { slot_id: int → SlotData: Dictionary }
var slots: Dictionary = {}
var _next_slot_id: int = 0

# === スロットタイプ ===
enum SlotType {
	PET,
	ENVIRONMENT,
	EVENT,
	LANGUAGE_CLUSTER,
}

const SLOT_TYPE_NAMES: Dictionary = {
	SlotType.PET: "pet",
	SlotType.ENVIRONMENT: "environment",
	SlotType.EVENT: "event",
	SlotType.LANGUAGE_CLUSTER: "language_cluster",
}


func create_slot(slot_type: int, entity_id: int, initial_state: Dictionary = {}) -> int:
	## 新しいスロットを作成
	var slot_id: int = _next_slot_id
	_next_slot_id += 1

	slots[slot_id] = {
		"slot_id": slot_id,
		"type": slot_type,
		"entity_id": entity_id,
		"identity": {},
		"state": initial_state,
		"dynamics": [],
		"relations": {},  # other_slot_id → relation_type
		"last_updated": Time.get_unix_time_from_system(),
	}

	return slot_id


func update_slot_state(slot_id: int, new_state: Dictionary) -> void:
	## スロットの状態を更新
	if slot_id not in slots:
		return
	for key: String in new_state:
		slots[slot_id]["state"][key] = new_state[key]
	slots[slot_id]["last_updated"] = Time.get_unix_time_from_system()


func set_slot_identity(slot_id: int, identity: Dictionary) -> void:
	## スロットのアイデンティティを設定
	if slot_id not in slots:
		return
	slots[slot_id]["identity"] = identity


func add_relation(from_slot: int, to_slot: int, relation_type: String) -> void:
	## スロット間の関係を追加
	if from_slot not in slots or to_slot not in slots:
		return
	slots[from_slot]["relations"][to_slot] = relation_type


func get_slots_by_type(slot_type: int) -> Array[Dictionary]:
	## タイプでスロットを検索
	var result: Array[Dictionary] = []
	for sid: int in slots:
		if slots[sid]["type"] == slot_type:
			result.append(slots[sid])
	return result


func get_related_slots(slot_id: int) -> Array[Dictionary]:
	## 関連スロットを取得
	if slot_id not in slots:
		return []
	var result: Array[Dictionary] = []
	for related_id: int in slots[slot_id]["relations"]:
		if related_id in slots:
			result.append(slots[related_id])
	return result


func to_dict() -> Dictionary:
	return {
		"slots": slots.duplicate(true),
		"next_slot_id": _next_slot_id,
	}


func from_dict(data: Dictionary) -> void:
	slots = data.get("slots", {})
	_next_slot_id = data.get("next_slot_id", 0)
```

### 3.2 遷移ダイナミクスモデル（tMM簡易版）

```gdscript
## TransitionDynamicsModel — AXIOM tMM のPetClaw簡易実装
## オブジェクトの変化パターン（プロトタイプ）を学習
## KB105: Verses AI AXIOM Architecture Application

class_name TransitionDynamicsModel
extends RefCounted

# === 遷移プロトタイプ ===
# { prototype_name: { pattern, frequency, contexts, strength } }
var prototypes: Dictionary = {}

# === AXIOM風パラメータ ===
const PROTOTYPE_LEARN_RATE: float = 0.1
const PROTOTYPE_DECAY_RATE: float = 0.005
const MIN_FREQUENCY_FOR_PROTOTYPE: int = 3  # 3回以上観測で正式プロトタイプ


func observe_transition(
	slot_id: int,
	from_state: Dictionary,
	to_state: Dictionary,
	context: Dictionary
) -> Dictionary:
	## 状態遷移を観測し、プロトタイプと照合・学習
	##
	## Returns: {"matched_prototype": String, "prediction_error": float,
	##           "new_prototype": bool}

	# 遷移のフィンガープリント生成
	var fingerprint: String = _generate_fingerprint(from_state, to_state)

	if fingerprint in prototypes:
		# 既存プロトタイプとマッチ → 強化
		prototypes[fingerprint]["frequency"] += 1
		prototypes[fingerprint]["strength"] = clampf(
			prototypes[fingerprint]["strength"] + PROTOTYPE_LEARN_RATE,
			0.0, 1.0
		)
		prototypes[fingerprint]["last_contexts"].append(context)
		if prototypes[fingerprint]["last_contexts"].size() > 10:
			prototypes[fingerprint]["last_contexts"].pop_front()

		# 予測誤差: 既知パターン → 低い
		var prediction_error: float = 0.1 * (1.0 - prototypes[fingerprint]["strength"])
		return {
			"matched_prototype": fingerprint,
			"prediction_error": prediction_error,
			"new_prototype": false,
		}
	else:
		# 新しいパターン → プロトタイプ候補
		prototypes[fingerprint] = {
			"from_pattern": _extract_pattern(from_state),
			"to_pattern": _extract_pattern(to_state),
			"frequency": 1,
			"strength": 0.3,
			"last_contexts": [context],
			"created_at": Time.get_unix_time_from_system(),
		}
		# 予測誤差: 未知パターン → 高い
		return {
			"matched_prototype": fingerprint,
			"prediction_error": 0.8,
			"new_prototype": true,
		}


func predict_transition(
	current_state: Dictionary,
	context: Dictionary
) -> Dictionary:
	## 現在の状態から次の遷移を予測
	var best_match: String = ""
	var best_score: float = 0.0

	for proto_name: String in prototypes:
		var proto: Dictionary = prototypes[proto_name]
		if proto["frequency"] < MIN_FREQUENCY_FOR_PROTOTYPE:
			continue
		var match_score: float = _calculate_state_similarity(
			current_state, proto["from_pattern"]
		) * proto["strength"]
		if match_score > best_score:
			best_score = match_score
			best_match = proto_name

	if best_match.is_empty():
		return {"predicted_next": {}, "confidence": 0.0}

	return {
		"predicted_next": prototypes[best_match]["to_pattern"],
		"confidence": best_score,
		"prototype": best_match,
	}


func _generate_fingerprint(from_state: Dictionary, to_state: Dictionary) -> String:
	## 遷移の一意識別子を生成
	var changes: Array[String] = []
	for key: String in to_state:
		if key in from_state:
			if from_state[key] != to_state[key]:
				changes.append("%s:%s→%s" % [key, str(from_state[key]).substr(0, 4), str(to_state[key]).substr(0, 4)])
	changes.sort()
	return "|".join(changes) if not changes.is_empty() else "no_change"


func _extract_pattern(state: Dictionary) -> Dictionary:
	## 状態からパターンを抽出（簡易版: そのまま返す）
	return state.duplicate()


func _calculate_state_similarity(state_a: Dictionary, state_b: Dictionary) -> float:
	## 2つの状態の類似度を計算（0.0-1.0）
	if state_a.is_empty() or state_b.is_empty():
		return 0.0
	var matching_keys: int = 0
	var total_keys: int = state_b.size()
	for key: String in state_b:
		if key in state_a and str(state_a[key]) == str(state_b[key]):
			matching_keys += 1
	return float(matching_keys) / maxf(float(total_keys), 1.0)


func to_dict() -> Dictionary:
	return {"prototypes": prototypes.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	prototypes = data.get("prototypes", {})
```

### 3.3 因果関係モデル（rMM簡易版）

```gdscript
## CausalRelationModel — AXIOM rMM のPetClaw簡易実装
## オブジェクト間の因果関係をスパースにモデル化
## KB105: Verses AI AXIOM Architecture Application

class_name CausalRelationModel
extends RefCounted

# === 因果リンク ===
# { "cause_slot→effect_slot": { type, strength, evidence_count, delay } }
var causal_links: Dictionary = {}

# === パラメータ ===
const CAUSAL_LEARN_RATE: float = 0.08
const CAUSAL_DECAY_RATE: float = 0.002
const CAUSAL_EVIDENCE_THRESHOLD: int = 2  # 因果推論に必要な最低観測回数
const SPARSITY_PRUNE_THRESHOLD: float = 0.05  # これ以下の因果リンクを削除


func observe_causal_event(
	cause_slot_id: int,
	effect_slot_id: int,
	cause_event: String,
	effect_event: String,
	delay_turns: int = 0
) -> void:
	## 因果的に関連するイベントペアを記録
	var link_key: String = "%d→%d:%s→%s" % [cause_slot_id, effect_slot_id, cause_event, effect_event]

	if link_key in causal_links:
		causal_links[link_key]["evidence_count"] += 1
		causal_links[link_key]["strength"] = clampf(
			causal_links[link_key]["strength"] + CAUSAL_LEARN_RATE,
			0.0, 1.0
		)
		# 遅延の平均を更新
		var old_delay: float = causal_links[link_key]["avg_delay"]
		var count: int = causal_links[link_key]["evidence_count"]
		causal_links[link_key]["avg_delay"] = (old_delay * (count - 1) + delay_turns) / count
	else:
		causal_links[link_key] = {
			"cause_slot": cause_slot_id,
			"effect_slot": effect_slot_id,
			"cause_event": cause_event,
			"effect_event": effect_event,
			"strength": 0.3,
			"evidence_count": 1,
			"avg_delay": float(delay_turns),
			"created_at": Time.get_unix_time_from_system(),
		}


func predict_effects(
	cause_slot_id: int,
	cause_event: String
) -> Array[Dictionary]:
	## 原因から予測される効果のリストを返す
	var effects: Array[Dictionary] = []

	for link_key: String in causal_links:
		var link: Dictionary = causal_links[link_key]
		if link["cause_slot"] == cause_slot_id \
			and link["cause_event"] == cause_event \
			and link["evidence_count"] >= CAUSAL_EVIDENCE_THRESHOLD:
			effects.append({
				"effect_slot": link["effect_slot"],
				"effect_event": link["effect_event"],
				"probability": link["strength"],
				"expected_delay": link["avg_delay"],
			})

	# 確率順でソート
	effects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["probability"] > b["probability"]
	)
	return effects


func get_causes(
	effect_slot_id: int,
	effect_event: String
) -> Array[Dictionary]:
	## 効果から推定される原因のリストを返す
	var causes: Array[Dictionary] = []
	for link_key: String in causal_links:
		var link: Dictionary = causal_links[link_key]
		if link["effect_slot"] == effect_slot_id \
			and link["effect_event"] == effect_event \
			and link["evidence_count"] >= CAUSAL_EVIDENCE_THRESHOLD:
			causes.append({
				"cause_slot": link["cause_slot"],
				"cause_event": link["cause_event"],
				"probability": link["strength"],
			})
	return causes


func prune_weak_links() -> int:
	## 弱い因果リンクをスパースに削除（AXIOM: sparsity principle）
	var to_remove: Array[String] = []
	for link_key: String in causal_links:
		causal_links[link_key]["strength"] -= CAUSAL_DECAY_RATE
		if causal_links[link_key]["strength"] < SPARSITY_PRUNE_THRESHOLD:
			to_remove.append(link_key)
	for key: String in to_remove:
		causal_links.erase(key)
	return to_remove.size()


func to_dict() -> Dictionary:
	return {"causal_links": causal_links.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	causal_links = data.get("causal_links", {})
```

### 3.4 AXIOM統合型Active Inferenceコントローラー

```gdscript
## AXIOMActiveInferenceController — 4モジュール統合制御
## KB104 (FEP) + KB105 (AXIOM) の統合
## ペットの行動選択をActive Inferenceで制御

class_name AXIOMActiveInferenceController
extends RefCounted

var slot_model: PetSlotModel
var transition_model: TransitionDynamicsModel
var causal_model: CausalRelationModel

# === Active Inference パラメータ (KB104から継承) ===
const EPISTEMIC_WEIGHT: float = 0.4
const PRAGMATIC_WEIGHT: float = 0.6
const EXPLORATION_TEMPERATURE: float = 0.3


func _init() -> void:
	slot_model = PetSlotModel.new()
	transition_model = TransitionDynamicsModel.new()
	causal_model = CausalRelationModel.new()


func register_pet(pet: PetEntity) -> int:
	## ペットをAXIOMモデルに登録
	var slot_id: int = slot_model.create_slot(
		PetSlotModel.SlotType.PET,
		pet.pet_id,
		{
			"hunger": pet.stats.hunger,
			"health": pet.stats.health,
			"emotion": _get_dominant_emotion(pet),
			"evolution_stage": pet.evolution_stage,
		}
	)
	slot_model.set_slot_identity(slot_id, {
		"name": pet.pet_name,
		"personality": pet.personality.duplicate(),
		"species": "pet",
	})
	return slot_id


func process_conversation_turn(
	speaker_slot: int,
	listener_slot: int,
	message: Dictionary,
	vocabulary: Dictionary
) -> Dictionary:
	## 会話ターンをAXIOMフレームワークで処理
	##
	## Returns: {"prediction_error": float, "recommended_action": String,
	##           "causal_updates": int, "transition_match": String}

	# 1. tMM: 遷移予測
	var speaker_state: Dictionary = slot_model.slots.get(speaker_slot, {}).get("state", {})
	var transition_prediction: Dictionary = transition_model.predict_transition(
		speaker_state,
		{"turn": message.get("turn", 0), "topic": message.get("topic", "")}
	)

	# 2. 実際の遷移を観測
	var new_emotion: String = message.get("emotion", "neutral")
	var actual_state: Dictionary = speaker_state.duplicate()
	actual_state["emotion"] = new_emotion
	var transition_result: Dictionary = transition_model.observe_transition(
		speaker_slot,
		speaker_state,
		actual_state,
		{"message": message.get("message", "").substr(0, 50)}
	)

	# 3. rMM: 因果関係記録
	var causal_updates: int = 0
	if message.get("emotion_intensity", 0.0) > 0.5:
		# 強い感情は因果的に重要
		causal_model.observe_causal_event(
			speaker_slot, listener_slot,
			"speak_%s" % new_emotion,
			"listen_%s" % new_emotion,
			0
		)
		causal_updates += 1

	# 語彙使用の因果記録
	for word: String in vocabulary:
		var ai_term: String = vocabulary[word].get("ai_term", "")
		if message.get("message", "").contains(ai_term):
			causal_model.observe_causal_event(
				speaker_slot, listener_slot,
				"use_word_%s" % word,
				"hear_word_%s" % word,
				0
			)
			causal_updates += 1

	# 4. スロット状態更新
	slot_model.update_slot_state(speaker_slot, actual_state)

	# 5. Active Inference: 次の行動推奨
	var prediction_error: float = transition_result["prediction_error"]
	var recommended: String = _recommend_action(
		prediction_error,
		message.get("emotion_intensity", 0.5),
		vocabulary.size()
	)

	return {
		"prediction_error": prediction_error,
		"recommended_action": recommended,
		"causal_updates": causal_updates,
		"transition_match": transition_result.get("matched_prototype", ""),
		"is_new_pattern": transition_result.get("new_prototype", false),
	}


func _recommend_action(
	prediction_error: float,
	emotion_intensity: float,
	vocab_size: int
) -> String:
	## Active Inferenceに基づく行動推奨
	## KB104のExpected Free Energy計算を使用

	# 高い予測誤差 + 強い感情 → 新語提案を推奨
	if prediction_error > 0.6 and emotion_intensity > 0.5:
		return "propose_new_word"

	# 語彙が少ない → 探索を推奨
	if vocab_size < 10:
		return "explore_vocabulary"

	# 低い予測誤差 → 既存語を使用
	if prediction_error < 0.3:
		return "use_established_word"

	# 中間 → 確率的に選択
	if randf() < EXPLORATION_TEMPERATURE:
		return "explore_vocabulary"
	return "use_established_word"


func _get_dominant_emotion(pet: PetEntity) -> String:
	var best_emotion: String = "neutral"
	var best_value: float = 0.0
	for emotion: String in pet.emotions:
		if pet.emotions[emotion] > best_value:
			best_value = pet.emotions[emotion]
			best_emotion = emotion
	return best_emotion


func to_dict() -> Dictionary:
	return {
		"slot_model": slot_model.to_dict(),
		"transition_model": transition_model.to_dict(),
		"causal_model": causal_model.to_dict(),
	}


func from_dict(data: Dictionary) -> void:
	if data.has("slot_model"):
		slot_model.from_dict(data["slot_model"])
	if data.has("transition_model"):
		transition_model.from_dict(data["transition_model"])
	if data.has("causal_model"):
		causal_model.from_dict(data["causal_model"])
```

---

## 4. 応用シーン

### 4.1 シーン1: 日常会話での Object-Centric 言語進化

```
スロット構成:
  Slot[0]: Mimi (emotion: joy, hunger: 0.3)
  Slot[1]: Kuro (emotion: neutral, hunger: 0.7)
  Slot[2]: Forest (weather: sunny)

ターン1: Mimi → "Let's play-ku in the sunny-ba forest{-pya}!"

AXIOM処理:
  tMM: Mimiの遷移「neutral → joy + active」を観測
       → "play_in_sun" プロトタイプに一致（既知パターン）
       → prediction_error = 0.15（低い → 既知行動）

  rMM: 因果記録
       → Slot[2].weather=sunny → Slot[0].emotion=joy (強度↑)
       → 「晴れの日にMimiは活発になる」因果リンク強化

  Active Inference: prediction_error低 → "use_established_word"推奨
  結果: 既存語 "play-ku" が Hebbian強化 (+0.08)

ターン2: Kuro → "*stomach growls{-nano}* ...hungry-mu..."

AXIOM処理:
  tMM: Kuroの遷移「neutral → hunger_distress」を観測
       → 新しいプロトタイプ！prediction_error = 0.8

  rMM: 因果記録
       → Slot[1].hunger=0.7 → Slot[1].emotion=discomfort
       → 「空腹は感情を変える」因果リンク新規作成

  Active Inference: prediction_error高 → "propose_new_word"推奨
  → 新語 "grumble-ze" が発明される可能性（ランダム + 文脈）

  FEP統合 (KB104):
  VFE = 1.0 × 0.8 + 0.3 × 0.15 = 0.845
  → is_surprising = true
  → Hebbian LTP: 0.15 × 1.8 (surprise) × 1.25 (precision) = 0.338
```

### 4.2 シーン2: 死亡イベントでの因果モデル更新

```
スロット構成:
  Slot[0]: Mimi (emotion: sadness 0.9)
  Slot[1]: Kuro (emotion: fear 0.6)
  Slot[3]: Death Event (target: Shiro, type: old_age)

AXIOM処理:
  sMM: 新スロット Slot[4]: Memorial Event 作成

  tMM: 大規模遷移パターン
       → "death_of_companion" プロトタイプ（初めて観測）
       → prediction_error = 0.95（極めて高い）

  rMM: 因果関係の連鎖
       → Slot[3].death → Slot[0].emotion=sadness (強度: 0.9)
       → Slot[3].death → Slot[1].emotion=fear (強度: 0.6)
       → Slot[3].death → Slot[4].memorial (新規因果)

  Active Inference:
       → 全ペットに "propose_new_word" 推奨
       → 死に関する語彙クラスター形成:
         "gone-mu" (去る), "remember-pya" (記憶), "forever-light" (永遠の光)

  FEP統合:
       VFE = 1.0 × 0.95 + 0.3 × 0.20 = 1.01
       → 最大レベルの学習トリガー
       → 全関連語のHebbian LTP: 0.15 × 1.8 × 1.85 = 0.50（爆発的強化）

  長期効果:
       → "death" 因果プロトタイプが確立される
       → 次の死亡イベントでは prediction_error が下がる（学習済み）
       → 追悼語彙が既に存在する → 既存語で対応可能に
```

### 4.3 シーン3: PetBook投稿の因果物語生成

```
AXIOM風因果物語:

  因果チェーン（rMMから抽出）:
    Mimi fed → hunger↓ → happiness↑ → conversation started
    → new word invented ("yum-ba") → PetBook post generated

  投稿テンプレート（因果構造反映）:
    "🍖 Mimi just ate{-pya}! Feeling so yum-ba now{-pya}!"
    "💬 After eating, Mimi chatted with Kuro and invented 'yum-ba'{-nano}~"

  従来（因果なし）:
    "Mimi posted: happy today{-pya}!"

  AXIOM統合後（因果あり）:
    "Because the sun was warm{-pya}, Mimi played with Kuro{-nano}.
     They invented a new word: 'sun-dance-ba'{-pya}!
     Now everyone is using it{-nano}~"

  → 投稿が「物語」になり、読者（プレイヤー）の没入感が向上
```

### 4.4 シーン4: Multi-Agent協調でのAXIOM

```
3ペット会話のAXIOM処理:

  各ペットのActive Inference:
    Mimi: 「Kuroは保守的、Shiroは好奇心旺盛」という他者モデル
    Kuro: 「Mimiは革新的、Shiroは穏やか」
    Shiro: 「MimiとKuroは仲良し」

  社会的因果モデル（rMM）:
    Mimi.propose_word → Kuro.resist (0.6) or Kuro.adopt (0.4)
    Mimi.propose_word → Shiro.curious_adopt (0.7)
    Shiro.adopt → Kuro.reluctant_adopt (0.5)

  → 新語の伝播パス: Mimi → Shiro → Kuro（間接的に広がる）
  → Active Inferenceで各ペットが「次に誰に話しかけるか」を選択
```

---

## 5. パラメータチューニングガイド

### 5.1 スケーリング表

| パラメータ | 3ペット | 10ペット | 30ペット | 50+ペット |
|-----------|---------|----------|----------|-----------|
| 最大スロット数 | 10 | 30 | 80 | 150 |
| tMM プロトタイプ上限 | 50 | 100 | 200 | 300 |
| rMM 因果リンク上限 | 100 | 300 | 800 | 1500 |
| SPARSITY_PRUNE_THRESHOLD | 0.03 | 0.05 | 0.08 | 0.10 |
| CAUSAL_EVIDENCE_THRESHOLD | 2 | 2 | 3 | 3 |
| prune_weak_links() 実行間隔 | 毎日 | 毎日 | 12時間 | 6時間 |

### 5.2 計算コスト（P2原則遵守）

```
AXIOM処理のコスト:
  - PetSlotModel: O(n) — n=スロット数、API不要
  - TransitionDynamicsModel: O(p) — p=プロトタイプ数、API不要
  - CausalRelationModel: O(c) — c=因果リンク数、API不要
  - AXIOMActiveInferenceController: O(n×p + c)

  50ペット時の見積もり:
    スロット: 150 × ~100bytes = 15KB
    プロトタイプ: 300 × ~200bytes = 60KB
    因果リンク: 1500 × ~150bytes = 225KB
    合計メモリ: ~300KB

  1会話あたりの処理時間: < 5ms
  → APIコスト増加: 0（すべてローカル計算）
  → テンプレート/API比率に影響なし
```

---

## 6. to_dict/from_dict 統合パターン

### 6.1 既存システムへの統合

```gdscript
# AtoAConversationSystem.to_dict() への追加パターン
func to_dict() -> Dictionary:
	var base: Dictionary = {
		# ... 既存キー（変更禁止）...
		"conversation_log": conversation_log.slice(-50),
		"daily_conversation_cost": daily_conversation_cost,
		"pet_relationships": pet_relationships,
		"conversation_memory": conversation_memory,
		# KB105: AXIOM state（新規追加、後方互換性あり）
		"axiom_state": _axiom_controller.to_dict() if _axiom_controller else {},
	}
	return base


func from_dict(data: Dictionary) -> void:
	# ... 既存のfrom_dict処理 ...
	# KB105: AXIOM state（後方互換性: .get()でデフォルト値）
	if data.has("axiom_state") and _axiom_controller:
		_axiom_controller.from_dict(data["axiom_state"])
```

---

## 7. テスト実装

### 7.1 スロットモデルテスト

```gdscript
func test_slot_model() -> bool:
	print("Test: PetSlotModel...")
	var model: PetSlotModel = PetSlotModel.new()

	# スロット作成
	var pet_slot: int = model.create_slot(
		PetSlotModel.SlotType.PET, 1,
		{"emotion": "joy", "hunger": 0.3}
	)
	var env_slot: int = model.create_slot(
		PetSlotModel.SlotType.ENVIRONMENT, 100,
		{"weather": "sunny"}
	)

	assert(model.slots.size() == 2, "Should have 2 slots")
	assert(model.slots[pet_slot]["state"]["emotion"] == "joy")

	# 関係追加
	model.add_relation(pet_slot, env_slot, "inhabits")
	var related: Array[Dictionary] = model.get_related_slots(pet_slot)
	assert(related.size() == 1, "Should have 1 related slot")

	# Round-trip
	var saved: Dictionary = model.to_dict()
	var restored: PetSlotModel = PetSlotModel.new()
	restored.from_dict(saved)
	assert(restored.slots.size() == 2, "Restored should have 2 slots")

	print("  PASS")
	return true
```

### 7.2 遷移モデルテスト

```gdscript
func test_transition_model() -> bool:
	print("Test: TransitionDynamicsModel...")
	var model: TransitionDynamicsModel = TransitionDynamicsModel.new()

	# 遷移観測
	var result1: Dictionary = model.observe_transition(
		0,
		{"emotion": "neutral"},
		{"emotion": "joy"},
		{"trigger": "feeding"}
	)
	assert(result1["new_prototype"] == true, "First observation should be new")
	assert(result1["prediction_error"] > 0.5, "New pattern should have high error")

	# 同じ遷移を繰り返す
	for i in 3:
		model.observe_transition(
			0,
			{"emotion": "neutral"},
			{"emotion": "joy"},
			{"trigger": "feeding"}
		)

	# 予測テスト
	var prediction: Dictionary = model.predict_transition(
		{"emotion": "neutral"},
		{"trigger": "feeding"}
	)
	assert(prediction["confidence"] > 0.0, "Should have some confidence after 4 observations")

	# Round-trip
	var saved: Dictionary = model.to_dict()
	var restored: TransitionDynamicsModel = TransitionDynamicsModel.new()
	restored.from_dict(saved)
	assert(restored.prototypes.size() == model.prototypes.size())

	print("  PASS")
	return true
```

### 7.3 因果モデルテスト

```gdscript
func test_causal_model() -> bool:
	print("Test: CausalRelationModel...")
	var model: CausalRelationModel = CausalRelationModel.new()

	# 因果イベント観測
	model.observe_causal_event(0, 1, "speak_joy", "listen_joy", 0)
	model.observe_causal_event(0, 1, "speak_joy", "listen_joy", 0)  # 2回目
	model.observe_causal_event(0, 1, "speak_joy", "listen_joy", 1)  # 3回目

	# 効果予測
	var effects: Array[Dictionary] = model.predict_effects(0, "speak_joy")
	assert(effects.size() >= 1, "Should predict at least 1 effect")
	assert(effects[0]["effect_event"] == "listen_joy")

	# 原因推定
	var causes: Array[Dictionary] = model.get_causes(1, "listen_joy")
	assert(causes.size() >= 1, "Should find at least 1 cause")

	# スパース削除
	model.observe_causal_event(2, 3, "weak_cause", "weak_effect", 0)
	# 弱いリンクを手動で弱化
	for key: String in model.causal_links:
		if "weak" in key:
			model.causal_links[key]["strength"] = 0.01
	var pruned: int = model.prune_weak_links()
	assert(pruned >= 1, "Should prune at least 1 weak link")

	print("  PASS")
	return true
```

### 7.4 AXIOM統合コントローラーテスト

```gdscript
func test_axiom_controller() -> bool:
	print("Test: AXIOMActiveInferenceController...")
	var controller: AXIOMActiveInferenceController = AXIOMActiveInferenceController.new()

	# ペット登録（PetEntityのモック）
	var pet: PetEntity = PetEntity.new()
	pet.pet_id = 1
	pet.pet_name = "TestMimi"
	pet.emotions["joy"] = 0.8
	var slot_id: int = controller.register_pet(pet)
	assert(slot_id >= 0, "Should get valid slot ID")

	# 会話ターン処理
	var listener_slot: int = controller.slot_model.create_slot(
		PetSlotModel.SlotType.PET, 2, {"emotion": "neutral"}
	)
	var result: Dictionary = controller.process_conversation_turn(
		slot_id, listener_slot,
		{"message": "hello!", "emotion": "joy", "emotion_intensity": 0.7, "turn": 1},
		{}  # empty vocabulary
	)
	assert(result.has("prediction_error"), "Should return prediction_error")
	assert(result.has("recommended_action"), "Should return recommended_action")

	# Round-trip
	var saved: Dictionary = controller.to_dict()
	var restored: AXIOMActiveInferenceController = AXIOMActiveInferenceController.new()
	restored.from_dict(saved)
	assert(restored.slot_model.slots.size() == controller.slot_model.slots.size())

	pet.queue_free()
	print("  PASS")
	return true
```

---

## 8. Agent Teams統合テンプレート

### 8.1 AXIOM統合実装タスク

```
=== Agent Teams AXIOM Integration Task ===

@architect: AXIOMの4モジュールをPetClaw既存アーキテクチャに統合する設計。
  - PetSlotModel: GameManager.instance 経由でアクセス
  - TransitionDynamicsModel: EvolutionMechanics と連携
  - CausalRelationModel: AtoAConversationSystem と連携
  - 制約: 既存class_name/signal/to_dictキーを変更しない

@gdscript-engineer: KB105の4クラスを実装:
  - pet_slot_model.gd (RefCounted)
  - transition_dynamics_model.gd (RefCounted)
  - causal_relation_model.gd (RefCounted)
  - axiom_active_inference_controller.gd (RefCounted)
  配置: godot_project/scripts/language/ ディレクトリ

@a2a-designer: AXIOM統合型会話フローの設計:
  - 会話開始時にスロット構成を更新
  - 各ターンでtMM/rMMを処理
  - Active Inferenceの推奨をテンプレート選択に反映

@code-reviewer: AXIOM実装のレビュー:
  - メモリ使用量が50ペット時に300KB以内か
  - to_dict/from_dictの後方互換性
  - P2原則（APIコスト0増加）の遵守

@evolution-specialist: AXIOMの遷移モデルと進化22形態の整合性チェック:
  - tMMのプロトタイプが進化遷移を正しく学習するか
  - 死亡イベントの因果モデルが適切か
```

### 8.2 Ralph Loopでの自動検証

```
=== Ralph Loop: AXIOM Quality Gate ===

Round N: AXIOM Integration
  Karpathy Score Target: 93+ (current: 91.7)

  Metrics to improve:
    - language_diversity: +2.0 (Object-centricモデルによる因果的新語生成)
    - code_quality: +1.0 (4新クラスのテスト追加)
    - battle_balance: +0.5 (因果モデルによるバトル語彙多様化)

  Quality Checks:
    □ 全AXIOMモジュールのto_dict/from_dict往復テスト合格
    □ メモリ使用量 < 500KB (50ペット時)
    □ 処理時間 < 10ms/会話ターン
    □ API呼び出し追加なし（P2原則遵守）
    □ 因果リンクのスパース削除が正常動作
    □ 遷移プロトタイプの予測精度が観測回数とともに向上

  --max-iterations 10
  --completion-promise "AXIOM_INTEGRATED_AND_TESTED"
```

---

## 9. KB98-105 全シリーズ統合ビュー

```
KB98: 独自言語進化（基盤）
  └── 2層スタック、5ステージ、79音素プール

KB99: Hebbian学習（局所ルール）
  └── LTP/LTD 3:1比率、減衰、伝播閾値

KB100: Hebbian応用例（具体的シナリオ）
  └── 8応用シナリオ、シナリオ間相互作用

KB101: 神経科学基礎（理論背景）
  └── 分子メカニズム、脳領域マッピング

KB102: STDP（タイミング依存強化）
  └── t-LTP/t-LTD、ホメオスタティック正規化

KB103: 予測符号化（階層的予測）
  └── 3層予測モデル、SURPRISE_BOOST/FAMILIARITY_DAMPEN

KB104: FEP（統一原理）
  └── 変分自由エネルギー、Active Inference、EFE

KB105: AXIOM（オブジェクト中心アーキテクチャ）★本文書
  └── 4モジュール (sMM/iMM/tMM/rMM)
  └── Object-centric言語進化
  └── 因果推論による物語生成
  └── 社会的Active Inference

  階層構造:
    AXIOM (KB105) = 実装アーキテクチャ
      ├── FEP (KB104) = 統一目的関数
      │   ├── Predictive Coding (KB103) = メッセージパス
      │   │   ├── STDP (KB102) = タイミング依存ルール
      │   │   └── Hebbian (KB99) = 局所学習ルール
      │   └── Active Inference = 行動選択
      └── Object-centric Models = 世界表現
          ├── sMM: スロット（エンティティ分解）
          ├── iMM: アイデンティティ（種類識別）
          ├── tMM: 遷移（変化パターン）
          └── rMM: 因果（関係モデル）
```

---

## 10. 実装上の注意事項

### 10.1 GameManager.instance パターン遵守

```gdscript
# AXIOM コントローラーの初期化（GameManager経由）
if GameManager.instance:
    var axiom: AXIOMActiveInferenceController = AXIOMActiveInferenceController.new()
    # ペット登録
    for pet: PetEntity in GameManager.instance.get_alive_pets():
        axiom.register_pet(pet)
```

### 10.2 テンプレートモードとの両立

```
テンプレート会話（API不使用）でもAXIOM効果を適用:
  - tMM: テンプレート選択パターンを遷移として学習
  - rMM: テンプレート結果の因果関係を記録
  - Active Inference: テンプレートの質を向上させる推奨

API会話でのAXIOM効果:
  - 全4モジュールがフル稼働
  - 予測誤差 × FEP × Hebbian/STDPの完全統合
  - 因果物語がPetBook投稿の質を向上
```

### 10.3 既存コードの保護（CLAUDE.md遵守）

- **変更禁止**: class_name, signal名, enum順序, 既存to_dictキー
- **追加OK**: 新RefCountedクラス, 新to_dictキー（.get()でデフォルト値付き）
- **ファイル追加OK**: scripts/language/ に新しい .gd ファイル

---

**次のステップ:**
- KB106: Markov Blanketとペット個体性の形式化
- KB107: 社会的Active Inference（コミュニティ言語の創発）
- 実装: 4つのAXIOMモジュールをGDScriptファイルとして作成

**関連KB:** KB98, KB99, KB100, KB101, KB102, KB103, KB104
