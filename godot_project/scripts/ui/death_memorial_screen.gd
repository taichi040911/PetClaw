## DeathMemorialScreen — ペット死亡時の追悼画面
## 暗い背景に名前と思い出を表示。新しい卵を受け取るオプション
class_name DeathMemorialScreen
extends Control

signal new_egg_requested
signal back_to_main

## 色
const BG_COLOR: Color = Color(0.04, 0.04, 0.08)
const TITLE_COLOR: Color = Color(0.7, 0.65, 0.9)
const TEXT_COLOR: Color = Color(0.55, 0.55, 0.65)
const ACCENT_COLOR: Color = Color(0.5, 0.45, 0.75)

var _pet_name: String = ""
var _pet_age: float = 0.0
var _death_cause: String = ""
var _vbox: VBoxContainer


func setup(pet_name: String, pet_age: float, cause: String) -> void:
	_pet_name = pet_name
	_pet_age = pet_age
	_death_cause = cause


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	modulate.a = 0.0  # フェードイン用
	_build_ui()

	# SFX
	if SfxManager.instance:
		SfxManager.instance.play(SfxManager.SfxType.DEATH)

	# フェードイン
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.5)


func _build_ui() -> void:
	# 暗い背景
	var bg: ColorRect = ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# パーティクル（ゆっくり落ちる光の粒）
	_create_memorial_particles()

	# メインコンテンツ
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 16)
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(_vbox)

	# 十字架 / 追悼シンボル
	var symbol: Label = Label.new()
	symbol.text = "✦"
	symbol.add_theme_font_size_override("font_size", 48)
	symbol.add_theme_color_override("font_color", ACCENT_COLOR)
	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(symbol)

	# ペット名
	var name_label: Label = Label.new()
	name_label.text = _pet_name
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.add_theme_color_override("font_color", TITLE_COLOR)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(name_label)

	# 年齢
	var age_text: String = ""
	if _pet_age < 1.0:
		age_text = "Lived for %d minutes" % int(_pet_age * 60.0)
	else:
		age_text = "Lived for %.1f hours" % _pet_age
	var age_label: Label = Label.new()
	age_label.text = age_text
	age_label.add_theme_font_size_override("font_size", 16)
	age_label.add_theme_color_override("font_color", TEXT_COLOR)
	age_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(age_label)

	# セパレーター
	var sep: HSeparator = HSeparator.new()
	sep.custom_minimum_size = Vector2(200, 2)
	_vbox.add_child(sep)

	# 追悼メッセージ
	var messages: Array[String] = [
		"They lived a full life...",
		"Their memory lives on in the field.",
		"The stars welcome them home.",
		"A gentle soul returns to the cosmos.",
		"Their laughter echoes in the wind.",
	]
	var memorial_text: Label = Label.new()
	memorial_text.text = messages[randi() % messages.size()]
	memorial_text.add_theme_font_size_override("font_size", 18)
	memorial_text.add_theme_color_override("font_color", Color(0.65, 0.6, 0.8))
	memorial_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	memorial_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	memorial_text.custom_minimum_size = Vector2(300, 0)
	_vbox.add_child(memorial_text)

	# 死因
	if not _death_cause.is_empty():
		var cause_label: Label = Label.new()
		cause_label.text = "Cause: %s" % _death_cause
		cause_label.add_theme_font_size_override("font_size", 12)
		cause_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		cause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_vbox.add_child(cause_label)

	# スペーサー
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	_vbox.add_child(spacer)

	# ボタンエリア
	var btn_box: VBoxContainer = VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 12)
	_vbox.add_child(btn_box)

	# 新しい卵ボタン
	var new_egg_btn: Button = Button.new()
	new_egg_btn.text = "🥚 Receive a new egg"
	new_egg_btn.custom_minimum_size = Vector2(220, 48)
	var egg_style: StyleBoxFlat = StyleBoxFlat.new()
	egg_style.bg_color = Color(0.3, 0.35, 0.6)
	egg_style.corner_radius_top_left = 12
	egg_style.corner_radius_top_right = 12
	egg_style.corner_radius_bottom_left = 12
	egg_style.corner_radius_bottom_right = 12
	new_egg_btn.add_theme_stylebox_override("normal", egg_style)
	var egg_hover: StyleBoxFlat = egg_style.duplicate()
	egg_hover.bg_color = Color(0.4, 0.45, 0.7)
	new_egg_btn.add_theme_stylebox_override("hover", egg_hover)
	new_egg_btn.add_theme_color_override("font_color", Color.WHITE)
	new_egg_btn.add_theme_font_size_override("font_size", 16)
	new_egg_btn.pressed.connect(func() -> void:
		if SfxManager.instance:
			SfxManager.instance.play(SfxManager.SfxType.EGG_TAP)
		new_egg_requested.emit()
		_fade_out()
	)
	btn_box.add_child(new_egg_btn)

	# 戻るボタン
	var back_btn: Button = Button.new()
	back_btn.text = "Return"
	back_btn.custom_minimum_size = Vector2(220, 36)
	var back_style: StyleBoxFlat = StyleBoxFlat.new()
	back_style.bg_color = Color(0.2, 0.2, 0.28)
	back_style.corner_radius_top_left = 8
	back_style.corner_radius_top_right = 8
	back_style.corner_radius_bottom_left = 8
	back_style.corner_radius_bottom_right = 8
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	back_btn.pressed.connect(func() -> void:
		back_to_main.emit()
		_fade_out()
	)
	btn_box.add_child(back_btn)


func _fade_out() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)


func _create_memorial_particles() -> void:
	# 手動パーティクル（ゆっくり降る光の粒）
	for i: int in range(12):
		var particle: ColorRect = ColorRect.new()
		particle.custom_minimum_size = Vector2(3, 3)
		particle.size = Vector2(3, 3)
		particle.color = Color(0.6, 0.55, 0.8, 0.3)
		particle.position = Vector2(randf_range(20, 700), randf_range(-200, -20))
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(particle)

		# ゆっくり落下アニメ
		var duration: float = randf_range(6.0, 12.0)
		var tween: Tween = create_tween().set_loops()
		tween.tween_property(particle, "position:y", 1300.0, duration)
		tween.tween_callback(func() -> void:
			particle.position.y = randf_range(-100, -20)
			particle.position.x = randf_range(20, 700)
		)
