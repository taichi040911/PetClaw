## SfxManager — プロシージャル効果音マネージャー
## レトロチップチューン風の効果音をコードで生成・再生
## 外部音声ファイル不要 — AudioStreamGenerator で波形を直接合成
class_name SfxManager
extends Node

## サウンドタイプ定義
enum SfxType {
	TAP,          ## タップ/ボタン押下
	FEED,         ## ごはんをあげる
	PET,          ## なでる
	PLAY,         ## 遊ぶ
	EGG_TAP,      ## 卵タップ
	EGG_CRACK,    ## 卵にヒビ
	HATCH,        ## 孵化
	EVOLVE,       ## 進化
	LEVEL_UP,     ## レベルアップ
	SAD,          ## 悲しみ
	HAPPY,        ## 喜び
	DEATH,        ## 死亡
	UI_OPEN,      ## 画面遷移（開く）
	UI_CLOSE,     ## 画面遷移（閉じる）
}

## ボリューム設定
var bgm_volume: float = 0.7
var sfx_volume: float = 0.8

## 内部: AudioStreamPlayer プール
var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 4
const SAMPLE_RATE: float = 22050.0


static var instance: SfxManager


func _ready() -> void:
	instance = self
	for i: int in range(POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)


## 効果音を再生
func play(sfx_type: SfxType) -> void:
	var player: AudioStreamPlayer = _get_available_player()
	if not player:
		return

	var samples: PackedFloat32Array = _generate_samples(sfx_type)
	if samples.is_empty():
		return

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_IMA_ADPCM if false else AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(SAMPLE_RATE)
	wav.stereo = false
	wav.data = _float_to_16bit(samples)

	player.stream = wav
	player.volume_db = linear_to_db(sfx_volume)
	player.play()


## プレイヤープールから空きを取得
func _get_available_player() -> AudioStreamPlayer:
	for p: AudioStreamPlayer in _players:
		if not p.playing:
			return p
	# 全部使用中なら最初のものを再利用
	return _players[0]


## Float32 → 16bit PCM バイト変換
func _float_to_16bit(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i: int in range(samples.size()):
		var s: float = clampf(samples[i], -1.0, 1.0)
		var val: int = int(s * 32767.0)
		bytes[i * 2] = val & 0xFF
		bytes[i * 2 + 1] = (val >> 8) & 0xFF
	return bytes


## サウンドタイプに応じたサンプル生成
func _generate_samples(sfx_type: SfxType) -> PackedFloat32Array:
	match sfx_type:
		SfxType.TAP:
			return _gen_tap()
		SfxType.FEED:
			return _gen_feed()
		SfxType.PET:
			return _gen_pet()
		SfxType.PLAY:
			return _gen_play()
		SfxType.EGG_TAP:
			return _gen_egg_tap()
		SfxType.EGG_CRACK:
			return _gen_egg_crack()
		SfxType.HATCH:
			return _gen_hatch()
		SfxType.EVOLVE:
			return _gen_evolve()
		SfxType.LEVEL_UP:
			return _gen_level_up()
		SfxType.SAD:
			return _gen_sad()
		SfxType.HAPPY:
			return _gen_happy()
		SfxType.DEATH:
			return _gen_death()
		SfxType.UI_OPEN:
			return _gen_ui_open()
		SfxType.UI_CLOSE:
			return _gen_ui_close()
	return PackedFloat32Array()


# ========================================================
# 波形ジェネレーター ユーティリティ
# ========================================================

## 矩形波（チップチューン基本音）
func _square_wave(t: float, freq: float, duty: float = 0.5) -> float:
	var phase: float = fmod(t * freq, 1.0)
	return 1.0 if phase < duty else -1.0


## 三角波
func _triangle_wave(t: float, freq: float) -> float:
	var phase: float = fmod(t * freq, 1.0)
	return 4.0 * absf(phase - 0.5) - 1.0


## ノイズ（パーカッション用）
func _noise() -> float:
	return randf_range(-1.0, 1.0)


## エンベロープ（Attack-Decay）
func _envelope_ad(t: float, attack: float, decay: float) -> float:
	if t < attack:
		return t / attack
	var decay_t: float = t - attack
	return maxf(0.0, 1.0 - decay_t / decay)


## エンベロープ（Attack-Sustain-Release）
func _envelope_asr(t: float, attack: float, sustain_end: float, release: float) -> float:
	if t < attack:
		return t / attack
	if t < sustain_end:
		return 1.0
	var rel_t: float = t - sustain_end
	return maxf(0.0, 1.0 - rel_t / release)


# ========================================================
# 各効果音の波形定義
# ========================================================

## タップ — 短いクリック音（高周波パルス）
func _gen_tap() -> PackedFloat32Array:
	var duration: float = 0.06
	var count: int = int(SAMPLE_RATE * duration)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		var env: float = _envelope_ad(t, 0.002, 0.05)
		out[i] = _square_wave(t, 800.0, 0.3) * env * 0.4
	return out


## ごはん — 上昇フレーズ（もぐもぐ感）
func _gen_feed() -> PackedFloat32Array:
	var duration: float = 0.3
	var count: int = int(SAMPLE_RATE * duration)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		# 3段階の音程上昇
		var note_idx: int = int(t / 0.1)
		var freqs: Array[float] = [330.0, 392.0, 523.0]
		var freq: float = freqs[mini(note_idx, 2)]
		var local_t: float = fmod(t, 0.1)
		var env: float = _envelope_ad(local_t, 0.005, 0.09)
		out[i] = _square_wave(t, freq, 0.4) * env * 0.35
	return out


## なでる — やさしい三角波のフレーズ
func _gen_pet() -> PackedFloat32Array:
	var duration: float = 0.35
	var count: int = int(SAMPLE_RATE * duration)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		var freq: float = 440.0 + sin(t * 8.0) * 60.0  # ゆらぎ
		var env: float = _envelope_asr(t, 0.02, 0.2, 0.15)
		out[i] = _triangle_wave(t, freq) * env * 0.3
	return out


## 遊ぶ — 元気なリズミカルフレーズ
func _gen_play() -> PackedFloat32Array:
	var duration: float = 0.4
	var count: int = int(SAMPLE_RATE * duration)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		var note_idx: int = int(t / 0.08)
		var freqs: Array[float] = [523.0, 659.0, 784.0, 659.0, 523.0]
		var freq: float = freqs[mini(note_idx, 4)]
		var local_t: float = fmod(t, 0.08)
		var env: float = _envelope_ad(local_t, 0.003, 0.07)
		out[i] = _square_wave(t, freq, 0.25) * env * 0.3
	return out


## 卵タップ — ドン！という低いパーカッション
func _gen_egg_tap() -> PackedFloat32Array:
	var duration: float = 0.12
	var count: int = int(SAMPLE_RATE * duration)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		var env: float = _envelope_ad(t, 0.001, 0.11)
		var freq: float = 200.0 - t * 800.0  # ピッチ下降
		out[i] = (_square_wave(t, maxf(freq, 60.0)) * 0.5 + _noise() * 0.3) * env * 0.4
	return out


## 卵ヒビ — パキッ
func _gen_egg_crack() -> PackedFloat32Array:
	var duration: float = 0.15
	var count: int = int(SAMPLE_RATE * duration)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		var env: float = _envelope_ad(t, 0.001, 0.14)
		# ノイズバースト + 高周波
		out[i] = (_noise() * 0.6 + _square_wave(t, 1200.0 - t * 4000.0) * 0.4) * env * 0.35
	return out


## 孵化 — 華やかな上昇アルペジオ
func _gen_hatch() -> PackedFloat32Array:
	var duration: float = 0.8
	var count: int = int(SAMPLE_RATE * duration)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		# C-E-G-C' アルペジオ
		var note_idx: int = int(t / 0.15)
		var freqs: Array[float] = [523.0, 659.0, 784.0, 1047.0, 1047.0, 1047.0]
		var freq: float = freqs[mini(note_idx, 5)]
		var local_t: float = fmod(t, 0.15)
		var env: float = _envelope_ad(local_t, 0.005, 0.14)
		# 最後の音は長く
		if note_idx >= 3:
			env = _envelope_asr(t - 0.45, 0.01, 0.6, 0.2)
		out[i] = (_square_wave(t, freq, 0.3) * 0.3 + _triangle_wave(t, freq) * 0.25) * env
	return out


## 進化 — ドラマチックな変身音
func _gen_evolve() -> PackedFloat32Array:
	var duration: float = 1.2
	var count: int = int(SAMPLE_RATE * duration)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		var env: float = _envelope_asr(t, 0.05, 0.8, 0.4)
		# 上昇スイープ
		var freq: float = 200.0 + t * 600.0
		var wave: float = _square_wave(t, freq, 0.35) * 0.25
		wave += _triangle_wave(t, freq * 1.5) * 0.15
		# キラキラ高音
		if t > 0.6:
			var sparkle_env: float = _envelope_ad(t - 0.6, 0.01, 0.55)
			wave += _square_wave(t, 1568.0, 0.2) * sparkle_env * 0.2
		out[i] = wave * env
	return out


## レベルアップ — 短い勝利ファンファーレ
func _gen_level_up() -> PackedFloat32Array:
	var duration: float = 0.5
	var count: int = int(SAMPLE_RATE * duration)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		var note_idx: int = int(t / 0.1)
		var freqs: Array[float] = [659.0, 784.0, 1047.0, 1319.0, 1319.0]
		var freq: float = freqs[mini(note_idx, 4)]
		var local_t: float = fmod(t, 0.1)
		var env: float = _envelope_ad(local_t, 0.003, 0.09)
		if note_idx >= 3:
			env = _envelope_asr(t - 0.3, 0.005, 0.4, 0.1)
		out[i] = _square_wave(t, freq, 0.3) * env * 0.35
	return out


## 悲しみ — 下降する三角波
func _gen_sad() -> PackedFloat32Array:
	var duration: float = 0.5
	var count: int = int(SAMPLE_RATE * duration)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		var note_idx: int = int(t / 0.15)
		var freqs: Array[float] = [392.0, 330.0, 262.0, 220.0]
		var freq: float = freqs[mini(note_idx, 3)]
		var env: float = _envelope_asr(t, 0.02, 0.35, 0.15)
		out[i] = _triangle_wave(t, freq) * env * 0.3
	return out


## 喜び — 明るい短い上昇フレーズ
func _gen_happy() -> PackedFloat32Array:
	var duration: float = 0.25
	var count: int = int(SAMPLE_RATE * duration)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		var freq: float = 660.0 + t * 800.0
		var env: float = _envelope_ad(t, 0.005, 0.22)
		out[i] = _square_wave(t, freq, 0.35) * env * 0.3
	return out


## 死亡 — 暗い下降音
func _gen_death() -> PackedFloat32Array:
	var duration: float = 1.5
	var count: int = int(SAMPLE_RATE * duration)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		var env: float = _envelope_asr(t, 0.1, 0.8, 0.7)
		var freq: float = 330.0 - t * 150.0
		out[i] = _triangle_wave(t, maxf(freq, 80.0)) * env * 0.25
	return out


## UI開く — 短い上昇スイープ
func _gen_ui_open() -> PackedFloat32Array:
	var duration: float = 0.1
	var count: int = int(SAMPLE_RATE * duration)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		var freq: float = 600.0 + t * 2000.0
		var env: float = _envelope_ad(t, 0.005, 0.09)
		out[i] = _square_wave(t, freq, 0.2) * env * 0.25
	return out


## UI閉じる — 短い下降スイープ
func _gen_ui_close() -> PackedFloat32Array:
	var duration: float = 0.08
	var count: int = int(SAMPLE_RATE * duration)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in range(count):
		var t: float = float(i) / SAMPLE_RATE
		var freq: float = 900.0 - t * 4000.0
		var env: float = _envelope_ad(t, 0.002, 0.07)
		out[i] = _square_wave(t, maxf(freq, 200.0), 0.2) * env * 0.25
	return out
