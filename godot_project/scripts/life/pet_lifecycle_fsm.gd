class_name PetLifecycleFSM
extends RefCounted

## Finite State Machine for pet lifecycle stages
## Inspired by avatar-ui's Field FSM pattern
## Manages state transitions, behaviors, and persistence

enum LifecycleState {
	EGG = 0,          # Initial state, pre-hatch
	BABY = 1,         # Stage 1, high care dependency
	CHILD = 2,        # Stage 2, personality forming
	TEEN = 3,         # Stage 3, rapid changes
	ADULT = 4,        # Stage 4, stable personality
	ELDER = 5,        # Stage 5, wisdom, slower
	SLEEPING = 6,     # Overlay state (any active)
	PAUSED = 7,       # Game suspended
	DEAD = 8,         # Terminal state
	ETERNAL = 9       # Fully bonded revival path
}

# Age thresholds (in hours)
const HATCH_AGE: float = 0.5
const BABY_TO_CHILD_AGE: float = 2.0
const CHILD_TO_TEEN_AGE: float = 6.0
const TEEN_TO_ADULT_AGE: float = 12.0
const ADULT_TO_ELDER_AGE: float = 24.0

# Energy thresholds for sleep
const SLEEP_THRESHOLD: float = 0.15
const WAKE_THRESHOLD: float = 0.5

# State multipliers
const BABY_HUNGER_MULT: float = 2.0
const BABY_AFFECTION_MULT: float = 2.0
const TEEN_EMOTION_VOLATILITY: float = 1.5
const ELDER_ENERGY_RECOVERY: float = 3.0
const SLEEPING_ENERGY_RECOVERY: float = 3.0

signal state_changed(pet_id: int, old_state: int, new_state: int)
signal lifecycle_milestone(pet_id: int, milestone: String)
signal sleep_started(pet_id: int)
signal sleep_ended(pet_id: int)
signal entered_eternal(pet_id: int)

var pet_id: int
var current_state: int = LifecycleState.EGG
var previous_state: int = LifecycleState.EGG
var sleeping_return_state: int = LifecycleState.EGG
var paused_return_state: int = LifecycleState.EGG

var state_entered_time: float = 0.0
var state_duration: float = 0.0

# State persistence file path
var state_file_path: String = ""


func _init(p_pet_id: int) -> void:
	pet_id = p_pet_id
	state_file_path = "user://petclaw/pet_%d_lifecycle.save" % pet_id


## Main tick update - evaluates transitions and applies state behaviors
func tick_update(delta: float, pet_data: Dictionary) -> void:
	state_duration += delta
	
	# Skip updates while paused
	if current_state == LifecycleState.PAUSED:
		return
	
	# Handle sleep wake-up condition
	if current_state == LifecycleState.SLEEPING:
		if pet_data.get("energy", 0.0) > WAKE_THRESHOLD:
			_wake_from_sleep()
		return
	
	# Evaluate state transitions
	_evaluate_transitions(pet_data)
	
	# Apply state-specific behaviors
	_apply_state_behaviors(delta, pet_data)


## Evaluate all possible state transitions based on conditions
func _evaluate_transitions(pet_data: Dictionary) -> void:
	var age: float = pet_data.get("age_hours", 0.0)
	var evolution_stage: int = pet_data.get("evolution_stage", 1)
	var health: float = pet_data.get("health", 1.0)
	var energy: float = pet_data.get("energy", 0.5)
	
	# Death check (highest priority)
	if health <= 0.0 or pet_data.get("starvation_critical", false):
		if current_state != LifecycleState.DEAD:
			_change_state(LifecycleState.DEAD, pet_data)
		return
	
	# Sleep triggers on any active state
	if energy < SLEEP_THRESHOLD and current_state != LifecycleState.EGG:
		if current_state != LifecycleState.SLEEPING:
			_enter_sleep()
		return
	
	# Age-based progression
	match current_state:
		LifecycleState.EGG:
			if age >= HATCH_AGE:
				_change_state(LifecycleState.BABY, pet_data)
		
		LifecycleState.BABY:
			if age >= BABY_TO_CHILD_AGE and evolution_stage >= 2:
				_change_state(LifecycleState.CHILD, pet_data)
		
		LifecycleState.CHILD:
			if age >= CHILD_TO_TEEN_AGE and evolution_stage >= 3:
				_change_state(LifecycleState.TEEN, pet_data)
		
		LifecycleState.TEEN:
			if age >= TEEN_TO_ADULT_AGE and evolution_stage >= 4:
				_change_state(LifecycleState.ADULT, pet_data)
		
		LifecycleState.ADULT:
			if age >= ADULT_TO_ELDER_AGE:
				_change_state(LifecycleState.ELDER, pet_data)


## Apply per-state behavioral multipliers and effects
func _apply_state_behaviors(delta: float, pet_data: Dictionary) -> void:
	match current_state:
		LifecycleState.EGG:
			# Slow stat changes, warmth affects hatch speed
			pet_data["stat_change_rate"] = pet_data.get("stat_change_rate", 1.0) * 0.5
			
		LifecycleState.BABY:
			# 2x hunger drain, 2x affection gain
			pet_data["hunger_drain_mult"] = BABY_HUNGER_MULT
			pet_data["affection_gain_mult"] = BABY_AFFECTION_MULT
			
		LifecycleState.CHILD:
			# Normal rates with personality formation bonus
			pet_data["personality_formation_bonus"] = 1.5
			
		LifecycleState.TEEN:
			# Emotional volatility and evolution readiness
			pet_data["emotion_volatility"] = TEEN_EMOTION_VOLATILITY
			pet_data["evolution_readiness"] = pet_data.get("evolution_readiness", 1.0) * 1.3
			
		LifecycleState.ADULT:
			# Stable, full AtoA capability
			pet_data["atoa_enabled"] = true
			pet_data["breeding_eligible"] = true
			
		LifecycleState.ELDER:
			# Slower recovery, wisdom bonus
			pet_data["energy_recovery_mult"] = 0.7
			pet_data["wisdom_bonus"] = 1.5
			
		LifecycleState.SLEEPING:
			# Energy recovery 3x, dream-based memory consolidation
			pet_data["energy_recovery_mult"] = SLEEPING_ENERGY_RECOVERY
			pet_data["memory_consolidation_active"] = true


## Transition to sleep from any active state
func _enter_sleep() -> void:
	sleeping_return_state = current_state
	_change_state(LifecycleState.SLEEPING, {})
	sleep_started.emit(pet_id)


## Wake up from sleep back to previous state
func _wake_from_sleep() -> void:
	var return_to: int = sleeping_return_state
	if return_to == LifecycleState.EGG:
		return_to = LifecycleState.BABY
	_change_state(return_to, {})
	sleep_ended.emit(pet_id)


## Pause the game - save current state to resume later
func pause_game() -> void:
	if current_state != LifecycleState.PAUSED:
		paused_return_state = current_state
		_change_state(LifecycleState.PAUSED, {})


## Resume from pause - return to previous state
func resume_game() -> void:
	if current_state == LifecycleState.PAUSED:
		_change_state(paused_return_state, {})


## Attempt revival to ETERNAL state (special condition path)
func attempt_eternal_ascension(pet_data: Dictionary) -> bool:
	var affection: float = pet_data.get("affection", 0.0)
	var redeemed_elder: bool = pet_data.get("redeemed_elder", false)
	
	# Require max affection and redeemed_elder flag
	if redeemed_elder and affection >= 1.0 and current_state == LifecycleState.DEAD:
		_change_state(LifecycleState.ETERNAL, pet_data)
		entered_eternal.emit(pet_id)
		return true
	
	return false


## Core state change logic with signal emission
func _change_state(new_state: int, pet_data: Dictionary) -> void:
	if new_state == current_state:
		return
	
	previous_state = current_state
	current_state = new_state
	state_entered_time = Time.get_ticks_msec() / 1000.0
	state_duration = 0.0
	
	# Emit state change signal
	state_changed.emit(pet_id, previous_state, current_state)
	
	# Emit milestone for major transitions
	var milestone: String = _get_milestone_name(current_state)
	if milestone:
		lifecycle_milestone.emit(pet_id, milestone)
	
	# Persist state change
	_persist_state()


## Get human-readable milestone name for state
func _get_milestone_name(state: int) -> String:
	match state:
		LifecycleState.BABY:
			return "hatched"
		LifecycleState.CHILD:
			return "childhood"
		LifecycleState.TEEN:
			return "adolescence"
		LifecycleState.ADULT:
			return "adulthood"
		LifecycleState.ELDER:
			return "elderhood"
		LifecycleState.ETERNAL:
			return "eternal_ascension"
		LifecycleState.DEAD:
			return "death"
	return ""


## Persist state to disk (atomic write pattern)
func _persist_state() -> void:
	var state_data: Dictionary = {
		"pet_id": pet_id,
		"current_state": current_state,
		"previous_state": previous_state,
		"state_entered_time": state_entered_time,
		"state_duration": state_duration,
		"timestamp": Time.get_ticks_msec()
	}
	
	# Use GameManager to handle atomic writes
	var game_manager = GameManager.instance
	if game_manager:
		game_manager.save_pet_lifecycle_state(pet_id, state_data)


## Load state from disk with corruption recovery
func load_state() -> bool:
	var game_manager = GameManager.instance
	if not game_manager:
		return false
	
	var state_data: Dictionary = game_manager.load_pet_lifecycle_state(pet_id)
	if state_data.is_empty():
		# Recovery: default to EGG
		current_state = LifecycleState.EGG
		return false
	
	# Validate loaded state
	if state_data.has("current_state"):
		var loaded_state: int = state_data["current_state"]
		if loaded_state >= 0 and loaded_state < LifecycleState.size():
			current_state = loaded_state
			previous_state = state_data.get("previous_state", LifecycleState.EGG)
			state_entered_time = state_data.get("state_entered_time", 0.0)
			return true
	
	# Corruption recovery: reconstruct from evolution history
	current_state = LifecycleState.EGG
	return false


## Get current state as human-readable string
func get_state_name() -> String:
	match current_state:
		LifecycleState.EGG:
			return "Egg"
		LifecycleState.BABY:
			return "Baby"
		LifecycleState.CHILD:
			return "Child"
		LifecycleState.TEEN:
			return "Teen"
		LifecycleState.ADULT:
			return "Adult"
		LifecycleState.ELDER:
			return "Elder"
		LifecycleState.SLEEPING:
			return "Sleeping"
		LifecycleState.PAUSED:
			return "Paused"
		LifecycleState.DEAD:
			return "Dead"
		LifecycleState.ETERNAL:
			return "Eternal"
	return "Unknown"


## Export state to dictionary for serialization
func to_dict() -> Dictionary:
	return {
		"pet_id": pet_id,
		"current_state": current_state,
		"previous_state": previous_state,
		"sleeping_return_state": sleeping_return_state,
		"paused_return_state": paused_return_state,
		"state_entered_time": state_entered_time,
		"state_duration": state_duration
	}


## Import state from dictionary for deserialization
func from_dict(data: Dictionary) -> void:
	pet_id = data.get("pet_id", pet_id)
	current_state = data.get("current_state", LifecycleState.EGG)
	previous_state = data.get("previous_state", LifecycleState.EGG)
	sleeping_return_state = data.get("sleeping_return_state", LifecycleState.EGG)
	paused_return_state = data.get("paused_return_state", LifecycleState.EGG)
	state_entered_time = data.get("state_entered_time", 0.0)
	state_duration = data.get("state_duration", 0.0)


# === 死亡演出システム（v2追加） ===

signal death_triggered(pet_id: int, cause: String)
signal resurrection_evaluated(pet_id: int, evaluation: Dictionary)
signal resurrection_success(pet_id: int)
signal resurrection_failure(pet_id: int)

## 死亡データ構造
class DeathRecord:
	var pet_id: int
	var cause: String  # natural/starvation/disease/accident
	var age_at_death: float
	var last_emotion: Dictionary
	var care_quality: float
	var bond_level: float
	var relationships: Array[Dictionary]
	var death_time: float
	var location: String

	func _init(p_pet_id: int, p_cause: String) -> void:
		pet_id = p_pet_id
		cause = p_cause
		death_time = Time.get_unix_time_from_system()

	func to_dict() -> Dictionary:
		return {
			"pet_id": pet_id,
			"cause": cause,
			"age_at_death": age_at_death,
			"last_emotion": last_emotion.duplicate(),
			"care_quality": care_quality,
			"bond_level": bond_level,
			"relationships": relationships.duplicate(),
			"death_time": death_time,
			"location": location,
		}

	static func from_dict(data: Dictionary) -> DeathRecord:
		var record := DeathRecord.new(data.get("pet_id", 0), data.get("cause", "natural"))
		record.age_at_death = data.get("age_at_death", 0.0)
		record.last_emotion = data.get("last_emotion", {})
		record.care_quality = data.get("care_quality", 0.5)
		record.bond_level = data.get("bond_level", 0.0)
		record.relationships = data.get("relationships", [])
		record.death_time = data.get("death_time", 0.0)
		record.location = data.get("location", "unknown")
		return record

var death_record: DeathRecord = null  ## 現在の死亡データ（DEAD状態時）


func trigger_death(cause: String = "natural") -> void:
	## 死亡を発動（原因: natural/starvation/disease/accident）
	if current_state == LifecycleState.DEAD:
		return
	var old_state := current_state
	previous_state = old_state
	current_state = LifecycleState.DEAD
	state_entered_time = Time.get_unix_time_from_system()
	state_duration = 0.0
	state_changed.emit(pet_id, old_state, LifecycleState.DEAD)
	lifecycle_milestone.emit(pet_id, "death_%s" % cause)
	_record_death_data(cause)
	death_triggered.emit(pet_id, cause)
	_persist_state()


func _record_death_data(cause: String) -> void:
	## 死亡データを記録（追悼・蘇生判定用）
	death_record = DeathRecord.new(pet_id, cause)

	# GameManagerから現在のペットデータを取得
	var game_manager = GameManager.instance
	if game_manager:
		var pet: PetEntity = game_manager.get_pet(pet_id)
		if pet:
			death_record.age_at_death = pet.age
			death_record.last_emotion = pet.emotions.duplicate()
			death_record.care_quality = pet.stats.get_care_quality() if pet.stats.has_method("get_care_quality") else 0.5
			death_record.bond_level = pet.affection

			# 関係ペット情報を記録
			for relationship in pet.relationships:
				var rel_data := {
					"target_pet_id": relationship.get("target_pet_id", -1),
					"relationship_type": relationship.get("type", "friend"),
					"bond_strength": relationship.get("bond", 0.5),
				}
				death_record.relationships.append(rel_data)

			death_record.location = pet.current_environment if pet.has_meta("current_environment") else "unknown"


func evaluate_resurrection() -> Dictionary:
	## 蘇生可能性を評価
	## 条件: 愛着スコア > 0.7 AND ケア品質 > 0.6 AND プレイヤーアクション
	## Returns: {"possible": bool, "probability": float, "requirements": Array}
	if not death_record:
		return {"possible": false, "probability": 0.0, "requirements": ["no_death_record"]}

	var requirements: Array[String] = []
	var probability: float = 0.0

	# 愛着スコアチェック（P1: consistency × memory = attachment）
	var bond_probability: float = 0.0
	if death_record.bond_level > 0.7:
		bond_probability = (death_record.bond_level - 0.7) * 2.0  # 0.7-1.0 → 0.0-0.6
	else:
		requirements.append("bond_level_insufficient")

	# ケア品質チェック
	var care_probability: float = 0.0
	if death_record.care_quality > 0.6:
		care_probability = (death_record.care_quality - 0.6) * 1.5  # 0.6-1.0 → 0.0-0.6
	else:
		requirements.append("care_quality_insufficient")

	# 関係者の悲嘆チェック（friends/family who grieve）
	var relationship_probability: float = 0.0
	if death_record.relationships.size() > 0:
		# 関係ペット数に応じてボーナス
		relationship_probability = minf(0.3, death_record.relationships.size() * 0.1)
	else:
		requirements.append("no_surviving_relationships")

	# 年齢要因（若いほど蘇生確率が高い）
	var age_probability: float = 0.0
	if death_record.age_at_death < 30.0:
		age_probability = (1.0 - death_record.age_at_death / 30.0) * 0.2
	else:
		requirements.append("age_limit_exceeded")

	# 総合確率（各要因を合算）
	probability = clampf(bond_probability + care_probability + relationship_probability + age_probability, 0.0, 1.0)

	var possible: bool = (
		death_record.bond_level > 0.7 and
		death_record.care_quality > 0.6 and
		current_state == LifecycleState.DEAD
	)

	var result := {
		"possible": possible,
		"probability": probability,
		"requirements": requirements,
		"death_record": death_record.to_dict(),
	}

	resurrection_evaluated.emit(pet_id, result)
	return result


func attempt_resurrection(player_action: String) -> bool:
	## 蘇生を試みる（P3: Player Agency）
	## player_action: "pray" / "memory_offering" / "bond_call"
	if current_state != LifecycleState.DEAD or not death_record:
		return false

	# 蘇生確率を評価
	var eval := evaluate_resurrection()
	if not eval.get("possible", false):
		resurrection_failure.emit(pet_id)
		return false

	var base_probability: float = eval.get("probability", 0.0)

	# プレイヤーアクション別の確率修正
	var action_modifier: float = 0.0
	match player_action:
		"pray":
			action_modifier = 0.2  # 祈り: 標準的なアクション
		"memory_offering":
			action_modifier = 0.35  # 記憶奉献: より効果的
		"bond_call":
			action_modifier = 0.4  # 絆の呼びかけ: 最も効果的

	var final_probability: float = clampf(base_probability + action_modifier, 0.0, 1.0)

	# 蘇生判定
	var success: bool = randf() < final_probability

	if success:
		# 蘇生成功 → ETERNAL状態へ遷移
		previous_state = current_state
		current_state = LifecycleState.ETERNAL
		state_entered_time = Time.get_unix_time_from_system()
		state_duration = 0.0
		state_changed.emit(pet_id, LifecycleState.DEAD, LifecycleState.ETERNAL)
		lifecycle_milestone.emit(pet_id, "eternal_resurrection_%s" % player_action)
		entered_eternal.emit(pet_id)
		resurrection_success.emit(pet_id)
		_persist_state()
		return true
	else:
		# 蘇生失敗 → 追悼効果を発動
		resurrection_failure.emit(pet_id)
		return false


func get_death_summary() -> Dictionary:
	## 死亡サマリーを取得（追悼投稿用）
	## Returns: cause, age, last_words, significant_memories, surviving_family, bond_score
	if not death_record:
		return {}

	return {
		"pet_id": pet_id,
		"cause": death_record.cause,
		"age_at_death": death_record.age_at_death,
		"last_emotion": death_record.last_emotion,
		"care_quality_score": death_record.care_quality,
		"bond_level": death_record.bond_level,
		"surviving_family": death_record.relationships.size(),
		"death_time": death_record.death_time,
		"location": death_record.location,
		"death_record": death_record.to_dict(),
	}


func from_dict_with_death(data: Dictionary) -> void:
	## Import state from dictionary including death data
	pet_id = data.get("pet_id", pet_id)
	current_state = data.get("current_state", LifecycleState.EGG)
	previous_state = data.get("previous_state", LifecycleState.EGG)
	sleeping_return_state = data.get("sleeping_return_state", LifecycleState.EGG)
	paused_return_state = data.get("paused_return_state", LifecycleState.EGG)
	state_entered_time = data.get("state_entered_time", 0.0)
	state_duration = data.get("state_duration", 0.0)

	# 死亡データの復元
	if data.has("death_record") and data["death_record"]:
		death_record = DeathRecord.from_dict(data["death_record"])
