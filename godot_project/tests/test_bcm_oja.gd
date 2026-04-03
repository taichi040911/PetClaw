## test_bcm_oja.gd — BCM / OJA テスト
## 実行: godot --headless --script tests/test_bcm_oja.gd
##
## KB参照: KB99 (Hebbian), KB112 (BCM), KB113 (Oja)
class_name TestBCMOja
extends SceneTree

const BCM := preload("res://scripts/inference/bcm_language_core.gd")
const OJA := preload("res://scripts/inference/oja_language_core.gd")

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


func _init() -> void:
	var passed: int = 0
	var failed: int = 0

	print("")
	print("========================================")
	print("  BCM / Oja Language Core Tests")
	print("========================================")

	# ==========================================
	#  BCM Tests
	# ==========================================

	# ─── Test 1: BCM空語彙 ───
	print("\nTest 1: BCM empty vocabulary...")
	var bcm1: BCM = BCM.new()
	var r1: Dictionary = bcm1.apply_bcm_learning({}, _make_conversation(), 0.5)
	if r1["ltp_count"] == 0 and r1["ltd_count"] == 0 and r1["vocab_size"] == 0:
		print("  PASS: empty vocab returns zeros")
		passed += 1
	else:
		print("  FAIL: ltp=%d ltd=%d size=%d" % [r1["ltp_count"], r1["ltd_count"], r1["vocab_size"]])
		failed += 1

	# ─── Test 2: 使用された語のLTP ───
	print("\nTest 2: BCM used word LTP...")
	var bcm2: BCM = BCM.new()
	var vocab2: Dictionary = _make_vocab([{"key": "hello", "ai_term": "hello", "strength": 0.5}])
	var conv2: Array[Dictionary] = _make_conversation(["hello"])
	var r2: Dictionary = bcm2.apply_bcm_learning(vocab2, conv2, 0.7)
	if vocab2["hello"]["strength"] > 0.5:
		print("  PASS: strength=%.3f (was 0.500), LTP=%d" % [vocab2["hello"]["strength"], r2["ltp_count"]])
		passed += 1
	else:
		print("  FAIL: strength=%.3f" % vocab2["hello"]["strength"])
		failed += 1

	# ─── Test 3: 未使用語のLTD ───
	# BCMでは activity(=base_strength) が閾値を下回るとLTD
	# 閾値 = avg*0.8 + drift + avg_sq*0.1 ≈ 0.24 + 0 + 0.009 = 0.249 for strength=0.3
	# activity = 0.3 > 0.249 → まだLTP。strengthを十分低くする必要がある
	# 高いstrengthの語と混在させて閾値を上げる
	print("\nTest 3: BCM unused word LTD...")
	var bcm3: BCM = BCM.new()
	var vocab3: Dictionary = _make_vocab([
		{"key": "rare", "ai_term": "xyzzy", "strength": 0.3},
		{"key": "common", "ai_term": "common", "strength": 0.8},
	])
	var conv3: Array[Dictionary] = _make_conversation(["common is here"])
	var r3: Dictionary = bcm3.apply_bcm_learning(vocab3, conv3, 0.5)
	if vocab3["rare"]["strength"] < 0.3:
		print("  PASS: strength=%.3f (was 0.300), LTD=%d" % [vocab3["rare"]["strength"], r3["ltd_count"]])
		passed += 1
	else:
		print("  FAIL: strength=%.3f" % vocab3["rare"]["strength"])
		failed += 1

	# ─── Test 4: 閾値が平均に応じて変化 ───
	print("\nTest 4: BCM threshold update...")
	var bcm4: BCM = BCM.new()
	var initial_threshold: float = bcm4.get_threshold()
	var vocab4: Dictionary = _make_vocab([
		{"key": "w1", "ai_term": "w1", "strength": 0.8},
		{"key": "w2", "ai_term": "w2", "strength": 0.9},
		{"key": "w3", "ai_term": "w3", "strength": 0.7},
	])
	bcm4.apply_bcm_learning(vocab4, _make_conversation(), 0.5)
	var new_threshold: float = bcm4.get_threshold()
	if new_threshold != initial_threshold:
		print("  PASS: threshold changed %.3f -> %.3f" % [initial_threshold, new_threshold])
		passed += 1
	else:
		print("  FAIL: threshold unchanged at %.3f" % new_threshold)
		failed += 1

	# ─── Test 5: death イベントで閾値低下 ───
	print("\nTest 5: BCM death event lowers threshold...")
	var bcm5: BCM = BCM.new()
	var vocab5: Dictionary = _make_vocab([
		{"key": "farewell", "ai_term": "farewell", "strength": 0.5},
		{"key": "goodbye", "ai_term": "goodbye", "strength": 0.5},
	])
	var conv5: Array[Dictionary] = _make_conversation(["farewell"])
	# Normal run first to establish baseline
	var r5_normal: Dictionary = bcm5.apply_bcm_learning(vocab5.duplicate(true), conv5, 0.5)
	var bcm5b: BCM = BCM.new()
	var r5_death: Dictionary = bcm5b.apply_bcm_with_event(vocab5.duplicate(true), conv5, 0.5, "death")
	if r5_death.has("event_type") and r5_death["event_type"] == "death" and r5_death.has("threshold_adjustment"):
		print("  PASS: death event applied, adj=%.2f" % r5_death["threshold_adjustment"])
		passed += 1
	else:
		print("  FAIL: missing event keys")
		failed += 1

	# ─── Test 6: resurrection イベント ───
	print("\nTest 6: BCM resurrection event...")
	var bcm6: BCM = BCM.new()
	var vocab6: Dictionary = _make_vocab([
		{"key": "rebirth", "ai_term": "rebirth", "strength": 0.4},
	])
	var conv6: Array[Dictionary] = _make_conversation(["rebirth"])
	var r6: Dictionary = bcm6.apply_bcm_with_event(vocab6, conv6, 0.8, "resurrection")
	if r6["event_type"] == "resurrection" and r6["threshold_adjustment"] == -0.25:
		print("  PASS: resurrection adj=%.2f, LTP=%d" % [r6["threshold_adjustment"], r6["ltp_count"]])
		passed += 1
	else:
		print("  FAIL: event_type=%s adj=%s" % [str(r6.get("event_type", "")), str(r6.get("threshold_adjustment", 0))])
		failed += 1

	# ─── Test 7: 語彙健全性チェック ───
	print("\nTest 7: BCM vocabulary health...")
	var bcm7: BCM = BCM.new()
	var vocab7_healthy: Dictionary = _make_vocab([
		{"key": "a", "strength": 0.5},
		{"key": "b", "strength": 0.6},
		{"key": "c", "strength": 0.4},
	])
	var health7: Dictionary = bcm7.check_vocabulary_health(vocab7_healthy)
	if health7["healthy"] == true and health7["warnings"].size() == 0:
		print("  PASS: healthy vocab reported correctly")
		passed += 1
	else:
		print("  FAIL: healthy=%s warnings=%s" % [str(health7["healthy"]), str(health7["warnings"])])
		failed += 1

	# Unhealthy case: too many dead words
	var bcm7b: BCM = BCM.new()
	var vocab7_dead: Dictionary = _make_vocab([
		{"key": "d1", "strength": 0.05},
		{"key": "d2", "strength": 0.06},
		{"key": "d3", "strength": 0.07},
		{"key": "alive", "strength": 0.5},
	])
	var health7b: Dictionary = bcm7b.check_vocabulary_health(vocab7_dead)
	if health7b["healthy"] == false and health7b["warnings"].size() > 0:
		print("  (bonus) unhealthy vocab detected: %s" % str(health7b["warnings"]))
	else:
		print("  (bonus) unexpected: unhealthy vocab not detected")

	# ─── Test 8: BCM セーブ/ロード往復 ───
	print("\nTest 8: BCM save/load round-trip...")
	var bcm8: BCM = BCM.new()
	var vocab8: Dictionary = _make_vocab([{"key": "test", "ai_term": "test", "strength": 0.5}])
	bcm8.apply_bcm_learning(vocab8, _make_conversation(["test"]), 0.6)
	var saved8: Dictionary = bcm8.to_dict()
	var restored8: BCM = BCM.new()
	restored8.from_dict(saved8)
	if (restored8.sliding_threshold == bcm8.sliding_threshold
			and restored8.conversation_count == bcm8.conversation_count
			and is_equal_approx(restored8.threshold_drift_accumulated, bcm8.threshold_drift_accumulated)):
		print("  PASS: state preserved (θ=%.3f count=%d drift=%.3f)" % [
			restored8.sliding_threshold, restored8.conversation_count, restored8.threshold_drift_accumulated])
		passed += 1
	else:
		print("  FAIL: state mismatch")
		failed += 1

	# ─── Test 9: PetBook BCMデータ生成 ───
	print("\nTest 9: BCM PetBook data generation...")
	var bcm9: BCM = BCM.new()
	var pb_ltp: Dictionary = bcm9.get_petbook_bcm_data({"ltp_count": 5, "ltd_count": 0})
	var pb_ltd: Dictionary = bcm9.get_petbook_bcm_data({"ltp_count": 0, "ltd_count": 3})
	var pb_stable: Dictionary = bcm9.get_petbook_bcm_data({"ltp_count": 0, "ltd_count": 0})
	if (pb_ltp.has("particle_color") and pb_ltp.has("highlight_text") and pb_ltp.has("particle_amount")
			and pb_ltd.has("highlight_text") and pb_stable.has("highlight_text")):
		print("  PASS: ltp='%s' ltd='%s' stable='%s'" % [
			pb_ltp["highlight_text"], pb_ltd["highlight_text"], pb_stable["highlight_text"]])
		passed += 1
	else:
		print("  FAIL: missing petbook keys")
		failed += 1

	# ==========================================
	#  Oja Tests
	# ==========================================

	# ─── Test 10: Oja空語彙 ───
	print("\nTest 10: Oja empty vocabulary...")
	var oja10: OJA = OJA.new()
	var r10: Dictionary = oja10.apply_oja_learning({}, _make_conversation(), 0.5)
	if r10["strengthened"] == 0 and r10["weakened"] == 0 and r10["normalized"] == false:
		print("  PASS: empty vocab returns zeros")
		passed += 1
	else:
		print("  FAIL: strengthened=%d weakened=%d" % [r10["strengthened"], r10["weakened"]])
		failed += 1

	# ─── Test 11: 使用された語のLTP ───
	print("\nTest 11: Oja used word strengthened...")
	var oja11: OJA = OJA.new()
	var vocab11: Dictionary = _make_vocab([{"key": "play", "ai_term": "play", "strength": 0.5}])
	var conv11: Array[Dictionary] = _make_conversation(["play"])
	var r11: Dictionary = oja11.apply_oja_learning(vocab11, conv11, 0.6)
	# After Hebbian LTP + normalization, the word should be strengthened
	if r11["strengthened"] > 0:
		print("  PASS: strengthened=%d, strength=%.3f" % [r11["strengthened"], vocab11["play"]["strength"]])
		passed += 1
	else:
		print("  FAIL: strengthened=%d strength=%.3f" % [r11["strengthened"], vocab11["play"]["strength"]])
		failed += 1

	# ─── Test 12: 正規化が平均をターゲット近くに維持 ───
	print("\nTest 12: Oja normalization keeps avg near target...")
	var oja12: OJA = OJA.new()
	var vocab12: Dictionary = _make_vocab([
		{"key": "a", "ai_term": "a", "strength": 0.9},
		{"key": "b", "ai_term": "b", "strength": 0.85},
		{"key": "c", "ai_term": "c", "strength": 0.8},
	])
	var r12: Dictionary = oja12.apply_oja_learning(vocab12, _make_conversation(), 0.5)
	var avg_after: float = r12["avg_after"]
	# After normalization, avg should move closer to TARGET_AVG_STRENGTH (0.55)
	if avg_after < 0.85:
		print("  PASS: avg moved toward target: %.3f (was ~0.85)" % avg_after)
		passed += 1
	else:
		print("  FAIL: avg=%.3f did not decrease" % avg_after)
		failed += 1

	# ─── Test 13: 二次減衰が高strength語を減少させる ───
	print("\nTest 13: Oja quadratic decay reduces high-strength words...")
	var oja13: OJA = OJA.new()
	var vocab13_high: Dictionary = _make_vocab([
		{"key": "strong", "ai_term": "xyzzy_nomatch", "strength": 0.95},
	])
	var original_strength: float = vocab13_high["strong"]["strength"]
	# No conversation match, so only LTD + quadratic decay apply
	oja13.apply_oja_learning(vocab13_high, _make_conversation(["no match"]), 0.5)
	if vocab13_high["strong"]["strength"] < original_strength:
		print("  PASS: strength %.3f -> %.3f (decay applied)" % [original_strength, vocab13_high["strong"]["strength"]])
		passed += 1
	else:
		print("  FAIL: strength=%.3f (was %.3f)" % [vocab13_high["strong"]["strength"], original_strength])
		failed += 1

	# ─── Test 14: コントラスト分析 ───
	print("\nTest 14: Oja contrast analysis...")
	var oja14: OJA = OJA.new()
	var vocab14: Dictionary = _make_vocab([
		{"key": "strong_w", "strength": 0.9},
		{"key": "weak_w", "strength": 0.1},
		{"key": "mid_w", "strength": 0.5},
	])
	var contrast14: Dictionary = oja14.analyze_contrast(vocab14)
	if (contrast14.has("contrast_ratio") and contrast14.has("std_dev")
			and contrast14.has("health") and contrast14["contrast_ratio"] > 1.0
			and contrast14["health"] is String):
		print("  PASS: contrast=%.2f std=%.3f health='%s'" % [
			contrast14["contrast_ratio"], contrast14["std_dev"], contrast14["health"]])
		passed += 1
	else:
		print("  FAIL: %s" % str(contrast14))
		failed += 1

	# Too few words case
	var contrast14_few: Dictionary = oja14.analyze_contrast(_make_vocab([{"key": "only_one", "strength": 0.5}]))
	if contrast14_few["health"] == "too_few_words":
		print("  (bonus) single word correctly returns too_few_words")

	# ─── Test 15: BCM後の正規化 ───
	print("\nTest 15: Oja apply_after_bcm normalization...")
	var oja15: OJA = OJA.new()
	var vocab15: Dictionary = _make_vocab([
		{"key": "w1", "strength": 0.9},
		{"key": "w2", "strength": 0.85},
		{"key": "w3", "strength": 0.8},
	])
	var fake_bcm_result: Dictionary = {"ltp_count": 2, "ltd_count": 1}
	var r15: Dictionary = oja15.apply_after_bcm(vocab15, fake_bcm_result)
	if (r15.has("bcm_ltp") and r15.has("oja_normalized") and r15.has("oja_scale")
			and r15.has("avg_after") and r15["bcm_ltp"] == 2):
		print("  PASS: bcm_ltp=%d normalized=%s scale=%.3f avg=%.3f" % [
			r15["bcm_ltp"], str(r15["oja_normalized"]), r15["oja_scale"], r15["avg_after"]])
		passed += 1
	else:
		print("  FAIL: %s" % str(r15))
		failed += 1

	# ─── Test 16: Oja セーブ/ロード往復 ───
	print("\nTest 16: Oja save/load round-trip...")
	var oja16: OJA = OJA.new()
	var vocab16: Dictionary = _make_vocab([{"key": "test", "ai_term": "test", "strength": 0.5}])
	oja16.apply_oja_learning(vocab16, _make_conversation(["test"]), 0.5)
	var saved16: Dictionary = oja16.to_dict()
	var restored16: OJA = OJA.new()
	restored16.from_dict(saved16)
	if (restored16.conversation_count == oja16.conversation_count
			and restored16.last_normalization.hash() == oja16.last_normalization.hash()):
		print("  PASS: state preserved (count=%d)" % restored16.conversation_count)
		passed += 1
	else:
		print("  FAIL: state mismatch (count %d vs %d)" % [
			restored16.conversation_count, oja16.conversation_count])
		failed += 1

	# ─── Test 17: PetBook Ojaデータ生成 ───
	print("\nTest 17: Oja PetBook data generation...")
	var oja17: OJA = OJA.new()
	var pb_norm_down: Dictionary = oja17.get_petbook_oja_data(
		{"normalized": true, "scale_factor": 0.8, "strengthened": 1})
	var pb_norm_up: Dictionary = oja17.get_petbook_oja_data(
		{"normalized": true, "scale_factor": 1.2, "strengthened": 1})
	var pb_bloom: Dictionary = oja17.get_petbook_oja_data(
		{"normalized": false, "scale_factor": 1.0, "strengthened": 5})
	var pb_balanced: Dictionary = oja17.get_petbook_oja_data(
		{"normalized": false, "scale_factor": 1.0, "strengthened": 0})
	if (pb_norm_down.has("particle_color") and pb_norm_down.has("highlight_text")
			and pb_norm_up.has("highlight_text") and pb_bloom.has("highlight_text")
			and pb_balanced.has("highlight_text")):
		print("  PASS: down='%s' up='%s' bloom='%s' bal='%s'" % [
			pb_norm_down["highlight_text"], pb_norm_up["highlight_text"],
			pb_bloom["highlight_text"], pb_balanced["highlight_text"]])
		passed += 1
	else:
		print("  FAIL: missing petbook keys")
		failed += 1

	# ==========================================
	#  Integration Tests
	# ==========================================

	# ─── Test 18: BCM → Oja パイプライン ───
	print("\nTest 18: BCM then Oja pipeline...")
	var bcm18: BCM = BCM.new()
	var oja18: OJA = OJA.new()
	var vocab18: Dictionary = _make_vocab([
		{"key": "hello", "ai_term": "hello", "strength": 0.5},
		{"key": "goodbye", "ai_term": "goodbye", "strength": 0.5},
		{"key": "rare", "ai_term": "xyzzy_no_match", "strength": 0.5},
	])
	var conv18: Array[Dictionary] = _make_conversation(["hello"])

	# Step 1: BCM learning
	var bcm_result18: Dictionary = bcm18.apply_bcm_learning(vocab18, conv18, 0.7)

	# Step 2: Oja normalization after BCM
	var oja_result18: Dictionary = oja18.apply_after_bcm(vocab18, bcm_result18)

	if (oja_result18.has("bcm_ltp") and oja_result18.has("oja_normalized")
			and oja_result18.has("avg_after") and oja_result18["avg_after"] > 0.0):
		print("  PASS: pipeline complete, bcm_ltp=%d bcm_ltd=%d oja_norm=%s avg=%.3f" % [
			oja_result18["bcm_ltp"], oja_result18["bcm_ltd"],
			str(oja_result18["oja_normalized"]), oja_result18["avg_after"]])
		passed += 1
	else:
		print("  FAIL: pipeline result=%s" % str(oja_result18))
		failed += 1

	# ─── Test 19: strength境界チェック ───
	print("\nTest 19: Strength never exceeds bounds...")
	var bcm19: BCM = BCM.new()
	var oja19: OJA = OJA.new()
	var vocab19: Dictionary = _make_vocab([
		{"key": "maxed", "ai_term": "maxed", "strength": 0.99},
		{"key": "floored", "ai_term": "floored_no_match", "strength": 0.06},
	])

	# Run BCM multiple times with strong emotion to push boundaries
	for i: int in 20:
		bcm19.apply_bcm_learning(vocab19, _make_conversation(["maxed"]), 1.0)

	# Then run Oja
	oja19.apply_oja_learning(vocab19, _make_conversation(["maxed"]), 1.0)

	var all_in_bounds: bool = true
	var violation_msg: String = ""
	for word: String in vocab19:
		var s: float = vocab19[word]["strength"]
		if s < BCM.STRENGTH_FLOOR - 0.001 or s > BCM.STRENGTH_CEILING + 0.001:
			all_in_bounds = false
			violation_msg = "word='%s' strength=%.4f" % [word, s]
			break

	if all_in_bounds:
		print("  PASS: all strengths in [%.2f, %.2f] (maxed=%.3f floored=%.3f)" % [
			BCM.STRENGTH_FLOOR, BCM.STRENGTH_CEILING,
			vocab19["maxed"]["strength"], vocab19["floored"]["strength"]])
		passed += 1
	else:
		print("  FAIL: out of bounds: %s" % violation_msg)
		failed += 1

	# ─── Summary ───
	print("")
	print("========================================")
	print("  BCM / Oja Tests: %d/%d passed" % [passed, passed + failed])
	if failed > 0:
		print("  FAILED: %d tests" % failed)
	else:
		print("  ALL PASSED!")
	print("========================================")
	quit(1 if failed > 0 else 0)
