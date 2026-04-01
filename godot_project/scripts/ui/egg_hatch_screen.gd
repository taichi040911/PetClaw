## EggHatchScreen — 卵孵化演出画面
## タップで卵にヒビが入り、孵化してペットが生まれる
## P4: 10秒フック — 最初の体験を印象的にする
class_name EggHatchScreen
extends Control

signal hatch_completed(pet: PetEntity)

# === UI ===
var _egg_container: Control
var _egg_body: ColorRect
var _crack_lines: Array[ColorRect] = []
var _instruction_label: Label
var _tap_counter_label: Label
var _name_input: LineEdit
var _confirm_button: Button
var _particles: GPUParticles2D
var _bg: ColorRect
var _hatch_progress: float = 0.0
var _tap_count: int = 0
var _is_hatching: bool = false
var _is_naming: bool = false
var _idle_time: float = 0.0

# === Constants ===
const TAPS_TO_HATCH: int = 10
const EGG_COLOR: Color = Color(0.95, 0.9, 0.75)
const EGG_HIGHLIGHT: Color = Color(1.0, 0.97, 0.85)
const CRACK_COLOR: Color = Color(0.3, 0.25, 0.15)
const BG_COLOR: Color = Color(0.06, 0.07, 0.14)


func _ready() -> void:
	_build_ui()


func _process(delta: float) -> void:
	_idle_time += delta
	if _egg_body and not _is_hatching and not _is_naming:
		# 卵のゆらゆらアニメーション
		var sway: float = sin(_idle_time * 1.2) * 2.0
		_egg_container.rotation = deg_to_rad(sway)
		# 呼吸のような膨張
		var breathe: float = 1.0 + sin(_idle_time * 2.0) * 0.015
		_egg_container.scale = Vector2(breathe, breathe)


func _build_ui() -> void:
	# 背景（グラデーション風）
	_bg = ColorRect.new()
	_bg.color = BG_COLOR
	_bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_bg)

	# 星パーティクル背景
	_create_star_particles()

	# 中央コンテナ
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	# タイトルラベル
	var title: Label = Label.new()
	title.text = "A mysterious egg appears..."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
	vbox.add_child(title)

	# スペーサー
	var spacer1: Control = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)

	# 卵コンテナ（回転・スケール用）
	var egg_center: CenterContainer = CenterContainer.new()
	vbox.add_child(egg_center)

	_egg_container = Control.new()
	_egg_container.custom_minimum_size = Vector2(140, 180)
	_egg_container.pivot_offset = Vector2(70, 90)
	egg_center.add_child(_egg_container)

	# 卵本体（楕円的な表現 — 重ねた丸角レクト）
	_egg_body = ColorRect.new()
	_egg_body.custom_minimum_size = Vector2(120, 160)
	_egg_body.position = Vector2(10, 10)
	_egg_body.color = EGG_COLOR
	_egg_body.mouse_filter = Control.MOUSE_FILTER_PASS
	_egg_container.add_child(_egg_body)

	# 卵のハイライト
	var highlight: ColorRect = ColorRect.new()
	highlight.custom_minimum_size = Vector2(40, 60)
	highlight.position = Vector2(30, 25)
	highlight.color = EGG_HIGHLIGHT
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_egg_container.add_child(highlight)

	# ヒビ線（最初は非表示）
	for i: int in range(5):
		var crack: ColorRect = ColorRect.new()
		crack.custom_minimum_size = Vector2(randi_range(15, 40), 2)
		crack.position = Vector2(
			randi_range(20, 100),
			randi_range(30, 140)
		)
		crack.rotation = randf_range(-0.5, 0.5)
		crack.color = CRACK_COLOR
		crack.visible = false
		crack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_egg_container.add_child(crack)
		_crack_lines.append(crack)

	# タップカウンター
	_tap_counter_label = Label.new()
	_tap_counter_label.text = ""
	_tap_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap_counter_label.add_theme_font_size_override("font_size", 16)
	_tap_counter_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	vbox.add_child(_tap_counter_label)

	# 指示テキスト
	_instruction_label = Label.new()
	_instruction_label.text = "✨ Tap the egg to hatch! ✨"
	_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instruction_label.add_theme_font_size_override("font_size", 20)
	_instruction_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	vbox.add_child(_instruction_label)

	# 名前入力（最初は非表示）
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Name your pet..."
	_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_input.custom_minimum_size = Vector2(220, 44)
	_name_input.visible = false
	vbox.add_child(_name_input)

	# 入力フィールドスタイル
	var input_style: StyleBoxFlat = StyleBoxFlat.new()
	input_style.bg_color = Color(0.15, 0.17, 0.25)
	input_style.border_color = Color(0.4, 0.45, 0.6)
	input_style.set_border_width_all(2)
	input_style.corner_radius_top_left = 10
	input_style.corner_radius_top_right = 10
	input_style.corner_radius_bottom_left = 10
	input_style.corner_radius_bottom_right = 10
	input_style.content_margin_left = 12
	input_style.content_margin_right = 12
	_name_input.add_theme_stylebox_override("normal", input_style)
	_name_input.add_theme_color_override("font_color", Color.WHITE)
	_name_input.add_theme_color_override("font_placeholder_color", Color(0.5, 0.5, 0.6))

	_confirm_button = Button.new()
	_confirm_button.text = "🎉 Welcome!"
	_confirm_button.custom_minimum_size = Vector2(160, 48)
	_confirm_button.visible = false
	_confirm_button.pressed.connect(_on_confirm_name)
	vbox.add_child(_confirm_button)

	# ボタンスタイル
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.3, 0.6, 0.9)
	btn_style.corner_radius_top_left = 12
	btn_style.corner_radius_top_right = 12
	btn_style.corner_radius_bottom_left = 12
	btn_style.corner_radius_bottom_right = 12
	_confirm_button.add_theme_stylebox_override("normal", btn_style)
	var btn_hover: StyleBoxFlat = btn_style.duplicate()
	btn_hover.bg_color = Color(0.4, 0.7, 1.0)
	_confirm_button.add_theme_stylebox_override("hover", btn_hover)
	_confirm_button.add_theme_color_override("font_color", Color.WHITE)
	_confirm_button.add_theme_font_size_override("font_size", 18)

	# フェードイン
	modulate.a = 0.0
	var fade_in: Tween = create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, 0.5)


func _create_star_particles() -> void:
	_particles = GPUParticles2D.new()
	_particles.position = Vector2(360, 640)
	_particles.emitting = true
	_particles.amount = 30
	_particles.lifetime = 4.0

	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(360, 640, 0)
	mat.gravity = Vector3(0, -5, 0)
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 8.0
	mat.scale_min = 0.5
	mat.scale_max = 2.0
	mat.spread = 180.0

	var gradient: Gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.6, 0.65, 0.9, 0.0))
	gradient.add_point(0.3, Color(0.7, 0.75, 1.0, 0.4))
	gradient.add_point(1.0, Color(0.5, 0.55, 0.8, 0.0))
	var grad_tex: GradientTexture1D = GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_initial_ramp = grad_tex

	_particles.process_material = mat
	add_child(_particles)


func _gui_input(event: InputEvent) -> void:
	if _is_naming or _is_hatching:
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_on_egg_tapped()


func _on_egg_tapped() -> void:
	_tap_count += 1
	_hatch_progress = float(_tap_count) / float(TAPS_TO_HATCH)

	# ヒビを段階的に表示
	var cracks_to_show: int = int(_hatch_progress * _crack_lines.size())
	for i: int in range(_crack_lines.size()):
		if i < cracks_to_show:
			_crack_lines[i].visible = true

	# 卵を揺らすアニメーション（進むほど激しく）
	var shake_amount: float = _hatch_progress * 10.0
	var tween: Tween = create_tween()
	tween.tween_property(_egg_container, "position:x",
		_egg_container.position.x + shake_amount, 0.04)
	tween.tween_property(_egg_container, "position:x",
		_egg_container.position.x - shake_amount, 0.04)
	tween.tween_property(_egg_container, "position:x",
		_egg_container.position.x, 0.04)

	# 卵の色が段階的に明るく
	_egg_body.color = EGG_COLOR.lerp(Color(1.0, 1.0, 0.8), _hatch_progress * 0.5)

	# タップカウンター更新
	var dots: String = ""
	for i: int in range(_tap_count):
		dots += "●"
	for i: int in range(TAPS_TO_HATCH - _tap_count):
		dots += "○"
	_tap_counter_label.text = dots

	# テキスト変化
	if _tap_count < 3:
		_instruction_label.text = "Tap the egg! (%d/%d)" % [_tap_count, TAPS_TO_HATCH]
	elif _tap_count < 7:
		_instruction_label.text = "It's moving...! (%d/%d)" % [_tap_count, TAPS_TO_HATCH]
	else:
		_instruction_label.text = "Almost there!! (%d/%d)" % [_tap_count, TAPS_TO_HATCH]

	if _tap_count >= TAPS_TO_HATCH:
		_start_hatch_animation()


func _start_hatch_animation() -> void:
	_is_hatching = true
	_instruction_label.text = "✨ Hatching...! ✨"
	_tap_counter_label.text = ""

	var tween: Tween = create_tween()

	# 卵が激しく振動
	for i: int in range(8):
		var shake: float = (8 - i) * 3.0
		tween.tween_property(_egg_container, "position:x",
			_egg_container.position.x + shake, 0.03)
		tween.tween_property(_egg_container, "position:x",
			_egg_container.position.x - shake, 0.03)
	tween.tween_property(_egg_container, "position:x",
		_egg_container.position.x, 0.03)

	# 卵が白く光る
	tween.tween_property(_egg_body, "color", Color(1.0, 1.0, 0.9), 0.3)

	# 画面フラッシュ
	var flash: ColorRect = ColorRect.new()
	flash.color = Color(1, 1, 0.9, 0)
	flash.set_anchors_preset(PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 100
	add_child(flash)

	tween.tween_property(flash, "color:a", 0.9, 0.2)
	tween.tween_interval(0.3)
	tween.tween_property(flash, "color:a", 0.0, 0.8)
	tween.tween_callback(func() -> void:
		flash.queue_free()
		# 卵を非表示
		_egg_container.visible = false
		_show_naming_screen()
	)


func _show_naming_screen() -> void:
	_is_hatching = false
	_is_naming = true

	_instruction_label.text = "🎊 A new life is born!"
	_instruction_label.add_theme_font_size_override("font_size", 24)
	_instruction_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))

	_name_input.visible = true
	_confirm_button.visible = true

	# フェードイン
	_name_input.modulate.a = 0.0
	_confirm_button.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(_name_input, "modulate:a", 1.0, 0.3)
	tween.tween_property(_confirm_button, "modulate:a", 1.0, 0.3)
	tween.tween_callback(func() -> void: _name_input.grab_focus())


func _on_confirm_name() -> void:
	var pet_name: String = _name_input.text.strip_edges()
	if pet_name.is_empty():
		pet_name = ["Mimi", "Kuro", "Pochi", "Hana", "Sora"].pick_random()

	# ボタン無効化（二重押し防止）
	_confirm_button.disabled = true
	_instruction_label.text = "Welcome, %s! 🌟" % pet_name

	# フェードアウト後にペット作成
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		# ペットを作成
		var new_pet: PetEntity = PetEntity.new()
		new_pet.pet_name = pet_name
		new_pet.evolution_stage = 0

		# GameManager に登録
		if GameManager.instance:
			GameManager.instance.register_pet(new_pet)
			if GameManager.instance.emotion_system:
				GameManager.instance.emotion_system.stimulate(
					new_pet.pet_id, "joy", 0.5
				)
				GameManager.instance.emotion_system.stimulate(
					new_pet.pet_id, "curiosity", 0.3
				)

		hatch_completed.emit(new_pet)
	)
