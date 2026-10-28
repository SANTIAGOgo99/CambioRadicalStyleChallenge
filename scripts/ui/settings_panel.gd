class_name AudioSettingsPanel
extends Control

signal closed

const BUS_LABELS := {"Master": "Volumen general", "Music": "Música", "Effects": "Efectos", "Voice": "Voces"}

var sliders: Dictionary = {}
var subtitles := CheckButton.new()
var save_error := Label.new()
var close_button := Button.new()
var entrance: Tween

@onready var rows: VBoxContainer = $Center/Panel/Margin/Rows


func _ready() -> void:
	var title := Label.new()
	title.text = "Ajustes"
	title.add_theme_font_size_override("font_size", 42)
	rows.add_child(title)
	for bus: String in BUS_LABELS:
		_add_volume_row(bus)
	subtitles.text = "Subtítulos"
	subtitles.toggled.connect(Settings.set_subtitles_enabled)
	rows.add_child(subtitles)
	save_error.text = "No se pudieron guardar los ajustes. Inténtalo de nuevo."
	save_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_error.modulate = Color(1.0, 0.65, 0.65)
	save_error.hide()
	rows.add_child(save_error)
	close_button.text = "Guardar y volver"
	close_button.pressed.connect(close)
	rows.add_child(close_button)
	var focus_controls: Array[Control] = []
	for bus: String in BUS_LABELS:
		focus_controls.append(sliders[bus])
	focus_controls.append(subtitles)
	focus_controls.append(close_button)
	for index in range(focus_controls.size()):
		var control := focus_controls[index]
		var next := focus_controls[(index + 1) % focus_controls.size()]
		var previous := focus_controls[(index - 1 + focus_controls.size()) % focus_controls.size()]
		control.focus_next = next.get_path()
		control.focus_previous = previous.get_path()
		control.focus_neighbor_top = previous.get_path()
		control.focus_neighbor_bottom = next.get_path()
		control.focus_neighbor_left = control.get_path()
		control.focus_neighbor_right = control.get_path()


func open() -> void:
	for bus: String in sliders:
		(sliders[bus] as HSlider).set_value_no_signal(Settings.volumes[bus] * 100.0)
	subtitles.set_pressed_no_signal(Settings.subtitles_enabled)
	save_error.hide()
	show()
	if entrance != null and entrance.is_valid():
		entrance.kill()
	modulate.a = 0.0
	entrance = create_tween()
	entrance.tween_property(self, "modulate:a", 1.0, 0.16)
	(sliders["Master"] as HSlider).grab_focus()


func close() -> void:
	if Settings.save_settings() != OK:
		save_error.show()
		return
	if entrance != null and entrance.is_valid():
		entrance.kill()
	hide()
	closed.emit()


func _add_volume_row(bus: String) -> void:
	var column := VBoxContainer.new()
	var heading := HBoxContainer.new()
	var label := Label.new()
	label.text = BUS_LABELS[bus]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var percentage := Label.new()
	percentage.custom_minimum_size.x = 84
	percentage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percentage.text = "%d %%" % roundi(Settings.volumes[bus] * 100.0)
	heading.add_child(label)
	heading.add_child(percentage)
	column.add_child(heading)
	var slider := HSlider.new()
	slider.custom_minimum_size.y = 38
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = Settings.volumes[bus] * 100.0
	slider.value_changed.connect(func(value: float) -> void:
		Settings.set_volume(bus, value / 100.0)
		percentage.text = "%d %%" % roundi(value)
	)
	column.add_child(slider)
	rows.add_child(column)
	sliders[bus] = slider
