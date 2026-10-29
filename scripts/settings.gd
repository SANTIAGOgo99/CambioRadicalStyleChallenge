extends Node

signal subtitles_changed(enabled: bool)

const SAVE_PATH := "user://settings.cfg"
const DEFAULT_VOLUMES := {"Master": 1.0, "Music": 0.8, "Effects": 1.0, "Voice": 1.0}

var volumes: Dictionary = DEFAULT_VOLUMES.duplicate()
var subtitles_enabled := true
var fullscreen := false


func _ready() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error == OK:
		for bus: String in DEFAULT_VOLUMES:
			var stored: Variant = config.get_value("audio", bus, DEFAULT_VOLUMES[bus])
			if (stored is float or stored is int) and is_finite(float(stored)):
				volumes[bus] = clampf(float(stored), 0.0, 1.0)
		var stored_subtitles: Variant = config.get_value("accessibility", "subtitles", true)
		if stored_subtitles is bool:
			subtitles_enabled = stored_subtitles
		fullscreen = bool(config.get_value("display", "fullscreen", false))
	elif error != ERR_FILE_NOT_FOUND:
		push_warning("No se pudieron cargar los ajustes; se usarán los valores iniciales.")
	for bus: String in volumes:
		_apply_volume(bus)
	if fullscreen:
		set_fullscreen(true)


func set_volume(bus: String, value: float) -> void:
	if not volumes.has(bus) or not is_finite(value):
		return
	volumes[bus] = clampf(value, 0.0, 1.0)
	_apply_volume(bus)


func set_subtitles_enabled(enabled: bool) -> void:
	subtitles_enabled = enabled
	subtitles_changed.emit(enabled)


func save_settings() -> Error:
	var config := ConfigFile.new()
	for bus: String in volumes:
		config.set_value("audio", bus, volumes[bus])
	config.set_value("accessibility", "subtitles", subtitles_enabled)
	config.set_value("display", "fullscreen", fullscreen)
	return config.save(SAVE_PATH)


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)


func _apply_volume(bus: String) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index >= 0:
		var volume: float = volumes[bus]
		AudioServer.set_bus_volume_linear(index, maxf(volume, 0.0001))
		AudioServer.set_bus_mute(index, is_zero_approx(volume))
