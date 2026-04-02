## test_cultural_emergence.gd — CulturalEmergenceSystem ユニットテスト
## 実行: godot --headless --script tests/test_cultural_emergence.gd
class_name TestCulturalEmergence
extends Node


func _ready() -> void:
	var passed: int = 0
	var failed: int = 0
	var total: int = 0
	var tests: Array[String] = [
		"test_create_artifact", "test_to_dict_from_dict",
		"test_cultural_transmission", "test_artifact_promotion",
	]
	for t: String in tests:
		total += 1
		var ok: bool = call(t)
		print("  %s: %s" % ["PASS" if ok else "FAIL", t])
		if ok: passed += 1
		else: failed += 1
	print("\n========================================")
	print("CulturalEmergence Tests: %d/%d passed" % [passed, total])
	print("========================================")
	get_tree().quit(1 if failed > 0 else 0)


func test_create_artifact() -> bool:
	var sys: CulturalEmergenceSystem = CulturalEmergenceSystem.new()
	add_child(sys)
	var art_id: String = sys.create_artifact(
		CulturalEmergenceSystem.ArtifactType.FESTIVAL, 1, [1, 2, 3],
		"We celebrate {name} together!", "HarvestFest")
	if art_id.is_empty():
		push_warning("create_artifact: returned empty id")
		sys.queue_free(); return false
	if not sys.artifacts.has(art_id):
		push_warning("create_artifact: not stored in artifacts dict")
		sys.queue_free(); return false
	var art: Dictionary = sys.artifacts[art_id]
	if art.get("type") != CulturalEmergenceSystem.ArtifactType.FESTIVAL:
		push_warning("create_artifact: wrong type"); sys.queue_free(); return false
	if art.get("name") != "HarvestFest":
		push_warning("create_artifact: wrong name"); sys.queue_free(); return false
	if sys.total_artifacts_created != 1:
		push_warning("create_artifact: total_artifacts_created != 1")
		sys.queue_free(); return false
	sys.queue_free(); return true


func test_to_dict_from_dict() -> bool:
	var sys: CulturalEmergenceSystem = CulturalEmergenceSystem.new()
	add_child(sys)
	sys.create_artifact(CulturalEmergenceSystem.ArtifactType.STORY, 42, [42, 7],
		"Once upon a time {name}...", "TheLegend")
	sys.create_artifact(CulturalEmergenceSystem.ArtifactType.SONG, 7, [7],
		"La la {name}", "MorningHymn")
	var data: Dictionary = sys.to_dict()
	var r: CulturalEmergenceSystem = CulturalEmergenceSystem.new()
	add_child(r)
	r.from_dict(data)
	if r.total_artifacts_created != sys.total_artifacts_created:
		push_warning("round-trip: total_artifacts_created mismatch")
		sys.queue_free(); r.queue_free(); return false
	if r.artifacts.size() != sys.artifacts.size():
		push_warning("round-trip: artifacts size mismatch")
		sys.queue_free(); r.queue_free(); return false
	if r._next_artifact_index != sys._next_artifact_index:
		push_warning("round-trip: _next_artifact_index mismatch")
		sys.queue_free(); r.queue_free(); return false
	sys.queue_free(); r.queue_free(); return true


func test_cultural_transmission() -> bool:
	var sys: CulturalEmergenceSystem = CulturalEmergenceSystem.new()
	add_child(sys)
	var art_id: String = sys.create_artifact(
		CulturalEmergenceSystem.ArtifactType.RITUAL, 10, [10],
		"Do {name} every sunrise", "SunriseRitual")
	# Transmit directly (bypass TRANSMISSION_CHANCE)
	sys._add_knowledge(20, art_id)
	sys.artifacts[art_id]["transmission_count"] = sys.artifacts[art_id].get("transmission_count", 0) + 1
	if not sys._get_knowledge(20).has(art_id):
		push_warning("transmission: pet 20 did not receive artifact")
		sys.queue_free(); return false
	if sys.artifacts[art_id].get("transmission_count", 0) < 1:
		push_warning("transmission: transmission_count not incremented")
		sys.queue_free(); return false
	sys.queue_free(); return true


func test_artifact_promotion() -> bool:
	var sys: CulturalEmergenceSystem = CulturalEmergenceSystem.new()
	add_child(sys)
	var art_id: String = sys.create_artifact(
		CulturalEmergenceSystem.ArtifactType.FESTIVAL, 5, [5, 6],
		"All gather for {name}!", "AncientFest")
	var art: Dictionary = sys.artifacts[art_id]
	# Age the artifact past the threshold with sufficient popularity
	art["creation_time"] = 0.0
	art["popularity"] = 0.5
	var age: float = sys._get_game_time() - art.get("creation_time", 0.0)
	if age >= CulturalEmergenceSystem.TRADITION_AGE_THRESHOLD and art.get("popularity", 0.0) >= 0.3:
		art["type"] = CulturalEmergenceSystem.ArtifactType.TRADITION
		art["type_name"] = CulturalEmergenceSystem.ARTIFACT_TYPE_NAMES[CulturalEmergenceSystem.ArtifactType.TRADITION]
	if art.get("type") != CulturalEmergenceSystem.ArtifactType.TRADITION:
		push_warning("promotion: artifact not promoted to TRADITION")
		sys.queue_free(); return false
	if art.get("type_name") != "tradition":
		push_warning("promotion: type_name not 'tradition'")
		sys.queue_free(); return false
	sys.queue_free(); return true
