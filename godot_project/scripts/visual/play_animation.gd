## PlayAnimation — 遊びアクションの視覚エフェクト
## ボール/星が跳ねるアニメーション + ペットの興奮リアクション
class_name PlayAnimation
extends Node2D

signal animation_finished

const BALL_EMOJIS: Array = ["⚽", "🎾", "🏀", "⭐", "🎈"]
const SPARKLE_COLORS: Array = [
	Color(1.0, 0.9, 0.3),   # 黄色
	Color(0.3, 0.9, 1.0),   # シアン
	Color(1.0, 0.5, 0.8),   # ピンク
	Color(0.5, 1.0, 0.5),   # 緑
]


func play_start(pet_position: Vector2) -> void:
	# ボールが飛んでくるアニメーション
	var ball: Label = Label.new()
	ball.text = BALL_EMOJIS[randi() % BALL_EMOJIS.size()]
	ball.add_theme_font_size_override("font_size", 32)
	ball.position = Vector2(pet_position.x + 200, pet_position.y - 150)
	ball.z_index = 20
	add_child(ball)

	# アーチ状の軌道
	var tween: Tween = create_tween()
	tween.tween_property(ball, "position", pet_position + Vector2(0, -20), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func() -> void:
		# ヒット時のインパクト
		_spawn_impact(pet_position)
		ball.queue_free()
	)
	tween.tween_interval(0.3)
	tween.tween_callback(func() -> void:
		# バウンドする星
		_spawn_bouncing_stars(pet_position)
	)
	tween.tween_interval(0.8)
	tween.tween_callback(func() -> void:
		animation_finished.emit()
		queue_free()
	)


func play_result(pet_position: Vector2, grade: String) -> void:
	# 結果表示アニメーション
	var result_label: Label = Label.new()
	match grade:
		"perfect":
			result_label.text = "⭐ PERFECT! ⭐"
			result_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		"great":
			result_label.text = "✨ Great!"
			result_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
		"good":
			result_label.text = "👍 Good"
			result_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
		_:
			result_label.text = "Nice try!"
			result_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))

	result_label.add_theme_font_size_override("font_size", 28)
	result_label.position = pet_position + Vector2(-60, -80)
	result_label.z_index = 25
	add_child(result_label)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(result_label, "position:y", result_label.position.y - 60, 1.0)
	tween.tween_property(result_label, "scale", Vector2(1.3, 1.3), 0.2).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(result_label, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(func() -> void:
		result_label.queue_free()
		animation_finished.emit()
		queue_free()
	)

	# 結果に応じたパーティクル数
	var particle_count: int = 3
	match grade:
		"perfect": particle_count = 12
		"great": particle_count = 8
		"good": particle_count = 5

	for i: int in range(particle_count):
		_spawn_celebration_particle(pet_position, i * 0.05)


func _spawn_impact(pos: Vector2) -> void:
	# インパクトの放射状エフェクト
	for i: int in range(6):
		var spark: Label = Label.new()
		spark.text = "✦"
		spark.add_theme_font_size_override("font_size", int(randf_range(12, 20)))
		spark.add_theme_color_override("font_color", SPARKLE_COLORS[randi() % SPARKLE_COLORS.size()])
		spark.position = pos
		spark.z_index = 22
		add_child(spark)

		var angle: float = (TAU / 6.0) * i + randf_range(-0.3, 0.3)
		var dist: float = randf_range(40, 80)
		var target: Vector2 = pos + Vector2(cos(angle) * dist, sin(angle) * dist)

		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "position", target, 0.3).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "modulate:a", 0.0, 0.3).set_delay(0.1)
		tween.tween_property(spark, "rotation", randf_range(-1.0, 1.0), 0.3)
		tween.chain().tween_callback(spark.queue_free)


func _spawn_bouncing_stars(pos: Vector2) -> void:
	for i: int in range(3):
		var star: Label = Label.new()
		star.text = ["⭐", "✨", "🌟"][i]
		star.add_theme_font_size_override("font_size", int(randf_range(14, 22)))
		star.position = pos + Vector2(randf_range(-30, 30), 0)
		star.z_index = 21
		add_child(star)

		# バウンスアニメーション
		var delay: float = i * 0.1
		var peak_y: float = pos.y - randf_range(60, 100)

		var tween: Tween = create_tween()
		tween.tween_interval(delay)
		tween.tween_property(star, "position:y", peak_y, 0.25).set_ease(Tween.EASE_OUT)
		tween.tween_property(star, "position:y", pos.y, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
		tween.parallel().tween_property(star, "modulate:a", 0.0, 0.15).set_delay(0.3)
		tween.tween_callback(star.queue_free)


func _spawn_celebration_particle(pos: Vector2, delay: float) -> void:
	var particle: Label = Label.new()
	particle.text = ["✨", "⭐", "♪", "★", "·"][randi() % 5]
	particle.add_theme_font_size_override("font_size", int(randf_range(10, 18)))
	particle.add_theme_color_override("font_color", SPARKLE_COLORS[randi() % SPARKLE_COLORS.size()])
	particle.position = pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	particle.z_index = 24
	particle.modulate.a = 0.0
	add_child(particle)

	var angle: float = randf() * TAU
	var dist: float = randf_range(50, 120)
	var target: Vector2 = particle.position + Vector2(cos(angle) * dist, sin(angle) * dist - 40)

	var tween: Tween = create_tween()
	tween.tween_interval(delay)
	tween.set_parallel(true)
	tween.tween_property(particle, "modulate:a", 1.0, 0.1)
	tween.tween_property(particle, "position", target, randf_range(0.6, 1.0)).set_ease(Tween.EASE_OUT)
	tween.tween_property(particle, "rotation", randf_range(-1.5, 1.5), 0.8)
	tween.chain().tween_property(particle, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(particle.queue_free)
