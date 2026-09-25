extends Node

## SettingsManager.gd - Central manager for user preferences & configuration.
## Manages Audio (Master/SFX volume, mute), Display (Window/Fullscreen, resolution, VSync),
## and Localization persistence across game sessions via user://settings.cfg.

signal settings_applied
signal volume_changed(bus_name: String, volume: float, muted: bool)
signal display_changed(mode: int, resolution: Vector2i, vsync: bool)

const CONFIG_PATH: String = "user://settings.cfg"

enum WindowMode {
	WINDOWED = 0,
	FULLSCREEN = 1,
	BORDERLESS = 2
}

const RESOLUTION_OPTIONS: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720)
]

# Audio settings (0.0 to 1.0 linear)
var master_volume: float = 0.8
var sfx_volume: float = 0.8
var master_muted: bool = false
var sfx_muted: bool = false

# Display settings
var window_mode: int = WindowMode.WINDOWED
var resolution: Vector2i = Vector2i(1920, 1080)
var vsync: bool = true

# Locale
var current_locale: String = "tr"


func _ready() -> void:
	_ensure_audio_buses()
	load_settings()
	apply_all_settings()


func _ensure_audio_buses() -> void:
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx == -1:
		AudioServer.add_bus()
		sfx_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")


## Sets linear master volume (0.0 to 1.0)
func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)
	_apply_bus_volume("Master", master_volume, master_muted)
	volume_changed.emit("Master", master_volume, master_muted)


## Sets master mute state
func set_master_muted(muted: bool) -> void:
	master_muted = muted
	_apply_bus_volume("Master", master_volume, master_muted)
	volume_changed.emit("Master", master_volume, master_muted)


## Sets linear SFX volume (0.0 to 1.0)
func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	_apply_bus_volume("SFX", sfx_volume, sfx_muted)
	volume_changed.emit("SFX", sfx_volume, sfx_muted)


## Sets SFX mute state
func set_sfx_muted(muted: bool) -> void:
	sfx_muted = muted
	_apply_bus_volume("SFX", sfx_volume, sfx_muted)
	volume_changed.emit("SFX", sfx_volume, sfx_muted)


func _apply_bus_volume(bus_name: String, vol: float, muted: bool) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return

	if muted or vol <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		var db_val := linear_to_db(vol)
		AudioServer.set_bus_volume_db(bus_idx, db_val)


## Sets window mode (0: Windowed, 1: Fullscreen, 2: Borderless)
func set_window_mode(mode: int) -> void:
	window_mode = clampi(mode, 0, 2)
	_apply_display_settings()
	display_changed.emit(window_mode, resolution, vsync)


## Sets window resolution
func set_resolution(res: Vector2i) -> void:
	resolution = res
	_apply_display_settings()
	display_changed.emit(window_mode, resolution, vsync)


## Toggles VSync
func set_vsync(enabled: bool) -> void:
	vsync = enabled
	_apply_display_settings()
	display_changed.emit(window_mode, resolution, vsync)


## Changes language and persists it
func set_locale(loc: String) -> void:
	current_locale = loc
	LocalizationManager.set_locale(loc)


func _apply_display_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return

	match window_mode:
		WindowMode.FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		WindowMode.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			_apply_resolution_and_center()
		WindowMode.WINDOWED:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			_apply_resolution_and_center()

	var vsync_mode: DisplayServer.VSyncMode = (
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)
	DisplayServer.window_set_vsync_mode(vsync_mode)


func _apply_resolution_and_center() -> void:
	if DisplayServer.get_name() == "headless":
		return

	DisplayServer.window_set_size(resolution)
	var screen_idx := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen_idx)
	if screen_size.x > resolution.x and screen_size.y > resolution.y:
		var target_pos := Vector2i(
			(screen_size.x - resolution.x) / 2,
			(screen_size.y - resolution.y) / 2
		)
		DisplayServer.window_set_position(target_pos)


## Applies all settings globally
func apply_all_settings() -> void:
	_apply_bus_volume("Master", master_volume, master_muted)
	_apply_bus_volume("SFX", sfx_volume, sfx_muted)
	_apply_display_settings()
	if not current_locale.is_empty():
		LocalizationManager.set_locale(current_locale)
	settings_applied.emit()


## Saves preferences to user://settings.cfg
func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "master_muted", master_muted)
	config.set_value("audio", "sfx_muted", sfx_muted)

	config.set_value("display", "window_mode", window_mode)
	config.set_value("display", "resolution_x", resolution.x)
	config.set_value("display", "resolution_y", resolution.y)
	config.set_value("display", "vsync", vsync)

	config.set_value("localization", "locale", current_locale)
	config.save(CONFIG_PATH)


## Loads preferences from user://settings.cfg
func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)
	if err != OK:
		# Use default locale matching LocalizationManager
		current_locale = LocalizationManager.get_current_locale()
		return

	master_volume = config.get_value("audio", "master_volume", 0.8)
	sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
	master_muted = config.get_value("audio", "master_muted", false)
	sfx_muted = config.get_value("audio", "sfx_muted", false)

	window_mode = config.get_value("display", "window_mode", WindowMode.WINDOWED)
	var res_x: int = config.get_value("display", "resolution_x", 1920)
	var res_y: int = config.get_value("display", "resolution_y", 1080)
	resolution = Vector2i(res_x, res_y)
	vsync = config.get_value("display", "vsync", true)

	current_locale = config.get_value("localization", "locale", "tr")


## Resets all preferences to factory defaults
func reset_to_defaults() -> void:
	master_volume = 0.8
	sfx_volume = 0.8
	master_muted = false
	sfx_muted = false
	window_mode = WindowMode.WINDOWED
	resolution = Vector2i(1920, 1080)
	vsync = true
	current_locale = "tr"
	apply_all_settings()
	save_settings()
