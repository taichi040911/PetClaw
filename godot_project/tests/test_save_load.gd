## test_save_load.gd — セーブ/ロード往復テスト
## 全サブシステムの to_dict() → from_dict() が正しく往復することを検証
## 実行: godot --headless --script tests/test_save_load.gd
class_name TestSaveLoad
extends SceneTree

const _StatsData = preload("res://scripts/core/stats_system.gd")
const _PetEntity = preload("res://scripts/core/pet_entity.gd")
const _PetBookSubMoltTheme = preload("res://scripts/ui/pet_book_sub_molt_theme.gd")
const _EvolutionMechanics = preload("res://scripts/evolution/evolution_mechanics.gd")
const _BiologicalMemorySystem = preload("res://scripts/memory/biological_memory_system.gd")
const _BreedingSystem = preload("res://scripts/life/breeding_system.gd")
const _LifeDeathSystem = preload("res://scripts/life/life_death_system.gd")


func _init() -> void:
	var passed: int = 0
	var failed: int = 0
	var total: int = 0

	# === Test: StatsData round-trip ===
	total += 1
	print("Test: StatsData serialization...")
	var stats: StatsData = StatsData.new()
	stats.modify("hunger", -0.3)
	stats.modify("health", -0.1)
	stats.modify("energy", -0.2)

	var stats_dict: Dictionary = stats.to_dict()
	var stats_restored: StatsData = StatsData.new()
	stats_restored.from_dict(stats_dict)

	if absf(stats_restored.hunger - stats.hunger) < 0.001 \
		and absf(stats_restored.health - stats.health) < 0.001 \
		and absf(stats_restored.energy - stats.energy) < 0.001:
		print("  PASS: StatsData round-trip OK")
		passed += 1
	else:
		print("  FAIL: StatsData mismatch")
		failed += 1

	# === Test: PetEntity round-trip ===
	total += 1
	print("\nTest: PetEntity serialization...")
	var pet: PetEntity = PetEntity.new()
	pet.pet_id = 42
	pet.pet_name = "TestPet"
	pet.age = 100.5
	pet.evolution_stage = 3
	pet.personality["brave"] = 0.8
	pet.emotions["joy"] = 0.7

	var pet_dict: Dictionary = pet.to_dict()
	var pet_restored: PetEntity = PetEntity.new()
	pet_restored.from_dict(pet_dict)

	if pet_restored.pet_name == "TestPet" \
		and pet_restored.pet_id == 42 \
		and absf(pet_restored.age - 100.5) < 0.001 \
		and pet_restored.evolution_stage == 3 \
		and absf(pet_restored.personality.get("brave", 0.0) - 0.8) < 0.001:
		print("  PASS: PetEntity round-trip OK")
		passed += 1
	else:
		print("  FAIL: PetEntity mismatch")
		failed += 1

	pet.queue_free()
	pet_restored.queue_free()

	# === Test: PetBookSubMoltTheme round-trip ===
	total += 1
	print("\nTest: PetBookSubMoltTheme serialization...")
	var theme: PetBookSubMoltTheme = PetBookSubMoltTheme.create(
		PetBookSubMoltTheme.SubMoltId.AFTERLIFE_ECHOES
	)
	var theme_dict: Dictionary = theme.to_dict()
	var theme_restored: PetBookSubMoltTheme = PetBookSubMoltTheme.from_dict(theme_dict)

	if theme_restored.theme_id == "afterlife_echoes" \
		and theme_restored.entrance_style == theme.entrance_style:
		print("  PASS: SubMoltTheme round-trip OK")
		passed += 1
	else:
		print("  FAIL: SubMoltTheme mismatch (id='%s', entrance='%s')" % [
			theme_restored.theme_id, theme_restored.entrance_style
		])
		failed += 1

	# === Test: EvolutionMechanics round-trip ===
	total += 1
	print("\nTest: EvolutionMechanics serialization...")
	var evo: EvolutionMechanics = EvolutionMechanics.new()
	var evo_dict: Dictionary = evo.to_dict()
	var evo_restored: EvolutionMechanics = EvolutionMechanics.new()
	evo_restored.from_dict(evo_dict)
	print("  PASS: EvolutionMechanics round-trip OK (no crash)")
	passed += 1

	# === Test: BiologicalMemorySystem round-trip ===
	total += 1
	print("\nTest: BiologicalMemorySystem serialization...")
	var bio_mem: BiologicalMemorySystem = BiologicalMemorySystem.new()
	var bio_dict: Dictionary = bio_mem.to_dict()
	var bio_restored: BiologicalMemorySystem = BiologicalMemorySystem.new()
	bio_restored.from_dict(bio_dict)
	print("  PASS: BiologicalMemorySystem round-trip OK (no crash)")
	passed += 1

	# === Test: BreedingSystem round-trip ===
	total += 1
	print("\nTest: BreedingSystem serialization...")
	var breed: BreedingSystem = BreedingSystem.new()
	var breed_dict: Dictionary = breed.to_dict()
	var breed_restored: BreedingSystem = BreedingSystem.new()
	breed_restored.from_dict(breed_dict)
	print("  PASS: BreedingSystem round-trip OK (no crash)")
	passed += 1

	# === Test: LifeDeathSystem round-trip ===
	total += 1
	print("\nTest: LifeDeathSystem serialization...")
	var life: LifeDeathSystem = LifeDeathSystem.new()
	var life_dict: Dictionary = life.to_dict()
	var life_restored: LifeDeathSystem = LifeDeathSystem.new()
	life_restored.from_dict(life_dict)
	print("  PASS: LifeDeathSystem round-trip OK (no crash)")
	passed += 1

	# === Summary ===
	print("\n========================================")
	print("Save/Load Tests: %d/%d passed (%d failed)" % [passed, total, failed])
	print("========================================")

	if failed > 0:
		quit(1)
	else:
		quit(0)
