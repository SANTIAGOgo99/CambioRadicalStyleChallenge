extends PanelContainer

signal line_finished
signal line_started(speaker: String)

var active := false
var speaker_name := ""

@onready var text_label: Label = $Margin/Text
@onready var voice: AudioStreamPlayer = $Voice
@onready var timer: Timer = $Timer


func _ready() -> void:
	add_to_group("Subtitles")
	Settings.subtitles_changed.connect(_update_visibility)
	voice.finished.connect(_finish)
	timer.timeout.connect(_finish)


func show_line(text: String, speaker: String = "", audio: AudioStream = null, duration: float = 4.0) -> void:
	clear()
	speaker_name = speaker
	text_label.text = text if speaker.is_empty() else "%s: %s" % [speaker, text]
	active = true
	line_started.emit(speaker)
	_update_visibility(Settings.subtitles_enabled)
	if audio != null and AudioServer.get_driver_name() != "Dummy":
		voice.stream = audio
		voice.play()
	else:
		timer.start(maxf(audio.get_length() if audio != null else duration, 0.1))


func clear() -> void:
	voice.stop()
	voice.stream_paused = false
	timer.paused = false
	timer.stop()
	active = false
	speaker_name = ""
	hide()


func set_paused(value: bool) -> void:
	voice.stream_paused = value
	timer.paused = value


func _exit_tree() -> void:
	voice.stop()
	voice.stream = null
	timer.stop()


func _update_visibility(enabled: bool) -> void:
	visible = active and enabled and not text_label.text.is_empty()


func _finish() -> void:
	clear()
	line_finished.emit()
