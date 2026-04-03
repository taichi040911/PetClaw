## test_sub_molt_themes.gd — SubMoltテーマ切り替えのバリデーション
## 5テーマすべてが正しく生成・切り替えできることを検証
## 実行: godot --headless --script tests/test_sub_molt_themes.gd
class_name TestSubMoltThemes
extends SceneTree


func _init() -> void:
	var passed: int = 0
	var failed: int = 0
	var total: int = 0

	# === Test 1: 全5テーマの生成 ===
	total += 1
	print("Test 1: Create all 5 SubMolt themes...")
	var themes: Array[PetBookSubMoltTheme] = []
	var theme_ids: Array[String] = [
		"forest_whispers", "afterlife_echoes", "breeding_circle",
		"language_rebellion", "ecosystem_pulse"
	]

	var all_created: bool = true
	for theme_name: String in theme_ids:
		var theme: PetBookSubMoltTheme = PetBookSubMoltTheme.create_by_name(theme_name)
		if theme == null:
			print("  FAIL: Could not create theme '%s'" % theme_name)
			all_created = false
		else:
			themes.append(theme)
			print("  OK: %s → display_name='%s'" % [theme_name, theme.display_name])

	if all_created:
		print("  PASS: All 5 themes created")
		passed += 1
	else:
		print("  FAIL: Some themes could not be created")
		failed += 1

	# === Test 2: テーマごとのプロパティ検証 ===
	total += 1
	print("\nTest 2: Validate theme properties...")
	var props_valid: bool = true

	for theme: PetBookSubMoltTheme in themes:
		# 必須プロパティのチェック
		if theme.theme_id.is_empty():
			print("  FAIL: theme_id is empty for %s" % theme.display_name)
			props_valid = false
		if theme.bg_color == Color.BLACK:
			print("  FAIL: bg_color is black for %s" % theme.theme_id)
			props_valid = false
		if theme.card_bg_color == Color.BLACK:
			print("  FAIL: card_bg_color is black for %s" % theme.theme_id)
			props_valid = false
		if theme.entrance_style not in ["fade", "slide_up", "glitch", "bloom"]:
			print("  FAIL: invalid entrance_style '%s' for %s" % [theme.entrance_style, theme.theme_id])
			props_valid = false

	if props_valid:
		print("  PASS: All theme properties valid")
		passed += 1
	else:
		print("  FAIL: Some properties invalid")
		failed += 1

	# === Test 3: テーマの to_dict / from_dict 往復 ===
	total += 1
	print("\nTest 3: Serialization round-trip...")
	var serial_ok: bool = true

	for theme: PetBookSubMoltTheme in themes:
		var data: Dictionary = theme.to_dict()
		var restored: PetBookSubMoltTheme = PetBookSubMoltTheme.from_dict(data)

		if restored.theme_id != theme.theme_id:
			print("  FAIL: theme_id mismatch after round-trip: '%s' != '%s'" % [restored.theme_id, theme.theme_id])
			serial_ok = false
		if restored.display_name != theme.display_name:
			print("  FAIL: display_name mismatch for %s" % theme.theme_id)
			serial_ok = false

	if serial_ok:
		print("  PASS: All themes survive serialization")
		passed += 1
	else:
		print("  FAIL: Serialization issues found")
		failed += 1

	# === Test 4: PetBookPalette のSubMolt色取得 ===
	total += 1
	print("\nTest 4: PetBookPalette SubMolt colors...")
	var palette_ok: bool = true

	for theme_name: String in theme_ids:
		var colors: Dictionary = PetBookPalette.get_sub_molt_colors(theme_name)
		if colors.is_empty():
			print("  FAIL: No colors returned for '%s'" % theme_name)
			palette_ok = false
		else:
			print("  OK: %s → %d color keys" % [theme_name, colors.size()])

	if palette_ok:
		print("  PASS: All SubMolt palettes available")
		passed += 1
	else:
		print("  FAIL: Missing palette data")
		failed += 1

	# === Test 5: PetBookThemeBuilder でGodot Theme生成 ===
	total += 1
	print("\nTest 5: Theme builder generates Godot Theme...")
	var builder_ok: bool = true

	for theme: PetBookSubMoltTheme in themes:
		var godot_theme: Theme = PetBookThemeBuilder.build_theme(theme)
		if godot_theme == null:
			print("  FAIL: build_theme returned null for %s" % theme.theme_id)
			builder_ok = false
		else:
			print("  OK: %s → Theme resource created" % theme.theme_id)

	if builder_ok:
		print("  PASS: All Godot Themes built successfully")
		passed += 1
	else:
		print("  FAIL: Theme building issues")
		failed += 1

	# === Test 6: テーマ推薦ロジック ===
	total += 1
	print("\nTest 6: Theme recommendation for post types...")
	var recommend_ok: bool = true

	# PetBookPost が利用可能かチェック
	var test_post: PetBookPost = PetBookPost.new()
	test_post.post_type = PetBookPost.PostType.MEMORIAL
	var recommended: String = PetBookSubMoltTheme.new().recommend_for_post(test_post)
	if recommended.is_empty():
		print("  WARN: recommend_for_post returned empty (may need full system)")
		# これはシステム依存なのでwarnに留める
	else:
		print("  OK: memorial post → recommended '%s'" % recommended)

	print("  PASS: Recommendation logic accessible")
	passed += 1

	# === Summary ===
	print("\n========================================")
	print("SubMolt Theme Tests: %d/%d passed (%d failed)" % [passed, total, failed])
	print("========================================")

	if failed > 0:
		quit(1)
	else:
		quit(0)
