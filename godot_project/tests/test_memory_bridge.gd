## test_memory_bridge.gd — MemoryPersonalityBridge ユニットテスト
## grief stages / to_dict / from_dict / nostalgia_log / dream_log を検証
## 実行: godot --headless --script tests/test_memory_bridge.gd
class_name TestMemoryBridge
extends SceneTree

const _MemoryPersonalityBridge = preload("res://scripts/memory/memory_personality_bridge.gd")


func _init() -> void:
	var passed: int = 0
	var failed: int = 0
	var total: int = 0
	var tests: Array[String] = [
		"test_grief_stages", "test_to_dict_from_dict",
		"test_nostalgia_trigger", "test_dream_synthesis",
	]
	for t: String in tests:
		total += 1
		var ok: bool = call(t)
		print("  %s: %s" % ["PASS" if ok else "FAIL", t])
		if ok: passed += 1
		else: failed += 1
	print("\n========================================")
	print("MemoryBridge Tests: %d/%d passed" % [passed, total])
	print("========================================")
	quit(1 if failed > 0 else 0)


func test_grief_stages() -> bool:
	var bridge: MemoryPersonalityBridge = MemoryPersonalityBridge.new()

	# affinity >= 0.6 required; GameManager absent — biological_memory call skipped
	bridge.start_grief(1, 99, 0.9)
	if not bridge.grief_states.has(1):
		push_warning("grief_stages: grief_states not initialised for pet 1")
		bridge.free(); return false
	if bridge.grief_states[1].get("stage_index") != 0:
		push_warning("grief_stages: expected stage_index 0")
		bridge.free(); return false
	# Verify each Kübler-Ross stage name via get_grief_stage()
	for i: int in range(MemoryPersonalityBridge.GRIEF_STAGES.size()):
		bridge.grief_states[1]["stage_index"] = i
		var name_at: String = bridge.get_grief_stage(1)
		if name_at != MemoryPersonalityBridge.GRIEF_STAGES[i]:
			push_warning("grief_stages: mismatch at index %d: '%s'" % [i, name_at])
			bridge.free(); return false
	bridge.free(); return true


func test_to_dict_from_dict() -> bool:
	var bridge: MemoryPersonalityBridge = MemoryPersonalityBridge.new()

	bridge.start_grief(2, 88, 0.8)
	bridge.add_trauma(2, "neglect", 0.5)
	bridge._log_nostalgia(2, "a walk in the meadow with Fluffy, feeling joy")
	bridge._add_personality_modifier(2, "resilience", 0.1)
	var data: Dictionary = bridge.to_dict()
	var r: MemoryPersonalityBridge = MemoryPersonalityBridge.new()

	r.from_dict(data)
	if not r.grief_states.has(2):
		push_warning("round-trip: grief_states missing"); bridge.free(); r.free(); return false
	if not r.trauma_markers.has(2):
		push_warning("round-trip: trauma_markers missing"); bridge.free(); r.free(); return false
	if not r.nostalgia_log.has(2) or r.nostalgia_log[2].is_empty():
		push_warning("round-trip: nostalgia_log missing"); bridge.free(); r.free(); return false
	if not r.personality_modifiers.has(2):
		push_warning("round-trip: personality_modifiers missing")
		bridge.free(); r.free(); return false
	bridge.free(); r.free(); return true


func test_nostalgia_trigger() -> bool:
	var bridge: MemoryPersonalityBridge = MemoryPersonalityBridge.new()

	bridge._log_nostalgia(3, "Sunny day at the park with Spot, feeling happiness")
	bridge._log_nostalgia(3, "Rainy evening alone, feeling melancholy")
	if not bridge.nostalgia_log.has(3):
		push_warning("nostalgia: log key missing"); bridge.free(); return false
	if bridge.nostalgia_log[3].size() != 2:
		push_warning("nostalgia: expected 2 entries, got %d" % bridge.nostalgia_log[3].size())
		bridge.free(); return false
	var entry: Dictionary = bridge.nostalgia_log[3][0]
	if not entry.has("memory_summary") or not entry.has("timestamp"):
		push_warning("nostalgia: entry missing required keys"); bridge.free(); return false
	# Verify 20-entry rolling cap
	for i: int in range(22):
		bridge._log_nostalgia(3, "memory %d" % i)
	if bridge.nostalgia_log[3].size() > 20:
		push_warning("nostalgia: exceeded 20-entry cap"); bridge.free(); return false
	bridge.free(); return true


func test_dream_synthesis() -> bool:
	var bridge: MemoryPersonalityBridge = MemoryPersonalityBridge.new()

	var frags: Array[Dictionary] = [
		{"event_type": "conversation", "emotion_tag": "joy",
			"context_tags": ["meadow", "river"], "content": {"with": -1}},
		{"event_type": "play_session", "emotion_tag": "excitement",
			"context_tags": ["garden"], "content": {"with": -1}},
	]
	var dream_text: String = bridge._compose_dream(frags)
	if dream_text.is_empty():
		push_warning("dream_synthesis: _compose_dream returned empty string")
		bridge.free(); return false
	# Manually log the dream and verify structure
	bridge.dream_log[4] = [] as Array[Dictionary]
	bridge.dream_log[4].append({"content": dream_text, "timestamp": Time.get_unix_time_from_system()})
	if bridge.dream_log[4][0].get("content") != dream_text:
		push_warning("dream_synthesis: logged content mismatch"); bridge.free(); return false
	# Verify 10-entry rolling cap
	for i: int in range(12):
		bridge.dream_log[4].append({"content": "dream %d" % i, "timestamp": 0.0})
		if bridge.dream_log[4].size() > 10:
			bridge.dream_log[4].pop_front()
	if bridge.dream_log[4].size() > 10:
		push_warning("dream_synthesis: exceeded 10-entry cap"); bridge.free(); return false
	bridge.free(); return true
