## PetTouchHandler — ペットをタッチ/ドラッグで撫でるインタラクション
## SubViewportContainerに重ねて配置し、ドラッグ距離と速度で「なでなで」判定
## ハート/星パーティクルを生成し、affection/loveステータスに反映
class_name PetTouchHandler
extends Control

signal pet_stroked(stroke_quality: float)  ## 0.0〜1.0 のなでなで品質
signal heart_spawned(position: Vector2)

# === Configuration ===
const MIN_DRAG_DISTANCE: float = 20.0   ## ストローク判定の最小ドラッグ距離
const MAX_STROKE_SPEED: float = 800.0   ## これ以上速いと「粗い」扱い
const IDEAL_SPEED_MIN: float = 80.0     ## 理想的な撫で速度（下限）
const IDEAL_SPEED_MAX: float = 350.0    ## 理想的な撫で速度（上限）
const HEART_INTERVAL: float = 0.12      ## ハート生成間隔（秒）
const STROKE_COOLDOWN: float = 0.3      ## ストローク完了後のクールダウン
const PET_HIT_RADIUS: float = 120.0     ## ペットの当たり判定半径

# === State ===
var _is_dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO
var _drag_prev: Vector2 = Vector2.ZERO
var _total_drag_distance: float = 0.0
var _drag_speed: float = 0.0
var _heart_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _stroke_count: int = 0
var _combo_timer: float = 0.0
var _pet_center: Vector2 = Vector2(360, 400)  ## PetDisplay位置

# === Visual ===
var _hearts: Array[Label] = []
var _wiggle_target: Node2D  ## VisualBridge を wiggle させる参照


func _ready() -> void:
	# フルスクリーンで入力を受ける透明オーバーレイ
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS  # 下のノードにも伝搬


func setup(pet_center: Vector2, wiggle_node: Node2D = null) -> void:
	_pet_center = pet_center
	_wiggle_target = wiggle_node


func _gui_input(event: InputEvent) -> void:
	if _cooldown_timer > 0.0:
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_drag(mb.position)
			else:
				_end_drag(mb.position)

	elif event is InputEventMouseMotion and _is_dragging:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		_update_drag(mm.position, mm.velocity)

	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_start_drag(st.position)
		else:
			_end_drag(st.position)

	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event as InputEventScreenDrag
		_update_drag(sd.position, sd.velocity)


func _process(delta: float) -> void:
	# クールダウン
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

	# コンボタイマー
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_stroke_count = 0

	# ハート生成タイマー
	if _is_dragging:
		_heart_timer += delta

	# 死んだハートを掃除
	_hearts = _hearts.filter(func(h: Label) -> bool: return is_instance_valid(h))


func _start_drag(pos: Vector2) -> void:
	# ペット付近のタッチのみ反応
	if not _is_near_pet(pos):
		return

	_is_dragging = true
	_drag_start = pos
	_drag_prev = pos
	_total_drag_distance = 0.0
	_drag_speed = 0.0
	_heart_timer = 0.0

	# タッチ開始のリアクション — 小さなハート
	_spawn_touch_indicator(pos)


func _update_drag(pos: Vector2, velocity: Vector2) -> void:
	var segment: float = pos.distance_to(_drag_prev)
	_total_drag_distance += segment
	_drag_speed = velocity.length()
	_drag_prev = pos

	# ドラッグ中にハートを定期的に生成
	if _heart_timer >= HEART_INTERVAL and _is_near_pet(pos):
		_heart_timer = 0.0
		var quality: float = _calculate_stroke_quality()
		if quality > 0.3:
			_spawn_heart(pos, quality)
			# ウィグル（揺れ）アニメーション
			if _wiggle_target:
				_apply_wiggle()


func _end_drag(pos: Vector2) -> void:
	if not _is_dragging:
		return
	_is_dragging = false

	# 十分な距離をドラッグしたかチェック
	if _total_drag_distance < MIN_DRAG_DISTANCE:
		return

	var quality: float = _calculate_stroke_quality()
	if quality > 0.1:
		_stroke_count += 1
		_combo_timer = 2.0
		_cooldown_timer = STROKE_COOLDOWN

		# コンボボーナス
		var combo_mult: float = minf(1.0 + _stroke_count * 0.1, 1.5)
		var final_quality: float = minf(quality * combo_mult, 1.0)

		pet_stroked.emit(final_quality)

		# コンボ表示
		if _stroke_count >= 3:
			_spawn_combo_text(pos)


func _calculate_stroke_quality() -> float:
	## ストローク品質を計算（0.0〜1.0）
	## 理想: ゆっくり〜中程度の速度で、ある程度の距離をなでる
	if _total_drag_distance < MIN_DRAG_DISTANCE:
		return 0.0

	# 距離スコア（長いほどいい、上限あり）
	var dist_score: float = clampf(_total_drag_distance / 200.0, 0.0, 1.0)

	# 速度スコア（理想速度範囲に近いほど高い）
	var speed_score: float = 0.0
	if _drag_speed < IDEAL_SPEED_MIN:
		speed_score = _drag_speed / IDEAL_SPEED_MIN  # 遅すぎ
	elif _drag_speed <= IDEAL_SPEED_MAX:
		speed_score = 1.0  # 理想範囲
	else:
		speed_score = maxf(0.0, 1.0 - (_drag_speed - IDEAL_SPEED_MAX) / MAX_STROKE_SPEED)  # 速すぎ

	return dist_score * 0.4 + speed_score * 0.6


func _is_near_pet(pos: Vector2) -> bool:
	## ペット付近かどうか判定（SubViewportContainer内の座標系）
	# PetAreaの範囲内（上部62%画面）で中心付近
	var screen_height: float = get_viewport_rect().size.y
	if pos.y > screen_height * 0.62:
		return false  # UIパネル領域

	# ペット中心からの距離
	var center: Vector2 = Vector2(get_viewport_rect().size.x * 0.5, screen_height * 0.32)
	return pos.distance_to(center) < PET_HIT_RADIUS


# ========================================================
# Visual Effects
# ========================================================

func _spawn_heart(pos: Vector2, quality: float) -> void:
	var heart: Label = Label.new()

	# 品質に応じたエフェクト文字
	if quality > 0.8:
		heart.text = ["♥", "💕", "✨"][randi() % 3]
	elif quality > 0.5:
		heart.text = ["♥", "♪"][randi() % 2]
	else:
		heart.text = "♥"

	var size: int = int(14 + quality * 14)
	heart.add_theme_font_size_override("font_size", size)

	# 品質に応じた色（低=薄ピンク、高=濃いピンク/赤）
	var color: Color = Color(1.0, 0.4 + (1.0 - quality) * 0.4, 0.5 + (1.0 - quality) * 0.3, 0.9)
	heart.add_theme_color_override("font_color", color)

	# ランダムなオフセット
	heart.position = pos + Vector2(randf_range(-30, 30), randf_range(-20, 10))
	heart.z_index = 100
	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heart)
	_hearts.append(heart)

	heart_spawned.emit(pos)

	# 浮遊アニメーション
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	var float_y: float = heart.position.y - randf_range(60, 120)
	var sway_x: float = heart.position.x + randf_range(-40, 40)
	tween.tween_property(heart, "position:y", float_y, randf_range(0.6, 1.2)).set_ease(Tween.EASE_OUT)
	tween.tween_property(heart, "position:x", sway_x, randf_range(0.6, 1.2)).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(heart, "modulate:a", 0.0, 0.8).set_delay(0.3)
	# スケールアップ
	heart.scale = Vector2(0.5, 0.5)
	tween.tween_property(heart, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(heart.queue_free)


func _spawn_touch_indicator(pos: Vector2) -> void:
	## タッチ開始時の小さなリング
	var indicator: Label = Label.new()
	indicator.text = "·"
	indicator.add_theme_font_size_override("font_size", 32)
	indicator.add_theme_color_override("font_color", Color(1.0, 0.8, 0.9, 0.6))
	indicator.position = pos - Vector2(8, 16)
	indicator.z_index = 99
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(indicator)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(indicator, "scale", Vector2(2.0, 2.0), 0.3)
	tween.tween_property(indicator, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(indicator.queue_free)


func _spawn_combo_text(pos: Vector2) -> void:
	var combo_label: Label = Label.new()
	combo_label.text = "x%d Combo!" % _stroke_count
	combo_label.add_theme_font_size_override("font_size", 18)
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	combo_label.position = pos + Vector2(-40, -50)
	combo_label.z_index = 101
	combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(combo_label)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(combo_label, "position:y", combo_label.position.y - 50, 0.8)
	tween.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.15)
	tween.chain().tween_property(combo_label, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(combo_label.queue_free)


func _apply_wiggle() -> void:
	if not _wiggle_target:
		return

	# ペットが左右に揺れる（なでなでリアクション）
	var tween: Tween = _wiggle_target.create_tween()
	var orig_rot: float = _wiggle_target.rotation
	var wiggle_amount: float = deg_to_rad(randf_range(3.0, 8.0))
	var direction: float = [-1.0, 1.0][randi() % 2]

	tween.tween_property(_wiggle_target, "rotation",
		orig_rot + wiggle_amount * direction, 0.06)
	tween.tween_property(_wiggle_target, "rotation",
		orig_rot - wiggle_amount * direction * 0.5, 0.08)
	tween.tween_property(_wiggle_target, "rotation",
		orig_rot, 0.06)
