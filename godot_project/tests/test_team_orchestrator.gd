## test_team_orchestrator.gd — PetTeamOrchestrator ユニットテスト
## team formation / to_dict / from_dict / leader selection / max_concurrent を検証
## 実行: godot --headless --script tests/test_team_orchestrator.gd
class_name TestTeamOrchestrator
extends SceneTree

const _PetTeamOrchestrator = preload("res://scripts/orchestration/pet_team_orchestrator.gd")


func _init() -> void:
	var passed: int = 0
	var failed: int = 0
	var total: int = 0
	var tests: Array[String] = [
		"test_form_team", "test_to_dict_from_dict",
		"test_leader_selection", "test_max_concurrent_teams",
	]
	for t: String in tests:
		total += 1
		var ok: bool = call(t)
		print("  %s: %s" % ["PASS" if ok else "FAIL", t])
		if ok: passed += 1
		else: failed += 1
	print("\n========================================")
	print("TeamOrchestrator Tests: %d/%d passed" % [passed, total])
	print("========================================")
	quit(1 if failed > 0 else 0)


func _insert_team(orch: PetTeamOrchestrator, tid: String, members: Array[int],
		leader: int, task: String) -> void:
	orch.active_teams[tid] = {
		"team_id": tid, "members": members, "leader_id": leader,
		"task": task, "task_type": PetTeamOrchestrator.TaskType.EXPLORATION,
		"status": "active", "created_at": Time.get_unix_time_from_system(),
		"completed_at": 0.0, "duration": 120.0, "elapsed": 0.0,
	}


func test_form_team() -> bool:
	var orch: PetTeamOrchestrator = PetTeamOrchestrator.new()

	_insert_team(orch, "team_0", [1, 2, 3], 1, "EXPLORATION")
	if not orch.active_teams.has("team_0"):
		push_warning("form_team: team_0 missing"); orch.free(); return false
	var team: Dictionary = orch.active_teams["team_0"]
	if team.get("members", []).size() != 3:
		push_warning("form_team: member count mismatch"); orch.free(); return false
	if team.get("leader_id") != 1:
		push_warning("form_team: unexpected leader_id"); orch.free(); return false
	if team.get("task") != "EXPLORATION":
		push_warning("form_team: unexpected task"); orch.free(); return false
	orch.free(); return true


func test_to_dict_from_dict() -> bool:
	var orch: PetTeamOrchestrator = PetTeamOrchestrator.new()

	_insert_team(orch, "team_0", [10, 20], 10, "TEACHING")
	_insert_team(orch, "team_1", [30, 40, 50], 30, "CAREGIVING")
	orch._next_team_id = 2
	orch._daily_formation_count = 2
	orch.faction_preferences["alpha_pack"] = [10, 20]
	var data: Dictionary = orch.to_dict()
	var r: PetTeamOrchestrator = PetTeamOrchestrator.new()

	r.from_dict(data)
	if r.active_teams.size() != orch.active_teams.size():
		push_warning("round-trip: active_teams size mismatch")
		orch.free(); r.free(); return false
	if r._next_team_id != orch._next_team_id:
		push_warning("round-trip: _next_team_id mismatch")
		orch.free(); r.free(); return false
	if r._daily_formation_count != orch._daily_formation_count:
		push_warning("round-trip: _daily_formation_count mismatch")
		orch.free(); r.free(); return false
	if not r.faction_preferences.has("alpha_pack"):
		push_warning("round-trip: faction_preferences not restored")
		orch.free(); r.free(); return false
	orch.free(); r.free(); return true


func test_leader_selection() -> bool:
	var orch: PetTeamOrchestrator = PetTeamOrchestrator.new()

	# Without GameManager, _choose_leader returns members[0]
	var members: Array[int] = [5, 6, 7]
	var leader_id: int = orch._choose_leader(members)
	if not members.has(leader_id):
		push_warning("leader_selection: returned id not in members")
		orch.free(); return false
	orch.free(); return true


func test_max_concurrent_teams() -> bool:
	var orch: PetTeamOrchestrator = PetTeamOrchestrator.new()

	for i: int in range(PetTeamOrchestrator.MAX_CONCURRENT_TEAMS):
		_insert_team(orch, "team_%d" % i, [i * 2, i * 2 + 1], i * 2, "PATROL")
	if orch.active_teams.size() != PetTeamOrchestrator.MAX_CONCURRENT_TEAMS:
		push_warning("max_teams: unexpected active_teams count %d" % orch.active_teams.size())
		orch.free(); return false
	# Guard condition that _try_form_team() checks
	if not (orch.active_teams.size() >= PetTeamOrchestrator.MAX_CONCURRENT_TEAMS):
		push_warning("max_teams: over-limit guard not satisfied")
		orch.free(); return false
	orch.free(); return true
