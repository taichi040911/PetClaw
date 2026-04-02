## MiniGameScreen — タップタイミングミニゲーム
## 「遊ぶ」ボタンで起動。ターゲットが流れてくるのをタイミングよくタップ
## スコアに応じてペットの mood/excitement/affection が上がる
class_name MiniGameScreen
extends Control

signal game_finished(score: int, max_score: int)

## ゲーム設定
const GAME_DURATION: float = 10.0
const TARGET_INTERVAL_MIN: float = 0.6
const TARGET_INTERVAL_MAX: float = 1.2
const TARGET_SIZE: float = 60.0
const HIT_TOLERANCE: float = 80.0  # タップ判定の許容距離

## 色定義
const BG_COLOR: Color = Color(0.06, 0.08, 0.14)
const TARGET_COLOR: Color = Color(0.95, 0.75, 0.2)
const HIT_COLOR: Color = Color(0.3, 0.9, 0.4)
const MISS_COLOR: Color = Color(0.9, 0.3, 0.3)
const PERFECT_COLOR: Color = Color(1.0, 0.85, 0.0)

## 状態
var _score: int = 0
var _max_score: int = 0
var _game_timer: float = 0.0
var _spawn_timer: float = 0.0
var _is_playing: bool = false
var _targets: Array[Dictionary] = []  # {node, position, alive}

## UI参照
var _score_label: Label
var _timer_label: Label
var _combo_label: Label
var _result_panel: PanelContainer
var _game_area: Control
var _combo: int = 0
var _best_combo: int = 0


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()
	_start_game()


func _build_ui() -> void:
	# 背景
	var bg: ColorRect = ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# ゲームエリア
	_game_area = Control.new()
	_game_area.set_anchors_preset(PRESET_FULL_RECT)
	_game_area.offset_top = 60
	_game_area.offset_bottom = -80
	_game_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_game_area.gui_input.connect(_on_game_area_input)
	add_child(_game_area)

	# スコア表示（左上）
	_score_label = Label.new()
	_score_label.text = "Score: 0"
	_score_label.add_theme_font_size_override("font_size", 22)
	_score_label.add_theme_color_override("font_color", Color.WHITE)
	_score_label.position = Vector2(16, 12)
	add_child(_score_label)

	# タイマー表示（右上）
	_timer_label = Label.new()
	_timer_label.text = "10.0"
	_timer_label.add_theme_font_size_override("font_size", 22)
	_timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	_timer_label.set_anchors_preset(PRESET_TOP_RIGHT)
	_timer_label.offset_left = -80
	_timer_label.offset_top = 12
	add_child(_timer_label)

	# コンボ表示（中央上）
	_combo_label = Label.new()
	_combo_label.text = ""
	_combo_label.add_theme_font_size_override("font_size", 28)
	_combo_label.add_theme_color_override("font_color", PERFECT_COLOR)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.set_anchors_preset(PRESET_CENTER_TOP)
	_combo_label.offset_top = 8
	_combo_label.offset_left = -100
	_combo_label.offset_right = 100
	add_child(_combo_label)

	# ヘルプテキスト
	var help: Label = Label.new()
	help.text = "Tap the stars! ⭐"
	help.add_theme_font_size_override("font_size", 14)
	help.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.set_anchors_preset(PRESET_BOTTOM_WIDE)
	help.offset_top = -40
	add_child(help)


func _start_game() -> void:
	_score = 0
	_max_score = 0
	_game_timer = GAME_DURATION
	_spawn_timer = 0.5  # 最初のターゲットまで少し待つ
	_combo = 0
	_best_combo = 0
	_is_playing = true

	# SFX
	if SfxManager.instance:
		SfxManager.instance.play(SfxManager.SfxType.UI_OPEN)


func _process(delta: float) -> void:
	if not _is_playing:
		return

	# ゲームタイマー
	_game_timer -= delta
	_timer_label.text = "%.1f" % maxf(_game_timer, 0.0)

	if _game_timer <= 0.0:
		_end_game()
		return

	# タイマー色変化
	if _game_timer < 3.0:
		_timer_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	elif _game_timer < 5.0:
		_timer_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))

	# ターゲット生成
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_target()
		_spawn_timer = randf_range(TARGET_INTERVAL_MIN, TARGET_INTERVAL_MAX)

	# ターゲットアニメーション更新
	_update_targets(delta)


func _spawn_target() -> void:
	_max_score += 1

	var area_size: Vector2 = _game_area.size
	var margin: float = TARGET_SIZE
	var pos: Vector2 = Vector2(
		randf_range(margin, area_size.x - margin),
		randf_range(margin, area_size.y - margin)
	)

	# ターゲットノード作成（星形の代わりにColorRect + ラベル）
	var container: Control = Control.new()
	container.position = pos - Vector2(TARGET_SIZE / 2, TARGET_SIZE / 2)
	container.custom_minimum_size = Vector2(TARGET_SIZE, TARGET_SIZE)
	container.size = Vector2(TARGET_SIZE, TARGET_SIZE)
	container.pivot_offset = Vector2(TARGET_SIZE / 2, TARGET_SIZE / 2)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var circle: ColorRect = ColorRect.new()
	circle.color = TARGET_COLOR
	circle.custom_minimum_size = Vector2(TARGET_SIZE, TARGET_SIZE)
	circle.size = Vector2(TARGET_SIZE, TARGET_SIZE)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(circle)

	var star: Label = Label.new()
	star.text = "⭐"
	star.add_theme_font_size_override("font_size", 28)
	star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star.set_anchors_preset(PRESET_FULL_RECT)
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(star)

	_game_area.add_child(container)

	# 出現アニメ
	container.scale = Vector2(0.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK)

	_targets.append({
		"node": container,
		"position": pos,
		"alive": true,
		"lifetime": 0.0,
		"max_life": randf_range(1.5, 2.5),
	})


func _update_targets(delta: float) -> void:
	var to_remove: Array[int] = []
	for i: int in range(_targets.size()):
		if not _targets[i]["alive"]:
			continue
		_targets[i]["lifetime"] += delta

		var lifetime: float = _targets[i]["lifetime"]
		var max_life: float = _targets[i]["max_life"]
		var node: Control = _targets[i]["node"]

		# 寿命に応じてフェードアウト
		var life_ratio: float = lifetime / max_life
		if life_ratio > 0.7:
			node.modulate.a = (1.0 - life_ratio) / 0.3

		# 寿命切れ → ミス
		if lifetime >= max_life:
			_targets[i]["alive"] = false
			_combo = 0
			_combo_label.text = ""
			_spawn_miss_effect(node.position + Vector2(TARGET_SIZE / 2, TARGET_SIZE / 2))
			node.queue_free()
			to_remove.append(i)

	# 除去（逆順）
	for i: int in range(to_remove.size() - 1, -1, -1):
		_targets.remove_at(to_remove[i])


func _on_game_area_input(event: InputEvent) -> void:
	if not _is_playing:
		return
	if not (event is InputEventMouseButton and event.pressed):
		return

	var tap_pos: Vector2 = event.position
	var hit: bool = false

	for i: int in range(_targets.size()):
		if not _targets[i]["alive"]:
			continue

		var target_pos: Vector2 = _targets[i]["position"]
		var dist: float = tap_pos.distance_to(target_pos)

		if dist <= HIT_TOLERANCE:
			# ヒット！
			hit = true
			_targets[i]["alive"] = false
			_score += 1
			_combo += 1
			_best_combo = maxi(_best_combo, _combo)

			# スコア更新
			_score_label.text = "Score: %d" % _score

			# コンボ表示
			if _combo >= 3:
				_combo_label.text = "%d Combo!" % _combo
				var combo_tween: Tween = create_tween()
				combo_tween.tween_property(_combo_label, "scale", Vector2(1.2, 1.2), 0.05)
				combo_tween.tween_property(_combo_label, "scale", Vector2(1.0, 1.0), 0.1)

			# ヒットエフェクト
			_spawn_hit_effect(target_pos)

			# SFX
			if SfxManager.instance:
				SfxManager.instance.play(SfxManager.SfxType.TAP)

			# ターゲットを消す
			_targets[i]["node"].queue_free()
			_targets.remove_at(i)
			break

	if not hit:
		# 空振り
		_combo = 0
		_combo_label.text = ""


func _spawn_hit_effect(pos: Vector2) -> void:
	var label: Label = Label.new()
	var texts: Array[String] = ["Nice!", "Great!", "⭐", "✨"]
	if _combo >= 5:
		texts = ["PERFECT!", "AMAZING!", "🌟🌟"]
	label.text = texts[randi() % texts.size()]
	label.add_theme_font_size_override("font_size", 18 + mini(_combo, 5) * 2)
	label.add_theme_color_override("font_color", HIT_COLOR if _combo < 5 else PERFECT_COLOR)
	label.position = pos - Vector2(30, 20)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game_area.add_child(label)

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 50, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)


func _spawn_miss_effect(pos: Vector2) -> void:
	var label: Label = Label.new()
	label.text = "Miss"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", MISS_COLOR)
	label.position = pos - Vector2(15, 10)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game_area.add_child(label)

	var tween: Tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)


func _end_game() -> void:
	_is_playing = false

	# 残りターゲットを消す
	for target: Dictionary in _targets:
		if target["alive"] and is_instance_valid(target["node"]):
			target["node"].queue_free()
	_targets.clear()

	# SFX
	if SfxManager.instance:
		if _score >= _max_score * 0.8:
			SfxManager.instance.play(SfxManager.SfxType.LEVEL_UP)
		else:
			SfxManager.instance.play(SfxManager.SfxType.HAPPY)

	# リザルト表示
	_show_result()


func _show_result() -> void:
	_result_panel = PanelContainer.new()
	_result_panel.set_anchors_preset(PRESET_CENTER)
	_result_panel.offset_left = -140
	_result_panel.offset_right = 140
	_result_panel.offset_top = -120
	_result_panel.offset_bottom = 120

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.2, 0.95)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	_result_panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_result_panel.add_child(vbox)

	# 評価
	var grade: String = ""
	var grade_color: Color = Color.WHITE
	var ratio: float = float(_score) / maxf(float(_max_score), 1.0)
	if ratio >= 0.9:
		grade = "⭐ PERFECT! ⭐"
		grade_color = PERFECT_COLOR
	elif ratio >= 0.7:
		grade = "Great!"
		grade_color = HIT_COLOR
	elif ratio >= 0.5:
		grade = "Good"
		grade_color = Color(0.7, 0.8, 0.9)
	else:
		grade = "Try again!"
		grade_color = Color(0.6, 0.6, 0.7)

	var grade_label: Label = Label.new()
	grade_label.text = grade
	grade_label.add_theme_font_size_override("font_size", 26)
	grade_label.add_theme_color_override("font_color", grade_color)
	grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(grade_label)

	var score_display: Label = Label.new()
	score_display.text = "Score: %d / %d" % [_score, _max_score]
	score_display.add_theme_font_size_override("font_size", 20)
	score_display.add_theme_color_override("font_color", Color.WHITE)
	score_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(score_display)

	if _best_combo >= 3:
		var combo_display: Label = Label.new()
		combo_display.text = "Best Combo: %d" % _best_combo
		combo_display.add_theme_font_size_override("font_size", 16)
		combo_display.add_theme_color_override("font_color", Color(0.8, 0.75, 0.5))
		combo_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(combo_display)

	var close_btn: Button = Button.new()
	close_btn.text = "Done"
	close_btn.custom_minimum_size = Vector2(120, 40)
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.3, 0.5, 0.8)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	close_btn.add_theme_stylebox_override("normal", btn_style)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.pressed.connect(func() -> void:
		game_finished.emit(_score, _max_score)
		queue_free()
	)
	vbox.add_child(close_btn)

	add_child(_result_panel)

	# フェードイン
	_result_panel.modulate.a = 0.0
	_result_panel.scale = Vector2(0.8, 0.8)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_result_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(_result_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
