## PersistentField — avatar-ui風 持続的共有記憶フィールド
## セッションを跨いだ記憶継続、atomic write + backup、
## オフライン自律行動（冒険→帰還報告）、全ペット共有の「場」
class_name PersistentField
extends Node

signal field_state_changed(change_type: String, data: Dictionary)
signal offline_adventure_completed(pet_id: int, adventure: Dictionary)
signal relationship_updated(pet1_id: int, pet2_id: int, new_score: float)
signal community_mood_shifted(old_mood: String, new_mood: String)

# === パス ===
const FIELD_STATE_PATH: String = "user://petclaw_field_state.json"
const FIELD_BACKUP_PATH: String = "user://petclaw_field_state.json.bak"
const FIELD_TEMP_PATH: String = "user://petclaw_field_state.json.tmp"

# === パラメータ ===
const AUTO_SAVE_INTERVAL: float = 120.0        # 自動保存間隔（秒）
const MAX_SHARED_EVENTS: int = 200             # 共有イベント上限
const MAX_OFFLINE_ADVENTURES: int = 20         # オフライン冒険ログ上限
const RELATIONSHIP_DECAY_RATE: float = 0.001   # 関係性の自然減衰（/日）
const ADVENTURE_MIN_OFFLINE: float = 1800.0    # 冒険に必要な最低オフライン秒数（30分）
const ADVENTURE_MAX_PER_SESSION: int = 3       # 1回のオフライン復帰で最大3件

# === State ===
var field_state: Dictionary = {}
var save_timer: float = 0.0
var is_initialized: bool = false


func _ready() -> void:
	_initialize_field()


func _process(delta: float) -> void:
	save_timer += delta
	if save_timer >= AUTO_SAVE_INTERVAL:
		save_timer = 0.0
		save_field()


# ========================================================
# 初期化
# ========================================================

func _initialize_field() -> void:
	if not _load_field():
		_create_default_field()
	is_initialized = true


func _create_default_field() -> void:
	field_state = {
		"shared_events": [],
		"community_topics": ["greeting", "weather", "play"],
		"relationship_graph": {},
		"offline_adventures": [],
		"cultural_artifacts": [],
		"field_mood": {
			"dominant": "peaceful",
			"intensity": 0.5,
			"contributing_emotions": {},
		},
		"last_save_time": Time.get_unix_time_from_system(),
		"session_count": 1,
		"total_play_time": 0.0,
		"first_created": Time.get_unix_time_from_system(),
	}


# ========================================================
# 共有イベントの記録
# ========================================================

func record_shared_event(event: Dictionary) -> void:
	## 全ペットが認識できる「場」のイベントを記録
	event["timestamp"] = Time.get_unix_time_from_system()
	event["session"] = field_state.get("session_count", 0)

	field_state["shared_events"].append(event)

	# 容量制限（古いイベントから削除）
	while field_state["shared_events"].size() > MAX_SHARED_EVENTS:
		field_state["shared_events"].pop_front()

	field_state_changed.emit("shared_event", event)


func get_recent_shared_events(count: int = 10) -> Array:
	var events: Array = field_state.get("shared_events", [])
	return events.slice(-count)


func get_shared_events_by_type(event_type: String, count: int = 5) -> Array:
	var result: Array = []
	var events: Array = field_state.get("shared_events", [])
	for i in range(events.size() - 1, -1, -1):
		if events[i].get("type", "") == event_type:
			result.append(events[i])
			if result.size() >= count:
				break
	return result


# ========================================================
# 関係性グラフ
# ========================================================

func update_relationship(pet1_id: int, pet2_id: int, delta: float, reason: String = "") -> void:
	## ペット間の関係性スコアを更新
	var key := _relationship_key(pet1_id, pet2_id)
	var graph: Dictionary = field_state.get("relationship_graph", {})

	if key not in graph:
		graph[key] = {
			"score": 0.5,
			"interactions": 0,
			"last_interaction": 0.0,
			"history": [],
		}

	var rel: Dictionary = graph[key]
	var old_score: float = rel["score"]
	rel["score"] = clampf(old_score + delta, 0.0, 1.0)
	rel["interactions"] += 1
	rel["last_interaction"] = Time.get_unix_time_from_system()

	if reason != "":
		rel["history"].append({
			"reason": reason,
			"delta": delta,
			"timestamp": Time.get_unix_time_from_system(),
		})
		# 履歴は最新20件まで
		while rel["history"].size() > 20:
			rel["history"].pop_front()

	field_state["relationship_graph"] = graph
	relationship_updated.emit(pet1_id, pet2_id, rel["score"])


func get_relationship_score(pet1_id: int, pet2_id: int) -> float:
	var key := _relationship_key(pet1_id, pet2_id)
	var graph: Dictionary = field_state.get("relationship_graph", {})
	if key in graph:
		return graph[key]["score"]
	return 0.5  # デフォルト中立


func get_closest_partner(pet_id: int) -> int:
	## 最も親しいペットのIDを返す（-1 = なし）
	var graph: Dictionary = field_state.get("relationship_graph", {})
	var best_id := -1
	var best_score := 0.0

	for key in graph:
		var ids: PackedStringArray = key.split("_")
		if ids.size() == 2:
			var id1 := int(ids[0])
			var id2 := int(ids[1])
			if id1 == pet_id or id2 == pet_id:
				var partner_id := id2 if id1 == pet_id else id1
				if graph[key]["score"] > best_score:
					best_score = graph[key]["score"]
					best_id = partner_id

	return best_id


func _relationship_key(pet1_id: int, pet2_id: int) -> String:
	var a := mini(pet1_id, pet2_id)
	var b := maxi(pet1_id, pet2_id)
	return "%d_%d" % [a, b]


# ========================================================
# フィールドムード（場の雰囲気）
# ========================================================

func update_field_mood(pets: Array) -> void:
	## 全ペットの感情から「場の雰囲気」を計算
	if pets.is_empty():
		return

	var emotion_totals: Dictionary = {}
	var count := 0

	for pet in pets:
		if not pet.is_alive:
			continue
		for emotion in pet.emotions:
			emotion_totals[emotion] = emotion_totals.get(emotion, 0.0) + pet.emotions[emotion]
		count += 1

	if count == 0:
		return

	# 平均感情を計算
	var dominant := "peaceful"
	var max_val := 0.0
	for emotion in emotion_totals:
		emotion_totals[emotion] /= count
		if emotion_totals[emotion] > max_val:
			max_val = emotion_totals[emotion]
			dominant = emotion

	var old_mood: String = field_state["field_mood"].get("dominant", "peaceful")
	field_state["field_mood"] = {
		"dominant": dominant if max_val > 0.2 else "peaceful",
		"intensity": max_val,
		"contributing_emotions": emotion_totals,
	}

	if dominant != old_mood:
		community_mood_shifted.emit(old_mood, dominant)


func get_field_mood() -> Dictionary:
	return field_state.get("field_mood", {"dominant": "peaceful", "intensity": 0.5})


# ========================================================
# コミュニティ話題
# ========================================================

func add_community_topic(topic: String) -> void:
	var topics: Array = field_state.get("community_topics", [])
	if topic not in topics:
		topics.append(topic)
	# 最新30件まで
	while topics.size() > 30:
		topics.pop_front()
	field_state["community_topics"] = topics


func get_community_topics() -> Array:
	return field_state.get("community_topics", [])


# ========================================================
# オフライン自律行動（冒険）
# ========================================================

func process_offline_period(offline_seconds: float, pets: Array) -> Array[Dictionary]:
	## オフライン期間にペットが「冒険」した結果を生成
	if offline_seconds < ADVENTURE_MIN_OFFLINE:
		return []

	var adventures: Array[Dictionary] = []
	var adventure_count := mini(
		ADVENTURE_MAX_PER_SESSION,
		int(offline_seconds / ADVENTURE_MIN_OFFLINE)
	)

	# 冒険可能なペット（生存 & evolution_stage >= 1）
	var eligible_pets: Array = []
	for pet in pets:
		if pet.is_alive and pet.evolution_stage >= 1:
			eligible_pets.append(pet)

	if eligible_pets.is_empty():
		return []

	for i in range(adventure_count):
		var pet = eligible_pets[randi() % eligible_pets.size()]
		var adventure := _generate_adventure(pet, offline_seconds)
		adventures.append(adventure)

		# 冒険ログに追加
		var adventure_log: Array = field_state.get("offline_adventures", [])
		adventure_log.append(adventure)
		while adventure_log.size() > MAX_OFFLINE_ADVENTURES:
			adventure_log.pop_front()
		field_state["offline_adventures"] = adventure_log

		offline_adventure_completed.emit(pet.pet_id, adventure)

	return adventures


func _generate_adventure(pet: Node, offline_seconds: float) -> Dictionary:
	## 性格に基づいた冒険を生成
	var personality: Dictionary = pet.personality
	var environment: String = pet.current_environment

	# 性格で冒険タイプを決定
	var adventure_type := "explore"
	var max_trait := 0.0
	for t_name in personality:
		if personality[t_name] > max_trait:
			max_trait = personality[t_name]
			match t_name:
				"brave": adventure_type = "battle"
				"curious": adventure_type = "explore"
				"calm": adventure_type = "meditate"
				"affectionate": adventure_type = "socialize"
				"playful": adventure_type = "play"

	# 環境で発見物を決定
	var discoveries: Dictionary = {
		"forest": ["rare_herb", "hidden_path", "ancient_tree", "firefly_grove"],
		"sea": ["pearl", "tidal_pool", "coral_garden", "message_bottle"],
		"ruins": ["rune_stone", "shadow_crystal", "forgotten_library", "echo_chamber"],
		"city": ["street_art", "rooftop_view", "lost_coin", "neon_garden"],
	}

	var env_items: Array = discoveries.get(environment, ["something_interesting"])
	var found_item: String = env_items[randi() % env_items.size()]

	# 冒険結果
	var emotion_gained: String = "joy"
	var emotion_amount := randf_range(0.1, 0.4)
	match adventure_type:
		"battle": emotion_gained = "excitement"
		"explore": emotion_gained = "excitement"
		"meditate": emotion_gained = "love"
		"socialize": emotion_gained = "love"
		"play": emotion_gained = "joy"

	return {
		"pet_id": pet.pet_id,
		"pet_name": pet.pet_name,
		"type": adventure_type,
		"environment": environment,
		"discovery": found_item,
		"duration_hours": offline_seconds / 3600.0,
		"emotion_gained": emotion_gained,
		"emotion_amount": emotion_amount,
		"timestamp": Time.get_unix_time_from_system(),
		"report": _generate_adventure_report(pet.pet_name, adventure_type, found_item, environment),
	}


func _generate_adventure_report(pet_name: String, adventure_type: String, discovery: String, env: String) -> String:
	## テンプレートベースの冒険レポート（オフラインで使用可能）
	match adventure_type:
		"explore":
			return "%s explored the %s and found a %s!" % [pet_name, env, discovery]
		"battle":
			return "%s bravely fought in the %s and discovered a %s!" % [pet_name, env, discovery]
		"meditate":
			return "%s meditated peacefully in the %s and sensed a %s nearby." % [pet_name, env, discovery]
		"socialize":
			return "%s made friends in the %s and was gifted a %s!" % [pet_name, env, discovery]
		"play":
			return "%s played around the %s and stumbled upon a %s!" % [pet_name, env, discovery]
		_:
			return "%s had an adventure in the %s." % [pet_name, env]


func get_offline_adventures(count: int = 5) -> Array:
	var adventures: Array = field_state.get("offline_adventures", [])
	return adventures.slice(-count)


# ========================================================
# 関係性の自然減衰
# ========================================================

func process_relationship_decay(offline_seconds: float) -> void:
	## オフライン期間に応じて関係性を少し減衰
	var days := offline_seconds / 86400.0
	if days < 0.1:
		return

	var graph: Dictionary = field_state.get("relationship_graph", {})
	for key in graph:
		var rel: Dictionary = graph[key]
		var decay := RELATIONSHIP_DECAY_RATE * days
		rel["score"] = maxf(0.3, rel["score"] - decay)  # 最低0.3まで（完全に忘れはしない）


# ========================================================
# 文化アーティファクト
# ========================================================

func record_cultural_artifact(artifact: Dictionary) -> void:
	artifact["timestamp"] = Time.get_unix_time_from_system()
	var artifacts: Array = field_state.get("cultural_artifacts", [])
	artifacts.append(artifact)
	while artifacts.size() > 50:
		artifacts.pop_front()
	field_state["cultural_artifacts"] = artifacts


# ========================================================
# Atomic Write セーブ/ロード
# ========================================================

func save_field() -> void:
	## atomic write: tmp → backup → rename
	if not is_initialized:
		return

	field_state["last_save_time"] = Time.get_unix_time_from_system()

	var json_string := JSON.stringify(field_state, "\t")

	# Step 1: tmpに書き込み
	var tmp_file := FileAccess.open(FIELD_TEMP_PATH, FileAccess.WRITE)
	if not tmp_file:
		push_error("[PersistentField] Failed to open temp file for writing")
		return
	tmp_file.store_string(json_string)
	tmp_file.close()

	# Step 2: 現行ファイルをbackupにリネーム
	if FileAccess.file_exists(FIELD_STATE_PATH):
		var dir := DirAccess.open("user://")
		if dir:
			# 既存backupがあれば削除
			if FileAccess.file_exists(FIELD_BACKUP_PATH):
				dir.remove(FIELD_BACKUP_PATH.get_file())
			dir.rename(FIELD_STATE_PATH.get_file(), FIELD_BACKUP_PATH.get_file())

	# Step 3: tmpを正式ファイルにリネーム
	var dir := DirAccess.open("user://")
	if dir:
		dir.rename(FIELD_TEMP_PATH.get_file(), FIELD_STATE_PATH.get_file())

	print("[PersistentField] Field saved (session %d)" % field_state.get("session_count", 0))


func _load_field() -> bool:
	## ロード: 正式ファイル → backup → 失敗
	if _try_load_from(FIELD_STATE_PATH):
		field_state["session_count"] = field_state.get("session_count", 0) + 1
		return true
	elif _try_load_from(FIELD_BACKUP_PATH):
		push_warning("[PersistentField] Loaded from backup (primary was corrupted)")
		field_state["session_count"] = field_state.get("session_count", 0) + 1
		return true
	return false


func _try_load_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return false

	var json := JSON.new()
	var result := json.parse(file.get_as_text())
	file.close()

	if result != OK:
		push_warning("[PersistentField] JSON parse failed for: %s" % path)
		return false

	if not json.data is Dictionary:
		return false

	field_state = json.data
	return true


# ========================================================
# セッション復帰処理
# ========================================================

func on_session_resume(pets: Array) -> Array[Dictionary]:
	## アプリ復帰時に呼ばれる。オフライン処理を一括実行。
	var last_save: float = field_state.get("last_save_time", Time.get_unix_time_from_system())
	var offline_seconds: float = Time.get_unix_time_from_system() - last_save

	if offline_seconds < 60.0:
		return []  # 1分未満は無視

	# 1) 関係性の自然減衰
	process_relationship_decay(offline_seconds)

	# 2) オフライン冒険の生成
	var adventures := process_offline_period(offline_seconds, pets)

	# 3) フィールドムードの更新
	update_field_mood(pets)

	print("[PersistentField] Session resumed after %.1f hours (%d adventures)" % [
		offline_seconds / 3600.0, adventures.size()
	])

	return adventures


# ========================================================
# AtoA会話向けコンテキスト提供
# ========================================================

func get_conversation_context(pet1_id: int, pet2_id: int) -> Dictionary:
	## AtoAConversationSystemがプロンプト構築に使うフィールドコンテキスト
	return {
		"field_mood": get_field_mood(),
		"relationship_score": get_relationship_score(pet1_id, pet2_id),
		"recent_shared_events": get_recent_shared_events(3),
		"community_topics": get_community_topics(),
		"recent_adventures": get_offline_adventures(2),
	}
