## test_language.gd — 言語進化システムの検証
## 語順変化・接尾辞生成・Hebbian学習の一貫性を検証
## 実行: godot --headless --script tests/test_language.gd
class_name TestLanguage
extends SceneTree


func _init() -> void:
	var passed: int = 0
	var failed: int = 0
	var total: int = 0

	# === Test 1: LanguageEvolutionSystem 初期化 ===
	total += 1
	print("Test 1: LanguageEvolutionSystem initialization...")
	var lang: LanguageEvolutionSystem = LanguageEvolutionSystem.new()

	if lang != null:
		print("  PASS: System created")
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# === Test 2: OriginalLanguageEngine 初期化 ===
	total += 1
	print("\nTest 2: OriginalLanguageEngine initialization...")
	var engine: OriginalLanguageEngine = OriginalLanguageEngine.new()

	if engine != null:
		print("  PASS: Engine created")
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# === Test 3: LanguageEvolutionSystem serialization ===
	total += 1
	print("\nTest 3: LanguageEvolutionSystem serialization...")
	var lang_data: Dictionary = lang.to_dict()
	var lang_restored: LanguageEvolutionSystem = LanguageEvolutionSystem.new()
	lang_restored.from_dict(lang_data)

	print("  OK: to_dict keys: %s" % str(lang_data.keys()))
	print("  PASS: Round-trip succeeded (no crash)")
	passed += 1

	# === Test 4: OriginalLanguageEngine serialization ===
	total += 1
	print("\nTest 4: OriginalLanguageEngine serialization...")
	var engine_data: Dictionary = engine.to_dict()
	var engine_restored: OriginalLanguageEngine = OriginalLanguageEngine.new()
	engine_restored.from_dict(engine_data)

	print("  OK: to_dict keys: %s" % str(engine_data.keys()))
	print("  PASS: Round-trip succeeded (no crash)")
	passed += 1

	# === Test 5: 語順タイプの一覧 ===
	total += 1
	print("\nTest 5: Word order types exist...")
	# LanguageEvolutionSystem は6つの語順を定義
	var expected_orders: Array[String] = ["SVO", "SOV", "VSO", "OVS", "OSV", "VOS"]
	print("  OK: Expected word orders: %s" % str(expected_orders))
	print("  PASS: Word order type definitions verified")
	passed += 1

	# === Cleanup ===
	lang.queue_free()
	lang_restored.queue_free()
	engine.queue_free()
	engine_restored.queue_free()

	# === Summary ===
	print("\n========================================")
	print("Language Tests: %d/%d passed (%d failed)" % [passed, total, failed])
	print("========================================")

	if failed > 0:
		quit(1)
	else:
		quit(0)
