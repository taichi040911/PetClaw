## DayNightCycle — 実時間ベースの昼夜サイクル
## 背景色・照明を実際の時刻に連動させ、生活感を演出
## ペットの行動にも時間帯の影響を与える
class_name DayNightCycle
extends Node

signal time_period_changed(period: String)

## 時間帯定義
enum TimePeriod {
	DAWN,      ## 5:00 - 7:59
	MORNING,   ## 8:00 - 11:59
	AFTERNOON, ## 12:00 - 16:59
	EVENING,   ## 17:00 - 19:59
	NIGHT,     ## 20:00 - 4:59
}

## 時間帯ごとの背景色
const PERIOD_COLORS: Dictionary = {
	TimePeriod.DAWN: Color(0.15, 0.10, 0.22),       # 薄紫 — 夜明け
	TimePeriod.MORNING: Color(0.10, 0.12, 0.20),     # 明るい紺 — 朝
	TimePeriod.AFTERNOON: Color(0.08, 0.10, 0.18),   # 標準 — 昼
	TimePeriod.EVENING: Color(0.14, 0.08, 0.12),     # 暖色紫 — 夕方
	TimePeriod.NIGHT: Color(0.04, 0.04, 0.10),       # 深い紺 — 夜
}

## 時間帯ごとのアンビエント光の色調（ペットのmodulate用）
const PERIOD_TINTS: Dictionary = {
	TimePeriod.DAWN: Color(0.95, 0.85, 0.95),
	TimePeriod.MORNING: Color(1.0, 1.0, 1.0),
	TimePeriod.AFTERNOON: Color(1.0, 1.0, 0.98),
	TimePeriod.EVENING: Color(1.0, 0.9, 0.8),
	TimePeriod.NIGHT: Color(0.7, 0.7, 0.9),
}

## 時間帯ごとの文字列名
const PERIOD_NAMES: Dictionary = {
	TimePeriod.DAWN: "dawn",
	TimePeriod.MORNING: "morning",
	TimePeriod.AFTERNOON: "afternoon",
	TimePeriod.EVENING: "evening",
	TimePeriod.NIGHT: "night",
}

var current_period: TimePeriod = TimePeriod.AFTERNOON
var _target_bg_color: Color = PERIOD_COLORS[TimePeriod.AFTERNOON]
var _target_tint: Color = PERIOD_TINTS[TimePeriod.AFTERNOON]
var _bg_node: ColorRect
var _pet_area_node: SubViewportContainer

static var instance: DayNightCycle


func _ready() -> void:
	instance = self
	_update_period()


func setup(bg: ColorRect, pet_area: SubViewportContainer) -> void:
	_bg_node = bg
	_pet_area_node = pet_area
	_update_period()
	# 即座に色を適用（補間なし）
	if _bg_node:
		_bg_node.color = _target_bg_color
	if _pet_area_node:
		_pet_area_node.modulate = _target_tint


func _process(_delta: float) -> void:
	_update_period()

	# 背景色をゆっくり補間
	if _bg_node:
		_bg_node.color = _bg_node.color.lerp(_target_bg_color, 0.01)

	# ペットエリアの色調をゆっくり補間
	if _pet_area_node:
		_pet_area_node.modulate = _pet_area_node.modulate.lerp(_target_tint, 0.01)


func _update_period() -> void:
	var hour: int = Time.get_datetime_dict_from_system()["hour"]
	var new_period: TimePeriod = _hour_to_period(hour)

	if new_period != current_period:
		current_period = new_period
		_target_bg_color = PERIOD_COLORS[current_period]
		_target_tint = PERIOD_TINTS[current_period]
		time_period_changed.emit(PERIOD_NAMES[current_period])


func _hour_to_period(hour: int) -> TimePeriod:
	if hour >= 5 and hour < 8:
		return TimePeriod.DAWN
	elif hour >= 8 and hour < 12:
		return TimePeriod.MORNING
	elif hour >= 12 and hour < 17:
		return TimePeriod.AFTERNOON
	elif hour >= 17 and hour < 20:
		return TimePeriod.EVENING
	else:
		return TimePeriod.NIGHT


## 現在の時間帯でペットが眠いかどうか
func is_sleepy_time() -> bool:
	return current_period == TimePeriod.NIGHT


## 現在の時間帯名を返す
func get_period_name() -> String:
	return PERIOD_NAMES.get(current_period, "afternoon")


## 現在の時間帯の背景色を返す（ムード色との合成用）
func get_bg_color() -> Color:
	return _target_bg_color
