## PetEntity — ペットの中核エンティティ
## 全システムがこのノードを参照してペットの状態を読み書きする
class_name PetEntity
extends Node2D

# === Signals ===
signal stat_changed(stat_name: String, old_value: float, new_value: float)
signal emotion_changed(emotion: String, intensity: float)
signal personality_evolved(trait: String, delta: float)
signal pet_state_critical(warning_type: String)

# === Export ===
@export var pet_id: int = 0
@export var pet_name: String = "Unnamed"
@export var display_sprite: AnimatedSprite2D

# === Stats（体調） ===
var stats: StatsData = StatsData.new()

# === Personality（性格Traits 0.0〜1.0） ===
var personality: Dictionary = {
	"brave": 0.5,
	"curious": 0.5,
	"calm": 0.5,
	"affectionate": 0.5,
	"playful": 0.5,
}

# === Emotions（現在の感情状態） ===
var emotions: Dictionary = {
	"joy": 0.0,
	"fear": 0.0,
	"excitement": 0.0,
	"sadness": 0.0,
	"love": 0.0,
}

# === Memory（ペットの記憶） ===
## レガシー互換: 単純な記憶リスト（BiologicalMemorySystem が統合管理する）
var memories: Array[Dictionary] = []
var max_memories: int = 50

# === State ===
var is_alive: bool = true
var age: float = 0.0  # ゲーム内時間単位
var evolution_stage: int = 0  # 0=egg, 1=baby, 2=child, 3=teen, 4=adult, 5=elder
var current_environment: String = "forest"


func _ready() -> void:
	stats.stat_changed.connect(_on_stat_changed)


func _process(delta: float) -> void:
	if not is_alive:
		return
	_process_natural_decay(delta)
	_process_aging(delta)
	_process_mood_update()


# === 自然減衰（Ebbinghaus曲線模倣） ===
func _process_natural_decay(delta: float) -> void:
	# 空腹: 比較的速く減衰
	var hunger_decay: float = 0.002 * delta * _age_decay_multiplier()
	stats.modify("hunger", -hunger_decay)

	# エネルギー: 中程度の減衰
	var energy_decay: float = 0.0015 * delta * _age_decay_multiplier()
	stats.modify("energy", -energy_decay)

	# 体力: ゆっくり減衰（環境と空腹の影響）
	var health_decay: float = 0.0005 * delta * _age_decay_multiplier()
	if stats.hunger < 0.2:
		health_decay *= 3.0  # 空腹時は体力減衰が加速
	stats.modify("health", -health_decay)


# === 老化処理 ===
func _process_aging(delta: float) -> void:
	var old_age := age
	age += delta / 3600.0  # 1時間で1.0加齢

	# 進化段階チェック
	var new_stage := _calculate_evolution_stage()
	if new_stage != evolution_stage:
		evolution_stage = new_stage
		GameManager.evolution_mechanics.check_evolution(self)


func _age_decay_multiplier() -> float:
	# 老化に伴い減衰速度が上がる
	if age < 10.0:
		return 1.0
	elif age < 30.0:
		return 1.0 + (age - 10.0) * 0.02
	else:
		return 1.4 + (age - 30.0) * 0.05


func _calculate_evolution_stage() -> int:
	if age < 1.0: return 0      # Egg
	elif age < 5.0: return 1    # Baby
	elif age < 15.0: return 2   # Child
	elif age < 30.0: return 3   # Teen
	elif age < 60.0: return 4   # Adult
	else: return 5              # Elder


# === Mood（気分）計算 ===
func _process_mood_update() -> void:
	var mood := 0.0
	mood += stats.hunger * 0.25
	mood += stats.health * 0.3
	mood += stats.energy * 0.15
	mood += emotions["joy"] * 0.2
	mood -= emotions["sadness"] * 0.15
	mood -= emotions["fear"] * 0.1
	mood += emotions["love"] * 0.15
	stats.set_mood(clampf(mood, 0.0, 1.0))


# === 感情変更 ===
func set_emotion(emotion_name: String, intensity: float) -> void:
	if emotion_name in emotions:
		emotions[emotion_name] = clampf(intensity, 0.0, 1.0)
		emotion_changed.emit(emotion_name, intensity)


func blend_emotion(emotion_name: String, delta_intensity: float) -> void:
	if emotion_name in emotions:
		var new_val := clampf(emotions[emotion_name] + delta_intensity, 0.0, 1.0)
		set_emotion(emotion_name, new_val)


# === 性格進化 ===
func evolve_personality(trait: String, delta: float) -> void:
	if trait in personality:
		var old_val := personality[trait]
		personality[trait] = clampf(old_val + delta, 0.0, 1.0)
		personality_evolved.emit(trait, delta)


# === 記憶追加 ===
func add_memory(memory: Dictionary) -> void:
	## レガシー互換の記憶追加。BiologicalMemorySystem 経由も内部で呼ぶ
	memory["timestamp"] = Time.get_unix_time_from_system()
	memory["age_at_event"] = age
	memories.append(memory)
	if memories.size() > max_memories:
		memories.pop_front()

	# BiologicalMemorySystem への転送（存在する場合）
	if GameManager.instance and GameManager.instance.biological_memory:
		var emotion_tag := _get_dominant_emotion()
		var emotion_intensity := _get_max_emotion_intensity()
		var tags: Array = [current_environment, memory.get("type", "")]
		if memory.has("with"):
			tags.append("pet_%d" % memory["with"])
		GameManager.instance.biological_memory.consolidate_memory(
			pet_id, memory, emotion_tag, emotion_intensity, tags
		)


func _get_dominant_emotion() -> String:
	var best := "neutral"
	var best_val := 0.15
	for emo in emotions:
		if emotions[emo] > best_val:
			best_val = emotions[emo]
			best = emo
	return best


func _get_max_emotion_intensity() -> float:
	var max_val := 0.0
	for emo in emotions:
		max_val = maxf(max_val, emotions[emo])
	return max_val


# === シグナルハンドラ ===
func _on_stat_changed(stat_name: String, old_value: float, new_value: float) -> void:
	stat_changed.emit(stat_name, old_value, new_value)

	# 危険域チェック
	if new_value < 0.15 and old_value >= 0.15:
		pet_state_critical.emit(stat_name + "_low")


# === シリアライズ ===
func to_dict() -> Dictionary:
	return {
		"pet_id": pet_id,
		"pet_name": pet_name,
		"stats": stats.to_dict(),
		"personality": personality.duplicate(),
		"emotions": emotions.duplicate(),
		"memories": memories.duplicate(true),
		"is_alive": is_alive,
		"age": age,
		"evolution_stage": evolution_stage,
		"current_environment": current_environment,
	}


func from_dict(data: Dictionary) -> void:
	pet_id = data.get("pet_id", 0)
	pet_name = data.get("pet_name", "Unnamed")
	stats.from_dict(data.get("stats", {}))
	personality = data.get("personality", personality)
	emotions = data.get("emotions", emotions)
	memories = data.get("memories", [])
	is_alive = data.get("is_alive", true)
	age = data.get("age", 0.0)
	evolution_stage = data.get("evolution_stage", 0)
	current_environment = data.get("current_environment", "forest")
