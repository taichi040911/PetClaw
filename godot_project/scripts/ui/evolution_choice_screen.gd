## EvolutionChoiceScreen — 進化選択UI
## 進化条件を満たしたとき、利用可能な進化パスを提示
## プレイヤーが選択 → 進化実行 → 演出
class_name EvolutionChoiceScreen
extends Control

signal evolution_chosen(pet_id: int, form_id: String)
signal evolution_cancelled

var _pet_id: int = 0
var _choices: Array[Dictionary] = []
var _vbox: VBoxContainer
var _title_label: Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# 半透明背景
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# 中央パネル
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(PRESET_CENTER)
	panel.custom_minimum_size = Vector2(500, 400)
	panel.offset_left = -250
	panel.offset_top = -200
	panel.offset_right = 250
	panel.offset_bottom = 200
	add_child(panel)

	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.12, 0.14, 0.22)
	stylebox.border_color = Color(0.4, 0.5, 0.8)
	stylebox.set_border_width_all(2)
	stylebox.set_corner_radius_all(12)
	stylebox.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", stylebox)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 12)
	panel.add_child(_vbox)

	_title_label = Label.new()
	_title_label.text = "Evolution Available!"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	_vbox.add_child(_title_label)

	var separator: HSeparator = HSeparator.new()
	_vbox.add_child(separator)


func show_choices(pet_id: int, choices: Array[Dictionary]) -> void:
	_pet_id = pet_id
	_choices = choices

	# ペット名を取得
	var pet_name: String = "Your pet"
	if GameManager.instance and GameManager.instance.pets.has(pet_id):
		pet_name = GameManager.instance.pets[pet_id].pet_name

	_title_label.text = "%s can evolve!" % pet_name

	# 選択肢ボタンを生成
	for choice: Dictionary in choices:
		var btn_container: PanelContainer = PanelContainer.new()
		var btn_style: StyleBoxFlat = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.18, 0.2, 0.3)
		btn_style.set_border_width_all(1)
		btn_style.border_color = Color(0.3, 0.4, 0.6)
		btn_style.set_corner_radius_all(8)
		btn_style.set_content_margin_all(12)
		btn_container.add_theme_stylebox_override("panel", btn_style)
		_vbox.add_child(btn_container)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		btn_container.add_child(hbox)

		# 形態アイコン（実際のスプライトまたはプレースホルダー）
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(56, 56)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		var form_id_for_icon: String = choice.get("id", "blob")
		var sprite_path: String = "res://assets/sprites/forms/%s.png" % form_id_for_icon
		if ResourceLoader.exists(sprite_path):
			icon.texture = load(sprite_path)
		else:
			icon.texture = SpritePlaceholderGenerator.generate_placeholder(form_id_for_icon)
		hbox.add_child(icon)

		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)

		var name_label: Label = Label.new()
		name_label.text = choice.get("display_name", choice.get("id", "???"))
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
		info_vbox.add_child(name_label)

		# 条件表示
		var conditions: Dictionary = choice.get("conditions", {})
		var cond_text: String = ""
		if conditions.has("primary_environment"):
			cond_text += "Environment: %s  " % conditions["primary_environment"]
		if conditions.has("care_quality"):
			cond_text += "Care: %s" % conditions["care_quality"]

		if not cond_text.is_empty():
			var cond_label: Label = Label.new()
			cond_label.text = cond_text
			cond_label.add_theme_font_size_override("font_size", 12)
			cond_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
			info_vbox.add_child(cond_label)

		# ボーナス表示
		var bonuses: Dictionary = choice.get("stat_bonus", {})
		if not bonuses.is_empty():
			var bonus_parts: Array[String] = []
			for stat: String in bonuses:
				bonus_parts.append("+%s %s" % [bonuses[stat], stat])
			var bonus_label: Label = Label.new()
			bonus_label.text = ", ".join(bonus_parts)
			bonus_label.add_theme_font_size_override("font_size", 11)
			bonus_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
			info_vbox.add_child(bonus_label)

		# 選択ボタン
		var select_btn: Button = Button.new()
		select_btn.text = "⚡ Evolve"
		select_btn.custom_minimum_size = Vector2(90, 40)
		var form_id: String = choice.get("id", "")
		select_btn.pressed.connect(_on_choice_selected.bind(form_id))
		var evolve_style: StyleBoxFlat = StyleBoxFlat.new()
		evolve_style.bg_color = Color(0.3, 0.5, 0.9)
		evolve_style.set_corner_radius_all(8)
		select_btn.add_theme_stylebox_override("normal", evolve_style)
		var evolve_hover: StyleBoxFlat = evolve_style.duplicate()
		evolve_hover.bg_color = Color(0.4, 0.6, 1.0)
		select_btn.add_theme_stylebox_override("hover", evolve_hover)
		select_btn.add_theme_color_override("font_color", Color.WHITE)
		hbox.add_child(select_btn)

	# キャンセルボタン
	var cancel_btn: Button = Button.new()
	cancel_btn.text = "Not yet..."
	cancel_btn.custom_minimum_size = Vector2(120, 36)
	cancel_btn.pressed.connect(_on_cancel)
	_vbox.add_child(cancel_btn)

	# 表示アニメーション
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func _on_choice_selected(form_id: String) -> void:
	evolution_chosen.emit(_pet_id, form_id)

	# 進化演出
	var flash: ColorRect = ColorRect.new()
	flash.color = Color(1, 1, 0.8, 0)
	flash.set_anchors_preset(PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var tween: Tween = create_tween()
	tween.tween_property(flash, "color:a", 0.9, 0.3)
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(queue_free)


func _on_cancel() -> void:
	evolution_cancelled.emit()
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
