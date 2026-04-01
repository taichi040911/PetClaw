## AmbientBGM — プロシージャル環境BGM
## ゆったりしたチップチューンアンビエントをコードで生成
## 時間帯・ペットの感情に応じてトーンが変化
class_name AmbientBGM
extends Node

static var instance: AmbientBGM

var _player: AudioStreamPlayer
var _is_playing: bool = false
var _volume: float = 0.7
var _current_mood: String = "neutral"

const SAMPLE_RATE: float = 22050.0
const LOOP_DURATION: float = 8.0  # 8秒ループ

## 音階定義（ペンタトニックスケール — 不協和音が出にくい）
const SCALE_NEUTRAL: Array = [262, 294, 330, 392, 440]      # C D E G A
const SCALE_HAPPY: Array = [330, 370, 440, 494, 554]        # E F# A B C#
const SCALE_SAD: Array = [220, 262, 294, 330, 392]          # A C D E G (Am pentatonic)
const SCALE_NIGHT: Array = [196, 220, 262, 294, 330]        # G A C D E (low register)


func _ready() -> void:
	instance = self
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	_player.finished.connect(_on_loop_finished)


func start() -> void:
	if _is_playing:
		return
	_is_playing = true
	_generate_and_play()


func stop() -> void:
	_is_playing = false
	_player.stop()


func set_volume(vol: float) -> void:
	_volume = vol
	_player.volume_db = linear_to_db(_volume * 0.3)  # BGMは控えめに


func set_mood(mood: String) -> void:
	_current_mood = mood


func _on_loop_finished() -> void:
	if _is_playing:
		_generate_and_play()


func _generate_and_play() -> void:
	var samples: PackedFloat32Array = _generate_loop()
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(SAMPLE_RATE)
	wav.stereo = false
	wav.data = _float_to_16bit(samples)

	_player.stream = wav
	_player.volume_db = linear_to_db(_volume * 0.3)
	_player.play()


func _generate_loop() -> PackedFloat32Array:
	var count: int = int(SAMPLE_RATE * LOOP_DURATION)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)

	# ムードに応じたスケール選択
	var scale: Array = SCALE_NEUTRAL
	var is_night: bool = false
	if DayNightCycle.instance and DayNightCycle.instance.is_sleepy_time():
		scale = SCALE_NIGHT
		is_night = true
	elif _current_mood == "joy" or _current_mood == "excitement":
		scale = SCALE_HAPPY
	elif _current_mood == "sadness" or _current_mood == "fear":
		scale = SCALE_SAD

	# メロディシーケンスを生成（ランダムだがスケール内なので調和する）
	var melody_notes: Array[float] = []
	for i: int in range(16):
		melody_notes.append(float(scale[randi() % scale.size()]))

	# ベースノート（ルート音のオクターブ下）
	var bass_note: float = float(scale[0]) / 2.0

	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		var sample: float = 0.0

		# === ベースパッド（三角波、ゆったり） ===
		var bass_freq: float = bass_note + sin(t * 0.3) * 3.0  # ゆっくりデチューン
		sample += _triangle(t, bass_freq) * 0.12

		# === メロディ（矩形波、8分音符） ===
		var beat: float = t * 2.0  # 120 BPM 相当
		var note_idx: int = int(beat) % melody_notes.size()
		var note_t: float = fmod(beat, 1.0)
		var mel_env: float = maxf(0.0, 1.0 - note_t * 2.0)  # 短いスタッカート
		var mel_freq: float = melody_notes[note_idx]
		sample += _square(t, mel_freq, 0.25) * mel_env * 0.08

		# === アルペジオ（16分音符、三角波） ===
		var arp_beat: float = t * 4.0
		var arp_idx: int = int(arp_beat) % scale.size()
		var arp_t: float = fmod(arp_beat, 1.0)
		var arp_env: float = maxf(0.0, 1.0 - arp_t * 3.0)
		var arp_freq: float = float(scale[arp_idx]) * 2.0  # オクターブ上
		sample += _triangle(t, arp_freq) * arp_env * 0.05

		# === 夜モード: より静かに、テンポ遅く ===
		if is_night:
			sample *= 0.6

		# === フェードイン/アウト（ループのつなぎ目をスムーズに） ===
		var loop_t: float = t / LOOP_DURATION
		var fade: float = 1.0
		if loop_t < 0.05:
			fade = loop_t / 0.05
		elif loop_t > 0.95:
			fade = (1.0 - loop_t) / 0.05
		sample *= fade

		out[i] = clampf(sample, -1.0, 1.0)

	return out


func _square(t: float, freq: float, duty: float = 0.5) -> float:
	return 1.0 if fmod(t * freq, 1.0) < duty else -1.0


func _triangle(t: float, freq: float) -> float:
	var phase: float = fmod(t * freq, 1.0)
	return 4.0 * absf(phase - 0.5) - 1.0


func _float_to_16bit(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i: int in range(samples.size()):
		var s: float = clampf(samples[i], -1.0, 1.0)
		var val: int = int(s * 32767.0)
		bytes[i * 2] = val & 0xFF
		bytes[i * 2 + 1] = (val >> 8) & 0xFF
	return bytes
