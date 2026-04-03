## test_active_inference.gd — Active Inference Core テスト
## 実行: godot --headless --script tests/test_active_inference.gd
##
## KB参照: KB104 (FEP), KB107, KB108
class_name TestActiveInference
extends SceneTree


func _init() -> void:
	var passed: int = 0
	var failed: int = 0

	print("")
	print("========================================")
	print("  Active Inference Core Tests")
	print("========================================")

	# ─── Test 1: 基本推論ループ ───
	print("\nTest 1: Basic inference loop...")
	var ai: ActiveInferenceCore = ActiveInferenceCore.new()
	var r1: Dictionary = ai.run(
		[{"message": "hello!", "emotion": "joy", "pet_id": 1}],
		{"pet_id": 2, "emotion": "neutral", "vocab_size": 10},
		0.5
	)
	if r1.has("action") and r1.has("error") and r1.has("reason") and r1.has("free_energy"):
		print("  PASS: action='%s' error=%.2f fe=%.2f" % [r1["action"], r1["error"], r1["free_energy"]])
		passed += 1
	else:
		print("  FAIL: missing keys in result")
		failed += 1

	# ─── Test 2: 空の会話でクラッシュしない ───
	print("\nTest 2: Empty conversation...")
	var ai2: ActiveInferenceCore = ActiveInferenceCore.new()
	var r2: Dictionary = ai2.run([], {}, 0.0)
	if r2.has("action") and r2["error"] is float:
		print("  PASS: action='%s'" % r2["action"])
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ─── Test 3: 語彙へのHebbian反映 ───
	print("\nTest 3: Apply to vocabulary (Hebbian LTP)...")
	var ai3: ActiveInferenceCore = ActiveInferenceCore.new()
	var vocab: Dictionary = {
		"greeting": {"ai_term": "hello!", "strength": 0.5, "usage_count": 1,
			"last_used": Time.get_unix_time_from_system()},
	}
	var r3: Dictionary = ai3.run(
		[{"message": "hello!", "emotion": "joy", "pet_id": 1}],
		{"pet_id": 2, "emotion": "joy", "vocab_size": 5},
		0.5
	)
	var apply_result: Dictionary = ai3.apply_to_words(
		vocab,
		[{"message": "hello!", "emotion": "joy"}],
		r3
	)
	if apply_result["strengthened"] > 0 and vocab["greeting"]["strength"] > 0.5:
		print("  PASS: strength=%.3f (was 0.500), strengthened=%d" % [
			vocab["greeting"]["strength"], apply_result["strengthened"]])
		passed += 1
	else:
		print("  FAIL: strength=%.3f strengthened=%d" % [
			vocab["greeting"]["strength"], apply_result["strengthened"]])
		failed += 1

	# ─── Test 4: PetBookデータ生成 ───
	print("\nTest 4: PetBook data generation...")
	var pb: Dictionary = ai3.get_petbook_data(r3)
	if pb.has("particle_color") and pb.has("highlight_text") and pb.has("particle_amount"):
		print("  PASS: '%s' particles=%d" % [pb["highlight_text"], pb["particle_amount"]])
		passed += 1
	else:
		print("  FAIL: missing petbook keys")
		failed += 1

	# ─── Test 5: VFX推奨データ ───
	print("\nTest 5: VFX recommendation...")
	var vfx: Dictionary = ai3.get_vfx(r3)
	if vfx.has("effect") and vfx["particle_amount"] > 0 and vfx.has("duration"):
		print("  PASS: effect='%s' particles=%d dur=%.1f" % [
			vfx["effect"], vfx["particle_amount"], vfx["duration"]])
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ─── Test 6: Multi-Agent予測合意 ───
	print("\nTest 6: Multi-agent prediction merge...")
	var merged: Dictionary = ai3.merge_predictions(
		{"emotion": "joy", "word": "play", "confidence": 0.5},
		[{"emotion": "joy"}, {"emotion": "neutral"}, {"emotion": "joy"}]
	)
	# 3/4がjoy → consensus = 0.75
	if merged["consensus"] >= 0.7 and merged["prediction"]["emotion"] == "joy":
		print("  PASS: consensus=%.2f winner='%s'" % [
			merged["consensus"], merged["prediction"]["emotion"]])
		passed += 1
	else:
		print("  FAIL: consensus=%.2f" % merged["consensus"])
		failed += 1

	# ─── Test 7: 合意なし（全員バラバラ） ───
	print("\nTest 7: No consensus...")
	var merged2: Dictionary = ai3.merge_predictions(
		{"emotion": "joy", "word": "", "confidence": 0.5},
		[{"emotion": "sadness"}, {"emotion": "fear"}]
	)
	# 各1票ずつ → consensus = 1/3 ≈ 0.33
	if merged2["consensus"] < 0.5:
		print("  PASS: low consensus=%.2f" % merged2["consensus"])
		passed += 1
	else:
		print("  FAIL: consensus=%.2f" % merged2["consensus"])
		failed += 1

	# ─── Test 8: セーブ/ロード往復 ───
	print("\nTest 8: Save/load round-trip...")
	var saved: Dictionary = ai.to_dict()
	var restored: ActiveInferenceCore = ActiveInferenceCore.new()
	restored.from_dict(saved)
	if (restored.model.get("conversation_count", 0) == ai.model.get("conversation_count", 0)
			and restored.memory.get("last_action", "") == ai.memory.get("last_action", "")):
		print("  PASS: model and memory preserved")
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ─── Test 9: 空データからの復元（後方互換性） ───
	print("\nTest 9: Restore from empty data (backward compat)...")
	var empty_restore: ActiveInferenceCore = ActiveInferenceCore.new()
	empty_restore.from_dict({})
	if (empty_restore.model.get("emotion_accuracy", 0.0) == 0.3
			and empty_restore.history.size() == 0):
		print("  PASS: defaults restored correctly")
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ─── Test 10: 履歴の上限 ───
	print("\nTest 10: History limit (max=%d)..." % ActiveInferenceCore.MAX_HISTORY)
	var ai10: ActiveInferenceCore = ActiveInferenceCore.new()
	for i: int in 30:
		ai10.run(
			[{"message": "msg%d" % i, "emotion": "neutral", "pet_id": 1}],
			{"pet_id": 2, "emotion": "neutral", "vocab_size": i},
			0.3
		)
	if ai10.history.size() == ActiveInferenceCore.MAX_HISTORY:
		print("  PASS: history=%d" % ai10.history.size())
		passed += 1
	else:
		print("  FAIL: history=%d" % ai10.history.size())
		failed += 1

	# ─── Test 11: 悲しみで閾値低下（追悼語彙促進） ───
	print("\nTest 11: Sadness lowers threshold...")
	var sad_count: int = 0
	var total_runs: int = 100
	for i: int in total_runs:
		var ai_sad: ActiveInferenceCore = ActiveInferenceCore.new()
		var r_sad: Dictionary = ai_sad.run(
			[{"message": "farewell...", "emotion": "sadness", "pet_id": 1}],
			{"pet_id": 2, "emotion": "sadness", "vocab_size": 5},
			0.9  # 強い感情
		)
		if r_sad["action"] == "propose_new_word" or r_sad["action"] == "explore":
			sad_count += 1
	# 悲しみ+強い感情 → propose_new_word + explore が多くなるはず（>50%）
	var sad_ratio: float = float(sad_count) / float(total_runs)
	if sad_ratio > 0.4:
		print("  PASS: creative actions at %.0f%% (sadness + high emotion)" % (sad_ratio * 100))
		passed += 1
	else:
		print("  FAIL: creative actions at %.0f%% (expected >40%%)" % (sad_ratio * 100))
		failed += 1

	# ─── Test 12: Free Energyの計算確認 ───
	print("\nTest 12: Free energy includes complexity penalty...")
	var ai12: ActiveInferenceCore = ActiveInferenceCore.new()
	var r12_small: Dictionary = ai12.run(
		[{"message": "test", "emotion": "neutral", "pet_id": 1}],
		{"pet_id": 2, "emotion": "neutral", "vocab_size": 5},
		0.5
	)
	var ai12b: ActiveInferenceCore = ActiveInferenceCore.new()
	var r12_large: Dictionary = ai12b.run(
		[{"message": "test", "emotion": "neutral", "pet_id": 1}],
		{"pet_id": 2, "emotion": "neutral", "vocab_size": 80},
		0.5
	)
	if r12_large["free_energy"] > r12_small["free_energy"]:
		print("  PASS: larger vocab → higher FE (%.2f > %.2f)" % [
			r12_large["free_energy"], r12_small["free_energy"]])
		passed += 1
	else:
		print("  FAIL: FE small=%.2f large=%.2f" % [
			r12_small["free_energy"], r12_large["free_energy"]])
		failed += 1

	# ─── Test 13: シグナル発火確認 ───
	print("\nTest 13: Signal emission...")
	var ai13: ActiveInferenceCore = ActiveInferenceCore.new()
	var signal_received: Array[bool] = [false]
	ai13.step_completed.connect(func(a: String, e: float) -> void:
		signal_received[0] = true
	)
	ai13.run(
		[{"message": "signal test", "emotion": "joy", "pet_id": 1}],
		{"pet_id": 2, "emotion": "joy", "vocab_size": 5},
		0.5
	)
	if signal_received[0]:
		print("  PASS: step_completed signal received")
		passed += 1
	else:
		print("  FAIL: signal not received")
		failed += 1

	# ─── Test 14: 学習による感情精度向上 ───
	print("\nTest 14: Emotion accuracy improves with correct predictions...")
	var ai14: ActiveInferenceCore = ActiveInferenceCore.new()
	var initial_acc: float = ai14.model.get("emotion_accuracy", 0.0)
	# 感情が一致する会話を繰り返す
	for i: int in 10:
		ai14.run(
			[{"message": "happy%d" % i, "emotion": "joy", "pet_id": 1}],
			{"pet_id": 2, "emotion": "joy", "vocab_size": 5},
			0.5
		)
	var final_acc: float = ai14.model.get("emotion_accuracy", 0.0)
	if final_acc > initial_acc:
		print("  PASS: accuracy %.2f → %.2f" % [initial_acc, final_acc])
		passed += 1
	else:
		print("  FAIL: accuracy did not improve (%.2f → %.2f)" % [initial_acc, final_acc])
		failed += 1

	# ─── Test 15: apply_to_words — マッチしない語彙は変更なし ───
	print("\nTest 15: Unmatched words unchanged...")
	var ai15: ActiveInferenceCore = ActiveInferenceCore.new()
	var vocab15: Dictionary = {
		"rare_word": {"ai_term": "xyzzy", "strength": 0.5, "usage_count": 0,
			"last_used": 0.0},
	}
	var r15: Dictionary = ai15.run(
		[{"message": "nothing relevant", "emotion": "neutral", "pet_id": 1}],
		{"pet_id": 2, "emotion": "neutral", "vocab_size": 5},
		0.5
	)
	var apply15: Dictionary = ai15.apply_to_words(
		vocab15,
		[{"message": "nothing relevant here"}],
		r15
	)
	if apply15["strengthened"] == 0 and vocab15["rare_word"]["strength"] == 0.5:
		print("  PASS: unmatched word strength unchanged (0.50)")
		passed += 1
	else:
		print("  FAIL: strength=%.2f strengthened=%d" % [
			vocab15["rare_word"]["strength"], apply15["strengthened"]])
		failed += 1

	# ─── Summary ───
	print("")
	print("========================================")
	print("  Active Inference Tests: %d/%d passed" % [passed, passed + failed])
	if failed > 0:
		print("  FAILED: %d tests" % failed)
	else:
		print("  ALL PASSED!")
	print("========================================")
	quit(1 if failed > 0 else 0)
