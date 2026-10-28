extends PanelContainer

signal line_finished

var active := false

@onready var text_label: Label = $Margin/Text
@onready var voice: AudioStreamPlayer = $Voice
@onready var timer: Timer = $Timer


func _ready() -> void:
	Settings.subtitles_changed.connect(_update_visibility)
	voice.finished.connect(_finish)
	timer.timeout.connect(_finish)


func show_line(text: String, speaker: String = "", audio: AudioStream = null, duration: float = 4.0) -> void:
	clear()
	text_label.text = text if speaker.is_empty() else "%s: %s" % [speaker, text]
	active = true
	_update_visibility(Settings.subtitles_enabled)
	if audio != null:
		voice.stream = audio
		voice.play()
	else:
		timer.start(maxf(duration, 0.1))


func clear() -> void:
	voice.stop()
	timer.stop()
	active = false
	hide()


func _update_visibility(enabled: bool) -> void:
	visible = active and enabled and not text_label.text.is_empty()


func _finish() -> void:
	clear()
	line_finished.emit()
