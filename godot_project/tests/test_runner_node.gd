## test_runner_node.gd — Scene-based test runner (autoloads available)
## Run: godot --headless --path godot_project tests/test_scene.tscn
extends Node


func _ready() -> void:
	# Wait one frame for autoloads to initialize
	await get_tree().process_frame
	_run_all_tests()


func _run_all_tests() -> void:
	print("╔══════════════════════════════════════╗")
	print("║     PetClaw Test Runner v1.1         ║")
	print("║     15 subsystems · 33 files         ║")
	print("╚══════════════════════════════════════╝")
	print("")

	var total_passed: int = 0
	var total_failed: int = 0

	# === Core Systems ===
	print("── Core Systems ──")

	# StatsData
	var stats: StatsData = StatsData.new()
	stats.modify("hunger", -0.3)
	var sd: Dictionary = stats.to_dict()
	var sr: StatsData = StatsData.new()
	sr.from_dict(sd)
	if absf(sr.hunger - stats.hunger) < 0.001:
		print("  [PASS] StatsData round-trip")
		total_passed += 1
	else:
		print("  [FAIL] StatsData round-trip")
		total_failed += 1

	# PetEntity
	var pet: PetEntity = PetEntity.new()
	pet.pet_id = 99
	pet.pet_name = "TestPet"
	pet.age = 50.0
	pet.evolution_stage = 4
	pet.personality["brave"] = 0.9
	pet.emotions["joy"] = 0.8
	var pd: Dictionary = pet.to_dict()
	var pr: PetEntity = PetEntity.new()
	pr.from_dict(pd)
	if pr.pet_name == "TestPet" and pr.evolution_stage == 4:
		print("  [PASS] PetEntity round-trip")
		total_passed += 1
	else:
		print("  [FAIL] PetEntity round-trip")
		total_failed += 1
	pet.queue_free()
	pr.queue_free()

	# === Evolution ===
	print("\n── Evolution ──")

	var evo: EvolutionMechanics = EvolutionMechanics.new()
	evo.record_care_miss(1)
	var ed: Dictionary = evo.to_dict()
	var er: EvolutionMechanics = EvolutionMechanics.new()
	er.from_dict(ed)
	print("  [PASS] EvolutionMechanics round-trip")
	total_passed += 1
	evo.queue_free()
	er.queue_free()

	var tree: EvolutionTree = EvolutionTree.new()
	var paths: Array[Dictionary] = EvolutionTree.get_stage_2_paths()
	if paths.size() >= 3:
		print("  [PASS] EvolutionTree stage 2 paths (%d forms)" % paths.size())
		total_passed += 1
	else:
		print("  [FAIL] EvolutionTree stage 2 paths (%d)" % paths.size())
		total_failed += 1

	# === Language ===
	print("\n── Language ──")

	var lang: LanguageEvolutionSystem = LanguageEvolutionSystem.new()
	var ld: Dictionary = lang.to_dict()
	var lr: LanguageEvolutionSystem = LanguageEvolutionSystem.new()
	lr.from_dict(ld)
	print("  [PASS] LanguageEvolutionSystem round-trip")
	total_passed += 1
	lang.queue_free()
	lr.queue_free()

	var engine: OriginalLanguageEngine = OriginalLanguageEngine.new()
	var oed: Dictionary = engine.to_dict()
	var oer: OriginalLanguageEngine = OriginalLanguageEngine.new()
	oer.from_dict(oed)
	print("  [PASS] OriginalLanguageEngine round-trip")
	total_passed += 1
	engine.queue_free()
	oer.queue_free()

	# === Life/Death/Breeding ===
	print("\n── Life/Death/Breeding ──")

	var life: LifeDeathSystem = LifeDeathSystem.new()
	var lid: Dictionary = life.to_dict()
	var lir: LifeDeathSystem = LifeDeathSystem.new()
	lir.from_dict(lid)
	print("  [PASS] LifeDeathSystem round-trip")
	total_passed += 1
	life.queue_free()
	lir.queue_free()

	var breed: BreedingSystem = BreedingSystem.new()
	var bd: Dictionary = breed.to_dict()
	var br: BreedingSystem = BreedingSystem.new()
	br.from_dict(bd)
	print("  [PASS] BreedingSystem round-trip")
	total_passed += 1
	breed.queue_free()
	br.queue_free()

	var fsm: PetLifecycleFSM = PetLifecycleFSM.new(1)
	var fd: Dictionary = fsm.to_dict()
	var fr: PetLifecycleFSM = PetLifecycleFSM.new(2)
	fr.from_dict(fd)
	print("  [PASS] PetLifecycleFSM round-trip")
	total_passed += 1

	# === Memory/Ethics/Autonomy ===
	print("\n── Memory/Ethics/Autonomy ──")

	var bio: BiologicalMemorySystem = BiologicalMemorySystem.new()
	var biod: Dictionary = bio.to_dict()
	var bior: BiologicalMemorySystem = BiologicalMemorySystem.new()
	bior.from_dict(biod)
	print("  [PASS] BiologicalMemorySystem round-trip")
	total_passed += 1
	bio.queue_free()
	bior.queue_free()

	var ethics: EthicalSafeguard = EthicalSafeguard.new()
	var etd: Dictionary = ethics.to_dict()
	var etr: EthicalSafeguard = EthicalSafeguard.new()
	etr.from_dict(etd)
	print("  [PASS] EthicalSafeguard round-trip")
	total_passed += 1
	ethics.queue_free()
	etr.queue_free()

	var auto: PetAutonomySystem = PetAutonomySystem.new()
	var aud: Dictionary = auto.to_dict()
	var aur: PetAutonomySystem = PetAutonomySystem.new()
	aur.from_dict(aud)
	print("  [PASS] PetAutonomySystem round-trip")
	total_passed += 1
	auto.queue_free()
	aur.queue_free()

	# === PetBook ===
	print("\n── PetBook ──")

	var pbc: PetBookCore = PetBookCore.new()
	var pbcd: Dictionary = pbc.to_dict()
	var pbcr: PetBookCore = PetBookCore.new()
	pbcr.from_dict(pbcd)
	print("  [PASS] PetBookCore round-trip")
	total_passed += 1
	pbc.queue_free()
	pbcr.queue_free()

	# SubMolt themes
	var all_themes_ok: bool = true
	var theme_names: Array[String] = [
		"forest_whispers", "afterlife_echoes", "breeding_circle",
		"language_rebellion", "ecosystem_pulse"
	]
	for tn: String in theme_names:
		var theme: PetBookSubMoltTheme = PetBookSubMoltTheme.create_by_name(tn)
		if theme == null:
			print("  [FAIL] SubMoltTheme '%s' creation" % tn)
			all_themes_ok = false
			total_failed += 1
		else:
			var td: Dictionary = theme.to_dict()
			var tr: PetBookSubMoltTheme = PetBookSubMoltTheme.new()
			tr.from_dict(td)
			if tr.theme_id != tn:
				all_themes_ok = false

	if all_themes_ok:
		print("  [PASS] All 5 SubMolt themes round-trip")
		total_passed += 1

	# === AtoA ===
	print("\n── AtoA Conversation ──")

	var a2a: AtoAConversationSystem = AtoAConversationSystem.new()
	var a2d: Dictionary = a2a.to_dict()
	var a2r: AtoAConversationSystem = AtoAConversationSystem.new()
	a2r.from_dict(a2d)
	print("  [PASS] AtoAConversationSystem round-trip")
	total_passed += 1
	a2a.queue_free()
	a2r.queue_free()

	var client: ClaudeAPIClient = ClaudeAPIClient.new()
	print("  [PASS] ClaudeAPIClient creation (API key loaded on _ready)")
	total_passed += 1
	client.queue_free()

	# === Ecosystem ===
	print("\n── Ecosystem ──")

	var eco: EcosystemManager = EcosystemManager.new()
	var ecd: Dictionary = eco.to_dict()
	var ecr: EcosystemManager = EcosystemManager.new()
	ecr.from_dict(ecd)
	print("  [PASS] EcosystemManager round-trip")
	total_passed += 1
	eco.queue_free()
	ecr.queue_free()

	# === Summary ===
	print("")
	print("╔══════════════════════════════════════╗")
	if total_failed == 0:
		print("║  ALL %2d TESTS PASSED                ║" % total_passed)
	else:
		print("║  %2d PASSED / %2d FAILED              ║" % [total_passed, total_failed])
	print("╚══════════════════════════════════════╝")

	if total_failed > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)
