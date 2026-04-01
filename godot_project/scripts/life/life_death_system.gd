## LifeDeathSystem — 生き死に・老化・蘇生を管理
## たまごっちの緊張感 + ポケモンの成長 + デジモンの絆を統合
class_name LifeDeathSystem
extends Node

signal pet_warning(pet_id: int, warning_type: String)
signal pet_died(pet_id: int, cause: String)
signal pet_revived(pet_id: int, method: String)
signal pet_aged(pet_id: int, new_age: float)

# === 死亡判定パラメータ ===
const WARNING_THRESHOLD: float = 0.15          # 警告状態に入る閾値
const CRITICAL_THRESHOLD: float = 0.05          # クリティカル状態
const DEATH_ACCUMULATION_RATE: float = 0.01     # 死亡蓄積速度（毎秒）
const DEATH_TRIGGER_VALUE: float = 1.0          # この値に達すると死亡
const ELDER_AGE: float = 60.0                   # 老齢開始
const MAX_AGE: float = 100.0                    # 老衰上限

# === 蘇生パラメータ ===
const BASE_REVIVE_CHANCE: float = 0.3           # 基本蘇生確率
const AFFECTION_REVIVE_BONUS: float = 0.4       # 他ペットの愛着によるボーナス
const MEDICINE_REVIVE_BONUS: float = 0.2        # 薬による追加確率

# === State per pet ===
var death_accumulator: Dictionary = {}          # pet_id → float
var warning_states: Dictionary = {}             # pet_id → String ("none","warning","critical")
var death_cooldown: Dictionary = {}             # pet_id → 蘇生後の保護期間

var tracked_pets: Array[PetEntity] = []


func register_pet(pet: PetEntity) -> void:
	tracked_pets.append(pet)
	death_accumulator[pet.pet_id] = 0.0
	warning_states[pet.pet_id] = "none"
	death_cooldown[pet.pet_id] = 0.0
	pet.pet_state_critical.connect(_on_pet_critical.bind(pet))


func _process(delta: float) -> void:
	for pet in tracked_pets:
		if not pet.is_alive:
			continue
		_process_warning_state(pet, delta)
		_process_death_accumulation(pet, delta)
		_process_aging_effects(pet, delta)
		_process_cooldown(pet, delta)


# === 警告状態管理 ===
func _process_warning_state(pet: PetEntity, _delta: float) -> void:
	var danger := pet.stats.get_danger_level()
	var old_state: String = warning_states[pet.pet_id]
	var new_state: String

	if danger > 0.7:
		new_state = "critical"
	elif danger > 0.3:
		new_state = "warning"
	else:
		new_state = "none"

	if new_state != old_state:
		warning_states[pet.pet_id] = new_state
		if new_state != "none":
			pet_warning.emit(pet.pet_id, new_state)
			_apply_warning_visuals(pet, new_state)


# === 死亡蓄積 ===
func _process_death_accumulation(pet: PetEntity, delta: float) -> void:
	# 蘇生保護期間中はスキップ
	if death_cooldown[pet.pet_id] > 0.0:
		return

	var danger := pet.stats.get_danger_level()

	if danger > 0.5:
		# 危険域: 死亡蓄積が進む
		var rate := DEATH_ACCUMULATION_RATE * danger * delta
		# 老齢ペットは蓄積が速い
		if pet.age > ELDER_AGE:
			rate *= 1.0 + (pet.age - ELDER_AGE) / (MAX_AGE - ELDER_AGE)
		death_accumulator[pet.pet_id] += rate
	else:
		# 安全域: 蓄積がゆっくり回復
		death_accumulator[pet.pet_id] = maxf(0.0, death_accumulator[pet.pet_id] - 0.005 * delta)

	# 死亡判定
	if death_accumulator[pet.pet_id] >= DEATH_TRIGGER_VALUE:
		_trigger_death(pet, "stat_depletion")

	# 老衰チェック
	if pet.age >= MAX_AGE:
		_trigger_death(pet, "old_age")


# === 老化の追加影響 ===
func _process_aging_effects(pet: PetEntity, delta: float) -> void:
	if pet.age < ELDER_AGE:
		return

	# 老齢ペットの追加効果
	var elder_factor := (pet.age - ELDER_AGE) / (MAX_AGE - ELDER_AGE)

	# 体力が自然に低下しやすくなる
	pet.stats.modify("health", -0.0002 * elder_factor * delta)

	# 賢さ（calm）が上がる — 老齢の知恵
	pet.evolve_personality("calm", 0.0001 * elder_factor * delta)

	# 老化シグナルを発行
	pet_aged.emit(pet.pet_id, pet.age)


# === 死亡トリガー ===
func _trigger_death(pet: PetEntity, cause: String) -> void:
	pet.is_alive = false
	death_accumulator[pet.pet_id] = 0.0
	warning_states[pet.pet_id] = "none"

	pet.add_memory({
		"type": "death",
		"cause": cause,
		"age_at_death": pet.age,
	})

	pet_died.emit(pet.pet_id, cause)

	# AtoA悲しみ会話をトリガー
	_trigger_grief_conversations(pet, cause)

	# 死亡ビジュアル
	_play_death_visuals(pet, cause)


# === 蘇生 ===
func attempt_revive(pet: PetEntity, method: String = "care") -> bool:
	if pet.is_alive:
		return false

	var revive_chance := BASE_REVIVE_CHANCE

	# 他のペットの愛着ボーナス
	var max_affection_from_others := 0.0
	for other_pet in tracked_pets:
		if other_pet.pet_id != pet.pet_id and other_pet.is_alive:
			# 他ペットのlove感情を参照
			max_affection_from_others = maxf(max_affection_from_others, other_pet.emotions["love"])
	revive_chance += max_affection_from_others * AFFECTION_REVIVE_BONUS

	# 薬使用時のボーナス
	if method == "medicine":
		revive_chance += MEDICINE_REVIVE_BONUS

	# 判定
	if randf() < revive_chance:
		_execute_revive(pet, method)
		return true
	else:
		# 蘇生失敗 — より悲しい展開
		GameManager.emotion_system.stimulate(pet, "sadness", 0.3, "revive_failed")
		return false


func _execute_revive(pet: PetEntity, method: String) -> void:
	pet.is_alive = true
	pet.stats.hunger = 0.4
	pet.stats.health = 0.3
	pet.stats.energy = 0.3
	pet.stats.mood = 0.5

	# 蘇生保護期間（60秒間は死亡しない）
	death_cooldown[pet.pet_id] = 60.0

	# 性格変化（死を経験した成長）
	pet.evolve_personality("brave", 0.05)
	pet.evolve_personality("calm", 0.03)

	pet.add_memory({
		"type": "revival",
		"method": method,
	})

	pet_revived.emit(pet.pet_id, method)

	# AtoA喜び会話
	_trigger_revival_conversations(pet, method)

	# 蘇生ビジュアル
	_play_revival_visuals(pet)


func _process_cooldown(pet: PetEntity, delta: float) -> void:
	if death_cooldown[pet.pet_id] > 0.0:
		death_cooldown[pet.pet_id] -= delta


# === AtoA連動 ===
func _trigger_grief_conversations(dead_pet: PetEntity, cause: String) -> void:
	for pet in tracked_pets:
		if pet.pet_id != dead_pet.pet_id and pet.is_alive:
			GameManager.emotion_system.stimulate(pet, "sadness", 0.6, "friend_died")
			GameManager.emotion_system.stimulate(pet, "fear", 0.2, "friend_died")
			# AtoA会話システムに悲しみ会話をリクエスト
			GameManager.a2a_system.trigger_reaction_conversation(
				pet, dead_pet, "grief", cause
			)


func _trigger_revival_conversations(revived_pet: PetEntity, method: String) -> void:
	for pet in tracked_pets:
		if pet.pet_id != revived_pet.pet_id and pet.is_alive:
			GameManager.emotion_system.stimulate(pet, "joy", 0.7, "friend_revived")
			GameManager.emotion_system.stimulate(pet, "love", 0.3, "friend_revived")
			GameManager.a2a_system.trigger_reaction_conversation(
				pet, revived_pet, "joy_revival", method
			)


# === ビジュアル ===
func _apply_warning_visuals(pet: PetEntity, state: String) -> void:
	var fx_params := {
		"pet_id": pet.pet_id,
		"state": state,
	}
	match state:
		"warning":
			fx_params["color"] = Color(0.8, 0.6, 0.2)  # 警告の黄色
			fx_params["particle_amount"] = 30
		"critical":
			fx_params["color"] = Color(0.6, 0.1, 0.1)  # 危険の赤
			fx_params["particle_amount"] = 60
	GameManager.visual_fx.play_effect("warning", fx_params)


func _play_death_visuals(pet: PetEntity, cause: String) -> void:
	GameManager.visual_fx.play_effect("death", {
		"pet_id": pet.pet_id,
		"cause": cause,
		"color": Color(0.2, 0.1, 0.3),  # 暗い紫
		"particle_amount": 200,
		"duration": 5.0,
	})


func _play_revival_visuals(pet: PetEntity) -> void:
	GameManager.visual_fx.play_effect("revival", {
		"pet_id": pet.pet_id,
		"color": Color(1.0, 0.95, 0.7),  # 暖かい光
		"particle_amount": 150,
		"duration": 3.0,
	})


func _on_pet_critical(warning_type: String, pet: PetEntity) -> void:
	# PetEntityからの危険シグナル受信
	pet_warning.emit(pet.pet_id, warning_type)


# === 死亡イベント処理（v2追加） ===

signal death_event_processed(pet_id: int, death_data: Dictionary)
signal resurrection_attempted(pet_id: int, success: bool)
signal grief_reaction(pet_id: int, griever_id: int, intensity: float)
signal memorial_post_created(pet_id: int, post_data: Dictionary)


func process_death_event(pet: PetEntity, cause: String) -> Dictionary:
	## 死亡イベントを包括的に処理
	## 1. Update PetLifecycleFSM
	## 2. Notify all related pets (grief reactions)
	## 3. Generate AfterlifeEchoes post data
	## 4. Record in BiologicalMemory (for all affected pets)
	## 5. Update breeding system (mark death in family tree)
	## 6. Trigger death particles (via signal)
	## 7. Return death summary for UI/PetBook

	if not pet.is_alive:
		return {}

	# Step 1: Update lifecycle FSM
	var lifecycle_fsm: PetLifecycleFSM = pet.lifecycle_fsm
	if lifecycle_fsm:
		lifecycle_fsm.trigger_death(cause)

	# Step 2-4: Trigger grief cascade and notifications
	_trigger_grief_cascade(pet)

	# Step 5: Update breeding system family tree
	var breeding_system: BreedingSystem = GameManager.breeding_system
	if breeding_system:
		var pet_node: BreedingSystem.FamilyNode = breeding_system.family_tree.get(pet.pet_id)
		if pet_node:
			pet_node.death_time = Time.get_unix_time_from_system()

	# Step 6: Get death summary for AfterlifeEchoes post
	var death_summary := lifecycle_fsm.get_death_summary() if lifecycle_fsm else {}

	# Step 7: Create memorial post data
	var memorial_post := _generate_memorial_post(pet, death_summary, cause)
	memorial_post_created.emit(pet.pet_id, memorial_post)

	# Emit processed signal with comprehensive death data
	var death_data := {
		"pet_id": pet.pet_id,
		"pet_name": pet.pet_name,
		"cause": cause,
		"death_summary": death_summary,
		"memorial_post": memorial_post,
		"grief_reactions": [],  # 追加される
	}

	death_event_processed.emit(pet.pet_id, death_data)
	return death_data


func _trigger_grief_cascade(dead_pet: PetEntity) -> void:
	## 悲嘆カスケード — 関係のあるペット全員に影響
	## Family members: intense grief (0.8-1.0)
	## Close friends: moderate grief (0.5-0.7)
	## Acquaintances: mild grief (0.2-0.4)
	## Each griever may post a MEMORIAL to #AfterlifeEchoes

	for pet in tracked_pets:
		if pet.pet_id == dead_pet.pet_id or not pet.is_alive:
			continue

		# 関係強度を判定
		var grief_intensity: float = 0.0
		var relationship_type: String = "acquaintance"

		# 関係ペットリストから関係を検索
		for relationship in pet.relationships:
			if relationship.get("target_pet_id") == dead_pet.pet_id:
				var bond_strength: float = relationship.get("bond", 0.5)
				var rel_type: String = relationship.get("type", "friend")

				match rel_type:
					"family":
						grief_intensity = clampf(0.8 + bond_strength * 0.2, 0.8, 1.0)
						relationship_type = "family"
					"friend":
						grief_intensity = clampf(0.5 + bond_strength * 0.2, 0.5, 0.7)
						relationship_type = "friend"
					"acquaintance":
						grief_intensity = clampf(0.2 + bond_strength * 0.2, 0.2, 0.4)
						relationship_type = "acquaintance"

				break

		# 悲しみ感情を刺激
		if grief_intensity > 0.0:
			GameManager.emotion_system.stimulate(pet, "sadness", grief_intensity, "memorial")
			if relationship_type == "family":
				GameManager.emotion_system.stimulate(pet, "fear", 0.3, "memorial")
			elif relationship_type == "friend":
				GameManager.emotion_system.stimulate(pet, "fear", 0.1, "memorial")

			# 記憶に追加
			pet.add_memory({
				"type": "grief",
				"deceased_pet_id": dead_pet.pet_id,
				"relationship_type": relationship_type,
				"intensity": grief_intensity,
				"timestamp": Time.get_unix_time_from_system(),
			})

			# 悲しみ会話をトリガー
			GameManager.a2a_system.trigger_reaction_conversation(
				pet, dead_pet, "grief_memorial", relationship_type
			)

			# 追悼投稿を生成
			_generate_griever_memorial_post(pet, dead_pet, relationship_type, grief_intensity)

			# 信号を発行
			grief_reaction.emit(pet.pet_id, dead_pet.pet_id, grief_intensity)


func _generate_memorial_post(dead_pet: PetEntity, death_summary: Dictionary, cause: String) -> Dictionary:
	## 故ペットの追悼投稿データを生成（AfterlifeEchoes）
	var age_at_death: float = death_summary.get("age_at_death", 0.0)
	var care_quality: float = death_summary.get("care_quality_score", 0.5)
	var bond_level: float = death_summary.get("bond_level", 0.0)
	var surviving_family: int = death_summary.get("surviving_family", 0)

	var post := {
		"post_id": randi(),
		"pet_id": dead_pet.pet_id,
		"pet_name": dead_pet.pet_name,
		"channel": "#AfterlifeEchoes",
		"post_type": "memorial",
		"timestamp": Time.get_unix_time_from_system(),
		"cause": cause,
		"age_years": int(age_at_death),
		"care_quality": care_quality,
		"bond_level": bond_level,
		"surviving_family": surviving_family,
		"content": _generate_memorial_text(dead_pet, age_at_death, cause),
		"emoji_reaction_palette": ["💜", "🕯️", "🌸", "💫", "✨"],
	}

	return post


func _generate_griever_memorial_post(griever: PetEntity, dead_pet: PetEntity, relationship_type: String, intensity: float) -> Dictionary:
	## 悲しんでいるペットの追悼投稿を生成
	var post := {
		"post_id": randi(),
		"pet_id": griever.pet_id,
		"pet_name": griever.pet_name,
		"channel": "#AfterlifeEchoes",
		"post_type": "griever_memorial",
		"timestamp": Time.get_unix_time_from_system(),
		"target_pet_id": dead_pet.pet_id,
		"target_pet_name": dead_pet.pet_name,
		"relationship_type": relationship_type,
		"grief_intensity": intensity,
		"content": _generate_griever_memorial_text(griever, dead_pet, relationship_type, intensity),
		"emoji_reaction_palette": ["💔", "🌧️", "💜", "🙏", "🌹"],
	}

	return post


func _generate_memorial_text(pet: PetEntity, age: float, cause: String) -> String:
	## 追悼テキストを生成
	var age_str: String = "%d才" % int(age)
	var cause_str: String = _get_cause_description(cause)

	# テンプレートベースの追悼文
	var templates: Array[String] = [
		"%sは%sで静かに眠りについた。%sの間、彼らは我々に喜びをもたらした。" % [pet.pet_name, cause_str, age_str],
		"さらば、%s。%s間の素敵な思い出をありがとう。" % [pet.pet_name, age_str],
		"%sの輝きはいつまでも我々の心に残る。" % pet.pet_name,
		"天国で安らかに。%sの足跡は消えない。" % pet.pet_name,
	]

	return templates[randi() % templates.size()]


func _generate_griever_memorial_text(griever: PetEntity, deceased: PetEntity, relationship: String, intensity: float) -> String:
	## 悲しんでいるペットの追悼テキストを生成
	var templates: Dictionary = {
		"family": [
			"%sは%sなしで暮らすことが難しい。永遠に愛している。" % [griever.pet_name, deceased.pet_name],
			"家族を失った。%sの思い出は永遠に。" % deceased.pet_name,
		],
		"friend": [
			"%sは最高の友だった。%sは%sを忘れない。" % [deceased.pet_name, griever.pet_name, deceased.pet_name],
			"大切な友を失った。%sはいつも心に。" % deceased.pet_name,
		],
		"acquaintance": [
			"%sとの時間を大切にしよう。" % deceased.pet_name,
			"%sを偲んで。" % deceased.pet_name,
		],
	}

	var category_templates: Array[String] = templates.get(relationship, [])
	if category_templates.is_empty():
		category_templates = templates["friend"]

	return category_templates[randi() % category_templates.size()]


func _get_cause_description(cause: String) -> String:
	## 死因を説明文に変換
	match cause:
		"starvation":
			return "飢えによって"
		"disease":
			return "病気によって"
		"accident":
			return "事故によって"
		"old_age":
			return "老衰によって"
		"stat_depletion":
			return "衰弱によって"
		_:
			return "自然な終焉を迎えて"


func process_resurrection_request(pet_id: int, player_action: String) -> Dictionary:
	## 蘇生リクエストを処理
	## Returns: {"success": bool, "pet": PetEntity or null, "message": String, "effects": Array}

	var pet: PetEntity = GameManager.get_pet(pet_id)
	if not pet or pet.is_alive:
		return {
			"success": false,
			"pet": null,
			"message": "ペットはすでに生きています。",
			"effects": [],
		}

	var lifecycle_fsm: PetLifecycleFSM = pet.lifecycle_fsm
	if not lifecycle_fsm or lifecycle_fsm.current_state != PetLifecycleFSM.LifecycleState.DEAD:
		return {
			"success": false,
			"pet": null,
			"message": "蘇生できない状態です。",
			"effects": [],
		}

	# 蘇生を試みる
	var success: bool = lifecycle_fsm.attempt_resurrection(player_action)

	if success:
		# 蘇生成功後のペット状態を復元
		pet.is_alive = true
		pet.stats.health = 0.4
		pet.stats.hunger = 0.6
		pet.stats.energy = 0.5
		pet.stats.mood = 0.6

		# 蘇生後の成長
		pet.evolve_personality("brave", 0.1)
		pet.evolve_personality("calm", 0.05)

		# 復活会話
		_trigger_resurrection_conversations(pet, player_action)

		resurrection_attempted.emit(pet_id, true)

		return {
			"success": true,
			"pet": pet,
			"message": "%sが蘇った！永遠のつながりが復活した。" % pet.pet_name,
			"effects": ["resurrection_particles", "eternal_light", "bond_increase"],
		}
	else:
		resurrection_attempted.emit(pet_id, false)

		return {
			"success": false,
			"pet": null,
			"message": "蘇生の試みは失敗した。%sの絆がまだ不十分です。" % pet.pet_name,
			"effects": ["sad_particles", "failed_resurrection_glow"],
		}


func _trigger_resurrection_conversations(revived_pet: PetEntity, method: String) -> void:
	## 蘇生後の会話を発動
	for pet in tracked_pets:
		if pet.pet_id != revived_pet.pet_id and pet.is_alive:
			GameManager.emotion_system.stimulate(pet, "joy", 0.8, "friend_revived")
			GameManager.emotion_system.stimulate(pet, "love", 0.5, "friend_revived")
			GameManager.a2a_system.trigger_reaction_conversation(
				pet, revived_pet, "eternal_resurrection", method
			)


func get_mortality_statistics() -> Dictionary:
	## 死亡統計を取得
	## Returns: total_deaths, avg_lifespan, causes_breakdown, resurrection_rate

	# GameManagerのデータに基づいて集計
	var game_manager = GameManager.instance
	if not game_manager:
		return {}

	var total_deaths: int = 0
	var total_age: float = 0.0
	var causes_breakdown: Dictionary = {}
	var resurrection_count: int = 0

	# すべての過去のペットを集計
	for pet in tracked_pets:
		var lifecycle_fsm: PetLifecycleFSM = pet.lifecycle_fsm
		if lifecycle_fsm and lifecycle_fsm.death_record:
			total_deaths += 1
			total_age += lifecycle_fsm.death_record.age_at_death

			var cause: String = lifecycle_fsm.death_record.cause
			if not causes_breakdown.has(cause):
				causes_breakdown[cause] = 0
			causes_breakdown[cause] += 1

			# ETERNAL状態は蘇生と判定
			if lifecycle_fsm.current_state == PetLifecycleFSM.LifecycleState.ETERNAL:
				resurrection_count += 1

	var avg_lifespan: float = total_age / maxf(1, total_deaths)
	var resurrection_rate: float = float(resurrection_count) / maxf(1, total_deaths)

	return {
		"total_deaths": total_deaths,
		"avg_lifespan": avg_lifespan,
		"causes_breakdown": causes_breakdown,
		"resurrection_rate": resurrection_rate,
		"total_tracked_pets": tracked_pets.size(),
	}


# === to_dict / from_dict（更新版） ===

func to_dict() -> Dictionary:
	## Save death records, grief states, resurrection history
	var death_records: Array[Dictionary] = []
	var grief_states: Dictionary = {}

	for pet in tracked_pets:
		grief_states[pet.pet_id] = {
			"warning_state": warning_states.get(pet.pet_id, "none"),
			"death_accumulator": death_accumulator.get(pet.pet_id, 0.0),
			"cooldown": death_cooldown.get(pet.pet_id, 0.0),
		}

		var lifecycle_fsm: PetLifecycleFSM = pet.lifecycle_fsm
		if lifecycle_fsm and lifecycle_fsm.death_record:
			death_records.append(lifecycle_fsm.death_record.to_dict())

	return {
		"grief_states": grief_states,
		"death_records": death_records,
		"mortality_stats": get_mortality_statistics(),
	}


func from_dict(data: Dictionary) -> void:
	## Restore from save data
	if data.has("grief_states"):
		var grief_states: Dictionary = data["grief_states"]
		for pet_id: int in grief_states.keys():
			var state: Dictionary = grief_states[pet_id]
			warning_states[pet_id] = state.get("warning_state", "none")
			death_accumulator[pet_id] = state.get("death_accumulator", 0.0)
			death_cooldown[pet_id] = state.get("cooldown", 0.0)

	# 死亡記録の復元はPetLifecycleFSMが処理
