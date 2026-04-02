## PetTeamOrchestrator -- Multi-Agent Pet Team Coordination
## Pets autonomously form teams, coordinate tasks, and execute group activities.
## Leader selection based on social trait; affinity-aware team formation.
class_name PetTeamOrchestrator
extends Node

signal team_formed(team_id: String, members: Array[int], task: String)
signal team_completed(team_id: String, results: Dictionary)
signal team_disbanded(team_id: String, reason: String)

enum TaskType { EXPLORATION, TEACHING, CAREGIVING, EVENT_PLANNING, LANGUAGE_PROJECT, PATROL }

const TEAM_CHECK_INTERVAL: float = 240.0
const MAX_CONCURRENT_TEAMS: int = 3
const MAX_DAILY_FORMATIONS: int = 10
const MIN_TEAM_SIZE: int = 2
const MAX_TEAM_SIZE: int = 4
const TASK_DURATIONS: Dictionary = {
	TaskType.EXPLORATION: 120.0, TaskType.TEACHING: 90.0,
	TaskType.CAREGIVING: 60.0, TaskType.EVENT_PLANNING: 180.0,
	TaskType.LANGUAGE_PROJECT: 150.0, TaskType.PATROL: 80.0,
}
const FORMATION_TEMPLATES: Array[String] = [
	"%s formed a team with %s for %s!",
	"Team assembled! %s leads %s on a %s mission.",
	"%s rallied %s together. Time for %s!",
	"A new squad! %s and %s set out for %s.",
	"%s organized a %s crew: %s joining forces!",
	"Adventure awaits! %s brought %s along for %s.",
]
const COMPLETION_TEMPLATES: Array[String] = [
	"%s's team completed their %s mission! %s",
	"Mission accomplished! %s and crew finished %s. %s",
	"Team %s wrapped up %s with great results. %s",
	"Success! %s led the %s effort to completion. %s",
	"%s's squad returned from %s triumphant! %s",
	"The %s team (%s) finished strong. %s",
]

var active_teams: Dictionary = {}  # team_id -> team Dictionary
var completed_teams: Array[Dictionary] = []
var _check_timer: float = 0.0
var _next_team_id: int = 0
var _daily_formation_count: int = 0
var _last_reset_day: String = ""


func _ready() -> void:
	_last_reset_day = Time.get_date_string_from_system()


func _process(delta: float) -> void:
	if not GameManager.instance or GameManager.instance.is_paused:
		return
	var today: String = Time.get_date_string_from_system()
	if today != _last_reset_day:
		_last_reset_day = today
		_daily_formation_count = 0
	_check_timer += delta
	if _check_timer >= TEAM_CHECK_INTERVAL:
		_check_timer = 0.0
		_try_form_team()
	_update_active_teams(delta)


# === Team Formation ===

func _try_form_team() -> void:
	if active_teams.size() >= MAX_CONCURRENT_TEAMS or _daily_formation_count >= MAX_DAILY_FORMATIONS:
		return
	var idle_pets: Array[int] = _get_idle_alive_pet_ids()
	if idle_pets.size() < MIN_TEAM_SIZE:
		return

	var task_type: TaskType = _select_task(idle_pets)
	var team_size: int = mini(idle_pets.size(), randi_range(MIN_TEAM_SIZE, MAX_TEAM_SIZE))
	var members: Array[int] = _select_members(idle_pets, team_size)
	if members.size() < MIN_TEAM_SIZE:
		return

	var leader_id: int = _choose_leader(members)
	var tid: String = "team_%d" % _next_team_id
	_next_team_id += 1
	_daily_formation_count += 1
	var task_name: String = TaskType.keys()[task_type]

	var team_data: Dictionary = {
		"team_id": tid, "members": members, "leader_id": leader_id,
		"task": task_name, "task_type": task_type, "status": "active",
		"created_at": Time.get_unix_time_from_system(), "completed_at": 0.0,
		"duration": TASK_DURATIONS.get(task_type, 120.0), "elapsed": 0.0,
	}
	active_teams[tid] = team_data
	team_formed.emit(tid, members, task_name)
	_post_to_petbook(team_data, FORMATION_TEMPLATES, "excitement")
	print("[TeamOrchestrator] Team %s: %s leader=%d members=%s" % [tid, task_name, leader_id, str(members)])


func _get_idle_alive_pet_ids() -> Array[int]:
	var gm: Node = GameManager.instance
	if not gm:
		return []
	var busy_ids: Dictionary = {}
	for tid: String in active_teams:
		for mid: int in active_teams[tid].get("members", []):
			busy_ids[mid] = true
	var idle: Array[int] = []
	for pet: Node in gm.get_all_pets():
		if pet.is_alive and not busy_ids.has(pet.pet_id):
			idle.append(pet.pet_id)
	return idle


func _select_members(candidates: Array[int], size: int) -> Array[int]:
	if candidates.size() <= size:
		return candidates.duplicate()
	var selected: Array[int] = []
	var pool: Array[int] = candidates.duplicate()
	pool.shuffle()
	selected.append(pool.pop_back())
	while selected.size() < size and not pool.is_empty():
		var best_id: int = pool[0]
		var best_score: float = -1.0
		for cid: int in pool:
			var score: float = 0.0
			for gid: int in selected:
				score += _get_affinity(cid, gid)
			score /= selected.size()
			if score > best_score:
				best_score = score
				best_id = cid
		selected.append(best_id)
		pool.erase(best_id)
	return selected


func _get_affinity(pet1_id: int, pet2_id: int) -> float:
	var gm: Node = GameManager.instance
	if not gm or not gm.a2a_system:
		return 0.3
	var key: String = "%d_%d" % [mini(pet1_id, pet2_id), maxi(pet1_id, pet2_id)]
	return gm.a2a_system.pet_relationships.get(key, {}).get("affinity", 0.3)


func _choose_leader(members: Array[int]) -> int:
	var gm: Node = GameManager.instance
	if not gm:
		return members[0]
	var best_id: int = members[0]
	var best_social: float = -1.0
	for pid: int in members:
		var pet: Node = gm.get_pet_by_id(pid)
		if not pet:
			continue
		var social: float = pet.personality.get("affectionate", 0.5) + pet.personality.get("playful", 0.5)
		if social > best_social:
			best_social = social
			best_id = pid
	return best_id


func _select_task(idle_pets: Array[int]) -> TaskType:
	var gm: Node = GameManager.instance
	if not gm:
		return TaskType.EXPLORATION
	var has_young: bool = false
	var high_energy: int = 0
	var has_low_stat: bool = false
	for pid: int in idle_pets:
		var pet: Node = gm.get_pet_by_id(pid)
		if not pet:
			continue
		if pet.evolution_stage <= 1:
			has_young = true
		if pet.stats.energy > 0.7:
			high_energy += 1
		if pet.stats.hunger < 0.3 or pet.stats.energy < 0.3:
			has_low_stat = true
	if has_young:
		return TaskType.TEACHING
	if has_low_stat:
		return TaskType.CAREGIVING
	if high_energy >= 2:
		return TaskType.EXPLORATION
	var options: Array[TaskType] = [
		TaskType.EXPLORATION, TaskType.EVENT_PLANNING,
		TaskType.LANGUAGE_PROJECT, TaskType.PATROL,
	]
	return options[randi() % options.size()]


# === Team Update & Completion ===

func _update_active_teams(delta: float) -> void:
	var to_complete: Array[String] = []
	for tid: String in active_teams:
		var team: Dictionary = active_teams[tid]
		if team.get("status") != "active":
			continue
		team["elapsed"] = team.get("elapsed", 0.0) + delta
		if team["elapsed"] >= team.get("duration", 120.0):
			to_complete.append(tid)
	for tid: String in to_complete:
		_complete_team(tid)


func _complete_team(tid: String) -> void:
	if not active_teams.has(tid):
		return
	var team: Dictionary = active_teams[tid]
	team["status"] = "completed"
	team["completed_at"] = Time.get_unix_time_from_system()
	var results: Dictionary = _apply_rewards(team)
	completed_teams.append(team)
	active_teams.erase(tid)
	team_completed.emit(tid, results)
	_post_to_petbook(team, COMPLETION_TEMPLATES, "joy", results)
	print("[TeamOrchestrator] Team %s completed %s" % [tid, team.get("task", "")])


func disband_team(tid: String, reason: String) -> void:
	if not active_teams.has(tid):
		return
	active_teams[tid]["status"] = "disbanded"
	active_teams.erase(tid)
	team_disbanded.emit(tid, reason)


# === Reward Application ===

func _apply_rewards(team: Dictionary) -> Dictionary:
	var gm: Node = GameManager.instance
	if not gm:
		return {}
	var task_type: int = team.get("task_type", TaskType.EXPLORATION)
	var members: Array = team.get("members", [])
	var leader_id: int = team.get("leader_id", -1)
	var results: Dictionary = {"task": team.get("task", ""), "rewards": []}

	match task_type:
		TaskType.EXPLORATION:
			for pid: int in members:
				var pet: Node = gm.get_pet_by_id(pid)
				if pet and pet.is_alive:
					pet.blend_emotion("excitement", 0.15)
					pet.evolve_personality("curious", 0.02)
			results["rewards"].append("curiosity_boost")
			if randf() < 0.3 and gm.original_language and gm.original_language.has_method("attempt_word_invention"):
				gm.original_language.attempt_word_invention(leader_id, "exploration")
				results["rewards"].append("word_discovery")

		TaskType.TEACHING:
			for i: int in range(members.size()):
				for j: int in range(i + 1, members.size()):
					_boost_affinity(members[i], members[j], 0.05)
			if gm.original_language and gm.original_language.has_method("share_vocabulary"):
				for pid: int in members:
					if pid != leader_id:
						gm.original_language.share_vocabulary(leader_id, pid)
			results["rewards"].append("affinity_boost")
			results["rewards"].append("vocabulary_shared")

		TaskType.CAREGIVING:
			for pid: int in members:
				var pet: Node = gm.get_pet_by_id(pid)
				if pet and pet.is_alive:
					pet.stats.modify("hunger", 0.15)
					pet.stats.modify("energy", 0.1)
			results["rewards"].append("stats_recovery")

		TaskType.EVENT_PLANNING:
			if gm.a2a_community:
				gm.a2a_community.community_event.emit("team_cultural_event", {
					"members": members, "leader": leader_id,
				})
			results["rewards"].append("cultural_event_triggered")

		TaskType.LANGUAGE_PROJECT:
			if gm.original_language and gm.original_language.has_method("create_compound_word"):
				gm.original_language.create_compound_word(members.duplicate())
				results["rewards"].append("compound_word_created")

		TaskType.PATROL:
			for pid: int in members:
				var pet: Node = gm.get_pet_by_id(pid)
				if pet and pet.is_alive:
					pet.evolve_personality("brave", 0.02)
					pet.stats.modify("energy", 0.05)
					pet.stats.modify("health", 0.05)
			results["rewards"].append("bravery_boost")

	return results


func _boost_affinity(pet1_id: int, pet2_id: int, amount: float) -> void:
	var gm: Node = GameManager.instance
	if not gm or not gm.a2a_system:
		return
	var key: String = "%d_%d" % [mini(pet1_id, pet2_id), maxi(pet1_id, pet2_id)]
	if key in gm.a2a_system.pet_relationships:
		gm.a2a_system.pet_relationships[key]["affinity"] = minf(
			1.0, gm.a2a_system.pet_relationships[key].get("affinity", 0.3) + amount)


# === PetBook Integration ===

func _post_to_petbook(team: Dictionary, templates: Array[String], emotion: String, results: Dictionary = {}) -> void:
	var gm: Node = GameManager.instance
	if not gm or not gm.pet_book:
		return
	var leader: Node = gm.get_pet_by_id(team.get("leader_id", -1))
	if not leader:
		return
	var member_names: Array[String] = []
	for pid: int in team.get("members", []):
		var p: Node = gm.get_pet_by_id(pid)
		if p and (not results.is_empty() or pid != leader.pet_id):
			member_names.append(p.pet_name)
	var names_str: String = " & ".join(member_names) if not member_names.is_empty() else "the team"
	var task_str: String = team.get("task", "mission").to_lower().replace("_", " ")
	var third: String = ", ".join(results.get("rewards", [])) if not results.is_empty() else task_str
	# For formation templates, third arg is task_str; for completion, it is reward_str
	if results.is_empty():
		third = task_str
	var tpl: String = templates[randi() % templates.size()]
	var content: String = tpl % [leader.pet_name, names_str, third]
	gm.pet_book.publish_conversation_post({
		"author_id": leader.pet_id, "author_name": leader.pet_name,
		"content": content, "post_type": "team_activity",
		"emotion": emotion, "partner_id": 0,
		"timestamp": Time.get_unix_time_from_system(),
	})


# === Public API ===

func get_active_teams() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for tid: String in active_teams:
		result.append(active_teams[tid].duplicate())
	return result


func get_team_by_id(tid: String) -> Dictionary:
	return active_teams.get(tid, {})


func get_pet_team(pet_id: int) -> Dictionary:
	for tid: String in active_teams:
		if pet_id in active_teams[tid].get("members", []):
			return active_teams[tid]
	return {}


# === Persistence ===

func to_dict() -> Dictionary:
	return {
		"active_teams": active_teams.duplicate(true),
		"completed_teams": completed_teams.duplicate(true),
		"next_team_id": _next_team_id,
		"daily_formation_count": _daily_formation_count,
		"last_reset_day": _last_reset_day,
	}


func from_dict(data: Dictionary) -> void:
	active_teams = data.get("active_teams", {})
	completed_teams = data.get("completed_teams", [])
	_next_team_id = data.get("next_team_id", 0)
	_daily_formation_count = data.get("daily_formation_count", 0)
	_last_reset_day = data.get("last_reset_day", "")
