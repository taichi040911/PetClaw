## EcosystemManager — 環境・気候・バイオームを一元管理
## 全ペットの体調・進化・AtoAに環境影響を伝播する
class_name EcosystemManager
extends Node

signal environment_changed(old_env: String, new_env: String)
signal climate_event(event_type: String, intensity: float)
signal resource_spawned(resource_type: String, position: Vector2)

# === 環境定義 ===
const ENVIRONMENTS: Dictionary = {
	"forest": {
		"display_name": "森",
		"stat_modifiers": {
			"health_decay_mult": 0.8,       # 体力減衰が緩やか
			"hunger_decay_mult": 1.0,
			"energy_decay_mult": 0.9,
		},
		"personality_boosts": {
			"curious": 0.001,               # 好奇心が少しずつ上がる
		},
		"evolution_bias": ["nature", "growth"],
		"particle_color": Color(0.3, 0.8, 0.4),
		"particle_amount": 80,
		"a2a_topics": ["自然", "木々", "虫", "光", "成長"],
		"breeding_bonus": 0.1,
		"special_events": ["rain", "bloom", "firefly"],
	},
	"sea": {
		"display_name": "海",
		"stat_modifiers": {
			"health_decay_mult": 0.9,
			"hunger_decay_mult": 1.1,        # 海では空腹が速い
			"energy_decay_mult": 0.7,         # エネルギー消費は穏やか
		},
		"personality_boosts": {
			"calm": 0.0015,
		},
		"evolution_bias": ["water", "mystery"],
		"particle_color": Color(0.2, 0.6, 1.0),
		"particle_amount": 60,
		"a2a_topics": ["波", "深海", "静けさ", "月", "潮"],
		"breeding_bonus": 0.0,
		"special_events": ["tide", "dolphin", "storm"],
	},
	"ruins": {
		"display_name": "廃墟",
		"stat_modifiers": {
			"health_decay_mult": 1.3,        # 体力減衰が速い（危険）
			"hunger_decay_mult": 1.2,
			"energy_decay_mult": 1.1,
		},
		"personality_boosts": {
			"brave": 0.002,                  # 勇敢さが上がりやすい
		},
		"evolution_bias": ["dark", "ancient"],
		"particle_color": Color(0.4, 0.3, 0.5),
		"particle_amount": 40,
		"a2a_topics": ["過去", "影", "秘密", "勇気", "不思議"],
		"breeding_bonus": -0.1,              # 交配しにくい
		"special_events": ["ghost", "treasure", "collapse"],
	},
	"city": {
		"display_name": "街",
		"stat_modifiers": {
			"health_decay_mult": 1.0,
			"hunger_decay_mult": 0.8,        # 食べ物が豊富
			"energy_decay_mult": 1.2,         # エネルギー消費が多い
		},
		"personality_boosts": {
			"affectionate": 0.0015,
			"playful": 0.001,
		},
		"evolution_bias": ["social", "tech"],
		"particle_color": Color(1.0, 0.85, 0.4),
		"particle_amount": 100,
		"a2a_topics": ["友達", "賑やか", "遊び", "お店", "音楽"],
		"breeding_bonus": 0.15,
		"special_events": ["festival", "market", "concert"],
	},
}

# === State ===
var current_environment: String = "forest"
var climate_intensity: float = 0.5  # 0.0=穏やか, 1.0=極端
var time_in_environment: float = 0.0
var active_event: String = ""
var event_timer: float = 0.0

# === References ===
var particle_system: GPUParticles2D


func to_dict() -> Dictionary:
	return {
		"current_environment": current_environment,
		"climate_intensity": climate_intensity,
		"time_in_environment": time_in_environment,
		"active_event": active_event,
		"event_timer": event_timer,
	}


func from_dict(data: Dictionary) -> void:
	current_environment = data.get("current_environment", "forest")
	climate_intensity = data.get("climate_intensity", 0.5)
	time_in_environment = data.get("time_in_environment", 0.0)
	active_event = data.get("active_event", "")
	event_timer = data.get("event_timer", 0.0)


func _ready() -> void:
	particle_system = get_node_or_null("EnvironmentParticles") as GPUParticles2D
	if not particle_system:
		particle_system = GPUParticles2D.new()
		particle_system.name = "EnvironmentParticles"
		add_child(particle_system)
	_apply_environment_visuals()


func _process(delta: float) -> void:
	time_in_environment += delta
	_process_climate(delta)
	_process_special_events(delta)
	_apply_long_term_effects(delta)


# === 環境変更 ===
func change_environment(new_env: String) -> void:
	if new_env not in ENVIRONMENTS:
		push_warning("Unknown environment: %s" % new_env)
		return
	if new_env == current_environment:
		return

	var old_env := current_environment
	current_environment = new_env
	time_in_environment = 0.0
	_apply_environment_visuals()
	environment_changed.emit(old_env, new_env)

	# 全ペットに即時影響
	for pet in GameManager.get_all_pets():
		_apply_immediate_effects(pet)


# === 即時影響（環境変更直後） ===
func _apply_immediate_effects(pet: PetEntity) -> void:
	var env_data: Dictionary = ENVIRONMENTS[current_environment]
	pet.current_environment = current_environment

	# 性格ブースト（即時は小さめ）
	for t_name in env_data["personality_boosts"]:
		pet.evolve_personality(t_name, env_data["personality_boosts"][t_name] * 5.0)

	# 感情刺激
	GameManager.emotion_system.stimulate(pet, "excitement", 0.2, "environment_change")


# === 長期影響（環境滞在中の毎フレーム） ===
func _apply_long_term_effects(delta: float) -> void:
	var env_data: Dictionary = ENVIRONMENTS[current_environment]

	for pet in GameManager.get_all_pets():
		if not pet.is_alive:
			continue

		# 性格の緩やかな変化
		for t_name in env_data["personality_boosts"]:
			pet.evolve_personality(t_name, env_data["personality_boosts"][t_name] * delta)


# === 環境修飾子を取得（他システムから参照） ===
func get_stat_modifier(stat_name: String) -> float:
	var env_data: Dictionary = ENVIRONMENTS[current_environment]
	var key := stat_name + "_decay_mult"
	return env_data["stat_modifiers"].get(key, 1.0)


func get_breeding_bonus() -> float:
	return ENVIRONMENTS[current_environment].get("breeding_bonus", 0.0)


func get_a2a_topics() -> Array:
	return ENVIRONMENTS[current_environment].get("a2a_topics", [])


func get_evolution_bias() -> Array:
	return ENVIRONMENTS[current_environment].get("evolution_bias", [])


# === 気候変動 ===
func _process_climate(delta: float) -> void:
	# 気候はゆっくりランダムに変動
	climate_intensity += (randf() - 0.5) * 0.001 * delta
	climate_intensity = clampf(climate_intensity, 0.0, 1.0)

	# 極端な気候時にイベント発火
	if climate_intensity > 0.85 and active_event == "":
		_trigger_climate_event()


func _trigger_climate_event() -> void:
	var events: Array = ENVIRONMENTS[current_environment].get("special_events", [])
	if events.is_empty():
		return
	active_event = events[randi() % events.size()]
	event_timer = randf_range(30.0, 120.0)  # 30〜120秒
	climate_event.emit(active_event, climate_intensity)


# === 特別イベント処理 ===
func _process_special_events(delta: float) -> void:
	if active_event == "":
		return

	event_timer -= delta
	if event_timer <= 0.0:
		active_event = ""
		return

	# イベント中の追加効果
	for pet in GameManager.get_all_pets():
		if not pet.is_alive:
			continue
		match active_event:
			"rain":
				pet.stats.modify("health", 0.0005 * delta)  # 雨は回復
			"storm":
				GameManager.emotion_system.stimulate(pet, "fear", 0.001 * delta, "storm")
			"bloom":
				GameManager.emotion_system.stimulate(pet, "joy", 0.001 * delta, "bloom")
			"festival":
				GameManager.emotion_system.stimulate(pet, "excitement", 0.002 * delta, "festival")
			"ghost":
				GameManager.emotion_system.stimulate(pet, "fear", 0.002 * delta, "ghost")
				pet.evolve_personality("brave", 0.0005 * delta)
			"treasure":
				GameManager.emotion_system.stimulate(pet, "excitement", 0.003 * delta, "treasure")


# === 視覚更新 ===
func _apply_environment_visuals() -> void:
	if not is_instance_valid(particle_system):
		return
	var env_data: Dictionary = ENVIRONMENTS[current_environment]
	particle_system.modulate = env_data.get("particle_color", Color.WHITE)
	particle_system.amount = env_data.get("particle_amount", 60)
	particle_system.emitting = true
