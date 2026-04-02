## PersonalityBadge — 性格トレイトをコンパクトに表示するUIコンポーネント
## メインUIに組み込み、ペットの性格傾向を色付きバッジで可視化
class_name PersonalityBadge
extends HBoxContainer

# === Trait Icons & Colors ===
const TRAIT_CONFIG: Dictionary = {
	"brave": {"icon": "🗡", "label": "Brave", "color": Color(0.9, 0.5, 0.3)},
	"curious": {"icon": "🔍", "label": "Curious", "color": Color(0.4, 0.8, 0.9)},
	"calm": {"icon": "🌿", "label": "Calm", "color": Color(0.5, 0.8, 0.5)},
	"affectionate": {"icon": "💕", "label": "Loving", "color": Color(0.9, 0.5, 0.65)},
	"playful": {"icon": "⭐", "label": "Playful", "color": Color(0.95, 0.8, 0.3)},
}

var _badges: Array[Control] = []
var _pet_entity: PetEntity


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 6)


func set_pet(pet: PetEntity) -> void:
	_pet_entity = pet
	update_display()


func update_display() -> void:
	# 古いバッジをクリア
	for badge: Control in _badges:
		if is_instance_valid(badge):
			badge.queue_free()
	_badges.clear()

	if not _pet_entity:
		return

	# 上位2つのトレイトを取得
	var sorted_traits: Array[Dictionary] = []
	for trait_name: String in _pet_entity.personality:
		var value: float = _pet_entity.personality[trait_name]
		sorted_traits.append({"name": trait_name, "value": value})

	sorted_traits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["value"] > b["value"]
	)

	# 上位2つ（閾値0.5以上）のみ表示
	var shown: int = 0
	for trait_data: Dictionary in sorted_traits:
		if shown >= 2:
			break
		if trait_data["value"] < 0.5:
			continue

		var trait_name: String = trait_data["name"]
		var config: Dictionary = TRAIT_CONFIG.get(trait_name, {})
		if config.is_empty():
			continue

		var badge: PanelContainer = _create_badge(
			config.get("icon", "?"),
			config.get("label", trait_name),
			config.get("color", Color.WHITE),
			trait_data["value"]
		)
		add_child(badge)
		_badges.append(badge)
		shown += 1

	# トレイトが一つもない場合
	if shown == 0:
		var label: Label = Label.new()
		label.text = "Developing..."
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		add_child(label)
		_badges.append(label)


func _create_badge(icon: String, label_text: String, color: Color, value: float) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()

	# バッジスタイル
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.6)
	style.bg_color.a = 0.6
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 3)
	panel.add_child(hbox)

	var icon_label: Label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 11)
	hbox.add_child(icon_label)

	var text_label: Label = Label.new()
	# 値が高いほどラベルが明るい
	var brightness: float = 0.5 + value * 0.5
	text_label.text = label_text
	text_label.add_theme_font_size_override("font_size", 10)
	text_label.add_theme_color_override("font_color", Color(brightness, brightness, brightness + 0.1))
	hbox.add_child(text_label)

	return panel
