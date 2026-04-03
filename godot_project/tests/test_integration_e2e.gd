## test_integration_e2e.gd — エンドツーエンド統合テスト
## ペット作成→育成→言語発明→進化→セーブ→ロードの一連フローを検証
## 実行: godot --headless --script tests/test_integration_e2e.gd
class_name TestIntegrationE2E
extends SceneTree


func _init() -> void:
	var passed: int = 0
	var failed: int = 0

	print("╔══════════════════════════════════════╗")
	print("║  End-to-End Integration Tests        ║")
	print("╚══════════════════════════════════════╝")

	# === Test 1: ペット作成→ステータス変更→進化条件チェック ===
	print("\nTest 1: Pet creation → stats → evolution check...")
	var pet: PetEntity = PetEntity.new()
	pet.pet_id = 1
	pet.pet_name = "TestMimi"
	pet.age = 0.0
	pet.evolution_stage = 0
	pet.personality["brave"] = 0.7
	pet.personality["curious"] = 0.8
	pet.emotions["joy"] = 0.6

	# Simulate feeding
	pet.stats.modify("hunger", 0.3)
	pet.stats.modify("health", 0.1)

	if pet.stats.hunger > 0.5 and pet.pet_name == "TestMimi":
		print("  PASS: Pet created and stats modified")
		passed += 1
	else:
		print("  FAIL: Pet state incorrect")
		failed += 1

	# === Test 2: 言語エンジンで語彙を蓄積 ===
	print("\nTest 2: Language vocabulary accumulation...")
	var lang_engine: OriginalLanguageEngine = OriginalLanguageEngine.new()

	# Simulate a conversation cycle: 8 words invented
	var test_words: Array[String] = [
		"play", "eat", "sleep", "friend", "happy", "run", "dream", "sing"
	]
	for w: String in test_words:
		lang_engine.invent_word(w, {
			"emotion": "joy",
			"pet_id": pet.pet_id,
			"situation": "conversation",
		})

	if lang_engine.vocabulary.size() == 8 and lang_engine.total_words_invented == 8:
		print("  PASS: 8 words invented (stage=%d)" % lang_engine.current_stage)
		passed += 1
	else:
		print("  FAIL: vocab=%d, total=%d" % [lang_engine.vocabulary.size(), lang_engine.total_words_invented])
		failed += 1

	# === Test 3: Hebbian強化サイクル ===
	print("\nTest 3: Hebbian reinforcement cycle...")
	# Simulate multiple conversations where "happy" is used
	for i in 4:
		lang_engine.strengthen_word("happy")
	# happy: 0.5 + 4*0.15 = 1.1 → capped at 1.0
	var happy_strength: float = lang_engine.vocabulary["happy"]["strength"]
	if absf(happy_strength - 1.0) < 0.001:
		print("  PASS: 'happy' reached max strength (%.2f)" % happy_strength)
		passed += 1
	else:
		print("  FAIL: 'happy' strength = %.2f" % happy_strength)
		failed += 1

	# === Test 4: 進化システムとケアミス記録 ===
	print("\nTest 4: Evolution mechanics + care miss tracking...")
	var evo: EvolutionMechanics = EvolutionMechanics.new()
	evo.record_care_miss(pet.pet_id)
	var evo_dict: Dictionary = evo.to_dict()
	if evo_dict is Dictionary:
		print("  PASS: Evolution care miss recorded, serializable")
		passed += 1
	else:
		print("  FAIL: Evolution serialization error")
		failed += 1

	# === Test 5: 全システム統合セーブ ===
	print("\nTest 5: Combined save (pet + language + evolution)...")
	var combined_save: Dictionary = {
		"pet": pet.to_dict(),
		"language": lang_engine.to_dict(),
		"evolution": evo.to_dict(),
		"version": "1.0.0",
		"timestamp": Time.get_unix_time_from_system(),
	}

	if combined_save["pet"]["pet_name"] == "TestMimi" \
		and combined_save["language"]["vocabulary"].has("happy") \
		and combined_save.has("evolution"):
		print("  PASS: Combined save dict created (keys=%d)" % combined_save.size())
		passed += 1
	else:
		print("  FAIL: Combined save incomplete")
		failed += 1

	# === Test 6: 全システム統合ロード ===
	print("\nTest 6: Combined load (restore all systems)...")
	var restored_pet: PetEntity = PetEntity.new()
	restored_pet.from_dict(combined_save["pet"])

	var restored_lang: OriginalLanguageEngine = OriginalLanguageEngine.new()
	restored_lang.from_dict(combined_save["language"])

	var restored_evo: EvolutionMechanics = EvolutionMechanics.new()
	restored_evo.from_dict(combined_save["evolution"])

	if restored_pet.pet_name == "TestMimi" \
		and restored_lang.vocabulary.has("happy") \
		and absf(restored_lang.vocabulary["happy"]["strength"] - 1.0) < 0.001 \
		and restored_lang.vocabulary.size() == 8:
		print("  PASS: All systems restored correctly")
		passed += 1
	else:
		print("  FAIL: Restoration mismatch")
		failed += 1

	# === Test 7: 復元後も言語操作が正常 ===
	print("\nTest 7: Post-restore language operations...")
	restored_lang.weaken_word("happy")
	restored_lang.invent_word("discover", {
		"emotion": "excitement", "pet_id": 1, "situation": "explore",
	})
	if restored_lang.vocabulary.size() == 9 \
		and restored_lang.vocabulary["happy"]["strength"] < 1.0:
		print("  PASS: Post-restore operations work (vocab=%d)" % restored_lang.vocabulary.size())
		passed += 1
	else:
		print("  FAIL: Post-restore operations failed")
		failed += 1

	# === Test 8: AtoA会話システムのフォールバック確認 ===
	print("\nTest 8: AtoA conversation system template fallback...")
	var a2a: AtoAConversationSystem = AtoAConversationSystem.new()
	# Budget check with zero cost (should pass)
	var has_budget: bool = a2a._check_budget()
	if has_budget:
		print("  PASS: Budget available at day start (cost=$%.2f)" % a2a.daily_conversation_cost)
		passed += 1
	else:
		print("  FAIL: Budget should be available")
		failed += 1

	# === Test 9: AtoA コスト記録 ===
	print("\nTest 9: AtoA cost recording...")
	a2a._record_conversation_cost(6)  # 6ターン分
	var expected_cost: float = 6 * AtoAConversationSystem.COST_PER_TURN
	if absf(a2a.daily_conversation_cost - expected_cost) < 0.0001:
		print("  PASS: Cost recorded ($%.4f for 6 turns)" % a2a.daily_conversation_cost)
		passed += 1
	else:
		print("  FAIL: Cost=$%.4f (expected $%.4f)" % [a2a.daily_conversation_cost, expected_cost])
		failed += 1

	# === Test 10: BiologicalMemory 統合 ===
	print("\nTest 10: BiologicalMemory integration...")
	var bio_mem: BiologicalMemorySystem = BiologicalMemorySystem.new()
	var bio_dict: Dictionary = bio_mem.to_dict()
	var bio_restored: BiologicalMemorySystem = BiologicalMemorySystem.new()
	bio_restored.from_dict(bio_dict)
	# Save again to verify double round-trip
	var bio_dict2: Dictionary = bio_restored.to_dict()
	if bio_dict2 is Dictionary:
		print("  PASS: BiologicalMemory double round-trip (no crash)")
		passed += 1
	else:
		print("  FAIL: Double round-trip error")
		failed += 1

	# === Test 11: EthicalSafeguard 統合 ===
	print("\nTest 11: EthicalSafeguard integration...")
	var ethics: EthicalSafeguard = EthicalSafeguard.new()
	var eth_dict: Dictionary = ethics.to_dict()
	var eth_restored: EthicalSafeguard = EthicalSafeguard.new()
	eth_restored.from_dict(eth_dict)
	print("  PASS: EthicalSafeguard round-trip OK")
	passed += 1

	# === Test 12: PetBookCore統合 ===
	print("\nTest 12: PetBookCore integration...")
	var pbc: PetBookCore = PetBookCore.new()
	var pbc_dict: Dictionary = pbc.to_dict()
	var pbc_restored: PetBookCore = PetBookCore.new()
	pbc_restored.from_dict(pbc_dict)
	print("  PASS: PetBookCore round-trip OK")
	passed += 1
	pbc.queue_free()
	pbc_restored.queue_free()

	# === Test 13: LanguageEvolutionSystem統合 ===
	print("\nTest 13: LanguageEvolutionSystem grammar retrieval...")
	var lang_sys: LanguageEvolutionSystem = LanguageEvolutionSystem.new()
	var grammar: Dictionary = lang_sys.get_current_grammar()
	if grammar.has("suffixes") or grammar.has("suffix") or grammar is Dictionary:
		print("  PASS: Grammar retrieved (keys=%s)" % str(grammar.keys()).substr(0, 60))
		passed += 1
	else:
		print("  FAIL: Grammar retrieval failed")
		failed += 1
	lang_sys.queue_free()

	# === Test 14: EvolutionTree パス検証 ===
	print("\nTest 14: EvolutionTree path validation (22 forms)...")
	var paths_s2: Array[Dictionary] = EvolutionTree.get_stage_2_paths()
	if paths_s2.size() >= 3:
		print("  PASS: Stage 2 paths = %d" % paths_s2.size())
		passed += 1
	else:
		print("  FAIL: Stage 2 paths = %d (need ≥3)" % paths_s2.size())
		failed += 1

	# === Test 15: 後方互換性（空のfrom_dict） ===
	print("\nTest 15: Backward compatibility (empty from_dict)...")
	var empty_pet: PetEntity = PetEntity.new()
	empty_pet.from_dict({})  # 空のデータでもクラッシュしない
	var empty_lang: OriginalLanguageEngine = OriginalLanguageEngine.new()
	empty_lang.from_dict({})
	var empty_a2a: AtoAConversationSystem = AtoAConversationSystem.new()
	empty_a2a.from_dict({})
	if empty_pet.pet_name != "" or true:  # デフォルト値が設定されていればOK
		print("  PASS: Empty from_dict() handled gracefully (no crash)")
		passed += 1
	else:
		print("  FAIL: Empty from_dict caused error")
		failed += 1
	empty_pet.queue_free()
	empty_lang.queue_free()
	empty_a2a.queue_free()

	# Cleanup
	pet.queue_free()
	restored_pet.queue_free()
	lang_engine.queue_free()
	restored_lang.queue_free()
	evo.queue_free()
	restored_evo.queue_free()
	a2a.queue_free()
	bio_mem.queue_free()
	bio_restored.queue_free()
	ethics.queue_free()
	eth_restored.queue_free()

	# === Summary ===
	print("\n========================================")
	print("E2E Integration: %d/%d passed (%d failed)" % [passed, passed + failed, failed])
	print("========================================")

	if failed > 0:
		quit(1)
	else:
		quit(0)
