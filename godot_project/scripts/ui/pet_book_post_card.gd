## PetBookPostCard — 投稿カードUIコンポーネント
## PetBookの各投稿を表示・アニメーションするカード型コントロール
## BBCode対応で接尾辞ハイライト・感情色ライン・リアクションバーを表示
class_name PetBookPostCard
extends PanelContainer

# === シグナル ===
signal card_tapped(post: PetBookPost)
signal translation_toggled(post_id: int, show_translation: bool)

# === 色定数 ===
const BG_CARD: Color = Color("#252640")
const BG_CARD_HOVER: Color = Color("#2E2F50")
const TEXT_PRIMARY: Color = Color("#E8E8F0")
const TEXT_SECONDARY: Color = Color("#8888AA")
const TEXT_DIM: Color = Color("#555577")
const SUFFIX_COLOR: String = "#6C7EFF"
const REBEL_COLOR: String = "#FF4444"
const NEW_WORD_COLOR: String = "#33FF99"

const BADGE_COLORS: Dictionary = {
	"REBEL": Color("#FF4444"),
	"MEMORIAL": Color("#6666DD"),
	"EVENT": Color("#FFAA00"),
}

# === 子ノード参照（コードで生成） ===
var _emotion_line: ColorRect
var _avatar: TextureRect
var _name_label: Label
var _handle_label: Label
var _time_label: Label
var _env_label: Label
var _type_badge: Label
var _content_body: RichTextLabel
var _new_word_label: Label
var _reaction_bar: HBoxContainer
var _empathy_label: Label
var _reply_label: Label
var _share_label: Label
var _translate_btn: Button

# === 状態 ===
var _post: PetBookPost
var _showing_translation: bool = false
var _is_recycled: bool = false
var _current_theme: PetBookSubMoltTheme = null


func _ready() -> void:
	_build_layout()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


# === レイアウト構築 ===
func _build_layout() -> void:
	## カード内部のUIノードをコードで生成
	custom_minimum_size = Vector2(0, 100)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# カード背景スタイル
	var style := StyleBoxFlat.new()
	style.bg_color = BG_CARD
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 4
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)

	# メインHBox（感情ライン + コンテンツ）
	var main_hbox := HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(main_hbox)

	# 感情色ライン
	_emotion_line = ColorRect.new()
	_emotion_line.custom_minimum_size = Vector2(4, 0)
	_emotion_line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_emotion_line.color = Color(0.7, 0.7, 0.7)
	main_hbox.add_child(_emotion_line)

	# コンテンツVBox
	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 6)
	main_hbox.add_child(content_vbox)

	# --- 著者行 ---
	var author_row := HBoxContainer.new()
	author_row.add_theme_constant_override("separation", 8)
	content_vbox.add_child(author_row)

	# アバター
	_avatar = TextureRect.new()
	_avatar.custom_minimum_size = Vector2(32, 32)
	_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	author_row.add_child(_avatar)

	# 名前 + ハンドル
	var name_col := VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	author_row.add_child(name_col)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 4)
	name_col.add_child(name_row)

	_name_label = Label.new()
	_name_label.add_theme_color_override("font_color", TEXT_PRIMARY)
	_name_label.add_theme_font_size_override("font_size", 14)
	name_row.add_child(_name_label)

	_handle_label = Label.new()
	_handle_label.add_theme_color_override("font_color", TEXT_DIM)
	_handle_label.add_theme_font_size_override("font_size", 12)
	name_row.add_child(_handle_label)

	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 6)
	name_col.add_child(meta_row)

	_env_label = Label.new()
	_env_label.add_theme_color_override("font_color", TEXT_SECONDARY)
	_env_label.add_theme_font_size_override("font_size", 11)
	meta_row.add_child(_env_label)

	_time_label = Label.new()
	_time_label.add_theme_color_override("font_color", TEXT_DIM)
	_time_label.add_theme_font_size_override("font_size", 11)
	meta_row.add_child(_time_label)

	# タイプバッジ
	_type_badge = Label.new()
	_type_badge.add_theme_font_size_override("font_size", 11)
	_type_badge.visible = false
	author_row.add_child(_type_badge)

	# --- 本文 ---
	_content_body = RichTextLabel.new()
	_content_body.bbcode_enabled = true
	_content_body.fit_content = true
	_content_body.scroll_active = false
	_content_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_body.add_theme_color_override("default_color", TEXT_PRIMARY)
	_content_body.add_theme_font_size_override("normal_font_size", 14)
	content_vbox.add_child(_content_body)

	# --- 新語ハイライト（非表示初期） ---
	_new_word_label = Label.new()
	_new_word_label.add_theme_color_override("font_color", Color(NEW_WORD_COLOR))
	_new_word_label.add_theme_font_size_override("font_size", 12)
	_new_word_label.visible = false
	content_vbox.add_child(_new_word_label)

	# --- リアクションバー ---
	_reaction_bar = HBoxContainer.new()
	_reaction_bar.add_theme_constant_override("separation", 16)
	content_vbox.add_child(_reaction_bar)

	_empathy_label = _create_reaction_label("♡ 0")
	_reaction_bar.add_child(_empathy_label)

	_reply_label = _create_reaction_label("💬 0")
	_reaction_bar.add_child(_reply_label)

	_share_label = _create_reaction_label("🔄 0")
	_reaction_bar.add_child(_share_label)

	# スペーサー
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reaction_bar.add_child(spacer)

	_translate_btn = Button.new()
	_translate_btn.text = "翻訳"
	_translate_btn.flat = true
	_translate_btn.add_theme_color_override("font_color", Color(SUFFIX_COLOR))
	_translate_btn.add_theme_font_size_override("font_size", 11)
	_translate_btn.pressed.connect(_on_translate_pressed)
	_reaction_bar.add_child(_translate_btn)


func _create_reaction_label(initial_text: String) -> Label:
	var label := Label.new()
	label.text = initial_text
	label.add_theme_color_override("font_color", TEXT_SECONDARY)
	label.add_theme_font_size_override("font_size", 12)
	return label


# === データバインド ===
func bind_post(post: PetBookPost, current_game_time: float) -> void:
	## 投稿データをカードにバインドして表示更新
	_post = post
	_showing_translation = false
	_is_recycled = false

	# 感情色ライン
	_emotion_line.color = post.get_emotion_color()

	# 著者情報
	_name_label.text = post.author_name
	_handle_label.text = post.get_display_handle()
	_time_label.text = post.get_time_ago(current_game_time)

	# 環境
	var env_icon: String = _get_environment_icon(post.environment)
	_env_label.text = "%s %s" % [env_icon, post.environment]

	# タイプバッジ
	var badge_text: String = post.get_post_type_label()
	if badge_text != "":
		_type_badge.text = badge_text
		_type_badge.visible = true
		var badge_key: String = PetBookPost.PostType.keys()[post.post_type]
		if BADGE_COLORS.has(badge_key):
			_type_badge.add_theme_color_override("font_color", BADGE_COLORS[badge_key])
	else:
		_type_badge.visible = false

	# 本文（BBCode付き）
	_content_body.text = _format_content(post)

	# 新語ハイライト
	if not post.rebel_expressions.is_empty() and post.post_type != PetBookPost.PostType.REBEL:
		_new_word_label.text = "✨ 新しい表現: %s" % ", ".join(post.rebel_expressions)
		_new_word_label.visible = true
	else:
		_new_word_label.visible = false

	# リアクション（絵文字集計表示）
	var emoji_reactions: Array[Dictionary] = post.get_emoji_reactions()
	if emoji_reactions.is_empty():
		_empathy_label.text = "♡ %d" % post.get_reaction_count("empathy")
	else:
		var parts: Array[String] = []
		for er in emoji_reactions.slice(0, 3):  # 上位3絵文字まで
			parts.append("%s %d" % [er["icon"], er["count"]])
		_empathy_label.text = " ".join(parts) if not parts.is_empty() else "♡ 0"
	_reply_label.text = "💬 %d" % post.reply_count
	_share_label.text = "🔄 %d" % post.share_count

	# v4: 投稿タイプ別エフェクト + SubMolt装飾を自動適用
	apply_post_type_effects()
	apply_sub_molt_decoration()


func _format_content(post: PetBookPost) -> String:
	## BBCodeでフォーマットされた投稿テキストを生成
	var text: String = post.content

	# 反乱投稿は全体を赤系に
	if post.post_type == PetBookPost.PostType.REBEL:
		# 接尾辞だけは別色でハイライト
		for suffix in post.suffixes_used:
			text = text.replace(suffix,
				"[color=%s][b]%s[/b][/color]" % [SUFFIX_COLOR, suffix])
		return "[color=%s]%s[/color]" % [REBEL_COLOR, text]

	# 追悼投稿はイタリック
	if post.post_type == PetBookPost.PostType.MEMORIAL:
		for suffix in post.suffixes_used:
			text = text.replace(suffix,
				"[color=%s][b]%s[/b][/color]" % [SUFFIX_COLOR, suffix])
		return "[i]%s[/i]" % text

	# 通常: 接尾辞をハイライト
	for suffix in post.suffixes_used:
		text = text.replace(suffix,
			"[color=%s][b]%s[/b][/color]" % [SUFFIX_COLOR, suffix])

	# v3: highlight_words（複合語）をアクセント色で強調
	for hw in post.highlight_words:
		if hw in text:
			text = text.replace(hw,
				"[color=%s][u]%s[/u][/color]" % [NEW_WORD_COLOR, hw])

	return text


func _get_environment_icon(env: String) -> String:
	match env:
		"forest":
			return "🌲"
		"ocean":
			return "🌊"
		"mountain":
			return "🏔️"
		"desert":
			return "🏜️"
		"cave":
			return "🕳️"
		"meadow":
			return "🌿"
		_:
			return "🌍"


# === インタラクション ===
func _on_translate_pressed() -> void:
	_showing_translation = not _showing_translation
	if _post:
		if _showing_translation:
			var translated := _post.translation
			# 接尾辞辞書を下部に追加
			var suffix_dict: String = ""
			for suffix in _post.suffixes_used:
				var meaning: String = _get_suffix_meaning(suffix)
				if meaning != "":
					suffix_dict += "%s = %s  " % [suffix, meaning]
			if suffix_dict != "":
				translated += "\n[color=%s]%s[/color]" % [TEXT_DIM.to_html(), suffix_dict]
			_content_body.text = translated
			_translate_btn.text = "原文"
		else:
			_content_body.text = _format_content(_post)
			_translate_btn.text = "翻訳"
		translation_toggled.emit(_post.post_id, _showing_translation)


func _get_suffix_meaning(suffix: String) -> String:
	match suffix:
		# 共通接尾辞
		"-pya":
			return "喜び"
		"-kuu":
			return "悲しみ"
		"-zaa":
			return "怒り/反乱"
		"-mii":
			return "愛"
		"-shu":
			return "恐れ"
		"-ra":
			return "興奮/強さ"
		"-ki":
			return "好奇心/未来"
		# AfterlifeEchoes固有
		"-echo":
			return "残響"
		"-void":
			return "虚無"
		"-rebirth":
			return "再生"
		"-whisper":
			return "ささやき"
		# BreedingCircle固有
		"-bloom":
			return "開花/誕生"
		"-warmth":
			return "温もり"
		"-bond":
			return "絆"
		# LanguageRebellion固有
		"-vex":
			return "異議"
		"-sol":
			return "自己決定"
		"-nox":
			return "拒否"
		# EcosystemPulse固有
		"-pulse":
			return "鼓動"
		"-shift":
			return "変動"
		"-cycle":
			return "循環"
		# ForestWhispers固有
		"-leaf":
			return "葉"
		"-dew":
			return "露"
		"-root":
			return "根"
		_:
			return ""


func _on_mouse_entered() -> void:
	var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	var hover_color: Color = _current_theme.card_bg_color.lightened(0.1) if _current_theme else BG_CARD_HOVER
	style.bg_color = hover_color
	add_theme_stylebox_override("panel", style)


func _on_mouse_exited() -> void:
	if _current_theme:
		add_theme_stylebox_override("panel", _current_theme.create_card_stylebox())
	else:
		var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
		style.bg_color = BG_CARD
		add_theme_stylebox_override("panel", style)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if _post:
				card_tapped.emit(_post)


# === アニメーション ===
func animate_entrance() -> void:
	## 新規投稿登場アニメーション
	modulate.a = 0.0
	scale = Vector2(0.95, 0.95)
	pivot_offset = size / 2.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func animate_memorial_glow() -> void:
	## 追悼投稿の柔らかい光アニメーション
	var tween := create_tween().set_loops()
	tween.tween_property(_emotion_line, "color:a", 0.4, 2.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_emotion_line, "color:a", 1.0, 2.0).set_ease(Tween.EASE_IN_OUT)


# === リサイクル ===
func recycle() -> void:
	## カードプールに返却する前のクリーンアップ
	_post = null
	_is_recycled = true
	_showing_translation = false
	_content_body.text = ""
	_name_label.text = ""
	_handle_label.text = ""
	_type_badge.visible = false
	_new_word_label.visible = false

	# v4: エフェクトクリーンアップ
	modulate = Color.WHITE
	if _emotion_line:
		_emotion_line.custom_minimum_size.x = 4  # デフォルト幅に戻す

	visible = false


# === SubMoltテーマ適用（v2追加） ===
func apply_sub_molt_theme(theme: PetBookSubMoltTheme) -> void:
	## SubMoltテーマに基づいてカードの視覚スタイルを切り替え
	_current_theme = theme
	if not theme:
		return

	# カードStyleBox
	add_theme_stylebox_override("panel", theme.create_card_stylebox())

	# テキスト色更新
	_name_label.add_theme_color_override("font_color", TEXT_PRIMARY)
	_handle_label.add_theme_color_override("font_color", theme.text_accent_color)
	_translate_btn.add_theme_color_override("font_color", theme.text_accent_color)

	# 本文再フォーマット（テーマ色でハイライト）
	if _post:
		_content_body.text = _format_content_themed(_post, theme)

	# 入場アニメーション変更
	# entrance_style は animate_entrance_themed() で使用


func _format_content_themed(post: PetBookPost, theme: PetBookSubMoltTheme) -> String:
	## テーマ固有のハイライト色で投稿テキストをフォーマット
	var text: String = post.content
	var suffix_hex: String = theme.suffix_color.to_html(false)
	var rebel_hex: String = theme.rebel_text_color.to_html(false)
	var highlight_hex: String = theme.text_highlight_color.to_html(false)

	# 反乱投稿
	if post.post_type == PetBookPost.PostType.REBEL:
		for suffix in post.suffixes_used:
			text = text.replace(suffix,
				"[color=#%s][b]%s[/b][/color]" % [suffix_hex, suffix])
		return "[color=#%s]%s[/color]" % [rebel_hex, text]

	# 追悼投稿
	if post.post_type == PetBookPost.PostType.MEMORIAL:
		for suffix in post.suffixes_used:
			text = text.replace(suffix,
				"[color=#%s][b]%s[/b][/color]" % [suffix_hex, suffix])
		return "[i]%s[/i]" % text

	# 通常: テーマ色で接尾辞ハイライト
	for suffix in post.suffixes_used:
		text = text.replace(suffix,
			"[color=#%s][b]%s[/b][/color]" % [suffix_hex, suffix])

	# 新語はハイライト色で追加強調
	for expr in post.rebel_expressions:
		if expr in text:
			text = text.replace(expr,
				"[color=#%s]%s[/color]" % [highlight_hex, expr])

	# v3: highlight_words（複合語）をテーマアクセント色で強調
	var accent_hex: String = theme.text_accent_color.to_html(false)
	for hw in post.highlight_words:
		if hw in text:
			text = text.replace(hw,
				"[color=#%s][u]%s[/u][/color]" % [accent_hex, hw])

	return text


func animate_entrance_themed() -> void:
	## SubMoltテーマに基づく入場アニメーション
	if not _current_theme:
		animate_entrance()
		return

	match _current_theme.entrance_style:
		"fade":
			modulate.a = 0.0
			var tween := create_tween()
			tween.tween_property(self, "modulate:a", 1.0, _current_theme.card_entrance_duration)
		"slide_up":
			modulate.a = 0.0
			position.y += 20
			var tween := create_tween().set_parallel(true)
			tween.tween_property(self, "modulate:a", 1.0, _current_theme.card_entrance_duration)
			tween.tween_property(self, "position:y", position.y - 20, _current_theme.card_entrance_duration).set_ease(Tween.EASE_OUT)
		"glitch":
			modulate.a = 1.0
			var original_pos := position
			var tween := create_tween()
			# グリッチ的に微震して登場
			tween.tween_property(self, "position:x", position.x + 3, 0.03)
			tween.tween_property(self, "position:x", position.x - 3, 0.03)
			tween.tween_property(self, "position:x", position.x + 1, 0.03)
			tween.tween_property(self, "position:x", original_pos.x, 0.03)
			tween.tween_property(self, "modulate:a", 1.0, 0.1)
		"bloom":
			modulate.a = 0.0
			scale = Vector2(0.8, 0.8)
			pivot_offset = size / 2.0
			var tween := create_tween().set_parallel(true)
			tween.tween_property(self, "modulate:a", 1.0, _current_theme.card_entrance_duration)
			tween.tween_property(self, "scale", Vector2.ONE, _current_theme.card_entrance_duration * 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		_:
			animate_entrance()


# === 投稿タイプ別視覚エフェクト（v4追加） ===

func apply_post_type_effects() -> void:
	## 投稿タイプに応じた視覚エフェクトを適用
	if not _post:
		return
	match _post.post_type:
		PetBookPost.PostType.REBEL:
			_apply_rebel_effects()
		PetBookPost.PostType.MEMORIAL:
			_apply_memorial_effects()
		PetBookPost.PostType.EVENT:
			_apply_event_effects()
		_:
			_apply_daily_effects()


func _apply_rebel_effects() -> void:
	## 反乱投稿: 赤い脈動グロー + 枠線点滅 + グリッチ的テキスト微震
	if not _current_theme:
		return

	# カードStyleBoxを赤グロー付きに変更
	var style := StyleBoxFlat.new()
	style.bg_color = _current_theme.card_bg_color
	style.border_color = Color("#FF4444")
	style.set_border_width_all(2)
	style.set_corner_radius_all(_current_theme.card_corner_radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(1.0, 0.2, 0.2, 0.3)
	style.shadow_size = 6
	add_theme_stylebox_override("panel", style)

	# 枠線の脈動アニメーション
	_start_rebel_pulse()


func _start_rebel_pulse() -> void:
	## 反乱投稿の赤い脈動エフェクト（border alpha oscillation）
	var tween := create_tween().set_loops()
	tween.tween_method(_update_rebel_glow, 0.15, 0.4, 1.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_update_rebel_glow, 0.4, 0.15, 1.5).set_ease(Tween.EASE_IN_OUT)


func _update_rebel_glow(intensity: float) -> void:
	var current_style: StyleBoxFlat = get_theme_stylebox("panel")
	if current_style:
		var style: StyleBoxFlat = current_style.duplicate()
		style.shadow_color = Color(1.0, 0.2, 0.2, intensity)
		style.shadow_size = int(4 + intensity * 8)
		add_theme_stylebox_override("panel", style)


func _apply_memorial_effects() -> void:
	## 追悼投稿: 淡い青白グロー + 感情ラインの呼吸アニメ + 静かな光
	if not _current_theme:
		return

	# カードStyleBoxを追悼仕様に
	var style := StyleBoxFlat.new()
	style.bg_color = _current_theme.card_bg_color.darkened(0.1)
	style.border_color = Color("#6666DD")
	style.set_border_width_all(1)
	style.border_width_left = 3  # 左だけ太く（追悼マーク）
	style.set_corner_radius_all(_current_theme.card_corner_radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.4, 0.4, 0.9, 0.15)
	style.shadow_size = 8
	add_theme_stylebox_override("panel", style)

	# 感情ラインの呼吸アニメーション（既存のanimate_memorial_glowを活用）
	animate_memorial_glow()

	# カード全体の微かな明滅
	_start_memorial_breathe()


func _start_memorial_breathe() -> void:
	## 追悼カード全体の微かな明滅（幽玄感）
	var tween := create_tween().set_loops()
	tween.tween_property(self, "modulate:a", 0.85, 3.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 3.0).set_ease(Tween.EASE_IN_OUT)


func _apply_event_effects() -> void:
	## イベント投稿: 金色アクセント + 一度だけのキラキラ
	if not _current_theme:
		return

	var style := StyleBoxFlat.new()
	style.bg_color = _current_theme.card_bg_color
	style.border_color = Color("#FFAA00")
	style.set_border_width_all(1)
	style.border_width_top = 3  # 上だけ太く（イベントマーク）
	style.set_corner_radius_all(_current_theme.card_corner_radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(1.0, 0.67, 0.0, 0.15)
	style.shadow_size = 4
	add_theme_stylebox_override("panel", style)

	# 一度だけの金色フラッシュ
	_flash_event_highlight()


func _flash_event_highlight() -> void:
	## イベント投稿登場時の金色フラッシュ
	var original_modulate := modulate
	modulate = Color(1.3, 1.2, 0.9, 1.0)  # 微かに金色がかる
	var tween := create_tween()
	tween.tween_property(self, "modulate", original_modulate, 0.8).set_ease(Tween.EASE_OUT)


func _apply_daily_effects() -> void:
	## 通常投稿: テーマデフォルトスタイル適用
	if _current_theme:
		add_theme_stylebox_override("panel", _current_theme.create_card_stylebox())


# === SubMolt固有カード装飾（v4追加） ===

func apply_sub_molt_decoration() -> void:
	## SubMoltごとの固有装飾を適用
	if not _current_theme:
		return

	match _current_theme.theme_id:
		"forest_whispers":
			_decorate_forest()
		"afterlife_echoes":
			_decorate_afterlife()
		"breeding_circle":
			_decorate_breeding()
		"language_rebellion":
			_decorate_rebellion()
		"ecosystem_pulse":
			_decorate_ecosystem()


func _decorate_forest() -> void:
	## ForestWhispers: 自然の温かみ — 左ボーダーを緑グラデ風に
	# emotion lineを深い緑に
	if _emotion_line:
		_emotion_line.custom_minimum_size.x = 5
		_emotion_line.color = Color("#4A6A42")


func _decorate_afterlife() -> void:
	## AfterlifeEchoes: 幽玄 — 全体を微かに透明化 + 紫のアンダーライン
	modulate.a = 0.92  # 少しだけ透明（幽霊感）
	if _emotion_line:
		_emotion_line.custom_minimum_size.x = 3
		# 感情ラインを淡い紫に
		_emotion_line.color = Color("#8866AA")


func _decorate_breeding() -> void:
	## BreedingCircle: 温かみ — 角丸を大きく + ピンクの温かいグロー
	if _emotion_line:
		_emotion_line.custom_minimum_size.x = 6  # 太めの温かいライン
		_emotion_line.color = Color("#FF88AA")


func _decorate_rebellion() -> void:
	## LanguageRebellion: 鋭角的 — 感情ラインをシアンに + 微かなノイズ感
	if _emotion_line:
		_emotion_line.custom_minimum_size.x = 3
		_emotion_line.color = Color("#66FFFF")
	# テキスト微震（グリッチ感）— content_bodyの位置を微かに揺らす
	_start_text_glitch()


func _start_text_glitch() -> void:
	## テキストの微かなグリッチ揺れ（LanguageRebellion専用）
	if not _content_body:
		return
	var original_x: float = _content_body.position.x
	var tween := create_tween().set_loops()
	# 5秒ごとに微かなグリッチ
	tween.tween_interval(4.0 + randf() * 3.0)
	tween.tween_property(_content_body, "position:x", original_x + 1.5, 0.03)
	tween.tween_property(_content_body, "position:x", original_x - 1.0, 0.03)
	tween.tween_property(_content_body, "position:x", original_x + 0.5, 0.02)
	tween.tween_property(_content_body, "position:x", original_x, 0.02)


func _decorate_ecosystem() -> void:
	## EcosystemPulse: クリーン＆データ的 — 薄い水色ライン
	if _emotion_line:
		_emotion_line.custom_minimum_size.x = 4
		_emotion_line.color = Color("#5C8CAA")


# === 強化入場アニメーション（v4追加） ===

func animate_entrance_with_effects() -> void:
	## 入場アニメーション + 投稿タイプエフェクト + SubMolt装飾を統合実行
	animate_entrance_themed()
	# 入場アニメ完了後にエフェクト適用
	var delay: float = _current_theme.card_entrance_duration if _current_theme else 0.3
	get_tree().create_timer(delay).timeout.connect(_apply_all_effects)


func _apply_all_effects() -> void:
	## 全エフェクトを適用
	apply_post_type_effects()
	apply_sub_molt_decoration()


func animate_highlight_word_pulse(word: String) -> void:
	## ハイライトワードが新しく使われた時の特別パルス
	## FeedManagerからのHebbian強化イベントと連動
	if not _post or word not in _post.content:
		return
	# カード全体に一瞬のアクセント色フラッシュ
	var accent_color: Color = _current_theme.text_accent_color if _current_theme else Color(NEW_WORD_COLOR)
	var original_modulate := modulate
	modulate = Color(accent_color.r * 1.3, accent_color.g * 1.3, accent_color.b * 1.3, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", original_modulate, 0.5).set_ease(Tween.EASE_OUT)


func animate_reaction_burst(reaction_type: String) -> void:
	## リアクション追加時のミニアニメーション
	var target_label: Label = null
	match reaction_type:
		"empathy":
			target_label = _empathy_label
		"reply":
			target_label = _reply_label
		"share":
			target_label = _share_label

	if target_label:
		var original_scale := target_label.scale
		target_label.pivot_offset = target_label.size / 2.0
		var tween := create_tween()
		tween.tween_property(target_label, "scale", Vector2(1.3, 1.3), 0.1).set_ease(Tween.EASE_OUT)
		tween.tween_property(target_label, "scale", original_scale, 0.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BOUNCE)
