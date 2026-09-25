extends Control

## SettingsModal.gd - Interactive modal dialog for municipal settings.
## Manages Audio, Display (Window/Fullscreen/Resolution), Language, and Twitch Live Streaming.

signal modal_closed
signal twitch_overlay_toggle_requested

@onready var modal_panel: PanelContainer = %ModalPanel
@onready var backdrop: ColorRect = %Backdrop
@onready var title_label: Label = %TitleLabel
@onready var btn_header_close: Button = %BtnHeaderClose

# Tabs
@onready var btn_tab_audio: Button = %BtnTabAudio
@onready var btn_tab_display: Button = %BtnTabDisplay
@onready var btn_tab_language: Button = %BtnTabLanguage
@onready var btn_tab_twitch: Button = %BtnTabTwitch
@onready var content_audio: VBoxContainer = %ContentAudio
@onready var content_display: VBoxContainer = %ContentDisplay
@onready var content_language: VBoxContainer = %ContentLanguage
@onready var content_twitch: VBoxContainer = %ContentTwitch

# Audio controls
@onready var label_master_vol: Label = %LabelMasterVol
@onready var slider_master: HSlider = %SliderMaster
@onready var check_master_mute: CheckBox = %CheckMasterMute
@onready var label_sfx_vol: Label = %LabelSFXVol
@onready var slider_sfx: HSlider = %SliderSFX
@onready var check_sfx_mute: CheckBox = %CheckSFXMute
@onready var btn_test_sound: Button = %BtnTestSound

# Display controls
@onready var label_display_mode: Label = %LabelDisplayMode
@onready var option_window_mode: OptionButton = %OptionWindowMode
@onready var label_resolution: Label = %LabelResolution
@onready var option_resolution: OptionButton = %OptionResolution
@onready var check_vsync: CheckBox = %CheckVSync

# Language controls
@onready var label_lang_header: Label = %LabelLangHeader
@onready var btn_lang_tr: Button = %BtnLangTR
@onready var btn_lang_en: Button = %BtnLangEN
@onready var btn_lang_es: Button = %BtnLangES

# Twitch controls
@onready var label_twitch_title: Label = %LabelTwitchTitle
@onready var label_twitch_desc: Label = %LabelTwitchDesc
@onready var label_twitch_channel: Label = %LabelTwitchChannel
@onready var twitch_channel_input: LineEdit = %TwitchChannelInput
@onready var btn_twitch_connect: Button = %BtnTwitchConnect
@onready var twitch_status_label: Label = %TwitchStatusLabel
@onready var label_overlay_header: Label = %LabelOverlayHeader
@onready var btn_toggle_twitch_overlay: Button = %BtnToggleTwitchOverlay
@onready var overlay_status_label: Label = %OverlayStatusLabel

# Footer buttons
@onready var btn_reset_defaults: Button = %BtnResetDefaults
@onready var btn_save_close: Button = %BtnSaveClose

var is_open: bool = false
var _active_tab: int = 0  # 0: Audio, 1: Display, 2: Language, 3: Twitch
var _twitch_overlay_ref: Control = null


func _ready() -> void:
	visible = false
	_setup_signals()
	_populate_options()
	_update_locale_texts()
	_refresh_twitch_ui()
	LocalizationManager.locale_changed.connect(func(_l): _update_locale_texts())


func set_twitch_overlay_reference(overlay: Control) -> void:
	_twitch_overlay_ref = overlay
	_refresh_twitch_ui()


func _setup_signals() -> void:
	btn_header_close.pressed.connect(close)
	btn_save_close.pressed.connect(close)
	btn_reset_defaults.pressed.connect(_on_reset_defaults_pressed)

	# Tab buttons
	btn_tab_audio.pressed.connect(func(): _switch_tab(0))
	btn_tab_display.pressed.connect(func(): _switch_tab(1))
	btn_tab_language.pressed.connect(func(): _switch_tab(2))
	btn_tab_twitch.pressed.connect(func(): _switch_tab(3))

	# Audio controls
	slider_master.value_changed.connect(_on_master_slider_changed)
	check_master_mute.toggled.connect(_on_master_mute_toggled)
	slider_sfx.value_changed.connect(_on_sfx_slider_changed)
	check_sfx_mute.toggled.connect(_on_sfx_mute_toggled)
	btn_test_sound.pressed.connect(_on_test_sound_pressed)

	# Display controls
	option_window_mode.item_selected.connect(_on_window_mode_selected)
	option_resolution.item_selected.connect(_on_resolution_selected)
	check_vsync.toggled.connect(_on_vsync_toggled)

	# Language cards
	btn_lang_tr.pressed.connect(func(): _select_language("tr"))
	btn_lang_en.pressed.connect(func(): _select_language("en"))
	btn_lang_es.pressed.connect(func(): _select_language("es"))

	# Twitch controls
	btn_twitch_connect.pressed.connect(_on_twitch_connect_pressed)
	twitch_channel_input.text_submitted.connect(func(_t): _on_twitch_connect_pressed())
	btn_toggle_twitch_overlay.pressed.connect(_on_toggle_twitch_overlay_pressed)
	TwitchManager.connection_status_changed.connect(_on_twitch_connection_status_changed)


func _populate_options() -> void:
	option_resolution.clear()
	for res in SettingsManager.RESOLUTION_OPTIONS:
		option_resolution.add_item("%d x %d" % [res.x, res.y])


func _switch_tab(tab_idx: int) -> void:
	_active_tab = tab_idx
	content_audio.visible = (tab_idx == 0)
	content_display.visible = (tab_idx == 1)
	content_language.visible = (tab_idx == 2)
	content_twitch.visible = (tab_idx == 3)

	var active_color := Color(1.0, 0.88, 0.45)
	var inactive_color := Color(0.7, 0.75, 0.85)

	btn_tab_audio.modulate = active_color if tab_idx == 0 else inactive_color
	btn_tab_display.modulate = active_color if tab_idx == 1 else inactive_color
	btn_tab_language.modulate = active_color if tab_idx == 2 else inactive_color
	btn_tab_twitch.modulate = active_color if tab_idx == 3 else inactive_color


func open() -> void:
	is_open = true
	visible = true
	_sync_ui_from_settings()
	_refresh_twitch_ui()
	_switch_tab(_active_tab)
	_update_locale_texts()

	backdrop.modulate = Color(1, 1, 1, 0)
	modal_panel.scale = Vector2(0.92, 0.92)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(backdrop, "modulate:a", 1.0, 0.2)
	tween.tween_property(modal_panel, "scale", Vector2.ONE, 0.25).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not is_open:
		return
	is_open = false
	SettingsManager.save_settings()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(backdrop, "modulate:a", 0.0, 0.15)
	tween.tween_property(modal_panel, "scale", Vector2(0.95, 0.95), 0.15)
	await tween.finished
	visible = false
	modal_closed.emit()


func _sync_ui_from_settings() -> void:
	# Audio sync
	slider_master.value = int(SettingsManager.master_volume * 100.0)
	check_master_mute.button_pressed = SettingsManager.master_muted
	_update_volume_label(label_master_vol, "UI_MASTER_VOLUME", int(slider_master.value))

	slider_sfx.value = int(SettingsManager.sfx_volume * 100.0)
	check_sfx_mute.button_pressed = SettingsManager.sfx_muted
	_update_volume_label(label_sfx_vol, "UI_SFX_VOLUME", int(slider_sfx.value))

	# Display sync
	option_window_mode.select(SettingsManager.window_mode)
	_update_resolution_dropdown_state()

	for i in range(SettingsManager.RESOLUTION_OPTIONS.size()):
		if SettingsManager.RESOLUTION_OPTIONS[i] == SettingsManager.resolution:
			option_resolution.select(i)
			break

	check_vsync.button_pressed = SettingsManager.vsync

	# Language sync
	_update_lang_button_highlights(LocalizationManager.get_current_locale())


func _update_resolution_dropdown_state() -> void:
	var is_windowed := (SettingsManager.window_mode != SettingsManager.WindowMode.FULLSCREEN)
	option_resolution.disabled = not is_windowed


func _update_locale_texts() -> void:
	title_label.text = tr("UI_SETTINGS_TITLE")
	btn_tab_audio.text = "🔊 " + tr("UI_TAB_AUDIO")
	btn_tab_display.text = "🖥️ " + tr("UI_TAB_DISPLAY")
	btn_tab_language.text = "🌐 " + tr("UI_TAB_LANGUAGE")
	btn_tab_twitch.text = "📺 " + tr("UI_TAB_TWITCH")

	_update_volume_label(label_master_vol, "UI_MASTER_VOLUME", int(slider_master.value))
	_update_volume_label(label_sfx_vol, "UI_SFX_VOLUME", int(slider_sfx.value))
	check_master_mute.text = tr("UI_MUTE")
	check_sfx_mute.text = tr("UI_MUTE")
	btn_test_sound.text = tr("UI_TEST_AUDIO")

	label_display_mode.text = tr("UI_DISPLAY_MODE")
	option_window_mode.set_item_text(0, tr("UI_MODE_WINDOWED"))
	option_window_mode.set_item_text(1, tr("UI_MODE_FULLSCREEN"))
	option_window_mode.set_item_text(2, tr("UI_MODE_BORDERLESS"))

	label_resolution.text = tr("UI_RESOLUTION")
	check_vsync.text = tr("UI_VSYNC")

	label_lang_header.text = tr("UI_TAB_LANGUAGE")
	btn_reset_defaults.text = tr("UI_BTN_RESET_DEFAULTS")
	btn_save_close.text = tr("UI_BTN_SAVE_CLOSE")

	# Twitch texts
	label_twitch_title.text = "📺 " + tr("UI_TWITCH_TITLE")
	label_twitch_desc.text = tr("UI_TWITCH_DESC")
	label_twitch_channel.text = tr("UI_TWITCH_CHANNEL") + ":"
	twitch_channel_input.placeholder_text = tr("UI_TWITCH_CHANNEL_PLACEHOLDER")
	btn_toggle_twitch_overlay.text = "📺 " + tr("UI_TWITCH_OVERLAY_TOGGLE")

	_refresh_twitch_ui()


func _refresh_twitch_ui() -> void:
	if TwitchManager.is_connected_to_twitch:
		btn_twitch_connect.text = tr("UI_TWITCH_DISCONNECT")
		twitch_status_label.text = tr("UI_TWITCH_STATUS_CONNECTED").format({
			"channel": TwitchManager.active_channel
		})
		twitch_status_label.modulate = Color(0.4, 0.9, 0.5)
	else:
		btn_twitch_connect.text = tr("UI_TWITCH_CONNECT")
		twitch_status_label.text = tr("UI_TWITCH_STATUS_OFFLINE")
		twitch_status_label.modulate = Color(0.7, 0.7, 0.75)

	if _twitch_overlay_ref != null:
		var is_vis: bool = _twitch_overlay_ref.visible
		overlay_status_label.text = "Durum: " + ("Açık (Görünüyor)" if is_vis else "Gizli (Kapalı)")
		overlay_status_label.modulate = Color(0.4, 0.9, 0.5) if is_vis else Color(0.65, 0.7, 0.8)


func _update_volume_label(lbl: Label, key: String, val: int) -> void:
	lbl.text = tr(key).format({"val": val})


func _update_lang_button_highlights(current_loc: String) -> void:
	var active_color := Color(1.0, 0.9, 0.45)
	var inactive_color := Color(0.7, 0.75, 0.8)

	btn_lang_tr.modulate = active_color if current_loc == "tr" else inactive_color
	btn_lang_en.modulate = active_color if current_loc == "en" else inactive_color
	btn_lang_es.modulate = active_color if current_loc == "es" else inactive_color


func _on_master_slider_changed(val: float) -> void:
	SettingsManager.set_master_volume(val / 100.0)
	_update_volume_label(label_master_vol, "UI_MASTER_VOLUME", int(val))


func _on_master_mute_toggled(toggled: bool) -> void:
	SettingsManager.set_master_muted(toggled)


func _on_sfx_slider_changed(val: float) -> void:
	SettingsManager.set_sfx_volume(val / 100.0)
	_update_volume_label(label_sfx_vol, "UI_SFX_VOLUME", int(val))


func _on_sfx_mute_toggled(toggled: bool) -> void:
	SettingsManager.set_sfx_muted(toggled)


func _on_test_sound_pressed() -> void:
	AudioManager.play_phone_ring()


func _on_window_mode_selected(idx: int) -> void:
	SettingsManager.set_window_mode(idx)
	_update_resolution_dropdown_state()


func _on_resolution_selected(idx: int) -> void:
	if idx >= 0 and idx < SettingsManager.RESOLUTION_OPTIONS.size():
		SettingsManager.set_resolution(SettingsManager.RESOLUTION_OPTIONS[idx])


func _on_vsync_toggled(toggled: bool) -> void:
	SettingsManager.set_vsync(toggled)


func _select_language(loc: String) -> void:
	SettingsManager.set_locale(loc)
	_update_lang_button_highlights(loc)
	_update_locale_texts()


func _on_twitch_connect_pressed() -> void:
	if TwitchManager.is_connected_to_twitch:
		TwitchManager.disconnect_channel()
	else:
		var ch := twitch_channel_input.text.strip_edges()
		if not ch.is_empty():
			TwitchManager.connect_channel(ch)
	_refresh_twitch_ui()


func _on_twitch_connection_status_changed(_conn: bool, _ch: String) -> void:
	_refresh_twitch_ui()


func _on_toggle_twitch_overlay_pressed() -> void:
	twitch_overlay_toggle_requested.emit()
	if _twitch_overlay_ref != null:
		# Small delay to sync after toggle
		get_tree().create_timer(0.05).timeout.connect(_refresh_twitch_ui)


func _on_reset_defaults_pressed() -> void:
	SettingsManager.reset_to_defaults()
	_sync_ui_from_settings()
	_update_locale_texts()
	AudioManager.play_paper_slide()


func _unhandled_input(event: InputEvent) -> void:
	if is_open and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
