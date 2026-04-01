## BiologicalMemorySystem — 神経科学模倣の記憶管理システム
## 海馬（短期）→ 大脳皮質（長期）の階層化、Ebbinghaus忘却曲線、
## Hebbian Learning（関連記憶強化）、アミグダラ効果（感情定着）を統合
class_name BiologicalMemorySystem
extends Node

signal memory_consolidated(pet_id: int, memory_id: int, location: String)  # hippocampus or cortex
signal memory_forgotten(pet_id: int, memory_id: int)
signal memory_promoted(pet_id: int, memory_id: int)  # 海馬 → 皮質昇格
signal hebbian_link_formed(pet_id: int, mem_a_id: int, mem_b_id: int, strength: float)
signal flashbulb_memory_created(pet_id: int, memory_id: int, emotion: String)

# === パラメータ ===
const HIPPOCAMPUS_CAPACITY: int = 30       # 短期記憶の上限
const CORTEX_CAPACITY: int = 100           # 長期記憶の上限
const DECAY_INTERVAL: float = 60.0         # 減衰処理の間隔（秒）
const PROMOTION_THRESHOLD: float = 0.75    # 皮質昇格の重要度閾値
const RECALL_PROMOTION_COUNT: int = 3      # 想起回数による昇格閾値
const FORGET_THRESHOLD: float = 0.05       # 忘却閾値
const FLASHBULB_EMOTION_THRESHOLD: float = 0.8  # フラッシュバルブ記憶の感情閾値
const HEBBIAN_DELTA: float = 0.1           # Hebbian強化のベース値
const RECALL_STRENGTH_BOOST: float = 0.08  # 想起による重要度回復
const RECALL_EMOTION_FACTOR: float = 0.3   # 想起時の感情再活性化係数
const RECALL_JITTER: float = 0.02          # 記憶の動的再構築（微変動）
const LINK_DECAY_RATE: float = 0.005       # リンク減衰率（/日）
const OFFLINE_HEBBIAN_BOOST: float = 0.05  # 睡眠時Hebbian強化

# === 半減期（秒） ===
const HALF_LIFE_SHORT: float = 1800.0      # 短期: 30分
const HALF_LIFE_MEDIUM: float = 86400.0    # 中期: 1日
const HALF_LIFE_LONG: float = 604800.0     # 長期: 7日

# === State ===
var pet_memories: Dictionary = {}  # pet_id → { "hippocampus": Array, "cortex": Array }
var next_memory_id: int = 1
var decay_timer: float = 0.0
var last_process_time: float = 0.0  # オフライン計算用


func _ready() -> void:
	last_process_time = Time.get_unix_time_from_system()


func _process(delta: float) -> void:
	decay_timer += delta
	if decay_timer >= DECAY_INTERVAL:
		decay_timer = 0.0
		_process_all_decay()


# === ペット登録 ===
func register_pet(pet_id: int) -> void:
	if pet_id not in pet_memories:
		pet_memories[pet_id] = {
			"hippocampus": [] as Array[Dictionary],
			"cortex": [] as Array[Dictionary],
		}


func unregister_pet(pet_id: int) -> void:
	pet_memories.erase(pet_id)


# ========================================================
# 記憶形成（アミグダラ効果付き）
# ========================================================

func consolidate_memory(pet_id: int, event: Dictionary, emotion_tag: String,
		emotion_intensity: float, context_tags: Array = []) -> Dictionary:
	## 新しい記憶を海馬に格納する（アミグダラ効果で感情が定着率に影響）
	register_pet(pet_id)

	var mem_id := _generate_memory_id()

	# アミグダラ効果: 感情強度が高いほど重要度が上がる
	var base_importance := _calculate_base_importance(event)
	var amygdala_boost := emotion_intensity * 0.7
	var initial_importance := clampf(base_importance + amygdala_boost, 0.0, 1.0)

	var memory_item: Dictionary = {
		"id": mem_id,
		"event_type": event.get("type", "unknown"),
		"content": event,
		"importance": initial_importance,
		"emotion_tag": emotion_tag,
		"emotion_intensity": emotion_intensity,
		"timestamp": Time.get_unix_time_from_system(),
		"last_recalled": Time.get_unix_time_from_system(),
		"recall_count": 0,
		"linked_memories": [] as Array[int],
		"context_tags": context_tags.duplicate(),
	}

	# フラッシュバルブ記憶: 極めて強い感情体験は即座に皮質へ
	if emotion_intensity >= FLASHBULB_EMOTION_THRESHOLD:
		pet_memories[pet_id]["cortex"].append(memory_item)
		_enforce_capacity(pet_id, "cortex")
		memory_consolidated.emit(pet_id, mem_id, "cortex")
		flashbulb_memory_created.emit(pet_id, mem_id, emotion_tag)
	else:
		pet_memories[pet_id]["hippocampus"].append(memory_item)
		_enforce_capacity(pet_id, "hippocampus")
		memory_consolidated.emit(pet_id, mem_id, "hippocampus")

	# 関連記憶とHebbian強化
	_auto_hebbian_link(pet_id, memory_item)

	return memory_item


# ========================================================
# 記憶想起（前頭前野フィルタ付き）
# ========================================================

func retrieve_memories(pet_id: int, query: Dictionary, personality: Dictionary,
		max_results: int = 3) -> Array[Dictionary]:
	## クエリに基づいて関連記憶を検索（性格バイアス付き）
	if pet_id not in pet_memories:
		return []

	var all_memories: Array[Dictionary] = []
	all_memories.append_array(pet_memories[pet_id]["hippocampus"])
	all_memories.append_array(pet_memories[pet_id]["cortex"])

	if all_memories.is_empty():
		return []

	# スコア計算（関連性 × 重要度 × 性格バイアス）
	var scored: Array[Dictionary] = []
	for mem in all_memories:
		var relevance := _calculate_relevance(mem, query)
		var personality_bias := _calculate_personality_bias(mem, personality)
		var score := relevance * mem["importance"] * personality_bias
		scored.append({"memory": mem, "score": score})

	# スコア降順ソート
	scored.sort_custom(func(a, b): return a["score"] > b["score"])

	# 上位N件を返す + 想起処理
	var results: Array[Dictionary] = []
	var count := mini(max_results, scored.size())
	for i in range(count):
		if scored[i]["score"] > 0.1:  # 最低スコア閾値
			var mem: Dictionary = scored[i]["memory"]
			_on_memory_recalled(pet_id, mem)
			results.append(mem)

	return results


func retrieve_shared_memories(pet_id_1: int, pet_id_2: int, max_results: int = 3) -> Array[Dictionary]:
	## 2体のペット間の共有記憶を検索
	if pet_id_1 not in pet_memories or pet_id_2 not in pet_memories:
		return []

	var shared: Array[Dictionary] = []
	var all_1 := pet_memories[pet_id_1]["hippocampus"] + pet_memories[pet_id_1]["cortex"]

	for mem in all_1:
		if mem["content"].get("with", -1) == pet_id_2:
			shared.append(mem)

	shared.sort_custom(func(a, b): return a["importance"] > b["importance"])
	return shared.slice(0, max_results)


# ========================================================
# 想起時の処理
# ========================================================

func _on_memory_recalled(pet_id: int, memory: Dictionary) -> void:
	## 想起するたびに: recall_count++, importance微回復, 動的再構築
	memory["recall_count"] += 1
	memory["last_recalled"] = Time.get_unix_time_from_system()

	# 想起による重要度回復（反復は記憶を強化する）
	memory["importance"] = clampf(
		memory["importance"] + RECALL_STRENGTH_BOOST, 0.0, 1.0
	)

	# 記憶の動的再構築（微妙な揺らぎ）
	memory["importance"] += randf_range(-RECALL_JITTER, RECALL_JITTER)
	memory["importance"] = clampf(memory["importance"], 0.0, 1.0)

	# 想起が昇格条件を満たすかチェック
	_check_promotion(pet_id, memory)


# ========================================================
# Ebbinghaus忘却曲線
# ========================================================

func _process_all_decay() -> void:
	var current_time := Time.get_unix_time_from_system()

	for pet_id in pet_memories:
		_decay_memory_pool(pet_id, "hippocampus", current_time)
		_decay_memory_pool(pet_id, "cortex", current_time)


func _decay_memory_pool(pet_id: int, pool_name: String, current_time: float) -> void:
	var pool: Array = pet_memories[pet_id][pool_name]
	var to_remove: Array[int] = []

	for i in range(pool.size()):
		var mem: Dictionary = pool[i]
		var time_passed: float = current_time - mem["timestamp"]

		# 強度に応じた半減期を計算
		var strength_multiplier := 1.0 + mem["emotion_intensity"] * 0.7 + mem["recall_count"] * 0.2
		var base_half_life: float = HALF_LIFE_SHORT if pool_name == "hippocampus" else HALF_LIFE_LONG

		# Ebbinghaus式: R(t) = e^(-t / (S × multiplier))
		var decay_factor: float = exp(-time_passed / (base_half_life * strength_multiplier))
		var initial_importance: float = _get_initial_importance(mem)
		mem["importance"] = clampf(initial_importance * decay_factor, 0.0, 1.0)

		# 忘却判定
		if mem["importance"] < FORGET_THRESHOLD:
			to_remove.append(i)

	# 後ろから削除（インデックスずれ防止）
	for i in range(to_remove.size() - 1, -1, -1):
		var mem: Dictionary = pool[to_remove[i]]
		memory_forgotten.emit(pet_id, mem["id"])
		pool.remove_at(to_remove[i])


func _get_initial_importance(mem: Dictionary) -> float:
	## 記憶の「元の重要度」を推定（recall_count + emotion考慮）
	var base := 0.3 + mem["emotion_intensity"] * 0.7
	var recall_bonus := mem["recall_count"] * 0.1
	return clampf(base + recall_bonus, 0.0, 1.0)


# ========================================================
# Hebbian Learning（関連記憶の相互強化）
# ========================================================

func _auto_hebbian_link(pet_id: int, new_memory: Dictionary) -> void:
	## 新規記憶と既存記憶の関連性をチェックし、強いものをリンク
	var all_memories: Array = pet_memories[pet_id]["hippocampus"] + pet_memories[pet_id]["cortex"]

	for existing in all_memories:
		if existing["id"] == new_memory["id"]:
			continue

		var similarity := _calculate_similarity(new_memory, existing)
		if similarity > 0.4:
			# 双方向リンク
			if existing["id"] not in new_memory["linked_memories"]:
				new_memory["linked_memories"].append(existing["id"])
			if new_memory["id"] not in existing["linked_memories"]:
				existing["linked_memories"].append(new_memory["id"])

			# Hebbian強化
			var delta: float = HEBBIAN_DELTA * similarity
			existing["importance"] = clampf(existing["importance"] + delta, 0.0, 1.0)

			hebbian_link_formed.emit(pet_id, new_memory["id"], existing["id"], similarity)


func strengthen_related_memories(pet_id: int, trigger_memory: Dictionary) -> void:
	## 特定の記憶に関連する記憶群を一括強化
	if pet_id not in pet_memories:
		return

	var all_memories: Array = pet_memories[pet_id]["hippocampus"] + pet_memories[pet_id]["cortex"]

	for mem in all_memories:
		if mem["id"] == trigger_memory["id"]:
			continue
		if mem["id"] in trigger_memory.get("linked_memories", []):
			var similarity := _calculate_similarity(trigger_memory, mem)
			var delta: float = HEBBIAN_DELTA * similarity
			mem["importance"] = clampf(mem["importance"] + delta, 0.0, 1.0)


# ========================================================
# 海馬→皮質 昇格
# ========================================================

func _check_promotion(pet_id: int, memory: Dictionary) -> void:
	## 昇格条件チェック: 重要度 or 想起回数
	if memory not in pet_memories[pet_id]["hippocampus"]:
		return  # すでに皮質にいる

	var should_promote := false
	if memory["importance"] >= PROMOTION_THRESHOLD:
		should_promote = true
	elif memory["recall_count"] >= RECALL_PROMOTION_COUNT:
		should_promote = true

	if should_promote:
		pet_memories[pet_id]["hippocampus"].erase(memory)
		pet_memories[pet_id]["cortex"].append(memory)
		_enforce_capacity(pet_id, "cortex")
		memory_promoted.emit(pet_id, memory["id"])


# ========================================================
# オフライン記憶整理（睡眠模倣）
# ========================================================

func process_offline_consolidation(offline_duration: float) -> void:
	## アプリ非アクティブ期間の記憶整理
	## offline_duration: オフラインだった秒数
	if offline_duration < 3600.0:
		return  # 1時間未満は処理不要

	for pet_id in pet_memories:
		# 1) Ebbinghaus減衰を一括適用
		var current_time := Time.get_unix_time_from_system()
		_decay_memory_pool(pet_id, "hippocampus", current_time)
		_decay_memory_pool(pet_id, "cortex", current_time)

		# 2) 海馬の高重要度記憶を皮質に昇格
		var to_promote: Array[Dictionary] = []
		for mem in pet_memories[pet_id]["hippocampus"]:
			if mem["importance"] > 0.6 and mem["recall_count"] >= 2:
				to_promote.append(mem)

		for mem in to_promote:
			pet_memories[pet_id]["hippocampus"].erase(mem)
			pet_memories[pet_id]["cortex"].append(mem)
			memory_promoted.emit(pet_id, mem["id"])

		_enforce_capacity(pet_id, "cortex")

		# 3) 皮質内のHebbian強化（睡眠中の記憶再活性化）
		var cortex: Array = pet_memories[pet_id]["cortex"]
		for i in range(cortex.size()):
			for j in range(i + 1, cortex.size()):
				var similarity := _calculate_similarity(cortex[i], cortex[j])
				if similarity > 0.5:
					cortex[i]["importance"] = clampf(
						cortex[i]["importance"] + OFFLINE_HEBBIAN_BOOST, 0.0, 1.0
					)
					cortex[j]["importance"] = clampf(
						cortex[j]["importance"] + OFFLINE_HEBBIAN_BOOST, 0.0, 1.0
					)


# ========================================================
# 類似度計算
# ========================================================

func _calculate_similarity(mem_a: Dictionary, mem_b: Dictionary) -> float:
	var score := 0.0

	# 同じイベントタイプ
	if mem_a["event_type"] == mem_b["event_type"]:
		score += 0.2

	# 同じ感情タグ
	if mem_a["emotion_tag"] == mem_b["emotion_tag"]:
		score += 0.3

	# 共通コンテキストタグ
	var tags_a: Array = mem_a.get("context_tags", [])
	var tags_b: Array = mem_b.get("context_tags", [])
	var shared_count := 0
	for tag in tags_a:
		if tag in tags_b:
			shared_count += 1
	score += shared_count * 0.15

	# 時間的近接（1時間以内）
	var time_diff: float = absf(mem_a["timestamp"] - mem_b["timestamp"])
	if time_diff < 3600.0:
		score += 0.2 * (1.0 - time_diff / 3600.0)

	return clampf(score, 0.0, 1.0)


func _calculate_relevance(memory: Dictionary, query: Dictionary) -> float:
	## クエリとの関連性スコア
	var score := 0.0

	# イベントタイプ一致
	if memory["event_type"] == query.get("event_type", ""):
		score += 0.3

	# 感情タグ一致
	if memory["emotion_tag"] == query.get("emotion_tag", ""):
		score += 0.25

	# コンテキストタグ共通
	var query_tags: Array = query.get("context_tags", [])
	var mem_tags: Array = memory.get("context_tags", [])
	for tag in query_tags:
		if tag in mem_tags:
			score += 0.15

	# 特定ペットとの共有記憶
	if query.has("with_pet_id"):
		if memory["content"].get("with", -1) == query["with_pet_id"]:
			score += 0.3

	# 新しい記憶ほど少しだけ優遇
	var age_hours: float = (Time.get_unix_time_from_system() - memory["timestamp"]) / 3600.0
	if age_hours < 24.0:
		score += 0.1 * (1.0 - age_hours / 24.0)

	return clampf(score, 0.0, 1.0)


func _calculate_personality_bias(memory: Dictionary, personality: Dictionary) -> float:
	## 前頭前野模倣: 性格に基づく記憶検索バイアス
	var bias := 1.0
	var event_type: String = memory["event_type"]

	match event_type:
		"battle", "train":
			bias += (personality.get("brave", 0.5) - 0.5) * 0.4
		"exploration", "environment":
			bias += (personality.get("curious", 0.5) - 0.5) * 0.4
		"care", "rest":
			bias += (personality.get("calm", 0.5) - 0.5) * 0.3
		"conversation", "social":
			bias += (personality.get("affectionate", 0.5) - 0.5) * 0.4
		"play", "fun":
			bias += (personality.get("playful", 0.5) - 0.5) * 0.4

	return maxf(0.1, bias)


func _calculate_base_importance(event: Dictionary) -> float:
	## イベントタイプ別の基本重要度
	match event.get("type", "unknown"):
		"evolution": return 0.8
		"death", "revival": return 0.9
		"breeding": return 0.85
		"battle": return 0.6
		"conversation": return 0.35
		"care": return 0.25
		"emotion_event": return 0.4
		"environment_change": return 0.3
		"language_milestone": return 0.7
		_: return 0.3


# ========================================================
# ユーティリティ
# ========================================================

func _generate_memory_id() -> int:
	var id := next_memory_id
	next_memory_id += 1
	return id


func _enforce_capacity(pet_id: int, pool_name: String) -> void:
	var pool: Array = pet_memories[pet_id][pool_name]
	var capacity: int = HIPPOCAMPUS_CAPACITY if pool_name == "hippocampus" else CORTEX_CAPACITY

	while pool.size() > capacity:
		# 最も重要度の低い記憶を削除
		var min_idx := 0
		var min_importance := 999.0
		for i in range(pool.size()):
			if pool[i]["importance"] < min_importance:
				min_importance = pool[i]["importance"]
				min_idx = i
		var removed: Dictionary = pool[min_idx]
		memory_forgotten.emit(pet_id, removed["id"])
		pool.remove_at(min_idx)


func get_memory_count(pet_id: int) -> Dictionary:
	## デバッグ用: ペットの記憶数を返す
	if pet_id not in pet_memories:
		return {"hippocampus": 0, "cortex": 0, "total": 0}
	var h: int = pet_memories[pet_id]["hippocampus"].size()
	var c: int = pet_memories[pet_id]["cortex"].size()
	return {"hippocampus": h, "cortex": c, "total": h + c}


func get_strongest_memory(pet_id: int) -> Dictionary:
	## 最も重要な記憶を返す
	if pet_id not in pet_memories:
		return {}
	var best: Dictionary = {}
	var best_score := 0.0
	for pool_name in ["hippocampus", "cortex"]:
		for mem in pet_memories[pet_id][pool_name]:
			if mem["importance"] > best_score:
				best_score = mem["importance"]
				best = mem
	return best


# ========================================================
# シリアライズ
# ========================================================

func to_dict() -> Dictionary:
	var data: Dictionary = {
		"next_memory_id": next_memory_id,
		"last_process_time": Time.get_unix_time_from_system(),
		"pets": {},
	}
	for pet_id in pet_memories:
		data["pets"][pet_id] = {
			"hippocampus": pet_memories[pet_id]["hippocampus"].duplicate(true),
			"cortex": pet_memories[pet_id]["cortex"].duplicate(true),
		}
	return data


func from_dict(data: Dictionary) -> void:
	next_memory_id = data.get("next_memory_id", 1)
	last_process_time = data.get("last_process_time", Time.get_unix_time_from_system())

	pet_memories = {}
	var pets_data: Dictionary = data.get("pets", {})
	for pet_id_key in pets_data:
		var pet_id: int = int(pet_id_key) if pet_id_key is String else pet_id_key
		pet_memories[pet_id] = {
			"hippocampus": pets_data[pet_id_key].get("hippocampus", []),
			"cortex": pets_data[pet_id_key].get("cortex", []),
		}

	# オフライン期間の記憶整理
	var offline_duration: float = Time.get_unix_time_from_system() - last_process_time
	if offline_duration > 0.0:
		process_offline_consolidation(offline_duration)
