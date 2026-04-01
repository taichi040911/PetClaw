## PetBookScreen — PetBook UI の表示コンテナ
## PetBookUI（コードで動的構築）をホストし、戻るボタンを提供
class_name PetBookScreen
extends Control

signal back_requested

@onready var back_button: Button = $BackButton
@onready var container: Control = $PetBookContainer

var pet_book_ui: Node  # PetBookUI instance


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	# PetBookUI を動的に作成して追加
	# PetBookUI は _build_scene() で全UIを自動構築する
	await get_tree().process_frame

	if GameManager.instance and GameManager.instance.pet_book:
		pet_book_ui = PetBookUI.new()
		pet_book_ui.name = "PetBookUI"
		container.add_child(pet_book_ui)

		# PetBookUI の anchors を設定
		if pet_book_ui is Control:
			pet_book_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	else:
		# PetBook が未初期化の場合、プレースホルダー表示
		var placeholder: Label = Label.new()
		placeholder.text = "PetBook is loading..."
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.set_anchors_preset(Control.PRESET_CENTER)
		container.add_child(placeholder)


func _on_back_pressed() -> void:
	back_requested.emit()
