## FeedingAnimation — フード投下→チョンプ→満足スパークルの演出
## ケアアクション「餌やり」時に再生するビジュアルエフェクト
class_name FeedingAnimation
extends Node2D

signal animation_finished

# === 定数 ===
const DROP_HEIGHT: float = 200.0
const DROP_DURATION: float = 0.6
const CHOMP_DURATION: float = 0.3
const SPARKLE_DURATION: float = 0.8
const SPARKLE_COUNT: int = 6
const SPARKLE_SPREAD: float = 60.0
const FOOD_FONT_SIZE: int = 48
const SPARKLE_FONT_SIZE: int = 32

# 空腹度に応じたフード絵文字（高い方がリッチ）
const FOOD_EMOJIS: Array[String] = [
	"🍖",  # hunger_level >= 0.75 — がっつり肉
	"🍕",  # hunger_level >= 0.50 — ピザ
	"🍎",  # hunger_level >= 0.25 — りんご
	"🧁",  # hunger_level <  0.25 — おやつ（満腹に近い）
]

const SPARKLE_EMOJI: String = "✨"

# === 内部状態 ===
var _is_playing: bool = false


## フード選択: 空腹度に応じて絵文字を返す
func _select_food_emoji(hunger_level: float) -> String:
	if hunger_level >= 0.75:
		return FOOD_EMOJIS[0]
	elif hunger_level >= 0.50:
		return FOOD_EMOJIS[1]
	elif hunger_level >= 0.25:
		return FOOD_EMOJIS[2]
	else:
		return FOOD_EMOJIS[3]


## メイン再生: フード投下 → チョンプ → スパークル → 自動クリーンアップ
func play_feed(pet_position: Vector2, hunger_level: float) -> void:
	if _is_playing:
		return
	_is_playing = true

	var food_emoji: String = _select_food_emoji(hunger_level)

	# --- Phase 1: フードドロップ ---
	var food_label: Label = _create_emoji_label(food_emoji, FOOD_FONT_SIZE)
	add_child(food_label)

	var start_pos: Vector2 = Vector2(pet_position.x, pet_position.y - DROP_HEIGHT)
	var end_pos: Vector2 = pet_position
	food_label.position = start_pos - food_label.size * 0.5

	var drop_tween: Tween = create_tween()
	drop_tween.set_ease(Tween.EASE_IN)
	drop_tween.set_trans(Tween.TRANS_QUAD)
	drop_tween.tween_property(
		food_label, "position:y",
		end_pos.y - food_label.size.y * 0.5,
		DROP_DURATION
	)

	await drop_tween.finished

	# フードラベル消去
	food_label.queue_free()

	# --- Phase 2: チョンプ（スケールパルス） ---
	await _play_chomp(pet_position)

	# --- Phase 3: 満足スパークル ---
	await _play_sparkles(pet_position)

	# --- クリーンアップ ---
	_is_playing = false
	animation_finished.emit()
	queue_free()


## チョンプ演出: 横に広がって→縦に伸びる スケールパルス
func _play_chomp(center: Vector2) -> void:
	var chomp_label: Label = _create_emoji_label("😋", FOOD_FONT_SIZE)
	add_child(chomp_label)
	chomp_label.position = center - chomp_label.size * 0.5
	chomp_label.pivot_offset = chomp_label.size * 0.5

	var chomp_tween: Tween = create_tween()

	# 横に広がる（squish）
	chomp_tween.tween_property(
		chomp_label, "scale",
		Vector2(1.4, 0.7),
		CHOMP_DURATION * 0.4
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# 縦に伸びる（stretch）
	chomp_tween.tween_property(
		chomp_label, "scale",
		Vector2(0.8, 1.3),
		CHOMP_DURATION * 0.3
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# 元に戻る
	chomp_tween.tween_property(
		chomp_label, "scale",
		Vector2(1.0, 1.0),
		CHOMP_DURATION * 0.3
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	await chomp_tween.finished
	chomp_label.queue_free()


## スパークル演出: 中心から放射状に ✨ が飛び散る
func _play_sparkles(center: Vector2) -> void:
	var sparkle_labels: Array[Label] = []
	var sparkle_tween: Tween = create_tween()
	sparkle_tween.set_parallel(true)

	for i: int in range(SPARKLE_COUNT):
		var label: Label = _create_emoji_label(SPARKLE_EMOJI, SPARKLE_FONT_SIZE)
		add_child(label)
		label.position = center - label.size * 0.5
		label.pivot_offset = label.size * 0.5
		label.modulate.a = 1.0
		sparkle_labels.append(label)

		# 放射方向を計算
		var angle: float = (TAU / SPARKLE_COUNT) * i
		var target_offset: Vector2 = Vector2(
			cos(angle) * SPARKLE_SPREAD,
			sin(angle) * SPARKLE_SPREAD
		)
		var target_pos: Vector2 = center + target_offset - label.size * 0.5

		# 各スパークルの移動 + フェードアウト
		var delay: float = randf_range(0.0, 0.15)

		sparkle_tween.tween_property(
			label, "position",
			target_pos,
			SPARKLE_DURATION
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(delay)

		sparkle_tween.tween_property(
			label, "modulate:a",
			0.0,
			SPARKLE_DURATION * 0.6
		).set_ease(Tween.EASE_IN).set_delay(delay + SPARKLE_DURATION * 0.4)

		sparkle_tween.tween_property(
			label, "scale",
			Vector2(0.3, 0.3),
			SPARKLE_DURATION
		).set_ease(Tween.EASE_IN).set_delay(delay)

	await sparkle_tween.finished

	for label: Label in sparkle_labels:
		label.queue_free()


## 絵文字ラベル生成ヘルパー
func _create_emoji_label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# サイズを固定して中心計算を安定させる
	label.custom_minimum_size = Vector2(font_size * 1.5, font_size * 1.5)
	label.size = label.custom_minimum_size
	return label
