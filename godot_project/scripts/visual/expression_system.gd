## ExpressionSystem — ペットの表情を感情・性格・状況から動的生成
## ピカチュウ36表情 + Ollobot動的目 + たまごっちドット絵表現を統合
## 目パターン×口パターンの組み合わせで数十種類の表情をカバー
class_name ExpressionSystem
extends Node

signal expression_changed(pet_id: int, expression: ExpressionState)


# ========================================================
# 表情パーツ定義
# ========================================================

## 目パターン（Ollobot-style動的目 + ピカチュウ表情分析ベース）
enum EyeShape {
	NORMAL,         # ●● 通常の丸い目
	HAPPY,          # ＾＾ 笑顔（下弧）
	EXCITED,        # ★★ キラキラ / 星
	SAD,            # ；； 下向き / 涙
	ANGRY,          # ＞＜ つり目
	SCARED,         # ◎◎ 見開き
	SLEEPY,         # ーー 半目
	LOVE,           # ♥♥ ハート目
	CURIOUS,        # ？● 片目大きめ / キョロ
	CLOSED,         # ×× 目閉じ（くしゃみ/衝撃）
	DOT,            # ・・ 点目（驚きすぎ/無表情）
	SPARKLE,        # ✧✧ 輝く瞳（進化時/特別イベント）
}

## 口パターン
enum MouthShape {
	NEUTRAL,        # ー 一文字
	SMILE,          # ⌒ 微笑み
	WIDE_SMILE,     # Ｕ 大笑い
	FROWN,          # ⌓ 不満/悲しみ
	OPEN,           # ○ 驚き/叫び
	WAVY,           # ～ 困惑/モゴモゴ
	CHOMP,          # ▽ 食事中
	POUT,           # ω ぷくー
	WHISTLE,        # ○ 口笛/歌
	TINY_SMILE,     # ` 小さな微笑み
}

## 付随エフェクト記号（ピカチュウ表情シートの記号補助）
enum ExpressionEffect {
	NONE,
	HEART,          # ♥ 愛情/好意
	MUSIC_NOTE,     # ♪ 楽しい/歌
	EXCLAMATION,    # ！ 驚き/発見
	QUESTION,       # ？ 困惑/好奇
	ANGER_MARK,     # 💢 怒りマーク
	SWEAT_DROP,     # 💦 冷や汗
	SPARKLES,       # ✨ キラキラ
	ZZZZZ,          # 💤 眠り
	TEARS,          # 涙
	BLUSH,          # 頬染め
	SHADOW,         # 影（ダーク進化関連）
}


# ========================================================
# 表情状態クラス
# ========================================================

class ExpressionState:
	var eye_shape: EyeShape = EyeShape.NORMAL
	var mouth_shape: MouthShape = MouthShape.NEUTRAL
	var effect: ExpressionEffect = ExpressionEffect.NONE
	var eye_openness: float = 1.0       # 0.0(閉)〜1.0(全開) — アニメーション用
	var pupil_size: float = 0.5         # 0.0(点)〜1.0(最大) — 興奮/恐怖で変化
	var blink_rate: float = 3.0         # 秒あたりのまばたき間隔
	var eye_offset: Vector2 = Vector2.ZERO  # 視線方向（ピクセル単位）

	func _to_string() -> String:
		return "Eye:%d Mouth:%d Fx:%d open:%.1f pupil:%.1f" % [
			eye_shape, mouth_shape, effect, eye_openness, pupil_size
		]

	func to_dict() -> Dictionary:
		return {
			"eye": eye_shape,
			"mouth": mouth_shape,
			"effect": effect,
			"eye_openness": eye_openness,
			"pupil_size": pupil_size,
			"blink_rate": blink_rate,
			"eye_offset_x": eye_offset.x,
			"eye_offset_y": eye_offset.y,
		}


# ========================================================
# 表情マッピングテーブル（ピカチュウ36表情分析ベース）
# ========================================================

## 感情 → 基本表情のマッピング
## 強度は3段階: low (0.15-0.4), mid (0.4-0.7), high (0.7+)
const EMOTION_EXPRESSION_MAP: Dictionary = {
	# --- joy ---
	"joy_low": {
		"eye": EyeShape.NORMAL,
		"mouth": MouthShape.TINY_SMILE,
		"effect": ExpressionEffect.NONE,
		"pupil": 0.55,
	},
	"joy_mid": {
		"eye": EyeShape.HAPPY,
		"mouth": MouthShape.SMILE,
		"effect": ExpressionEffect.MUSIC_NOTE,
		"pupil": 0.6,
	},
	"joy_high": {
		"eye": EyeShape.HAPPY,
		"mouth": MouthShape.WIDE_SMILE,
		"effect": ExpressionEffect.SPARKLES,
		"pupil": 0.65,
	},
	# --- fear ---
	"fear_low": {
		"eye": EyeShape.NORMAL,
		"mouth": MouthShape.WAVY,
		"effect": ExpressionEffect.SWEAT_DROP,
		"pupil": 0.6,
	},
	"fear_mid": {
		"eye": EyeShape.SCARED,
		"mouth": MouthShape.OPEN,
		"effect": ExpressionEffect.SWEAT_DROP,
		"pupil": 0.8,
	},
	"fear_high": {
		"eye": EyeShape.SCARED,
		"mouth": MouthShape.OPEN,
		"effect": ExpressionEffect.SWEAT_DROP,
		"pupil": 0.9,  # 恐怖で瞳孔拡大
	},
	# --- excitement ---
	"excitement_low": {
		"eye": EyeShape.NORMAL,
		"mouth": MouthShape.SMILE,
		"effect": ExpressionEffect.EXCLAMATION,
		"pupil": 0.6,
	},
	"excitement_mid": {
		"eye": EyeShape.EXCITED,
		"mouth": MouthShape.WIDE_SMILE,
		"effect": ExpressionEffect.SPARKLES,
		"pupil": 0.7,
	},
	"excitement_high": {
		"eye": EyeShape.SPARKLE,
		"mouth": MouthShape.WIDE_SMILE,
		"effect": ExpressionEffect.SPARKLES,
		"pupil": 0.75,
	},
	# --- sadness ---
	"sadness_low": {
		"eye": EyeShape.NORMAL,
		"mouth": MouthShape.FROWN,
		"effect": ExpressionEffect.NONE,
		"pupil": 0.4,
	},
	"sadness_mid": {
		"eye": EyeShape.SAD,
		"mouth": MouthShape.FROWN,
		"effect": ExpressionEffect.NONE,
		"pupil": 0.35,
	},
	"sadness_high": {
		"eye": EyeShape.SAD,
		"mouth": MouthShape.FROWN,
		"effect": ExpressionEffect.TEARS,
		"pupil": 0.3,   # 悲しみで瞳孔縮小
	},
	# --- love ---
	"love_low": {
		"eye": EyeShape.NORMAL,
		"mouth": MouthShape.TINY_SMILE,
		"effect": ExpressionEffect.BLUSH,
		"pupil": 0.55,
	},
	"love_mid": {
		"eye": EyeShape.HAPPY,
		"mouth": MouthShape.SMILE,
		"effect": ExpressionEffect.HEART,
		"pupil": 0.6,
	},
	"love_high": {
		"eye": EyeShape.LOVE,
		"mouth": MouthShape.SMILE,
		"effect": ExpressionEffect.HEART,
		"pupil": 0.65,
	},
}

## 状況 → 一時表情オーバーライド（ケア中、食事中、睡眠中など）
const ACTIVITY_EXPRESSION_MAP: Dictionary = {
	"eating": {
		"eye": EyeShape.HAPPY,
		"mouth": MouthShape.CHOMP,
		"effect": ExpressionEffect.NONE,
	},
	"sleeping": {
		"eye": EyeShape.SLEEPY,
		"mouth": MouthShape.NEUTRAL,
		"effect": ExpressionEffect.ZZZZZ,
		"eye_openness": 0.0,
	},
	"being_petted": {
		"eye": EyeShape.HAPPY,
		"mouth": MouthShape.SMILE,
		"effect": ExpressionEffect.HEART,
	},
	"sick": {
		"eye": EyeShape.SLEEPY,
		"mouth": MouthShape.WAVY,
		"effect": ExpressionEffect.SWEAT_DROP,
		"eye_openness": 0.4,
	},
	"evolving": {
		"eye": EyeShape.SPARKLE,
		"mouth": MouthShape.OPEN,
		"effect": ExpressionEffect.SPARKLES,
		"pupil": 0.9,
	},
	"dark_evolving": {
		"eye": EyeShape.DOT,
		"mouth": MouthShape.OPEN,
		"effect": ExpressionEffect.SHADOW,
		"pupil": 0.2,
	},
	"a2a_talking": {
		"eye": EyeShape.NORMAL,
		"mouth": MouthShape.OPEN,
		"effect": ExpressionEffect.NONE,
	},
	"a2a_listening": {
		"eye": EyeShape.CURIOUS,
		"mouth": MouthShape.NEUTRAL,
		"effect": ExpressionEffect.QUESTION,
	},
	"thinking": {
		"eye": EyeShape.CURIOUS,
		"mouth": MouthShape.POUT,
		"effect": ExpressionEffect.QUESTION,
	},
	"startled": {
		"eye": EyeShape.SCARED,
		"mouth": MouthShape.OPEN,
		"effect": ExpressionEffect.EXCLAMATION,
		"pupil": 0.85,
	},
	"angry_outburst": {
		"eye": EyeShape.ANGRY,
		"mouth": MouthShape.OPEN,
		"effect": ExpressionEffect.ANGER_MARK,
	},
	"whistling": {
		"eye": EyeShape.HAPPY,
		"mouth": MouthShape.WHISTLE,
		"effect": ExpressionEffect.MUSIC_NOTE,
	},
}


# ========================================================
# 状態管理
# ========================================================

var pet_expressions: Dictionary = {}           # pet_id → ExpressionState
var activity_overrides: Dictionary = {}        # pet_id → String (activity name)
var _blink_timers: Dictionary = {}             # pet_id → float (次のまばたきまで)
var _transition_progress: Dictionary = {}      # pet_id → float (0.0→1.0 遷移中)
var _prev_expressions: Dictionary = {}         # pet_id → ExpressionState (ブレンド元)

const TRANSITION_SPEED: float = 4.0            # 表情遷移速度（秒あたり）
const BLINK_DURATION: float = 0.15             # まばたきの長さ（秒）


# ========================================================
# メインループ
# ========================================================

func _process(delta: float) -> void:
	for pet_id in pet_expressions:
		_update_blink(pet_id, delta)
		_update_transition(pet_id, delta)


func register_pet(pet_id: int) -> void:
	if pet_id not in pet_expressions:
		pet_expressions[pet_id] = ExpressionState.new()
		_blink_timers[pet_id] = _random_blink_interval(3.0)


func unregister_pet(pet_id: int) -> void:
	pet_expressions.erase(pet_id)
	activity_overrides.erase(pet_id)
	_blink_timers.erase(pet_id)
	_transition_progress.erase(pet_id)
	_prev_expressions.erase(pet_id)


# ========================================================
# 表情の更新（EmotionSystem連携）
# ========================================================

func update_expression(pet: PetEntity) -> void:
	## ペットの感情状態から表情を計算
	## EmotionSystemの_check_dominant_emotionから呼ばれることを想定
	var state := _resolve_expression(pet)

	var current: ExpressionState = pet_expressions.get(pet.pet_id)
	if current == null:
		register_pet(pet.pet_id)
		current = pet_expressions[pet.pet_id]

	# 表情が変化した場合、スムーズ遷移開始
	if _expression_differs(current, state):
		_prev_expressions[pet.pet_id] = current
		_transition_progress[pet.pet_id] = 0.0

	pet_expressions[pet.pet_id] = state
	expression_changed.emit(pet.pet_id, state)


func set_activity_override(pet_id: int, activity: String) -> void:
	## 一時的な活動表情をセット（食事中、睡眠中など）
	activity_overrides[pet_id] = activity
	# 即座に表情変更をトリガー（ペット参照が無い場合はMapから取得）
	if GameManager.instance:
		var pet: PetEntity = GameManager.instance.pets.get(pet_id)
		if pet:
			update_expression(pet)


func clear_activity_override(pet_id: int) -> void:
	activity_overrides.erase(pet_id)
	if GameManager.instance:
		var pet: PetEntity = GameManager.instance.pets.get(pet_id)
		if pet:
			update_expression(pet)


# ========================================================
# 表情解決ロジック
# ========================================================

func _resolve_expression(pet: PetEntity) -> ExpressionState:
	var state := ExpressionState.new()

	# 1. 活動オーバーライドがあれば優先
	var activity: String = activity_overrides.get(pet.pet_id, "")
	if activity != "" and activity in ACTIVITY_EXPRESSION_MAP:
		var amap: Dictionary = ACTIVITY_EXPRESSION_MAP[activity]
		state.eye_shape = amap.get("eye", EyeShape.NORMAL)
		state.mouth_shape = amap.get("mouth", MouthShape.NEUTRAL)
		state.effect = amap.get("effect", ExpressionEffect.NONE)
		state.eye_openness = amap.get("eye_openness", 1.0)
		state.pupil_size = amap.get("pupil", 0.5)
		return state

	# 2. 支配的感情を取得
	var dominant: String = "neutral"
	var dominant_intensity: float = 0.0
	for emotion in pet.emotions:
		if pet.emotions[emotion] > dominant_intensity:
			dominant_intensity = pet.emotions[emotion]
			dominant = emotion

	# 感情が弱い場合はニュートラル表情
	if dominant_intensity < 0.15:
		state.eye_shape = EyeShape.NORMAL
		state.mouth_shape = MouthShape.NEUTRAL
		state.pupil_size = 0.5
		# 性格による基底表情の微調整
		state = _apply_personality_flavor(state, pet)
		return state

	# 3. 強度レベル判定
	var level: String
	if dominant_intensity < 0.4:
		level = "low"
	elif dominant_intensity < 0.7:
		level = "mid"
	else:
		level = "high"

	var key := "%s_%s" % [dominant, level]
	if key in EMOTION_EXPRESSION_MAP:
		var emap: Dictionary = EMOTION_EXPRESSION_MAP[key]
		state.eye_shape = emap.get("eye", EyeShape.NORMAL)
		state.mouth_shape = emap.get("mouth", MouthShape.NEUTRAL)
		state.effect = emap.get("effect", ExpressionEffect.NONE)
		state.pupil_size = emap.get("pupil", 0.5)
	else:
		# 未定義の感情はニュートラル
		state.eye_shape = EyeShape.NORMAL
		state.mouth_shape = MouthShape.NEUTRAL

	# 4. 性格による微調整
	state = _apply_personality_flavor(state, pet)

	# 5. まばたき間隔を感情で調整
	state.blink_rate = _calc_blink_rate(dominant, dominant_intensity)

	return state


func _apply_personality_flavor(state: ExpressionState, pet: PetEntity) -> ExpressionState:
	## 性格による表情の微調整（「この子らしさ」の表現）
	# playful → ニュートラル時も微笑み傾向
	if pet.personality.get("playful", 0.0) > 0.6:
		if state.mouth_shape == MouthShape.NEUTRAL:
			state.mouth_shape = MouthShape.TINY_SMILE

	# calm → 瞳孔が安定（極端に大きくならない）
	if pet.personality.get("calm", 0.0) > 0.7:
		state.pupil_size = clampf(state.pupil_size, 0.4, 0.65)

	# curious → 視線がわずかに動く（キョロキョロ感）
	if pet.personality.get("curious", 0.0) > 0.6:
		var t := Time.get_ticks_msec() / 1000.0
		state.eye_offset = Vector2(
			sin(t * 0.7) * 1.5,
			cos(t * 1.1) * 0.8
		)

	# brave → 怖いときも瞳孔が過剰に拡大しない
	if pet.personality.get("brave", 0.0) > 0.7:
		if state.eye_shape == EyeShape.SCARED:
			state.pupil_size = minf(state.pupil_size, 0.7)

	return state


func _calc_blink_rate(emotion: String, intensity: float) -> float:
	## 感情に応じたまばたき間隔（秒）
	# 興奮/恐怖 → 速い、落ち着き/悲しみ → 遅い
	match emotion:
		"excitement":
			return lerpf(3.0, 1.5, intensity)
		"fear":
			return lerpf(3.0, 1.0, intensity)
		"joy":
			return lerpf(3.0, 2.0, intensity)
		"sadness":
			return lerpf(3.0, 5.0, intensity)  # 悲しいとまばたきが遅い
		"love":
			return lerpf(3.0, 4.0, intensity)  # 見つめる
		_:
			return 3.0


# ========================================================
# まばたきアニメーション
# ========================================================

func _update_blink(pet_id: int, delta: float) -> void:
	var timer: float = _blink_timers.get(pet_id, 3.0)
	timer -= delta
	if timer <= 0.0:
		var state: ExpressionState = pet_expressions.get(pet_id)
		if state and state.eye_openness > 0.5:
			# まばたき実行 — eye_opennessを一時的に0にする
			# 実際のアニメーションはUI側で処理（ここではフラグだけ）
			state.eye_openness = 0.0
			# BLINK_DURATION後に復帰
			timer = BLINK_DURATION
		else:
			# まばたき終了 → 復帰
			if state:
				var base_openness := 1.0
				var activity: String = activity_overrides.get(pet_id, "")
				if activity in ACTIVITY_EXPRESSION_MAP:
					base_openness = ACTIVITY_EXPRESSION_MAP[activity].get("eye_openness", 1.0)
				state.eye_openness = base_openness
			timer = _random_blink_interval(
				pet_expressions.get(pet_id, ExpressionState.new()).blink_rate
			)
	_blink_timers[pet_id] = timer


func _random_blink_interval(base_rate: float) -> float:
	return base_rate + randf_range(-0.5, 0.5)


# ========================================================
# スムーズ遷移
# ========================================================

func _update_transition(pet_id: int, delta: float) -> void:
	if pet_id not in _transition_progress:
		return
	var progress: float = _transition_progress[pet_id]
	progress += delta * TRANSITION_SPEED
	if progress >= 1.0:
		_transition_progress.erase(pet_id)
		_prev_expressions.erase(pet_id)
	else:
		_transition_progress[pet_id] = progress


func get_transition_progress(pet_id: int) -> float:
	## UI用: 現在の表情遷移の進捗（0.0→1.0、遷移中でなければ1.0）
	return _transition_progress.get(pet_id, 1.0)


func get_previous_expression(pet_id: int) -> ExpressionState:
	## UI用: ブレンド元の表情（遷移アニメーション用）
	return _prev_expressions.get(pet_id)


# ========================================================
# ユーティリティ
# ========================================================

func _expression_differs(a: ExpressionState, b: ExpressionState) -> bool:
	return (a.eye_shape != b.eye_shape
		or a.mouth_shape != b.mouth_shape
		or a.effect != b.effect)


func get_expression(pet_id: int) -> ExpressionState:
	return pet_expressions.get(pet_id, ExpressionState.new())


func get_expression_name(pet_id: int) -> String:
	## デバッグ / UI表示用: 現在の表情を日本語名で返す
	var state: ExpressionState = pet_expressions.get(pet_id)
	if state == null:
		return "不明"

	var eye_names := {
		EyeShape.NORMAL: "通常",
		EyeShape.HAPPY: "笑顔",
		EyeShape.EXCITED: "キラキラ",
		EyeShape.SAD: "悲しみ",
		EyeShape.ANGRY: "怒り",
		EyeShape.SCARED: "恐怖",
		EyeShape.SLEEPY: "眠い",
		EyeShape.LOVE: "ハート",
		EyeShape.CURIOUS: "キョロ",
		EyeShape.CLOSED: "閉じ",
		EyeShape.DOT: "点目",
		EyeShape.SPARKLE: "輝き",
	}
	return eye_names.get(state.eye_shape, "通常")
