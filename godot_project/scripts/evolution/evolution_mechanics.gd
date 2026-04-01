## EvolutionMechanics — ペットの進化分岐・進化ツリーを管理
## Care Misses + 環境 + 性格 + AtoA関係性 + 年齢で進化ルートが決まる
## たまごっち/デジモン/ポケモンの進化チャートを統合分析した5段階システム
class_name EvolutionMechanics
extends Node

signal evolution_available(pet_id: int, options: Array[Dictionary])
signal evolution_completed(pet_id: int, new_form: String, reason: String)
signal dark_evolution_triggered(pet_id: int, form: String)

# === Care Misses トラッキング ===
# たまごっち直系: 世話のミス回数が進化ルートを左右する
var care_misses: Dictionary = {}     # pet_id → int（累積ミス回数）
var care_miss_window: Dictionary = {}  # pet_id → Array[float] (ミス発生時刻)

# === State ===
var pet_forms: Dictionary = {}  # pet_id → current form name
var pet_evolution_history: Dictionary = {}  # pet_id → Array of past forms
var pet_a2a_counts: Dictionary = {}  # pet_id → int (累積AtoA会話回数)


# ========================================================
# Care Misses 管理
# ========================================================

func record_care_miss(pet_id: int) -> void:
	## 世話のミス（空腹無視、病気無視など）を記録
	care_misses[pet_id] = care_misses.get(pet_id, 0) + 1
	var window: Array = care_miss_window.get(pet_id, [])
	window.append(Time.get_unix_time_from_system())
	care_miss_window[pet_id] = window
	print("[Evolution] Pet %d care miss recorded (total: %d)" % [pet_id, care_misses[pet_id]])


func get_care_quality(pet_id: int) -> String:
	## たまごっち方式: ミス回数でケア品質を判定
	var misses: int = care_misses.get(pet_id, 0)
	if misses <= EvolutionTree.CARE_QUALITY_THRESHOLDS["excellent"]:
		return "excellent"
	elif misses <= EvolutionTree.CARE_QUALITY_THRESHOLDS["good"]:
		return "good"
	elif misses <= EvolutionTree.CARE_QUALITY_THRESHOLDS["average"]:
		return "average"
	else:
		return "poor"


func record_a2a_conversation(pet_id: int) -> void:
	pet_a2a_counts[pet_id] = pet_a2a_counts.get(pet_id, 0) + 1


# ========================================================
# 進化判定（EvolutionTree データ使用）
# ========================================================

func check_evolution(pet: PetEntity) -> void:
	## PetEntityのevolution_stageが変わるタイミングで呼ばれる
	var target_stage := pet.evolution_stage

	# 年齢チェック
	var min_age: float = EvolutionTree.MIN_AGE_FOR_STAGE.get(target_stage, 0.0)
	if pet.age < min_age:
		return

	# 進化準備度チェック
	if pet.stats.evolution_readiness < EvolutionTree.READINESS_THRESHOLD:
		return

	# EvolutionTree から候補パスを取得
	var all_paths := EvolutionTree.get_paths_for_stage(target_stage)
	if all_paths.is_empty():
		return

	# 各パスの条件をチェック
	var available_paths: Array[Dictionary] = []
	for path in all_paths:
		if _check_tree_conditions(pet, path):
			available_paths.append(path)

	if available_paths.is_empty():
		_apply_default_evolution(pet)
		return

	if available_paths.size() == 1:
		_apply_tree_evolution(pet, available_paths[0])
	else:
		evolution_available.emit(pet.pet_id, available_paths)
		var best := _select_best_tree_path(pet, available_paths)
		_apply_tree_evolution(pet, best)


func _check_tree_conditions(pet: PetEntity, path: Dictionary) -> bool:
	var conditions: Dictionary = path.get("conditions", {})
	var care_qual := get_care_quality(pet.pet_id)

	for key in conditions:
		var val = conditions[key]
		match key:
			"primary_environment":
				if pet.current_environment != val:
					return false
			"care_quality":
				if not _care_quality_meets(care_qual, val):
					return false
			"personality_primary":
				var threshold: float = conditions.get("personality_threshold",
					conditions.get("primary_threshold", 0.6))
				if pet.personality.get(val, 0.0) < threshold:
					return false
			"personality_secondary":
				var threshold: float = conditions.get("secondary_threshold", 0.5)
				if pet.personality.get(val, 0.0) < threshold:
					return false
			"personality_threshold", "primary_threshold", "secondary_threshold":
				pass  # 上のprimaryで処理済み
			"personality_balance":
				if val:
					for trait in pet.personality:
						if pet.personality[trait] < 0.4:
							return false
			"a2a_conversation_count_min", "total_a2a_conversations_min":
				if pet_a2a_counts.get(pet.pet_id, 0) < val:
					return false
			"relationship_avg_min":
				if GameManager.instance and GameManager.instance.persistent_field:
					var avg := _get_avg_relationship(pet.pet_id)
					if avg < val:
						return false
			"relationship_max_below":
				if GameManager.instance and GameManager.instance.persistent_field:
					var max_rel := _get_max_relationship(pet.pet_id)
					if max_rel >= val:
						return false
			"affection_stat_min":
				if pet.stats.affection < val:
					return false
			"min_age_hours":
				if pet.age < val:
					return false
			"language_vocabulary_min":
				if GameManager.instance and GameManager.instance.original_language:
					var vocab: Dictionary = GameManager.instance.original_language.get_full_vocabulary()
					if vocab.size() < val:
						return false
			"previous_form_dark":
				if val:
					if not _has_dark_history(pet.pet_id):
						return false
	return true


func _care_quality_meets(actual: String, required: String) -> bool:
	## actualがrequired以上の品質かチェック
	var levels := ["poor", "average", "good", "excellent"]
	return levels.find(actual) >= levels.find(required)


func _select_best_tree_path(pet: PetEntity, paths: Array[Dictionary]) -> Dictionary:
	var best_path := paths[0]
	var best_score := -1.0

	for path in paths:
		var score := 0.0
		var conditions: Dictionary = path.get("conditions", {})

		# 性格適合度
		var primary_trait: String = conditions.get("personality_primary", "")
		if primary_trait in pet.personality:
			score += pet.personality[primary_trait] * 2.0

		var secondary_trait: String = conditions.get("personality_secondary", "")
		if secondary_trait in pet.personality:
			score += pet.personality[secondary_trait]

		# 環境一致ボーナス
		if conditions.has("primary_environment"):
			if pet.current_environment == conditions["primary_environment"]:
				score += 1.0

		# Care Quality ボーナス
		var care_qual := get_care_quality(pet.pet_id)
		match care_qual:
			"excellent": score += 0.5
			"good": score += 0.2

		# ダークルートはスコア低め（意図的でない限り選ばれにくい）
		if path.get("is_dark_route", false):
			score -= 0.3

		# スペシャルルートはボーナス
		if path.get("is_special", false):
			score += 0.5

		if score > best_score:
			best_score = score
			best_path = path

	return best_path


func _apply_tree_evolution(pet: PetEntity, path: Dictionary) -> void:
	## EvolutionTree パスデータに基づく進化適用
	var form_id: String = path["id"]
	var display_name: String = path.get("display_name", form_id)
	var is_dark: bool = path.get("is_dark_route", false)

	pet_forms[pet.pet_id] = form_id

	# 進化履歴に記録
	if pet.pet_id not in pet_evolution_history:
		pet_evolution_history[pet.pet_id] = []
	pet_evolution_history[pet.pet_id].append({
		"form": form_id,
		"display_name": display_name,
		"stage": pet.evolution_stage,
		"age": pet.age,
		"is_dark": is_dark,
		"timestamp": Time.get_unix_time_from_system(),
	})

	# ステータスボーナス適用
	for stat in path.get("stat_bonus", {}):
		pet.stats.modify(stat, path["stat_bonus"][stat])

	# unlock_trait があれば性格に反映
	var unlock_trait: String = path.get("unlock_trait", "")
	if unlock_trait != "":
		pet.personality[unlock_trait] = max(
			pet.personality.get(unlock_trait, 0.0), 0.5
		)

	# 進化準備度リセット
	pet.stats.evolution_readiness = 0.0

	# 記憶に記録
	pet.add_memory({
		"type": "evolution",
		"form": form_id,
		"display": display_name,
		"description": path.get("description", ""),
		"stage": pet.evolution_stage,
		"is_dark": is_dark,
	})

	# 感情刺激 — ダーク進化は異なる感情パターン
	if GameManager.instance and GameManager.instance.emotion_system:
		if is_dark:
			GameManager.instance.emotion_system.stimulate(pet, "fear", 0.3, "dark_evolution")
			GameManager.instance.emotion_system.stimulate(pet, "excitement", 0.5, "dark_evolution")
			dark_evolution_triggered.emit(pet.pet_id, form_id)
		else:
			GameManager.instance.emotion_system.stimulate(pet, "joy", 0.5, "evolution")
			GameManager.instance.emotion_system.stimulate(pet, "excitement", 0.4, "evolution")

	evolution_completed.emit(pet.pet_id, form_id, display_name)

	# ビジュアルエフェクト
	var particle_amount := 500 if is_dark else 300
	var duration := 6.0 if pet.evolution_stage >= 4 else 4.0
	var effect_color := Color.DARK_VIOLET if is_dark else Color.WHITE
	if GameManager.instance and GameManager.instance.emotion_system:
		effect_color = GameManager.instance.emotion_system.get_emotion_color(pet)

	if GameManager.instance and GameManager.instance.visual_fx:
		GameManager.instance.visual_fx.play_effect("evolution", {
			"pet_id": pet.pet_id,
			"form": form_id,
			"particle_amount": particle_amount,
			"duration": duration,
			"color": effect_color,
			"visual": path.get("visual", {}),
			"is_dark": is_dark,
			"is_special": path.get("is_special", false),
		})

	# Care Missesリセット（次のステージ用に）
	care_misses[pet.pet_id] = 0
	care_miss_window[pet.pet_id] = []

	print("[Evolution] Pet %d evolved to '%s' (%s) at stage %d" % [
		pet.pet_id, display_name, form_id, pet.evolution_stage
	])


func _apply_default_evolution(pet: PetEntity) -> void:
	## 条件に合うパスが無い場合のフォールバック進化
	var default_form := "basic_stage_%d" % pet.evolution_stage
	pet_forms[pet.pet_id] = default_form

	if pet.pet_id not in pet_evolution_history:
		pet_evolution_history[pet.pet_id] = []
	pet_evolution_history[pet.pet_id].append({
		"form": default_form,
		"display_name": "基本進化",
		"stage": pet.evolution_stage,
		"age": pet.age,
		"is_dark": false,
		"timestamp": Time.get_unix_time_from_system(),
	})

	pet.stats.evolution_readiness = 0.0
	care_misses[pet.pet_id] = 0
	care_miss_window[pet.pet_id] = []

	evolution_completed.emit(pet.pet_id, default_form, "基本進化")
	print("[Evolution] Pet %d → default form '%s'" % [pet.pet_id, default_form])


# ========================================================
# ヘルパー: 関係性・ダーク履歴
# ========================================================

func _has_dark_history(pet_id: int) -> bool:
	## 過去の進化にダークルートが含まれるか
	var history: Array = pet_evolution_history.get(pet_id, [])
	for entry in history:
		if entry.get("is_dark", false):
			return true
	return false


func _get_avg_relationship(pet_id: int) -> float:
	## PersistentField の relationship_graph から平均関係値を取得
	if not GameManager.instance or not GameManager.instance.persistent_field:
		return 0.5
	var pf := GameManager.instance.persistent_field
	var graph: Dictionary = pf.field_state.get("relationship_graph", {})
	if graph.is_empty():
		return 0.5

	var total := 0.0
	var count := 0
	for key in graph:
		var ids := key.split("_")
		if ids.size() == 2:
			var id1 := int(ids[0])
			var id2 := int(ids[1])
			if id1 == pet_id or id2 == pet_id:
				total += graph[key].get("score", 0.5)
				count += 1

	return total / float(count) if count > 0 else 0.5


func _get_max_relationship(pet_id: int) -> float:
	## pet_id の最も高い関係スコアを返す
	if not GameManager.instance or not GameManager.instance.persistent_field:
		return 0.0
	var pf := GameManager.instance.persistent_field
	var graph: Dictionary = pf.field_state.get("relationship_graph", {})

	var max_score := 0.0
	for key in graph:
		var ids := key.split("_")
		if ids.size() == 2:
			var id1 := int(ids[0])
			var id2 := int(ids[1])
			if id1 == pet_id or id2 == pet_id:
				var s: float = graph[key].get("score", 0.0)
				if s > max_score:
					max_score = s
	return max_score


# ========================================================
# 公開API
# ========================================================

func get_current_form(pet_id: int) -> String:
	return pet_forms.get(pet_id, "egg")


func get_evolution_history(pet_id: int) -> Array:
	return pet_evolution_history.get(pet_id, [])


func get_available_forms_for_stage(stage: int) -> Array[Dictionary]:
	## UIツリー表示用: 指定ステージの全進化パスを返す
	return EvolutionTree.get_paths_for_stage(stage)


func get_evolution_progress(pet: PetEntity) -> Dictionary:
	## UI用: ペットの現在の進化進捗情報
	var next_stage := pet.evolution_stage + 1
	var min_age: float = EvolutionTree.MIN_AGE_FOR_STAGE.get(next_stage, 999.0)
	var care_qual := get_care_quality(pet.pet_id)
	var readiness: float = pet.stats.evolution_readiness
	var all_paths := EvolutionTree.get_paths_for_stage(next_stage)

	# 現在の条件で到達可能なパスを列挙
	var reachable: Array[String] = []
	for path in all_paths:
		if _check_tree_conditions(pet, path):
			reachable.append(path["id"])

	return {
		"current_form": get_current_form(pet.pet_id),
		"current_stage": pet.evolution_stage,
		"next_stage": next_stage,
		"age": pet.age,
		"min_age_for_next": min_age,
		"age_ready": pet.age >= min_age,
		"readiness": readiness,
		"readiness_threshold": EvolutionTree.READINESS_THRESHOLD,
		"care_quality": care_qual,
		"care_misses": care_misses.get(pet.pet_id, 0),
		"a2a_conversations": pet_a2a_counts.get(pet.pet_id, 0),
		"has_dark_history": _has_dark_history(pet.pet_id),
		"reachable_forms": reachable,
		"total_forms_next_stage": all_paths.size(),
	}


# ========================================================
# セーブ / ロード
# ========================================================

func to_dict() -> Dictionary:
	return {
		"pet_forms": pet_forms.duplicate(),
		"pet_evolution_history": pet_evolution_history.duplicate(true),
		"care_misses": care_misses.duplicate(),
		"care_miss_window": care_miss_window.duplicate(true),
		"pet_a2a_counts": pet_a2a_counts.duplicate(),
	}


func from_dict(data: Dictionary) -> void:
	pet_forms = data.get("pet_forms", {})
	pet_evolution_history = data.get("pet_evolution_history", {})
	care_misses = data.get("care_misses", {})
	care_miss_window = data.get("care_miss_window", {})
	pet_a2a_counts = data.get("pet_a2a_counts", {})
