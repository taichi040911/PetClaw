## PetBookUI — PetBookメインUI管理
## ヘッダー・タイムライン・サイドバー・フッターを統合管理
## PetBookCoreからのシグナルを受けてUI更新・アニメーション・粒子を制御
## v4: PetBookPalette・ThemeBuilder・v4PostCard・v3Particlesを統合
class_name PetBookUI
extends Control

# === 色定数（v4: PetBookPaletteで統一） ===
const BG_BASE: Color = PetBookPalette.BG_DEEPEST
const BG_HEADER: Color = PetBookPalette.BG_DARK
const BG_SIDEBAR: Color = PetBookPalette.BG_NEUTRAL
const BG_FOOTER: Color = PetBookPalette.BG_DARK
const TEXT_PRIMARY: Color = PetBookPalette.TEXT_STRONG
const TEXT_SECONDARY: Color = PetBookPalette.TEXT_SECONDARY
const TEXT_DIM: Color = PetBookPalette.TEXT_DIM
const TEXT_ACCENT: Color = PetBookPalette.ACCENT_CYAN

# === SubMoltフィルター（v2: BREEDING追加） ===
enum FilterMode { ALL, ECOLOGY, DEATH, LANGUAGE, REBELLION, BREEDING }

# === ノード参照 ===
var _header: PanelContainer
var _submolt_label: Label
var _stats_label: Label
var _observing_label: Label
var _timeline_scroll: ScrollContainer
var _post_list: VBoxContainer
var _sidebar: PanelContainer
var _sidebar_content: VBoxContainer
var _trend_list: VBoxContainer
var _submolt_list: VBoxContainer
var _ecosystem_pulse: VBoxContainer
var _footer: PanelContainer
var _particles: PetBookParticles
var _detail_overlay: PanelContainer
var _detail_body: RichTextLabel
var _detail_translation: Label

# === 状態 ===
var _card_pool: Array[PetBookPostCard] = []
var _active_cards: Array[PetBookPostCard] = []
var _current_filter: FilterMode = FilterMode.ALL
var _is_paused: bool = false
var _auto_scroll: bool = true
var _current_sub_molt_theme: PetBookSubMoltTheme = null
var _theme_cache: Dictionary = {}  # theme_id → PetBookSubMoltTheme
var _bg_rect: ColorRect  # 背景矩形への参照
const CARD_POOL_SIZE: int = 30
const VISIBLE_BUFFER: int = 2  # 可視領域 ± N カードをアクティブに保持


func _ready() -> void:
	_preload_themes()
	_build_scene()
	_connect_petbook_signals()
	_create_card_pool()
	_refresh_feed()
	# v2: スクロール仮想化接続
	_timeline_scroll.get_v_scroll_bar().value_changed.connect(
		func(_value: float): _on_timeline_scrolled()
	)
	# v2: ピクセルフォント適用（フォントファイルがある場合のみ）
	_apply_pixel_theme()
	# v3: デフォルトSubMoltテーマ適用
	change_sub_molt_theme("#ForestWhispers")


# === シーン構築 ===
func _build_scene() -> void:
	## UIノードツリーをコードで構築
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)

	# === ParallaxBackground（v2: 3層深度背景） ===
	var parallax_bg := ParallaxBackground.new()
	add_child(parallax_bg)
	parallax_bg.z_index = -20

	# Layer 0: 環境シルエット（最奥、動き最小）
	var layer0 := ParallaxLayer.new()
	layer0.motion_scale = Vector2(0.1, 0.1)
	parallax_bg.add_child(layer0)
	var silhouette := ColorRect.new()
	silhouette.color = Color("#0D0E1A")
	silhouette.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	layer0.add_child(silhouette)

	# Layer 1: 中間（環境粒子はPetBookParticlesが管理）
	var layer1 := ParallaxLayer.new()
	layer1.motion_scale = Vector2(0.3, 0.3)
	parallax_bg.add_child(layer1)

	# Layer 2: 手前の浮遊光点
	var layer2 := ParallaxLayer.new()
	layer2.motion_scale = Vector2(0.6, 0.5)
	parallax_bg.add_child(layer2)

	# 背景（Parallax上のフォールバック）
	_bg_rect = ColorRect.new()
	_bg_rect.color = BG_BASE
	_bg_rect.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_bg_rect.z_index = -10
	var bg := _bg_rect
	add_child(bg)

	# 粒子レイヤー
	_particles = PetBookParticles.new()
	_particles.z_index = -5
	add_child(_particles)

	# メインレイアウト
	var main_layout := VBoxContainer.new()
	main_layout.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	main_layout.add_theme_constant_override("separation", 0)
	add_child(main_layout)

	# --- ヘッダー ---
	_header = _build_header()
	main_layout.add_child(_header)

	# --- コンテンツエリア ---
	var content_area := HSplitContainer.new()
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_layout.add_child(content_area)

	# タイムライン
	var timeline_container := PanelContainer.new()
	timeline_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline_container.size_flags_stretch_ratio = 3.0
	var timeline_style := StyleBoxFlat.new()
	timeline_style.bg_color = Color.TRANSPARENT
	timeline_container.add_theme_stylebox_override("panel", timeline_style)
	content_area.add_child(timeline_container)

	_timeline_scroll = ScrollContainer.new()
	_timeline_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_timeline_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_timeline_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	timeline_container.add_child(_timeline_scroll)
	
	# v4: Apply default scrollbar theme
	var default_theme := PetBookSubMoltTheme.create_by_name("#DailyPetLife")
	if default_theme:
		var scrollbar := _timeline_scroll.get_v_scroll_bar()
		scrollbar.add_theme_stylebox_override("grabber", PetBookThemeBuilder.build_scrollbar_grabber(default_theme))
		scrollbar.add_theme_stylebox_override("scroll", PetBookThemeBuilder.build_scrollbar_background(default_theme))

	_post_list = VBoxContainer.new()
	_post_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_post_list.add_theme_constant_override("separation", 8)
	_timeline_scroll.add_child(_post_list)

	# サイドバー
	_sidebar = _build_sidebar()
	content_area.add_child(_sidebar)

	# --- フッター ---
	_footer = _build_footer()
	main_layout.add_child(_footer)

	# --- 詳細オーバーレイ（非表示） ---
	_detail_overlay = _build_detail_overlay()
	add_child(_detail_overlay)


func _build_header() -> PanelContainer:
	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 60)
	# v4: Use PetBookThemeBuilder default theme
	var default_theme := PetBookSubMoltTheme.create_by_name("#DailyPetLife")
	var style := PetBookThemeBuilder.build_header_bar(default_theme) if default_theme else StyleBoxFlat.new()
	if not style:
		style = StyleBoxFlat.new()
		style.bg_color = BG_HEADER
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 8
		style.content_margin_bottom = 8
	header.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	header.add_child(hbox)

	# ロゴ
	var logo := Label.new()
	logo.text = "🐾 PetBook"
	logo.add_theme_color_override("font_color", TEXT_PRIMARY)
	logo.add_theme_font_size_override("font_size", 20)
	hbox.add_child(logo)

	# SubMolt名
	_submolt_label = Label.new()
	_submolt_label.text = "#TodayWeLive"
	_submolt_label.add_theme_color_override("font_color", TEXT_ACCENT)
	_submolt_label.add_theme_font_size_override("font_size", 14)
	_submolt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_submolt_label)

	# ステータスエリア
	var status_vbox := VBoxContainer.new()
	status_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(status_vbox)

	_observing_label = Label.new()
	_observing_label.text = "Observing..."
	_observing_label.add_theme_color_override("font_color", TEXT_DIM)
	_observing_label.add_theme_font_size_override("font_size", 10)
	_observing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_vbox.add_child(_observing_label)

	_stats_label = Label.new()
	_stats_label.text = "0 posts · 0 active"
	_stats_label.add_theme_color_override("font_color", TEXT_SECONDARY)
	_stats_label.add_theme_font_size_override("font_size", 11)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_vbox.add_child(_stats_label)

	return header


func _build_sidebar() -> PanelContainer:
	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(220, 0)
	sidebar.size_flags_stretch_ratio = 1.0
	# v4: Use PetBookThemeBuilder default theme
	var default_theme := PetBookSubMoltTheme.create_by_name("#DailyPetLife")
	var style := PetBookThemeBuilder.build_sidebar_panel(default_theme) if default_theme else StyleBoxFlat.new()
	if not style:
		style = StyleBoxFlat.new()
		style.bg_color = BG_SIDEBAR
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 12
		style.content_margin_bottom = 12
	sidebar.add_theme_stylebox_override("panel", style)

	_sidebar_content = VBoxContainer.new()
	_sidebar_content.add_theme_constant_override("separation", 16)
	sidebar.add_child(_sidebar_content)

	# SubMoltsセクション
	var submolt_section := _create_sidebar_section("SubMolts")
	_sidebar_content.add_child(submolt_section)
	_submolt_list = VBoxContainer.new()
	_submolt_list.add_theme_constant_override("separation", 4)
	submolt_section.add_child(_submolt_list)

	# デフォルトSubMolt（v4: ThemeBuilder styled）
	# v2: 詩的SubMolt命名
	var default_submolts: Array[String] = [
		"#DailyPetLife", "#ForestWhispers", "#OceanDepths",
		"#AfterlifeEchoes", "#TongueOfRebellion", "#BreedingCircle",
		"#EvolutionSpark", "#WordForge",
	]
	for sm in default_submolts:
		var btn := Button.new()
		btn.text = sm
		btn.flat = true
		btn.add_theme_color_override("font_color", TEXT_SECONDARY)
		btn.add_theme_font_size_override("font_size", 12)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_submolt_selected.bind(sm))
		# v4: Apply ThemeBuilder styling to inactive tabs
		var theme_obj := PetBookSubMoltTheme.create_by_name(sm)
		if theme_obj:
			var inactive_style := PetBookThemeBuilder.build_sub_molt_tab_inactive(theme_obj)
			btn.add_theme_stylebox_override("normal", inactive_style)
			btn.add_theme_stylebox_override("hover", inactive_style)
		_submolt_list.add_child(btn)

	# トレンドセクション
	var trend_section := _create_sidebar_section("Trending Language")
	_sidebar_content.add_child(trend_section)
	_trend_list = VBoxContainer.new()
	_trend_list.add_theme_constant_override("separation", 4)
	trend_section.add_child(_trend_list)

	# Ecosystem Pulseセクション（v2追加）
	var pulse_section := _create_sidebar_section("Ecosystem Pulse")
	_sidebar_content.add_child(pulse_section)
	_ecosystem_pulse = _build_ecosystem_pulse()
	pulse_section.add_child(_ecosystem_pulse)

	# 統計セクション
	var stats_section := _create_sidebar_section("Observation Stats")
	_sidebar_content.add_child(stats_section)

	return sidebar


func _create_sidebar_section(title: String) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color", TEXT_PRIMARY)
	label.add_theme_font_size_override("font_size", 13)
	section.add_child(label)
	var separator := HSeparator.new()
	section.add_child(separator)
	return section


func _build_footer() -> PanelContainer:
	var footer := PanelContainer.new()
	footer.custom_minimum_size = Vector2(0, 50)
	# v4: Use PetBookThemeBuilder default theme
	var default_theme := PetBookSubMoltTheme.create_by_name("#DailyPetLife")
	var style := PetBookThemeBuilder.build_footer_bar(default_theme) if default_theme else StyleBoxFlat.new()
	if not style:
		style = StyleBoxFlat.new()
		style.bg_color = BG_FOOTER
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 8
		style.content_margin_bottom = 8
	footer.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	footer.add_child(hbox)

	var filters: Array[Dictionary] = [
		{"text": "All", "mode": FilterMode.ALL},
		{"text": "Ecology", "mode": FilterMode.ECOLOGY},
		{"text": "Life & Death", "mode": FilterMode.DEATH},
		{"text": "Language", "mode": FilterMode.LANGUAGE},
		{"text": "Rebellion", "mode": FilterMode.REBELLION},
		{"text": "Breeding", "mode": FilterMode.BREEDING},
	]

	for f in filters:
		var btn := Button.new()
		btn.text = f["text"]
		btn.flat = true
		btn.add_theme_color_override("font_color", TEXT_SECONDARY)
		btn.add_theme_font_size_override("font_size", 12)
		btn.toggle_mode = true
		btn.pressed.connect(_on_filter_changed.bind(f["mode"]))
		hbox.add_child(btn)

	# スペーサー
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# 一時停止ボタン
	var pause_btn := Button.new()
	pause_btn.text = "⏸ Pause"
	pause_btn.flat = true
	pause_btn.add_theme_color_override("font_color", TEXT_DIM)
	pause_btn.add_theme_font_size_override("font_size", 12)
	pause_btn.toggle_mode = true
	pause_btn.pressed.connect(_on_pause_toggled)
	hbox.add_child(pause_btn)

	return footer


func _build_detail_overlay() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay.visible = false
	overlay.z_index = 100

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 60
	style.content_margin_bottom = 60
	overlay.add_theme_stylebox_override("panel", style)

	var inner := PanelContainer.new()
	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = Color("#252640")
	inner_style.corner_radius_top_left = 12
	inner_style.corner_radius_top_right = 12
	inner_style.corner_radius_bottom_left = 12
	inner_style.corner_radius_bottom_right = 12
	inner_style.content_margin_left = 20
	inner_style.content_margin_right = 20
	inner_style.content_margin_top = 16
	inner_style.content_margin_bottom = 16
	inner.add_theme_stylebox_override("panel", inner_style)
	overlay.add_child(inner)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	inner.add_child(vbox)

	# 閉じるボタン
	var close_btn := Button.new()
	close_btn.text = "✕ 閉じる"
	close_btn.flat = true
	close_btn.add_theme_color_override("font_color", TEXT_DIM)
	close_btn.pressed.connect(func(): overlay.visible = false)
	vbox.add_child(close_btn)

	_detail_body = RichTextLabel.new()
	_detail_body.bbcode_enabled = true
	_detail_body.fit_content = true
	_detail_body.add_theme_color_override("default_color", TEXT_PRIMARY)
	_detail_body.add_theme_font_size_override("normal_font_size", 16)
	vbox.add_child(_detail_body)

	_detail_translation = Label.new()
	_detail_translation.add_theme_color_override("font_color", TEXT_SECONDARY)
	_detail_translation.add_theme_font_size_override("font_size", 13)
	_detail_translation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_detail_translation)

	overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			overlay.visible = false
	)

	return overlay


# === PetBookCore連携 ===
func _connect_petbook_signals() -> void:
	var gm := GameManager.instance
	if not gm or not gm.pet_book:
		return

	gm.pet_book.post_created.connect(_on_new_post)
	gm.pet_book.trend_detected.connect(_on_trend_update)
	gm.pet_book.rebel_post_emerged.connect(_on_rebel_post)
	gm.pet_book.memorial_posted.connect(_on_memorial_post)

	# 環境変化 → 背景粒子
	if gm.ecosystem:
		gm.ecosystem.climate_event.connect(_on_environment_changed)


func _on_new_post(post: PetBookPost) -> void:
	if _is_paused:
		return
	if not _matches_filter(post):
		return

	var card := _get_card_from_pool()
	if not card:
		return

	card.bind_post(post, GameManager.instance.game_time)
	if _current_sub_molt_theme:
		card.apply_sub_molt_theme(_current_sub_molt_theme)
	card.visible = true
	_post_list.add_child(card)
	_post_list.move_child(card, 0)  # 先頭に配置
	_active_cards.push_front(card)
	# v4: unified entrance animation with effects
	card.animate_entrance_with_effects()

	# 投稿粒子
	var particle_type := "normal_post"
	match post.post_type:
		PetBookPost.PostType.REBEL:
			particle_type = "rebel_post"
		PetBookPost.PostType.MEMORIAL:
			particle_type = "memorial_post"
		PetBookPost.PostType.EVENT:
			if post.triggered_by_event == "birth":
				particle_type = "birth_event"
			elif post.triggered_by_event == "evolution":
				particle_type = "evolution_event"
			elif post.triggered_by_event.begins_with("death"):
				particle_type = "death_event"

	_particles.spawn_post_particles(particle_type, post.get_emotion_color(), card.position)

	# 統計更新
	_update_stats()

	# 自動スクロール
	if _auto_scroll:
		_timeline_scroll.scroll_vertical = 0

	# カード数制限
	while _active_cards.size() > CARD_POOL_SIZE:
		var oldest := _active_cards.pop_back()
		oldest.recycle()
		_post_list.remove_child(oldest)
		_card_pool.append(oldest)


func _on_trend_update(topic: String, count: int) -> void:
	_refresh_trends()


func _on_rebel_post(post: PetBookPost) -> void:
	# 反乱投稿は追加のフラッシュエフェクト
	pass


func _on_memorial_post(post: PetBookPost, _deceased_id: int) -> void:
	# 追悼投稿の特別演出
	pass


func _on_environment_changed(_event_data) -> void:
	var gm := GameManager.instance
	if gm and gm.ecosystem:
		_particles.set_environment(gm.ecosystem.current_environment)


# === フィルター ===
func _on_filter_changed(mode: FilterMode) -> void:
	_current_filter = mode
	match mode:
		FilterMode.ALL:
			_submolt_label.text = "#TodayWeLive"
		FilterMode.ECOLOGY:
			_submolt_label.text = "#Ecology"
		FilterMode.DEATH:
			_submolt_label.text = "#DeathAndRebirth"
		FilterMode.LANGUAGE:
			_submolt_label.text = "#LanguageEvolution"
		FilterMode.REBELLION:
			_submolt_label.text = "#TongueOfRebellion"
		FilterMode.BREEDING:
			_submolt_label.text = "#BreedingCircle"
	_refresh_feed()


func _on_submolt_selected(submolt_name: String) -> void:
	_submolt_label.text = submolt_name
	change_sub_molt_theme(submolt_name)
	_refresh_feed()
	# v4: Apply active tab styling to selected button
	_update_submolt_tab_styles(submolt_name)


func _update_submolt_tab_styles(active_submolt: String) -> void:
	## v4新規: SubMoltタブをアクティブ/非アクティブに分ける（ThemeBuilder統合）
	for btn in _submolt_list.get_children():
		if btn is Button:
			var theme_obj := PetBookSubMoltTheme.create_by_name(btn.text)
			if not theme_obj:
				continue
			
			if btn.text == active_submolt:
				# Active: ThemeBuilderで濃いスタイル
				var active_style := PetBookThemeBuilder.build_sub_molt_tab_active(theme_obj)
				btn.add_theme_stylebox_override("focus", active_style)
				btn.add_theme_stylebox_override("pressed", active_style)
			else:
				# Inactive: ThemeBuilderで薄いスタイル
				var inactive_style := PetBookThemeBuilder.build_sub_molt_tab_inactive(theme_obj)
				btn.add_theme_stylebox_override("normal", inactive_style)
				btn.add_theme_stylebox_override("hover", inactive_style)


func _matches_filter(post: PetBookPost) -> bool:
	match _current_filter:
		FilterMode.ALL:
			return true
		FilterMode.ECOLOGY:
			return post.environment != "" or post.triggered_by_event in ["birth", "disaster"]
		FilterMode.DEATH:
			return post.post_type == PetBookPost.PostType.MEMORIAL or post.triggered_by_event.begins_with("death")
		FilterMode.LANGUAGE:
			return not post.rebel_expressions.is_empty() or post.suffixes_used.size() >= 2
		FilterMode.REBELLION:
			return post.post_type == PetBookPost.PostType.REBEL
		FilterMode.BREEDING:
			return post.triggered_by_event in ["birth", "breeding"] or \
				"breeding" in post.content.to_lower()
	return true


# === 一時停止 ===
func _on_pause_toggled() -> void:
	_is_paused = not _is_paused
	_observing_label.text = "Paused" if _is_paused else "Observing..."


# === フィード更新 ===
func _refresh_feed() -> void:
	## フィード全体を再描画（v4: animate_entrance_with_effects統合）
	# 既存カードをプールに返却
	for card in _active_cards:
		card.recycle()
		_post_list.remove_child(card)
		_card_pool.append(card)
	_active_cards.clear()

	# PetBookCoreからデータ取得
	var gm := GameManager.instance
	if not gm or not gm.pet_book:
		return

	var posts: Array[PetBookPost] = gm.pet_book.get_feed(0, CARD_POOL_SIZE)
	for post in posts:
		if not _matches_filter(post):
			continue
		var card := _get_card_from_pool()
		if not card:
			break
		card.bind_post(post, gm.game_time)
		if _current_sub_molt_theme:
			card.apply_sub_molt_theme(_current_sub_molt_theme)
		card.visible = true
		card.card_tapped.connect(_on_card_tapped)
		_post_list.add_child(card)
		_active_cards.append(card)
		# v4: PostCard entrance animation with effects
		card.animate_entrance_with_effects()

	_update_stats()


func _refresh_trends() -> void:
	var gm := GameManager.instance
	if not gm or not gm.pet_book:
		return

	# トレンドリストをクリア
	for child in _trend_list.get_children():
		child.queue_free()

	# トレンド接尾辞
	for suffix in gm.pet_book.trending_suffixes:
		var label := Label.new()
		label.text = "📈 %s" % suffix
		label.add_theme_color_override("font_color", TEXT_ACCENT)
		label.add_theme_font_size_override("font_size", 12)
		_trend_list.add_child(label)

	# トレンドトピック
	for topic in gm.pet_book.trending_topics:
		var label := Label.new()
		label.text = "🔥 %s" % topic
		label.add_theme_color_override("font_color", TEXT_SECONDARY)
		label.add_theme_font_size_override("font_size", 12)
		_trend_list.add_child(label)


func _update_stats() -> void:
	var gm := GameManager.instance
	if not gm or not gm.pet_book:
		return

	var active_pets: int = 0
	for pid in gm.pets:
		if gm.pets[pid].is_alive:
			active_pets += 1

	_stats_label.text = "%d posts · %d active" % [gm.pet_book.total_posts_created, active_pets]


# === カードプール ===
func _create_card_pool() -> void:
	for i in range(CARD_POOL_SIZE):
		var card := PetBookPostCard.new()
		card.visible = false
		_card_pool.append(card)


func _get_card_from_pool() -> PetBookPostCard:
	if _card_pool.is_empty():
		return null
	return _card_pool.pop_back()


# === 投稿詳細 ===
func _on_card_tapped(post: PetBookPost) -> void:
	_detail_body.text = post.content
	_detail_translation.text = "翻訳: %s" % post.translation if post.translation != "" else ""
	_detail_overlay.visible = true


# === Ecosystem Pulse（v2追加） ===
func _build_ecosystem_pulse() -> VBoxContainer:
	## 環境×感情のヒートマップを構築
	var pulse := VBoxContainer.new()
	pulse.add_theme_constant_override("separation", 6)

	var gm := GameManager.instance
	if not gm:
		return pulse

	# 各環境のペット数と感情を集計
	var env_counts: Dictionary = {}  # env → {count, emotions}
	for pid in gm.pets:
		var pet: PetEntity = gm.pets[pid]
		if not pet.is_alive:
			continue
		var env: String = gm.ecosystem.current_environment if gm.ecosystem else "forest"
		if not env_counts.has(env):
			env_counts[env] = {"count": 0, "emotions": {}}
		env_counts[env]["count"] += 1
		var emo: String = _get_dominant_emotion(pet)
		env_counts[env]["emotions"][emo] = env_counts[env]["emotions"].get(emo, 0) + 1

	for env_name in env_counts:
		var row := _create_pulse_row(env_name, env_counts[env_name])
		pulse.add_child(row)

	# Community Mood
	var mood_label := Label.new()
	mood_label.text = "💓 Community Mood: %s" % _get_community_mood_text()
	mood_label.add_theme_color_override("font_color", TEXT_SECONDARY)
	mood_label.add_theme_font_size_override("font_size", 11)
	pulse.add_child(mood_label)

	# Activity Level
	var activity_label := Label.new()
	var activity_level: String = _get_activity_level()
	activity_label.text = "🔥 Activity: %s" % activity_level
	activity_label.add_theme_color_override("font_color", TEXT_SECONDARY)
	activity_label.add_theme_font_size_override("font_size", 11)
	pulse.add_child(activity_label)

	return pulse


func _create_pulse_row(env_name: String, data: Dictionary) -> VBoxContainer:
	## 環境ごとのミニヒートマップ行
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	var env_icon: String = _get_env_icon_for_pulse(env_name)
	var count: int = data["count"]
	var bar: String = "█".repeat(mini(count, 5)) + "░".repeat(maxi(0, 5 - count))

	var header := Label.new()
	header.text = "%s %s  %s %d/5" % [env_icon, env_name.capitalize(), bar, mini(count, 5)]
	header.add_theme_color_override("font_color", TEXT_PRIMARY)
	header.add_theme_font_size_override("font_size", 11)
	row.add_child(header)

	# 感情内訳
	var emotions: Dictionary = data["emotions"]
	if not emotions.is_empty():
		var emo_parts: Array[String] = []
		for emo_name in emotions:
			var emo_count: int = emotions[emo_name]
			var emo_bar: String = "█".repeat(mini(emo_count, 3)) + "░".repeat(maxi(0, 3 - emo_count))
			emo_parts.append("%s %s" % [emo_name, emo_bar])
		var emo_label := Label.new()
		emo_label.text = "   %s" % "  ".join(emo_parts)
		emo_label.add_theme_color_override("font_color", TEXT_DIM)
		emo_label.add_theme_font_size_override("font_size", 10)
		row.add_child(emo_label)

	return row


func _get_env_icon_for_pulse(env: String) -> String:
	match env:
		"forest": return "🌲"
		"ocean": return "🌊"
		"mountain": return "🏔️"
		"desert": return "🏜️"
		"cave": return "🕳️"
		"meadow": return "🌿"
		_: return "🌍"


func _get_dominant_emotion(pet: PetEntity) -> String:
	## ペットの支配的感情を取得
	if not pet.emotion_system:
		return "calm"
	var emotions: Dictionary = pet.emotion_system.get_emotions()
	var max_val: float = 0.0
	var max_name: String = "calm"
	for emo_name in emotions:
		if emotions[emo_name] > max_val:
			max_val = emotions[emo_name]
			max_name = emo_name
	return max_name


func _get_community_mood_text() -> String:
	## コミュニティ全体のムードを判定
	var gm := GameManager.instance
	if not gm:
		return "Unknown"
	var mood_counts: Dictionary = {}
	for pid in gm.pets:
		var pet: PetEntity = gm.pets[pid]
		if not pet.is_alive:
			continue
		var emo: String = _get_dominant_emotion(pet)
		mood_counts[emo] = mood_counts.get(emo, 0) + 1

	var top_mood: String = "Calm"
	var top_count: int = 0
	for mood in mood_counts:
		if mood_counts[mood] > top_count:
			top_count = mood_counts[mood]
			top_mood = mood.capitalize()
	return top_mood


func _get_activity_level() -> String:
	## 直近の投稿頻度からアクティビティレベルを判定
	var gm := GameManager.instance
	if not gm or not gm.pet_book:
		return "Low"
	var recent_posts: Array[PetBookPost] = gm.pet_book.get_feed(0, 20)
	if recent_posts.is_empty():
		return "Low"
	# 直近20投稿の時間範囲から頻度を推定
	var newest_time: float = recent_posts[0].timestamp
	var oldest_time: float = recent_posts[recent_posts.size() - 1].timestamp
	var span: float = newest_time - oldest_time
	if span <= 0:
		return "Low"
	var posts_per_minute: float = recent_posts.size() / (span / 60.0)
	if posts_per_minute > 2.0:
		return "High"
	elif posts_per_minute > 0.5:
		return "Medium"
	return "Low"


func refresh_ecosystem_pulse() -> void:
	## Ecosystem Pulseパネルを更新
	if _ecosystem_pulse and _ecosystem_pulse.get_parent():
		var parent := _ecosystem_pulse.get_parent()
		_ecosystem_pulse.queue_free()
		_ecosystem_pulse = _build_ecosystem_pulse()
		parent.add_child(_ecosystem_pulse)


# === 動的ヘッダー統計（v2追加） ===
func _update_header_stats() -> void:
	## 「X pets chatting · Y alive」形式の生命感ある表示
	var gm := GameManager.instance
	if not gm:
		return

	var alive_count: int = 0
	var chatting_count: int = 0
	for pid in gm.pets:
		var pet: PetEntity = gm.pets[pid]
		if pet.is_alive:
			alive_count += 1
		# 最近30秒以内に投稿したペットを「chatting」とみなす
		if gm.pet_book:
			var recent_posts: Array[PetBookPost] = gm.pet_book.get_pet_posts(pid, 1)
			if not recent_posts.is_empty():
				var last_post: PetBookPost = recent_posts[0]
				if gm.game_time - last_post.timestamp < 30.0:
					chatting_count += 1

	_stats_label.text = "%d pets chatting · %d alive" % [chatting_count, alive_count]


func _update_observing_animation() -> void:
	## 「Observing...」のドット点滅アニメーション
	if _is_paused:
		return
	var gm := GameManager.instance
	if not gm:
		return
	var dots: int = int(gm.game_time * 0.5) % 4
	_observing_label.text = "Observing" + ".".repeat(dots)


# === SubMoltテーマ切替（v3追加） ===
func _preload_themes() -> void:
	## 全SubMoltテーマをキャッシュにプリロード
	for theme in PetBookSubMoltTheme.get_all_themes():
		_theme_cache[theme.display_name] = theme


func change_sub_molt_theme(submolt_name: String) -> void:
	## SubMoltテーマを切り替え: 背景・粒子・カードスタイルを一括変更
	## v4: PetBookThemeBuilder統合で全エレメントを統一的にテーマ化
	var theme: PetBookSubMoltTheme = _theme_cache.get(submolt_name)
	if not theme:
		theme = PetBookSubMoltTheme.create_by_name(submolt_name)
		_theme_cache[submolt_name] = theme

	# EcosystemPulseは環境連動
	if theme.theme_id == "ecosystem_pulse":
		var gm := GameManager.instance
		if gm and gm.ecosystem:
			theme.apply_environment_override(gm.ecosystem.current_environment)

	# 前のテーマから遷移
	if _current_sub_molt_theme and _current_sub_molt_theme != theme:
		_apply_theme_transition(_current_sub_molt_theme, theme)
	else:
		# 初期テーマ直適用
		_apply_theme_transition(theme, theme)
	
	_current_sub_molt_theme = theme
	_submolt_label.text = theme.display_name


func _apply_theme_transition(from_theme: PetBookSubMoltTheme, to_theme: PetBookSubMoltTheme) -> void:
	## なめらかなSubMoltテーマ遷移を実行（v4新規）
	## ThemeBuilder統合でv4PostCard・v3Particles双方に適用
	
	# スクロールバーテーマ適用
	var scrollbar := _timeline_scroll.get_v_scroll_bar()
	scrollbar.add_theme_stylebox_override("grabber", PetBookThemeBuilder.build_scrollbar_grabber(to_theme))
	scrollbar.add_theme_stylebox_override("scroll", PetBookThemeBuilder.build_scrollbar_background(to_theme))
	
	var tween := PetBookThemeBuilder.create_transition_tween(self, from_theme, to_theme, 0.5)
	
	# フェードアウト → 適用 → フェードイン（0.3s + 0.2s + 0.3s）
	tween.tween_property(_bg_rect, "modulate:a", 0.0, 0.3)
	
	tween.tween_callback(func():
		# 背景色トランジション（フェードイン中に行われる）
		var bg_tween := create_tween()
		bg_tween.tween_property(_bg_rect, "color", to_theme.bg_color, 0.5).set_ease(Tween.EASE_IN_OUT)
		
		# ヘッダースタイル（ThemeBuilder統合）
		var header_style := PetBookThemeBuilder.build_header_bar(to_theme)
		_header.add_theme_stylebox_override("panel", header_style)
		
		# サイドバースタイル（ThemeBuilder統合）
		var sidebar_style := PetBookThemeBuilder.build_sidebar_panel(to_theme)
		_sidebar.add_theme_stylebox_override("panel", sidebar_style)
		
		# フッターテーマ（ThemeBuilder統合）
		var footer_style := PetBookThemeBuilder.build_footer_bar(to_theme)
		_footer.add_theme_stylebox_override("panel", footer_style)
		
		# SubMoltラベル色
		_submolt_label.add_theme_color_override("font_color", to_theme.text_accent_color)
		
		# v3Particles: 詳細SUB_MOLT_PARTICLE_DETAILSを適用
		_particles._apply_sub_molt_ambient_detailed(to_theme.theme_id)
		
		# v4PostCard: 全アクティブカードにテーマ適用・entrance effect準備
		for card in _active_cards:
			card.apply_sub_molt_theme(to_theme)
	)
	
	tween.tween_property(_bg_rect, "modulate:a", 1.0, 0.3)


# === _process: 動的UI更新 ===
func _process(_delta: float) -> void:
	_update_observing_animation()
	# ヘッダー統計は5秒ごとに更新（負荷軽減）
	var gm := GameManager.instance
	if gm and int(gm.game_time) % 5 == 0:
		_update_header_stats()
	# Ecosystem Pulseは30秒ごとに更新
	if gm and int(gm.game_time) % 30 == 0:
		refresh_ecosystem_pulse()


# === 仮想化スクロール改善（v2追加） ===
func _on_timeline_scrolled() -> void:
	## 可視範囲外のカードを非表示にしてパフォーマンス向上
	var scroll_pos: float = _timeline_scroll.scroll_vertical
	var viewport_h: float = _timeline_scroll.size.y

	for i in range(_active_cards.size()):
		var card := _active_cards[i]
		var card_top: float = card.position.y
		var card_bottom: float = card_top + card.size.y
		var buffer: float = viewport_h * 0.5

		var is_visible: bool = card_bottom > scroll_pos - buffer and \
							   card_top < scroll_pos + viewport_h + buffer
		card.visible = is_visible

		# 非表示カードの粒子を停止
		if not is_visible and card.has_node("PostParticles"):
			card.get_node("PostParticles").emitting = false


# === ピクセルフォント統一（v2追加） ===
func _apply_pixel_theme() -> void:
	## ピクセルフォントを全Labelに一括適用
	var font := load("res://assets/fonts/pixel_font.tres") as Font
	if not font:
		return
	for node in _get_all_labels(self):
		node.add_theme_font_override("font", font)


func _get_all_labels(root: Node) -> Array[Label]:
	var labels: Array[Label] = []
	for child in root.get_children():
		if child is Label:
			labels.append(child)
		labels.append_array(_get_all_labels(child))
	return labels


# === SubMolt詩的命名（v2追加） ===
func get_poetic_submolt(post: PetBookPost) -> String:
	## 投稿内容に基づいて詩的SubMolt名を生成
	# 環境SubMolts
	match post.environment:
		"forest": return "#ForestWhispers"
		"ocean": return "#OceanDepths"
		"mountain": return "#MountainEchoes"
		"desert": return "#DesertWanderings"
		"cave": return "#CaveShadows"
		"meadow": return "#MeadowDreams"

	# テーマSubMolts
	match post.post_type:
		PetBookPost.PostType.MEMORIAL: return "#AfterlifeEchoes"
		PetBookPost.PostType.REBEL: return "#TongueOfRebellion"
		PetBookPost.PostType.EVENT:
			if post.triggered_by_event in ["birth", "breeding"]:
				return "#BreedingCircle"
			if post.triggered_by_event == "evolution":
				return "#EvolutionSpark"

	# 新語検出
	if not post.rebel_expressions.is_empty():
		return "#WordForge"

	return "#DailyPetLife"
