## test_learning_bridge.gd — LearningModelBridge 統合テスト
## 実行: godot --headless --script tests/test_learning_bridge.gd
##
## KB参照: KB108 (Active Inference), KB112 (BCM), KB113 (Oja)
class_name TestLearningBridge
extends SceneTree


# ─── テスト用語彙ヘルパー ───

static func _make_vocab(words: Array[Dictionary] = []) -> Dictionary:
	var vocab: Dictionary = {}
	for w: Dictionary in words:
		vocab[w["key"]] = {
			"ai_term": w.get("ai_term", w["key"]),
			"strength": w.get("strength", 0.5),
			"usage_count": w.get("usage_count", 0),
			"last_used": w.get("last_used", 0.0),
		}
	return vocab


static func _make_conversation(messages: Array[String] = []) -> Array[Dictionary]:
	var conv: Array[Dictionary] = []
	for msg: String in messages:
		conv.append({"message": msg, "emotion": "neutral", "pet_id": 1})
	return conv


static func _make_pet_state() -> Dictionary:
	return {"pet_id": 1, "emotion": "joy", "vocab_size": 5}


func _init() -> void:
	var pass_count: int = 0
	var fail_count: int = 0
	var tests: Array[Callable] = [
		test_bridge_init,
		test_empty_conversation,
		test_full_pipeline,
		test_pipeline_modifies_vocabulary,
		test_death_event,
		test_evolution_event,
		test_resurrection_event,
		test_breeding_event,
		test_petbook_data,
		test_vfx_data,
		test_analyze_vocabulary,
		test_multi_agent_merge,
		test_health_check,
		test_cumulative_stats,
		test_save_load_roundtrip,
		test_signal_emitted,
		test_strength_bounds_after_pipeline,
		test_multiple_cycles,
	]

	for t: Callable in tests:
		var name: String = t.get_method()
		var ok: bool = t.call()
		if ok:
			pass_count += 1
			print("  PASS: %s" % name)
		else:
			fail_count += 1
			print("  FAIL: %s" % name)

	print("\n=== LearningBridge Tests: %d passed, %d failed ===" % [pass_count, fail_count])
	quit(0 if fail_count == 0 else 1)


# ==========================================
#  Tests
# ==========================================

func test_bridge_init() -> bool:
	var bridge := LearningModelBridge.new()
	return bridge.active_inference != null and bridge.bcm_core != null and bridge.oja_core != null


func test_empty_conversation() -> bool:
	var bridge := LearningModelBridge.new()
	var vocab: Dictionary = _make_vocab([
		{"key": "hello", "ai_term": "helu", "strength": 0.5},
	])
	var conv: Array[Dictionary] = []
	var pet: Dictionary = _make_pet_state()
	var result: Dictionary = bridge.process_conversation(vocab, conv, pet, 0.5)
	# Should complete without errors
	return result.has("pipeline_summary") and result.has("health")


func test_full_pipeline() -> bool:
	var bridge := LearningModelBridge.new()
	var vocab: Dictionary = _make_vocab([
		{"key": "hello", "ai_term": "helu", "strength": 0.5},
		{"key": "friend", "ai_term": "furendo", "strength": 0.4},
		{"key": "happy", "ai_term": "hapii", "strength": 0.6},
	])
	var conv: Array[Dictionary] = _make_conversation(["helu furendo", "hapii helu"])
	var pet: Dictionary = _make_pet_state()
	var result: Dictionary = bridge.process_conversation(vocab, conv, pet, 0.7)

	# All three stages should produce results
	var has_ai: bool = not result.get("ai_result", {}).is_empty()
	var has_bcm: bool = not result.get("bcm_result", {}).is_empty()
	var has_oja: bool = not result.get("oja_result", {}).is_empty()
	return has_ai and has_bcm and has_oja


func test_pipeline_modifies_vocabulary() -> bool:
	var bridge := LearningModelBridge.new()
	var vocab: Dictionary = _make_vocab([
		{"key": "love", "ai_term": "rabu", "strength": 0.5},
		{"key": "sad", "ai_term": "kanashi", "strength": 0.5},
	])
	var original_love: float = vocab["love"]["strength"]
	var original_sad: float = vocab["sad"]["strength"]

	var conv: Array[Dictionary] = _make_conversation(["rabu rabu rabu"])
	var pet: Dictionary = _make_pet_state()
	bridge.process_conversation(vocab, conv, pet, 0.8)

	# "love" was used so it should change; "sad" was not used
	var love_changed: bool = absf(vocab["love"]["strength"] - original_love) > 0.001
	var sad_changed: bool = absf(vocab["sad"]["strength"] - original_sad) > 0.001
	# At least one should have changed
	return love_changed or sad_changed


func test_death_event() -> bool:
	var bridge := LearningModelBridge.new()
	var vocab: Dictionary = _make_vocab([
		{"key": "farewell", "ai_term": "sayonara", "strength": 0.3},
	])
	var conv: Array[Dictionary] = _make_conversation(["sayonara..."])
	var pet: Dictionary = _make_pet_state()
	var result: Dictionary = bridge.process_death_event(vocab, conv, pet)
	return result.get("event_type", "") == "death"


func test_evolution_event() -> bool:
	var bridge := LearningModelBridge.new()
	var vocab: Dictionary = _make_vocab([
		{"key": "grow", "ai_term": "seichou", "strength": 0.5},
	])
	var conv: Array[Dictionary] = _make_conversation(["seichou!"])
	var pet: Dictionary = _make_pet_state()
	var result: Dictionary = bridge.process_evolution_event(vocab, conv, pet)
	return result.get("event_type", "") == "evolution"


func test_resurrection_event() -> bool:
	var bridge := LearningModelBridge.new()
	var vocab: Dictionary = _make_vocab([
		{"key": "return", "ai_term": "modoru", "strength": 0.3},
	])
	var conv: Array[Dictionary] = _make_conversation(["modoru!"])
	var pet: Dictionary = _make_pet_state()
	var result: Dictionary = bridge.process_resurrection_event(vocab, conv, pet)
	return result.get("event_type", "") == "resurrection"


func test_breeding_event() -> bool:
	var bridge := LearningModelBridge.new()
	var vocab: Dictionary = _make_vocab([
		{"key": "child", "ai_term": "kodomo", "strength": 0.5},
	])
	var conv: Array[Dictionary] = _make_conversation(["kodomo!"])
	var pet: Dictionary = _make_pet_state()
	var result: Dictionary = bridge.process_breeding_event(vocab, conv, pet)
	return result.get("event_type", "") == "breeding"


func test_petbook_data() -> bool:
	var bridge := LearningModelBridge.new()
	var vocab: Dictionary = _make_vocab([
		{"key": "hello", "ai_term": "helu", "strength": 0.5},
	])
	var conv: Array[Dictionary] = _make_conversation(["helu"])
	var pet: Dictionary = _make_pet_state()
	var result: Dictionary = bridge.process_conversation(vocab, conv, pet, 0.5)
	var pb: Dictionary = bridge.get_petbook_data(result)
	return pb.has("particle_color") and pb.has("highlight_text") and pb.has("particle_amount")


func test_vfx_data() -> bool:
	var bridge := LearningModelBridge.new()
	var vocab: Dictionary = _make_vocab([
		{"key": "hello", "ai_term": "helu", "strength": 0.5},
	])
	var conv: Array[Dictionary] = _make_conversation(["helu"])
	var pet: Dictionary = _make_pet_state()
	var result: Dictionary = bridge.process_conversation(vocab, conv, pet, 0.5)
	var vfx: Dictionary = bridge.get_vfx_data(result)
	return vfx.has("effect") and vfx.has("color") and vfx.has("particle_amount")


func test_analyze_vocabulary() -> bool:
	var bridge := LearningModelBridge.new()
	var vocab: Dictionary = _make_vocab([
		{"key": "a", "strength": 0.8},
		{"key": "b", "strength": 0.3},
		{"key": "c", "strength": 0.5},
	])
	var analysis: Dictionary = bridge.analyze_vocabulary(vocab)
	return (
		analysis.has("bcm_health")
		and analysis.has("oja_contrast")
		and analysis.has("overall_healthy")
		and analysis.has("contrast_ratio")
	)


func test_multi_agent_merge() -> bool:
	var bridge := LearningModelBridge.new()
	var my_state: Dictionary = {"emotion": "joy"}
	var others: Array[Dictionary] = [
		{"emotion": "joy", "confidence": 0.5},
		{"emotion": "sadness", "confidence": 0.3},
	]
	var merged: Dictionary = bridge.merge_multi_agent_predictions(my_state, others)
	# Joy has 2 votes, sadness has 1 → joy wins
	return merged.get("prediction", {}).get("emotion", "") == "joy"


func test_health_check() -> bool:
	var bridge := LearningModelBridge.new()
	# Normal vocabulary → healthy
	var vocab: Dictionary = _make_vocab([
		{"key": "a", "strength": 0.5},
		{"key": "b", "strength": 0.6},
		{"key": "c", "strength": 0.4},
	])
	var conv: Array[Dictionary] = _make_conversation(["a"])
	var pet: Dictionary = _make_pet_state()
	var result: Dictionary = bridge.process_conversation(vocab, conv, pet, 0.5)
	var health: Dictionary = result.get("health", {})
	return health.has("healthy") and health.has("warnings")


func test_cumulative_stats() -> bool:
	var bridge := LearningModelBridge.new()
	var vocab: Dictionary = _make_vocab([
		{"key": "word1", "ai_term": "w1", "strength": 0.5},
		{"key": "word2", "ai_term": "w2", "strength": 0.5},
	])
	var conv: Array[Dictionary] = _make_conversation(["w1"])
	var pet: Dictionary = _make_pet_state()

	bridge.process_conversation(vocab, conv, pet, 0.5)
	bridge.process_conversation(vocab, conv, pet, 0.6)

	return bridge.total_cycles == 2 and bridge.cumulative_stats.get("total_ltp", -1) >= 0


func test_save_load_roundtrip() -> bool:
	var bridge := LearningModelBridge.new()
	var vocab: Dictionary = _make_vocab([
		{"key": "test", "ai_term": "tesuto", "strength": 0.5},
	])
	var conv: Array[Dictionary] = _make_conversation(["tesuto"])
	var pet: Dictionary = _make_pet_state()
	bridge.process_conversation(vocab, conv, pet, 0.5)

	var data: Dictionary = bridge.to_dict()

	var bridge2 := LearningModelBridge.new()
	bridge2.from_dict(data)

	return (
		bridge2.total_cycles == bridge.total_cycles
		and bridge2.cumulative_stats.get("total_ltp", -1) == bridge.cumulative_stats.get("total_ltp", -1)
	)


func test_signal_emitted() -> bool:
	var bridge := LearningModelBridge.new()
	var signal_received: Array[bool] = [false]
	bridge.learning_completed.connect(func(_r: Dictionary) -> void: signal_received[0] = true)

	var vocab: Dictionary = _make_vocab([
		{"key": "test", "ai_term": "t", "strength": 0.5},
	])
	var conv: Array[Dictionary] = _make_conversation(["t"])
	var pet: Dictionary = _make_pet_state()
	bridge.process_conversation(vocab, conv, pet, 0.5)

	return signal_received[0]


func test_strength_bounds_after_pipeline() -> bool:
	var bridge := LearningModelBridge.new()
	var vocab: Dictionary = _make_vocab([
		{"key": "strong", "ai_term": "s", "strength": 0.95},
		{"key": "weak", "ai_term": "w", "strength": 0.08},
		{"key": "normal", "ai_term": "n", "strength": 0.5},
	])
	var pet: Dictionary = _make_pet_state()

	# Run 10 cycles to stress-test bounds
	for i: int in 10:
		var conv: Array[Dictionary] = _make_conversation(["s s s"])
		bridge.process_conversation(vocab, conv, pet, 0.9)

	# Check all strengths are within [STRENGTH_FLOOR, STRENGTH_CEILING]
	for word: String in vocab:
		var s: float = vocab[word].get("strength", 0.0)
		if s < 0.04 or s > 1.01:
			return false
	return true


func test_multiple_cycles() -> bool:
	var bridge := LearningModelBridge.new()
	var vocab: Dictionary = _make_vocab([
		{"key": "alpha", "ai_term": "a", "strength": 0.5},
		{"key": "beta", "ai_term": "b", "strength": 0.5},
		{"key": "gamma", "ai_term": "g", "strength": 0.5},
	])
	var pet: Dictionary = _make_pet_state()

	# 5 cycles with different conversations
	for i: int in 5:
		var msg: String = "a b" if i % 2 == 0 else "g"
		var conv: Array[Dictionary] = _make_conversation([msg])
		bridge.process_conversation(vocab, conv, pet, 0.5 + float(i) * 0.1)

	# After 5 cycles, vocabulary should have differentiated
	var alpha_s: float = vocab["alpha"]["strength"]
	var gamma_s: float = vocab["gamma"]["strength"]
	# Both should still be valid
	return alpha_s > 0.0 and alpha_s <= 1.0 and gamma_s > 0.0 and gamma_s <= 1.0
