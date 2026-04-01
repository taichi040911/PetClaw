## AudioManager — サウンド管理
## BGM・SE・環境音の再生を統合管理
## 実際のオーディオファイルがなくてもクラッシュしない（silent fallback）
class_name AudioManager
extends Node

# === Audio Players ===
var bgm_player: AudioStreamPlayer
var se_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer

# === Settings ===
var bgm_volume: float = 0.7
var se_volume: float = 0.8
var ambient_volume: float = 0.5
var is_muted: bool = false

# === BGM Tracks (パスが存在しない場合は無音) ===
const BGM_PATHS: Dictionary = {
	"main": "res://assets/audio/bgm/main_theme.ogg",
	"petbook": "res://assets/audio/bgm/petbook_theme.ogg",
	"evolution": "res://assets/audio/bgm/evolution_fanfare.ogg",
	"night": "res://assets/audio/bgm/night_ambient.ogg",
}

# === SE (効果音) ===
const SE_PATHS: Dictionary = {
	"feed": "res://assets/audio/se/feed.wav",
	"pet": "res://assets/audio/se/pet.wav",
	"play": "res://assets/audio/se/play.wav",
	"hatch": "res://assets/audio/se/egg_hatch.wav",
	"evolve": "res://assets/audio/se/evolve.wav",
	"death": "res://assets/audio/se/death.wav",
	"notification": "res://assets/audio/se/notification.wav",
	"tap": "res://assets/audio/se/tap.wav",
}


func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"
	add_child(bgm_player)

	se_player = AudioStreamPlayer.new()
	se_player.bus = "SFX"
	add_child(se_player)

	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = "Ambient"
	add_child(ambient_player)


func play_bgm(track_name: String) -> void:
	if is_muted:
		return

	var path: String = BGM_PATHS.get(track_name, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return

	var stream: AudioStream = load(path)
	if stream:
		bgm_player.stream = stream
		bgm_player.volume_db = linear_to_db(bgm_volume)
		bgm_player.play()


func play_se(se_name: String) -> void:
	if is_muted:
		return

	var path: String = SE_PATHS.get(se_name, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return

	var stream: AudioStream = load(path)
	if stream:
		se_player.stream = stream
		se_player.volume_db = linear_to_db(se_volume)
		se_player.play()


func stop_bgm() -> void:
	bgm_player.stop()


func set_muted(muted: bool) -> void:
	is_muted = muted
	if muted:
		bgm_player.stop()
		ambient_player.stop()
