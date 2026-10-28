extends Control

@onready var settings_panel: AudioSettingsPanel = $SettingsPanel
@onready var settings_button: Button = $SettingsButton


func _ready() -> void:
	settings_button.pressed.connect(_open_settings)
	settings_panel.closed.connect(_settings_closed)
	settings_button.grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if settings_panel.visible:
			settings_panel.close()
		else:
			_open_settings()
		get_viewport().set_input_as_handled()


func _open_settings() -> void:
	settings_button.disabled = true
	settings_panel.open()


func _settings_closed() -> void:
	settings_button.disabled = false
	settings_button.grab_focus()
