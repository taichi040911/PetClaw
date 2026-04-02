## SettingsScreen — 設定画面
## 音量、APIキー設定、セーブデータ管理
class_name SettingsScreen
extends Control

signal back_requested

var _vbox: VBoxContainer


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.14)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_preset(PRESET_FULL_RECT)
	scroll.offset_top = 50
	scroll.offset_left = 20
	scroll.offset_right = -20
	add_child(scroll)

	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(_vbox)

	# ヘッダー
	var header: HBoxContainer = HBoxContainer.new()
	header.set_anchors_preset(PRESET_TOP_WIDE)
	header.offset_bottom = 48
	header.offset_left = 8
	add_child(header)

	var back_btn: Button = Button.new()
	back_btn.text = "< Back"
	back_btn.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back_btn)

	var title: Label = Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)

	# === 音量設定 ===
	_add_section_label("Audio")

	_add_slider_row("BGM Volume", AmbientBGM.instance._volume if AmbientBGM.instance else 0.7, func(value: float) -> void:
		if AmbientBGM.instance:
			AmbientBGM.instance.set_volume(value)
	)

	_add_slider_row("SFX Volume", SfxManager.instance.sfx_volume if SfxManager.instance else 0.8, func(value: float) -> void:
		if SfxManager.instance:
			SfxManager.instance.sfx_volume = value
			SfxManager.instance.play(SfxManager.SfxType.TAP)
	)

	# === API 設定 ===
	_add_section_label("Claude API")

	var api_row: HBoxContainer = HBoxContainer.new()
	_vbox.add_child(api_row)

	var api_label: Label = Label.new()
	api_label.text = "API Key:"
	api_label.custom_minimum_size = Vector2(100, 0)
	api_row.add_child(api_label)

	var api_input: LineEdit = LineEdit.new()
	api_input.placeholder_text = "sk-ant-..."
	api_input.secret = true
	api_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	api_row.add_child(api_input)

	var api_save_btn: Button = Button.new()
	api_save_btn.text = "Save"
	api_save_btn.pressed.connect(func() -> void:
		var key: String = api_input.text.strip_edges()
		if not key.is_empty():
			var file: FileAccess = FileAccess.open("user://api_key.txt", FileAccess.WRITE)
			if file:
				file.store_string(key)
				file.close()
				api_input.text = ""
				api_input.placeholder_text = "Saved!"
	)
	api_row.add_child(api_save_btn)

	# API ステータス
	var api_status: Label = Label.new()
	if OS.has_environment("ANTHROPIC_API_KEY") or FileAccess.file_exists("user://api_key.txt"):
		api_status.text = "API Key: Configured"
		api_status.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	else:
		api_status.text = "API Key: Not set (template mode)"
		api_status.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	api_status.add_theme_font_size_override("font_size", 12)
	_vbox.add_child(api_status)

	# === セーブデータ ===
	_add_section_label("Save Data")

	var save_row: HBoxContainer = HBoxContainer.new()
	_vbox.add_child(save_row)

	var save_btn: Button = Button.new()
	save_btn.text = "Save Now"
	save_btn.pressed.connect(func() -> void:
		if GameManager.instance:
			GameManager.instance.save_game()
	)
	save_row.add_child(save_btn)

	var save_info: Label = Label.new()
	save_info.text = "Auto-save every 5 minutes"
	save_info.add_theme_font_size_override("font_size", 12)
	save_info.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	save_row.add_child(save_info)

	# === デモモード ===
	_add_section_label("AtoA Demo")

	var demo_row: HBoxContainer = HBoxContainer.new()
	demo_row.add_theme_constant_override("separation", 12)
	_vbox.add_child(demo_row)

	var demo_btn: Button = Button.new()
	demo_btn.text = "⚡ Enable Demo Mode"
	demo_btn.custom_minimum_size = Vector2(200, 40)
	demo_btn.pressed.connect(func() -> void:
		_enable_demo_mode()
		demo_btn.text = "✅ Demo Mode Active"
		demo_btn.disabled = true
	)
	demo_row.add_child(demo_btn)

	var demo_info: Label = Label.new()
	demo_info.text = "Conversations every 30s\nBoosted emotions for demo"
	demo_info.add_theme_font_size_override("font_size", 11)
	demo_info.add_theme_color_override("font_color", Color(0.5, 0.55, 0.7))
	demo_row.add_child(demo_info)

	# === AtoA Analytics ===
	_add_section_label("📊 AtoA Analytics")

	if GameManager.instance and GameManager.instance.a2a_system:
		var a2a: AtoAConversationSystem = GameManager.instance.a2a_system
		var status: Dictionary = a2a.get_conversation_status()
		var log: Array[Dictionary] = a2a.conversation_log
		var rels: Dictionary = a2a.pet_relationships

		# --- Compute analytics ---
		# API vs Template ratio
		var api_count: int = 0
		var tpl_count: int = 0
		for entry: Dictionary in log:
			if entry.get("is_template", false):
				tpl_count += 1
			else:
				api_count += 1

		# Total unique relationships + strongest
		var strongest_key: String = ""
		var strongest_affinity: float = 0.0
		for rel_key: String in rels:
			var rel: Dictionary = rels[rel_key]
			var aff: float = rel.get("affinity", 0.0)
			if aff > strongest_affinity:
				strongest_affinity = aff
				strongest_key = rel_key

		# Total words taught across all relationships
		var total_words_taught: int = 0
		for rel_key: String in rels:
			var rel: Dictionary = rels[rel_key]
			total_words_taught += int(rel.get("words_taught", 0))

		# Most active pet (most messages in log)
		var pet_msg_counts: Dictionary = {}
		for entry: Dictionary in log:
			var pid: int = entry.get("pet_id", -1)
			if pid >= 0:
				pet_msg_counts[pid] = pet_msg_counts.get(pid, 0) + 1
		var most_active_id: int = -1
		var most_active_count: int = 0
		for pid: int in pet_msg_counts:
			var cnt: int = pet_msg_counts[pid]
			if cnt > most_active_count:
				most_active_count = cnt
				most_active_id = pid
		var most_active_name: String = "—"
		if most_active_id >= 0 and GameManager.instance.pets.has(most_active_id):
			var active_pet: Variant = GameManager.instance.pets[most_active_id]
			if active_pet is PetEntity:
				most_active_name = "%s (%d msgs)" % [active_pet.pet_name, most_active_count]

		# Format strongest relationship label
		var strongest_label: String = "—"
		if not strongest_key.is_empty():
			strongest_label = "%s (%.0f%%)" % [strongest_key.replace("_", " ↔ "), strongest_affinity * 100.0]

		# --- Build analytics rows ---
		var analytics_data: Array[Array] = [
			["Total Conversations", "%d" % status.get("total_conversations", 0)],
			["Daily Count / Max", "%d / %d" % [status.get("daily_count", 0), status.get("max_daily", 25)]],
			["API / Template", "%d / %d" % [api_count, tpl_count]],
			["Budget Remaining", "$%.3f" % status.get("budget_remaining", 0.0)],
			["Daily Cost", "$%.3f" % a2a.daily_conversation_cost],
			["Avg Compliance", "%.0f%%" % (status.get("avg_compliance", 0.0) * 100.0)],
			["Unique Relationships", "%d" % rels.size()],
			["Strongest Bond", strongest_label],
			["Words Taught", "%d" % total_words_taught],
			["Most Active Pet", most_active_name],
		]

		for row_data: Array in analytics_data:
			var row: HBoxContainer = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			_vbox.add_child(row)

			var lbl: Label = Label.new()
			lbl.text = row_data[0]
			lbl.custom_minimum_size = Vector2(160, 0)
			lbl.add_theme_font_size_override("font_size", 11)
			lbl.add_theme_color_override("font_color", Color(0.5, 0.52, 0.65))
			row.add_child(lbl)

			var val: Label = Label.new()
			val.text = row_data[1]
			val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			val.add_theme_font_size_override("font_size", 12)
			val.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
			row.add_child(val)

		# Reset Daily Stats button
		var reset_row: HBoxContainer = HBoxContainer.new()
		reset_row.add_theme_constant_override("separation", 12)
		_vbox.add_child(reset_row)

		var reset_btn: Button = Button.new()
		reset_btn.text = "Reset Daily Stats"
		reset_btn.custom_minimum_size = Vector2(160, 32)
		reset_btn.pressed.connect(func() -> void:
			if GameManager.instance and GameManager.instance.a2a_system:
				GameManager.instance.a2a_system._on_day_change()
				reset_btn.text = "✓ Reset Done"
				reset_btn.disabled = true
		)
		reset_row.add_child(reset_btn)

		var reset_hint: Label = Label.new()
		reset_hint.text = "Clears daily count & cost"
		reset_hint.add_theme_font_size_override("font_size", 11)
		reset_hint.add_theme_color_override("font_color", Color(0.45, 0.48, 0.6))
		reset_row.add_child(reset_hint)
	else:
		var no_data_label: Label = Label.new()
		no_data_label.text = "AtoA system not available"
		no_data_label.add_theme_font_size_override("font_size", 11)
		no_data_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.45))
		_vbox.add_child(no_data_label)

	# === Future AtoA Analytics ===
	_add_section_label("Future AtoA")

	if GameManager.instance:
		var future_data: Array[Array] = []

		# Cultural System stats
		if GameManager.instance.get("cultural_system"):
			var cs: Node = GameManager.instance.cultural_system
			var arts: Dictionary = cs.get("artifacts") if cs.get("artifacts") else {}
			var traditions: int = 0
			for aid: String in arts:
				if arts[aid].get("type_name", "") == "tradition":
					traditions += 1
			future_data.append(["Cultural Artifacts", "%d" % arts.size()])
			future_data.append(["Traditions", "%d" % traditions])

		# Team Orchestrator stats
		if GameManager.instance.get("team_orchestrator"):
			var to: Node = GameManager.instance.team_orchestrator
			var active: Dictionary = to.get("active_teams") if to.get("active_teams") else {}
			var completed: Array = to.get("completed_teams") if to.get("completed_teams") else []
			future_data.append(["Active Teams", "%d" % active.size()])
			future_data.append(["Completed Missions", "%d" % completed.size()])

		# Memory Bridge stats
		if GameManager.instance.get("memory_bridge"):
			var mb: Node = GameManager.instance.memory_bridge
			var gs: Dictionary = mb.get("grief_states") if mb.get("grief_states") else {}
			var tm: Dictionary = mb.get("trauma_markers") if mb.get("trauma_markers") else {}
			var dl: Dictionary = mb.get("dream_log") if mb.get("dream_log") else {}
			var total_dreams: int = 0
			for pid: Variant in dl:
				total_dreams += dl[pid].size() if dl[pid] is Array else 0
			future_data.append(["Active Grief", "%d pets" % gs.size()])
			future_data.append(["Total Dreams", "%d" % total_dreams])

		if future_data.is_empty():
			var no_data: Label = Label.new()
			no_data.text = "Future AtoA systems initializing..."
			no_data.add_theme_font_size_override("font_size", 11)
			_vbox.add_child(no_data)
		else:
			for row_data: Array in future_data:
				var row: HBoxContainer = HBoxContainer.new()
				row.add_theme_constant_override("separation", 8)
				_vbox.add_child(row)

				var lbl: Label = Label.new()
				lbl.text = row_data[0]
				lbl.custom_minimum_size = Vector2(160, 0)
				lbl.add_theme_font_size_override("font_size", 11)
				lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.7))
				row.add_child(lbl)

				var val: Label = Label.new()
				val.text = row_data[1]
				val.add_theme_font_size_override("font_size", 12)
				val.add_theme_color_override("font_color", Color(0.65, 0.75, 0.9))
				row.add_child(val)

	# === バージョン情報 ===
	_add_section_label("About")

	var version_label: Label = Label.new()
	version_label.text = "PetClaw v1.1.0\nGodot 4.x | Agent Teams + Karpathy Loop\nFuture AtoA: Culture + Teams + Memory Bridge"
	version_label.add_theme_font_size_override("font_size", 12)
	version_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	_vbox.add_child(version_label)


func _add_section_label(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	_vbox.add_child(label)

	var sep: HSeparator = HSeparator.new()
	_vbox.add_child(sep)


func _enable_demo_mode() -> void:
	## デモモード: 会話間隔を短縮し、感情をブースト
	if GameManager.instance and GameManager.instance.a2a_system:
		# 会話間隔を30秒に短縮 + タイマーを進める
		GameManager.instance.a2a_system.auto_conversation_interval = 30.0
		GameManager.instance.a2a_system.conversation_timer = 25.0  # 5秒後に会話開始

	# 全ペットの感情をブースト
	if GameManager.instance:
		for pet_id: int in GameManager.instance.pets:
			var pet: Variant = GameManager.instance.pets[pet_id]
			if pet is PetEntity and pet.is_alive:
				# 感情をランダムにブースト（会話を誘発）
				var boost_emotions: Array = ["joy", "love", "excitement", "curiosity"]
				var chosen: String = boost_emotions[randi() % boost_emotions.size()]
				if pet.emotions.has(chosen):
					pet.emotions[chosen] = maxf(pet.emotions[chosen], 0.6)
				elif GameManager.emotion_system:
					GameManager.emotion_system.stimulate(pet, chosen, 0.5, "demo_mode")
				# 空腹を少し減らして健全な状態に
				pet.stats.modify("hunger", 0.3)
				pet.stats.modify("energy", 0.3)

	print("[Settings] Demo mode enabled: timer advanced, emotions boosted")


func _add_slider_row(label_text: String, default_value: float, callback: Callable) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	_vbox.add_child(row)

	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)

	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = default_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	row.add_child(slider)

	var value_label: Label = Label.new()
	value_label.text = "%d%%" % int(default_value * 100)
	value_label.custom_minimum_size = Vector2(40, 0)
	slider.value_changed.connect(func(v: float) -> void:
		value_label.text = "%d%%" % int(v * 100)
	)
	row.add_child(value_label)
