## SplashScreen — アプリ起動時のブランドスプラッシュ
## ロゴ + タイトル + バージョンを表示して自動フェードアウト
## P4: 10秒フック — 最初の印象で引き込む
class_name SplashScreen
extends Control

signal splash_finished

const BG_COLOR: Color = Color(0.04, 0.05, 0.10)
const TITLE_COLOR: Color = Color(0.95, 0.75, 0.2)
const SUB_COLOR: Color = Color(0.6, 0.65, 0.75)
const VERSION_COLOR: Color = Color(0.4, 0.4, 0.5)

const DISPLAY_DURATION: float = 2.0
const FADE_IN_DURATION: float = 0.6
const FADE_OUT_DURATION: float = 0.4


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	modulate.a = 0.0
	_build_ui()
	_play_animation()


func _build_ui() -> void:
	# 背景
	var bg: ColorRect = ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# 中央コンテナ
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# ペットアイコン（ピクセルアート卵）
	var egg_texture: ImageTexture = SpritePlaceholderGenerator.generate_egg()
	var egg_sprite: TextureRect = TextureRect.new()
	egg_sprite.texture = egg_texture
	egg_sprite.custom_minimum_size = Vector2(80, 100)
	egg_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	egg_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	egg_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	egg_sprite.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(egg_sprite)

	# タイトル
	var title: Label = Label.new()
	title.text = "PetClaw"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# サブタイトル
	var subtitle: Label = Label.new()
	subtitle.text = "AI Virtual Pet Simulation"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", SUB_COLOR)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	# バージョン
	var version: Label = Label.new()
	version.text = "v0.3.0 Alpha"
	version.add_theme_font_size_override("font_size", 11)
	version.add_theme_color_override("font_color", VERSION_COLOR)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(version)

	# 装飾: 左右の星パーティクル
	for i: int in range(8):
		var star: Label = Label.new()
		star.text = ["·", "✦", "·", "✧"][i % 4]
		star.add_theme_font_size_override("font_size", randi_range(10, 18))
		star.add_theme_color_override("font_color", Color(0.5, 0.45, 0.7, randf_range(0.2, 0.5)))
		star.position = Vector2(randf_range(40, 680), randf_range(100, 1100))
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(star)


func _play_animation() -> void:
	# フェードイン
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION)

	# 待機
	tween.tween_interval(DISPLAY_DURATION)

	# フェードアウト
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)

	# 完了
	tween.tween_callback(func() -> void:
		splash_finished.emit()
		queue_free()
	)


func _input(event: InputEvent) -> void:
	# タップでスキップ
	if event is InputEventMouseButton and event.pressed:
		_skip()


func _skip() -> void:
	# 即座にフェードアウト
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void:
		splash_finished.emit()
		queue_free()
	)
