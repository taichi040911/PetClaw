## EggHatchScreen — 卵孵化演出画面
## タップで卵にヒビが入り、孵化してペットが生まれる
## P4: 10秒フック — 最初の体験を印象的にする
class_name EggHatchScreen
extends Control

signal hatch_completed(pet: PetEntity)

# === UI ===
var _egg_sprite: TextureRect
var _crack_overlay: TextureRect
var _instruction_label: Label
var _name_input: LineEdit
var _confirm_button: Button
var _hatch_progress: float = 0.0
var _tap_count: int = 0
var _is_hatching: bool = false
var _is_naming: bool = false

# === Constants ===
const TAPS_TO_HATCH: int = 10
const CRACK_STAGES: int = 4


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# 背景
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.15)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# 卵コンテナ（中央）
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# 卵スプライト（プレースホルダー：カラーレクト）
	_egg_sprite = TextureRect.new()
	_egg_sprite.custom_minimum_size = Vector2(120, 160)
	_egg_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(_egg_sprite)

	# 卵の代替表示（テクスチャなし時）
	var egg_visual: ColorRect = ColorRect.new()
	egg_visual.custom_minimum_size = Vector2(120, 160)
	egg_visual.color = Color(0.9, 0.85, 0.7)
	egg_visual.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(egg_visual)

	# ヒビ表示用オーバーレイ
	_crack_overlay = TextureRect.new()
	_crack_overlay.custom_minimum_size = Vector2(120, 160)
	_crack_overlay.modulate = Color(0.3, 0.2, 0.1, 0.0)
	vbox.add_child(_crack_overlay)

	# 指示テキスト
	_instruction_label = Label.new()
	_instruction_label.text = "Tap the egg to hatch!"
	_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instruction_label.add_theme_font_size_override("font_size", 20)
	_instruction_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	vbox.add_child(_instruction_label)

	# 名前入力（最初は非表示）
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Name your pet..."
	_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_input.custom_minimum_size = Vector2(200, 40)
	_name_input.visible = false
	vbox.add_child(_name_input)

	_confirm_button = Button.new()
	_confirm_button.text = "Welcome!"
	_confirm_button.custom_minimum_size = Vector2(120, 44)
	_confirm_button.visible = false
	_confirm_button.pressed.connect(_on_confirm_name)
	vbox.add_child(_confirm_button)


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

	# ヒビの段階表示
	var crack_stage: int = int(_hatch_progress * CRACK_STAGES)
	_crack_overlay.modulate.a = _hatch_progress * 0.8

	# 卵を揺らすアニメーション
	var shake_amount: float = _hatch_progress * 8.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:x", position.x + shake_amount, 0.05)
	tween.tween_property(self, "position:x", position.x - shake_amount, 0.05)
	tween.tween_property(self, "position:x", position.x, 0.05)

	# 進捗テキスト
	_instruction_label.text = "Tap! (%d/%d)" % [_tap_count, TAPS_TO_HATCH]

	if _tap_count >= TAPS_TO_HATCH:
		_start_hatch_animation()


func _start_hatch_animation() -> void:
	_is_hatching = true
	_instruction_label.text = "Hatching...!"

	# 孵化演出
	var tween: Tween = create_tween()

	# 卵が光る
	tween.tween_property(_crack_overlay, "modulate", Color(1.0, 1.0, 0.8, 1.0), 0.5)

	# 画面フラッシュ
	var flash: ColorRect = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_preset(PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	tween.tween_property(flash, "color:a", 0.8, 0.3)
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		flash.queue_free()
		_show_naming_screen()
	)


func _show_naming_screen() -> void:
	_is_hatching = false
	_is_naming = true

	_instruction_label.text = "A new life is born! Give it a name."
	_name_input.visible = true
	_confirm_button.visible = true
	_name_input.grab_focus()

	# 卵を隠す
	_crack_overlay.visible = false


func _on_confirm_name() -> void:
	var pet_name: String = _name_input.text.strip_edges()
	if pet_name.is_empty():
		pet_name = "Mimi"  # デフォルト名

	# ペットを作成
	var new_pet: PetEntity = PetEntity.new()
	new_pet.pet_name = pet_name
	new_pet.evolution_stage = 0  # 卵から孵化直後

	# GameManager に登録
	if GameManager.instance:
		GameManager.instance.register_pet(new_pet)

		# EmotionSystem に初期感情を設定
		if GameManager.instance.emotion_system:
			GameManager.instance.emotion_system.stimulate(
				new_pet.pet_id, "joy", 0.5
			)
			GameManager.instance.emotion_system.stimulate(
				new_pet.pet_id, "curiosity", 0.3
			)

	hatch_completed.emit(new_pet)
