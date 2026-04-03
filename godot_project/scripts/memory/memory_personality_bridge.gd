## MemoryPersonalityBridge — 記憶が性格・行動に影響を与えるブリッジシステム
## 悲嘆処理（Kubler-Ross）、ノスタルジア、トラウマ＆成長、夢合成、会話ヒント
class_name MemoryPersonalityBridge
extends Node

signal grief_stage_changed(pet_id: int, stage: String)
signal nostalgia_triggered(pet_id: int, memory_summary: String)
signal trauma_processed(pet_id: int, growth_trait: String)
signal dream_generated(pet_id: int, dream_content: String)

const GRIEF_STAGE_DURATION: float = 120.0
const NOSTALGIA_CHECK_INTERVAL: float = 120.0
const TRAUMA_DECAY_RATE: float = 0.01
const DREAM_MEMORY_REPLAY_COUNT: int = 3

const GRIEF_STAGES: Array[String] = [
	"denial", "anger", "bargaining", "depression", "acceptance"
]
const DREAM_TEMPLATES: Array[String] = [
	"I dreamed of {place}... {partner} was there, and we felt {emotion}.",
	"In my dream, {event} happened again, but this time it ended with {emotion}.",
	"A strange dream: {place} merged with {place2}, and {partner} said something I can't remember.",
	"I kept running through {place} in my dream, chasing a feeling of {emotion}.",
	"Last night I dreamed {partner} and I were {event}... it felt so real.",
	"My dream was full of {emotion}. Fragments of {event} swirled around me in {place}.",
]
const GROWTH_TRAITS: Dictionary = {
	"near_death": "resilience", "loss": "empathy", "neglect": "independence",
	"betrayal": "caution", "isolation": "self_reliance",
}

var grief_states: Dictionary = {}        # pet_id -> {deceased_id, stage_index, stage_timer, ...}
var trauma_markers: Dictionary = {}      # pet_id -> Array[{event_type, intensity, decay_rate, created_at}]
var nostalgia_log: Dictionary = {}       # pet_id -> Array[{memory_summary, timestamp}]
var dream_log: Dictionary = {}           # pet_id -> Array[{content, timestamp}]
var nostalgia_timer: float = 0.0
var personality_modifiers: Dictionary = {} # pet_id -> {trait -> float offset}


func _process(delta: float) -> void:
	_process_grief(delta)
	nostalgia_timer += delta
	if nostalgia_timer >= NOSTALGIA_CHECK_INTERVAL:
		nostalgia_timer = 0.0
		_process_nostalgia()
	_process_trauma_decay(delta)


# === Grief Processing (Kubler-Ross) ===

func start_grief(pet_id: int, deceased_id: int, affinity: float) -> void:
	if affinity < 0.6 or pet_id in grief_states:
		return
	grief_states[pet_id] = {
		"deceased_id": deceased_id, "stage_index": 0, "stage_timer": 0.0,
		"stage_duration": lerpf(180.0, 60.0, clampf(affinity, 0.6, 1.0)),
		"started_at": Time.get_unix_time_from_system(),
	}
	var gm := GameManager.instance
	if gm and gm.biological_memory:
		gm.biological_memory.consolidate_memory(pet_id, {
			"type": "death", "deceased_id": deceased_id,
			"description": "loss_of_companion",
		}, "grief", 0.95, ["loss", "death", "companion"])
	grief_stage_changed.emit(pet_id, GRIEF_STAGES[0])


func _process_grief(delta: float) -> void:
	var completed: Array[int] = []
	for pet_id: int in grief_states:
		var state: Dictionary = grief_states[pet_id]
		state["stage_timer"] += delta
		if state["stage_timer"] >= state["stage_duration"]:
			state["stage_timer"] = 0.0
			state["stage_index"] += 1
			if state["stage_index"] >= GRIEF_STAGES.size():
				completed.append(pet_id)
				_on_grief_completed(pet_id)
			else:
				var stage: String = GRIEF_STAGES[state["stage_index"]]
				grief_stage_changed.emit(pet_id, stage)
				_apply_grief_emotion(pet_id, stage)
	for pet_id: int in completed:
		grief_states.erase(pet_id)


func _apply_grief_emotion(pet_id: int, stage: String) -> void:
	var gm := GameManager.instance
	if not gm or not gm.emotion_system or not gm.emotion_system.has_method("apply_emotion_boost"):
		return
	match stage:
		"anger": gm.emotion_system.apply_emotion_boost(pet_id, "anger", 0.3)
		"depression": gm.emotion_system.apply_emotion_boost(pet_id, "sadness", 0.4)
		"bargaining": gm.emotion_system.apply_emotion_boost(pet_id, "anxiety", 0.2)


func _on_grief_completed(pet_id: int) -> void:
	_add_personality_modifier(pet_id, "bravery", 0.1)
	grief_stage_changed.emit(pet_id, "acceptance")
	_add_trauma_marker(pet_id, "loss", 0.6, TRAUMA_DECAY_RATE * 0.5)
	trauma_processed.emit(pet_id, "resilience")


func get_grief_stage(pet_id: int) -> String:
	if pet_id not in grief_states:
		return ""
	var idx: int = grief_states[pet_id]["stage_index"]
	if idx < 0 or idx >= GRIEF_STAGES.size():
		return ""
	return GRIEF_STAGES[idx]


# === Nostalgia System ===

func _process_nostalgia() -> void:
	var gm := GameManager.instance
	if not gm or not gm.biological_memory:
		return
	for pet_id: int in gm.biological_memory.pet_memories:
		var cortex: Array = gm.biological_memory.pet_memories[pet_id].get("cortex", [])
		if cortex.is_empty():
			continue
		if randf() > clampf(cortex.size() * 0.02, 0.05, 0.4):
			continue
		var chosen: Dictionary = _pick_nostalgia_memory(cortex)
		if chosen.is_empty():
			continue
		var summary: String = _summarize_memory(chosen)
		_log_nostalgia(pet_id, summary)
		if gm.emotion_system and gm.emotion_system.has_method("apply_emotion_boost"):
			gm.emotion_system.apply_emotion_boost(pet_id, chosen.get("emotion_tag", "joy"), 0.15)
		if gm.pet_book and gm.pet_book.has_method("publish_conversation_post"):
			gm.pet_book.publish_conversation_post({
				"author_id": pet_id, "author_name": _get_pet_name(pet_id),
				"content": "Remembering... " + summary, "post_type": "nostalgia",
				"emotion": chosen.get("emotion_tag", "joy"),
				"partner_id": chosen.get("content", {}).get("with", -1),
				"timestamp": Time.get_unix_time_from_system(),
			})
		nostalgia_triggered.emit(pet_id, summary)


func _pick_nostalgia_memory(cortex: Array) -> Dictionary:
	if cortex.is_empty():
		return {}
	var weights: Array[float] = []
	var total: float = 0.0
	for mem: Dictionary in cortex:
		var w: float = 0.3 + mem.get("importance", 0.5) * 0.4
		var age_days: float = (Time.get_unix_time_from_system() - mem.get("timestamp", 0.0)) / 86400.0
		if age_days > 3.0:
			w += clampf(age_days * 0.01, 0.0, 0.3)
		weights.append(w)
		total += w
	if total <= 0.0:
		return cortex[randi() % cortex.size()]
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for i: int in range(weights.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return cortex[i]
	return cortex[cortex.size() - 1]


func _summarize_memory(mem: Dictionary) -> String:
	var partner_id: int = mem.get("content", {}).get("with", -1)
	var partner_str: String = (" with " + _get_pet_name(partner_id)) if partner_id >= 0 else ""
	return "%s%s, feeling %s" % [mem.get("event_type", "something"), partner_str, mem.get("emotion_tag", "a feeling")]


func check_nostalgia_trigger(pet_id: int, partner_id: int) -> void:
	## R121: 会話後にパートナー関連の記憶でノスタルジアをトリガー
	var gm := GameManager.instance
	if not gm or not gm.biological_memory:
		return
	var memories: Dictionary = gm.biological_memory.pet_memories.get(pet_id, {})
	var cortex: Array = memories.get("cortex", [])
	if cortex.is_empty():
		return
	# パートナーとの過去の記憶を探す
	for mem: Dictionary in cortex:
		var content: Dictionary = mem.get("content", {})
		if content.get("with", -1) == partner_id and randf() < 0.25:
			var summary: String = _summarize_memory(mem)
			_log_nostalgia(pet_id, summary)
			nostalgia_triggered.emit(pet_id, summary)
			# 記憶の重要度を少しブースト（想起効果）
			mem["importance"] = minf(mem.get("importance", 0.5) + 0.05, 1.0)
			return


func _log_nostalgia(pet_id: int, summary: String) -> void:
	if pet_id not in nostalgia_log:
		nostalgia_log[pet_id] = [] as Array[Dictionary]
	nostalgia_log[pet_id].append({"memory_summary": summary, "timestamp": Time.get_unix_time_from_system()})
	if nostalgia_log[pet_id].size() > 20:
		nostalgia_log[pet_id].pop_front()


# === Trauma & Growth ===

func add_trauma(pet_id: int, event_type: String, intensity: float) -> void:
	_add_trauma_marker(pet_id, event_type, clampf(intensity, 0.0, 1.0), TRAUMA_DECAY_RATE)


func _add_trauma_marker(pet_id: int, event_type: String, intensity: float, decay_rate: float) -> void:
	if pet_id not in trauma_markers:
		trauma_markers[pet_id] = [] as Array[Dictionary]
	trauma_markers[pet_id].append({
		"event_type": event_type, "intensity": intensity,
		"decay_rate": decay_rate, "created_at": Time.get_unix_time_from_system(),
	})
	if intensity > 0.8:
		_add_personality_modifier(pet_id, GROWTH_TRAITS.get(event_type, "resilience"), 0.05)


func _process_trauma_decay(delta: float) -> void:
	var decay_amount: float = TRAUMA_DECAY_RATE * delta
	for pet_id: int in trauma_markers:
		var markers: Array = trauma_markers[pet_id]
		var to_process: Array[int] = []
		for i: int in range(markers.size()):
			var marker: Dictionary = markers[i]
			if marker["intensity"] > 0.8:
				marker["intensity"] -= decay_amount * 0.1
			else:
				marker["intensity"] -= decay_amount * marker["decay_rate"] / TRAUMA_DECAY_RATE
			marker["intensity"] = maxf(marker["intensity"], 0.0)
			if marker["intensity"] <= 0.05 and marker["intensity"] > 0.0:
				to_process.append(i)
		for i: int in range(to_process.size() - 1, -1, -1):
			var idx: int = to_process[i]
			var growth_trait: String = GROWTH_TRAITS.get(markers[idx]["event_type"], "resilience")
			_add_personality_modifier(pet_id, growth_trait, 0.05)
			trauma_processed.emit(pet_id, growth_trait)
			markers[idx]["intensity"] = 0.0


func get_trauma_markers(pet_id: int) -> Array[Dictionary]:
	if pet_id not in trauma_markers:
		return []
	var active: Array[Dictionary] = []
	for marker: Dictionary in trauma_markers[pet_id]:
		if marker["intensity"] > 0.0:
			active.append(marker)
	return active


# === Dream Synthesis (Sleep Consolidation) ===

func process_dreams(pet_id: int) -> String:
	var gm := GameManager.instance
	if not gm or not gm.biological_memory:
		return ""
	if pet_id not in gm.biological_memory.pet_memories:
		return ""
	var hippocampus: Array = gm.biological_memory.pet_memories[pet_id].get("hippocampus", [])
	var cortex: Array = gm.biological_memory.pet_memories[pet_id].get("cortex", [])
	# Replay recent hippocampus memories -> boost Hebbian links
	var replay_count: int = mini(DREAM_MEMORY_REPLAY_COUNT, hippocampus.size())
	var replayed: Array[Dictionary] = []
	for i: int in range(replay_count):
		var idx: int = hippocampus.size() - 1 - i
		if idx >= 0:
			gm.biological_memory.strengthen_related_memories(pet_id, hippocampus[idx])
			replayed.append(hippocampus[idx])
	if not cortex.is_empty():
		replayed.append(cortex[randi() % cortex.size()])
	if replayed.is_empty():
		return ""
	var dream_text: String = _compose_dream(replayed)
	# Log dream
	if pet_id not in dream_log:
		dream_log[pet_id] = [] as Array[Dictionary]
	dream_log[pet_id].append({"content": dream_text, "timestamp": Time.get_unix_time_from_system()})
	if dream_log[pet_id].size() > 10:
		dream_log[pet_id].pop_front()
	# Post to PetBook
	if gm.pet_book and gm.pet_book.has_method("publish_conversation_post"):
		gm.pet_book.publish_conversation_post({
			"author_id": pet_id, "author_name": _get_pet_name(pet_id),
			"content": dream_text, "post_type": "dream_diary",
			"emotion": replayed[0].get("emotion_tag", "wonder"),
			"partner_id": -1, "timestamp": Time.get_unix_time_from_system(),
		})
	dream_generated.emit(pet_id, dream_text)
	return dream_text


func _compose_dream(fragments: Array[Dictionary]) -> String:
	var template: String = DREAM_TEMPLATES[randi() % DREAM_TEMPLATES.size()]
	var places: Array[String] = []
	var partners: Array[String] = []
	var emotions: Array[String] = []
	var events: Array[String] = []
	for frag: Dictionary in fragments:
		for tag: Variant in frag.get("context_tags", []):
			if tag is String:
				places.append(tag)
		var pid: int = frag.get("content", {}).get("with", -1)
		if pid >= 0:
			partners.append(_get_pet_name(pid))
		emotions.append(frag.get("emotion_tag", "wonder"))
		events.append(frag.get("event_type", "something mysterious"))
	template = template.replace("{place}", places[randi() % places.size()] if not places.is_empty() else "a faraway place")
	template = template.replace("{place2}", places[randi() % places.size()] if places.size() > 1 else "somewhere unknown")
	template = template.replace("{partner}", partners[randi() % partners.size()] if not partners.is_empty() else "a shadowy figure")
	template = template.replace("{emotion}", emotions[randi() % emotions.size()] if not emotions.is_empty() else "wonder")
	template = template.replace("{event}", events[randi() % events.size()] if not events.is_empty() else "something strange")
	return template


# === Memory-Driven Dialogue Hints ===

func get_conversation_hints(pet_id: int) -> Array[String]:
	var hints: Array[String] = []
	# Unresolved grief
	if pet_id in grief_states:
		var stage: String = get_grief_stage(pet_id)
		if not stage.is_empty():
			hints.append("Currently in %s stage of grief" % stage)
	# Recent nostalgia
	if pet_id in nostalgia_log and not nostalgia_log[pet_id].is_empty():
		var recent: Dictionary = nostalgia_log[pet_id][nostalgia_log[pet_id].size() - 1]
		if Time.get_unix_time_from_system() - recent.get("timestamp", 0.0) < 300.0:
			hints.append("Recently remembered: %s" % recent.get("memory_summary", "old times"))
	# Dream echoes
	if pet_id in dream_log and not dream_log[pet_id].is_empty():
		var rd: Dictionary = dream_log[pet_id][dream_log[pet_id].size() - 1]
		if Time.get_unix_time_from_system() - rd.get("timestamp", 0.0) < 600.0:
			hints.append("Had a dream: %s" % rd.get("content", "something strange"))
	# Active trauma
	var active_trauma: Array[Dictionary] = get_trauma_markers(pet_id)
	if not active_trauma.is_empty():
		var strongest: Dictionary = active_trauma[0]
		for t: Dictionary in active_trauma:
			if t["intensity"] > strongest["intensity"]:
				strongest = t
		if strongest["intensity"] > 0.3:
			hints.append("Processing trauma from %s (intensity: %.1f)" % [strongest["event_type"], strongest["intensity"]])
	if hints.size() > 3:
		hints.resize(3)
	return hints


# === Personality Modifiers ===

func _add_personality_modifier(pet_id: int, trait_name: String, value: float) -> void:
	if pet_id not in personality_modifiers:
		personality_modifiers[pet_id] = {}
	var current: float = personality_modifiers[pet_id].get(trait_name, 0.0)
	personality_modifiers[pet_id][trait_name] = clampf(current + value, -0.5, 0.5)


func get_personality_modifiers(pet_id: int) -> Dictionary:
	return personality_modifiers.get(pet_id, {})


func _get_pet_name(pet_id: int) -> String:
	var gm := GameManager.instance
	if gm and gm.pets.has(pet_id):
		return gm.pets[pet_id].pet_name
	return "Pet#%d" % pet_id


# === Serialization ===

func to_dict() -> Dictionary:
	return {
		"grief_states": grief_states.duplicate(true),
		"trauma_markers": trauma_markers.duplicate(true),
		"nostalgia_log": nostalgia_log.duplicate(true),
		"dream_log": dream_log.duplicate(true),
		"personality_modifiers": personality_modifiers.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	grief_states = data.get("grief_states", {}).duplicate(true)
	trauma_markers = data.get("trauma_markers", {}).duplicate(true)
	nostalgia_log = data.get("nostalgia_log", {}).duplicate(true)
	dream_log = data.get("dream_log", {}).duplicate(true)
	personality_modifiers = data.get("personality_modifiers", {}).duplicate(true)
