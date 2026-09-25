extends Control

## PauseMenu.gd - In-game pause menu dialog.
## Allows pausing, saving, loading, configuring settings, and navigation.

signal resume_requested
signal save_requested
signal load_requested
signal settings_requested
signal main_menu_requested
signal quit_requested
signal pause_menu_closed

enum ConfirmAction { NONE, MAIN_MENU, QUIT }

var is_open: bool = false
var current_confirm: ConfirmAction = ConfirmAction.NONE

@onready var backdrop: ColorRect = %Backdrop
@onready var menu_panel: PanelContainer = %MenuPanel
@onready var title_label: Label = %TitleLabel

@onready var btn_resume: Button = %BtnResume
@onready var btn_save: Button = %BtnSave
@onready var btn_load: Button = %BtnLoad
@onready var btn_settings: Button = %BtnSettings
@onready var btn_main_menu: Button = %BtnMainMenu
@onready var btn_quit: Button = %BtnQuit

# Confirmation overlay
@onready var confirm_overlay: Control = %ConfirmOverlay
@onready var confirm_panel: PanelContainer = %ConfirmPanel
@onready var confirm_title: Label = %ConfirmTitle
@onready var confirm_message: Label = %ConfirmMessage
@onready var btn_confirm_yes: Button = %BtnConfirmYes
@onready var btn_confirm_no: Button = %BtnConfirmNo


func _ready() -> void:
	visible = false
	confirm_overlay.visible = false
	_connect_signals()
	_update_locale_texts()
	LocalizationManager.locale_changed.connect(func(_l): _update_locale_texts())


func _connect_signals() -> void:
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	btn_load.pressed.connect(_on_load_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_main_menu.pressed.connect(_on_main_menu_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

	btn_confirm_yes.pressed.connect(_on_confirm_yes_pressed)
	btn_confirm_no.pressed.connect(_on_confirm_no_pressed)


func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	confirm_overlay.visible = false
	_update_locale_texts()

	backdrop.modulate = Color(1, 1, 1, 0)
	menu_panel.scale = Vector2(0.92, 0.92)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(backdrop, "modulate:a", 1.0, 0.2)
	tween.tween_property(menu_panel, "scale", Vector2.ONE, 0.22).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not is_open:
		return
	is_open = false
	_hide_confirm()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(backdrop, "modulate:a", 0.0, 0.15)
	tween.tween_property(menu_panel, "scale", Vector2(0.94, 0.94), 0.15)
	await tween.finished
	visible = false
	pause_menu_closed.emit()


func _on_resume_pressed() -> void:
	close()
	resume_requested.emit()


func _on_save_pressed() -> void:
	save_requested.emit()


func _on_load_pressed() -> void:
	load_requested.emit()


func _on_settings_pressed() -> void:
	settings_requested.emit()


func _on_main_menu_pressed() -> void:
	current_confirm = ConfirmAction.MAIN_MENU
	_show_confirm(
		tr("UI_CONFIRM_MAIN_MENU_TITLE"),
		tr("UI_CONFIRM_MAIN_MENU_MSG")
	)


func _on_quit_pressed() -> void:
	current_confirm = ConfirmAction.QUIT
	_show_confirm(
		tr("UI_CONFIRM_QUIT_TITLE"),
		tr("UI_CONFIRM_QUIT_MSG")
	)


func _on_confirm_yes_pressed() -> void:
	var action := current_confirm
	_hide_confirm()

	if action == ConfirmAction.MAIN_MENU:
		main_menu_requested.emit()
		close()
		var main_menu_path := "res://scenes/menu/MainMenu.tscn"
		if ResourceLoader.exists(main_menu_path):
			get_tree().change_scene_to_file(main_menu_path)
	elif action == ConfirmAction.QUIT:
		quit_requested.emit()
		get_tree().quit()


func _on_confirm_no_pressed() -> void:
	_hide_confirm()


func _show_confirm(title_text: String, msg_text: String) -> void:
	confirm_title.text = title_text
	confirm_message.text = msg_text
	btn_confirm_yes.text = tr("UI_CONFIRM_YES")
	btn_confirm_no.text = tr("UI_CONFIRM_NO")

	confirm_overlay.visible = true
	confirm_overlay.modulate = Color(1, 1, 1, 0)
	confirm_panel.scale = Vector2(0.9, 0.9)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(confirm_overlay, "modulate:a", 1.0, 0.15)
	tween.tween_property(confirm_panel, "scale", Vector2.ONE, 0.2).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)


func _hide_confirm() -> void:
	confirm_overlay.visible = false
	current_confirm = ConfirmAction.NONE


func _update_locale_texts() -> void:
	title_label.text = tr("UI_PAUSE_TITLE")
	btn_resume.text = tr("UI_PAUSE_RESUME")
	btn_save.text = tr("UI_PAUSE_SAVE")
	btn_load.text = tr("UI_PAUSE_LOAD")
	btn_settings.text = tr("UI_PAUSE_SETTINGS")
	btn_main_menu.text = tr("UI_PAUSE_MAIN_MENU")
	btn_quit.text = tr("UI_PAUSE_QUIT")


func _unhandled_input(event: InputEvent) -> void:
	if is_open and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if confirm_overlay.visible:
				_hide_confirm()
			else:
				close()
				resume_requested.emit()
			get_viewport().set_input_as_handled()
