extends Control

const Character = preload("res://scripts/game/character_view.gd")
const ToolButton = preload("res://scripts/game/tool_button.gd")
const ToolTarget = preload("res://scripts/game/tool_target.gd")
const INK := Color("193e41")
const MUTED := Color("617477")
const PAPER := Color("fffaf1")
const GOLD := Color("eebd61")
const CORAL := Color("bb6856")

var level: Dictionary
var dialogue: Dictionary
var phase := "intro"
var selected := -1
var cut_choice := -1
var style_choice := -1
var money := 500
var remaining := 300.0
var running := false
var working := false
var strokes := 0
var warned := false
var best_stars := 0
var coins := 0
var selected_service: Dictionary = {}
var active_line := ""
var targets: Array[Button] = []
var comparison: Control

var sofia_sheet: Texture2D
var variants: Texture2D
var alex_sheet: Texture2D
var sofia: SalonCharacter
var alex: SalonCharacter
var mentor: SalonCharacter
var stage: Control
var actors: Control
var right_rows: VBoxContainer
var phase_title: Label
var status: Label
var work_hint: Label
var tool: Button
var confirm_button: Button
var error_label: Label
var music := AudioStreamPlayer.new()
var effects := AudioStreamPlayer.new()


func _ready() -> void:
	level = JSON.parse_string(FileAccess.get_file_as_string("res://data/level_01.json"))
	dialogue = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	sofia_sheet = load("res://assets/characters/sofia_original.png") as Texture2D
	variants = load("res://assets/characters/sofia_variants.png") as Texture2D
	alex_sheet = load("res://assets/characters/alex_original.png") as Texture2D
	var progress := ConfigFile.new()
	if progress.load("user://progress.cfg") == OK:
		best_stars = clampi(int(progress.get_value("level_01", "stars", 0)), 0, 3)
		coins = maxi(0, int(progress.get_value("player", "coins", 0)))
	_build_screen()
	music.bus = &"Music"
	add_child(music)
	var loop := load("res://assets/audio/music/salon_loop.wav") as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_end = loop.data.size() / 2
	music.stream = loop
	music.volume_db = -10.0
	if AudioServer.get_driver_name() != "Dummy":
		music.play()
	effects.bus = &"Effects"
	add_child(effects)
	_restart.call_deferred()


func _process(delta: float) -> void:
	if not running or get_parent().get_node("SettingsPanel").visible:
		return
	remaining = maxf(0.0, remaining - delta)
	_update_status()
	if remaining <= 30.0 and not warned:
		warned = true
		_sfx("warning")
	if remaining <= 0.0:
		_result(false, "Se terminó el tiempo", "timeout")


func _exit_tree() -> void:
	music.stop()
	music.stream = null
	effects.stop()
	effects.stream = null


func _build_screen() -> void:
	var backdrop := TextureRect.new()
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = load("res://assets/backgrounds/salon_original.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var veil := ColorRect.new()
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.97, 0.94, 0.86, 0.18)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 40
	margin.offset_top = 24
	margin.offset_right = -40
	margin.offset_bottom = -200
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 24)
	margin.add_child(layout)
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", _box(PAPER, 18))
	layout.add_child(header_panel)
	var header_margin := _margin(header_panel, 24)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 30)
	header_margin.add_child(header)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	brand.add_child(_label("CAMBIO RADICAL", 34))
	brand.add_child(_label("S T Y L E   C H A L L E N G E", 18, MUTED))
	status = _label("", 25)
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(status)
	var space := Control.new()
	space.custom_minimum_size.x = 240
	header.add_child(space)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 24)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)
	var left := _card(body, 380)
	left.add_theme_constant_override("separation", 10)
	left.add_child(_label("FICHA DE CLIENTA", 18, MUTED))
	left.add_child(_label("Conoce a Sofía", 34))
	left.add_child(_label("Entrevista de trabajo", 25, CORAL))
	left.add_child(HSeparator.new())
	left.add_child(_label("SU PETICIÓN", 20, MUTED))
	left.add_child(_label("Profesional y natural.", 24))
	left.add_child(_label("• Conservar el cabello largo\n• Mantener un color natural\n• Verse profesional\n• No pasar de $500", 22))
	left.add_child(HSeparator.new())
	mentor = Character.new()
	mentor.custom_minimum_size = Vector2(240, 110)
	left.add_child(mentor)
	mentor.setup(load("res://assets/characters/ezequiel_original.png") as Texture2D, 2, 1)
	left.add_child(_label("Ezequiel · tu mentor", 22, MUTED))
	var remind := _button("Escuchar la petición", func() -> void: _say("intro"), true)
	remind.custom_minimum_size.y = 52
	remind.add_theme_font_size_override("font_size", 21)
	left.add_child(remind)
	stage = Control.new()
	stage.custom_minimum_size.x = 620
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(stage)
	phase_title = _label("", 30)
	phase_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage.add_child(phase_title)
	phase_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	phase_title.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.9))
	phase_title.add_theme_constant_override("shadow_offset_x", 1)
	phase_title.add_theme_constant_override("shadow_offset_y", 2)
	actors = Control.new()
	stage.add_child(actors)
	actors.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	actors.offset_top = 52
	actors.offset_bottom = -78
	actors.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alex = Character.new()
	actors.add_child(alex)
	alex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	alex.anchor_right = 0.48
	alex.setup(alex_sheet)
	var alex_cell := Vector2(alex_sheet.get_size()) / Vector2(3, 2)
	# Wider gestures cross cell boundaries; use clean atlas regions, without editing the image.
	alex.frame_regions = {
		1: Rect2(Vector2(alex_cell.x * 1.05, 0), Vector2(alex_cell.x * 1.08, alex_cell.y)),
		2: Rect2(Vector2(alex_cell.x * 2.14, 0), Vector2(alex_cell.x * 0.86, alex_cell.y)),
		4: Rect2(Vector2(alex_cell.x * 1.05, alex_cell.y), Vector2(alex_cell.x * 1.08, alex_cell.y)),
		5: Rect2(Vector2(alex_cell.x * 2.14, alex_cell.y), Vector2(alex_cell.x * 0.86, alex_cell.y))
	}
	sofia = Character.new()
	actors.add_child(sofia)
	sofia.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sofia.anchor_left = 0.36
	sofia.setup(sofia_sheet)
	sofia.resized.connect(_position_targets)
	tool = ToolButton.new()
	stage.add_child(tool)
	tool.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	tool.offset_top = -64
	tool.add_theme_font_size_override("font_size", 24)
	tool.hide()
	work_hint = _label("", 22)
	stage.add_child(work_hint)
	work_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	work_hint.offset_top = -68
	work_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_rows = _card(body, 440)


func _restart() -> void:
	var subtitles := get_parent().get_node("Subtitles")
	if not subtitles.line_finished.is_connected(_dialogue_finished):
		subtitles.line_finished.connect(_dialogue_finished)
	phase = "intro"
	selected = -1
	cut_choice = -1
	style_choice = -1
	money = int(level.budget)
	remaining = float(level.seconds)
	running = false
	working = false
	warned = false
	_clear_targets()
	if is_instance_valid(comparison):
		comparison.queue_free()
		comparison = null
	alex.show()
	sofia.show()
	alex.show_pose(0)
	sofia.show_pose(0)
	phase_title.text = "Una nueva primera impresión"
	work_hint.text = "Alex y Sofía · salón de Ezequiel"
	tool.hide()
	_update_status()
	_clear(right_rows)
	right_rows.add_child(_label("Tu primer reto", 34))
	right_rows.add_child(_label("Escucha. Imagina. Transforma.", 25, CORAL))
	right_rows.add_child(_label("Sofía quiere causar una buena impresión en su entrevista. Tu reto es encontrar un look que la represente.", 27))
	right_rows.add_child(_label("Tienes 5 minutos y $500. Las vistas previas son gratuitas; confirma cada servicio antes de aplicarlo.", 25, MUTED))
	right_rows.add_child(_label("Necesitas al menos 2 de 3 estrellas. Hay más de una combinación correcta.", 24, MUTED))
	var start := _button("Comenzar reto  →", _begin)
	right_rows.add_child(start)
	_say("intro")


func _begin() -> void:
	_sfx("click")
	running = true
	phase = "cut"
	_show_choices()
	_say("cut")


func _show_choices() -> void:
	selected = -1
	working = false
	tool.hide()
	work_hint.text = "Prueba una opción antes de confirmarla"
	phase_title.text = "01 · Corte y color" if phase == "cut" else "02 · Peinado y estilo"
	_clear(right_rows)
	right_rows.add_child(_label("Corte y color" if phase == "cut" else "Peinado y estilo", 32))
	right_rows.add_child(_label("Vista previa gratuita. Elige pensando en lo que pidió Sofía.", 22, MUTED))
	var options: Array = level.cut_options if phase == "cut" else level.style_options
	for index in range(options.size()):
		var option: Dictionary = options[index]
		var callback := _select_option.bind(index)
		var button := _button("%s\n%s\n$%d   ·   %d s" % [option.name, option.detail, option.price, option.seconds], callback, true)
		button.name = "Option%d" % index
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 22)
		button.custom_minimum_size.y = 98
		button.tooltip_text = "%s — %s. $%d, %d segundos." % [option.name, option.detail, option.price, option.seconds]
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		right_rows.add_child(button)
	error_label = _label("", 21, CORAL)
	error_label.hide()
	right_rows.add_child(error_label)
	confirm_button = _button("Aplicar cambio", _start_service)
	confirm_button.disabled = true
	right_rows.add_child(confirm_button)
	alex.show_pose(0)
	_update_client()


func _select_option(index: int) -> void:
	if working:
		return
	selected = index
	_sfx("click")
	for option_index in range(3):
		var option := right_rows.get_node("Option%d" % option_index) as Button
		var style := option.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		style.bg_color = GOLD if index == option_index else Color("f0eee6")
		option.add_theme_stylebox_override("normal", style)
	confirm_button.disabled = false
	error_label.hide()
	if phase == "style" and index == 2 and cut_choice == 2:
		confirm_button.disabled = true
		error_label.text = "Un corte corto no permite este recogido."
		error_label.show()
	_update_client(true)


func _update_client(preview: bool = false) -> void:
	var cut := selected if preview and phase == "cut" else cut_choice
	var style := selected if preview and phase == "style" else style_choice
	if cut < 0:
		sofia.show_pose(0)
	elif style < 0:
		if cut == 2:
			sofia.show_pose(3)
		else:
			sofia.show_pose(cut, variants)
	elif style == 2:
		sofia.show_pose(4, variants)
	elif cut == 2:
		sofia.show_pose(5, variants)
	elif cut == 0:
		sofia.show_pose(1 if style == 0 else 2, sofia_sheet if style == 0 else variants)
	else:
		sofia.show_pose(3 if style == 0 else 2, variants if style == 0 else sofia_sheet)


func _start_service() -> void:
	if selected < 0 or working:
		return
	var options: Array = level.cut_options if phase == "cut" else level.style_options
	selected_service = options[selected]
	if money < int(selected_service.price):
		error_label.text = "No alcanza el presupuesto para este servicio."
		error_label.show()
		return
	if remaining <= float(selected_service.seconds):
		error_label.text = "No queda tiempo suficiente para este servicio."
		error_label.show()
		return
	money -= int(selected_service.price)
	remaining -= float(selected_service.seconds)
	working = true
	strokes = 0
	_update_status()
	_clear(right_rows)
	right_rows.add_child(_label("En tus manos", 34))
	right_rows.add_child(_label("Arrastra la herramienta a las zonas 1, 2 y 3 del cabello, en ese orden.", 29))
	right_rows.add_child(_label("Con teclado: usa Tab para llegar a la zona iluminada y pulsa Espacio o Enter.", 24, MUTED))
	right_rows.add_child(_label("Servicio confirmado\n%s\n$%d · %d segundos" % [selected_service.name, selected_service.price, selected_service.seconds], 25))
	tool.text = "ARRASTRA · Tijeras y brocha" if phase == "cut" else "ARRASTRA · Secadora y cepillo"
	tool.tool_id = phase
	var tool_sheet := load("res://assets/ui/salon_tools.png") as Texture2D
	var tool_part := AtlasTexture.new()
	tool_part.atlas = tool_sheet
	var tool_cell := Vector2(tool_sheet.get_size()) / Vector2(3, 1)
	var tool_index := (1 if selected == 1 else 0) if phase == "cut" else 2
	tool_part.region = Rect2(Vector2(tool_index * tool_cell.x, 0), tool_cell)
	tool.icon = tool_part
	tool.expand_icon = true
	tool.add_theme_constant_override("icon_max_width", 64)
	for state: String in ["normal", "hover", "pressed"]:
		var tool_style := tool.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		tool_style.content_margin_top = 4
		tool_style.content_margin_bottom = 4
		tool.add_theme_stylebox_override(state, tool_style)
	tool.mouse_default_cursor_shape = Control.CURSOR_DRAG
	tool.show()
	work_hint.text = ""
	alex.show_pose((2 if selected != 1 else 3) if phase == "cut" else 4)
	for index in range(3):
		var target := ToolTarget.new()
		target.tool_id = phase
		target.text = str(index + 1)
		target.tooltip_text = "Aplicar herramienta · zona %d" % (index + 1)
		target.add_theme_stylebox_override("normal", _box(GOLD, 32))
		target.add_theme_color_override("font_color", INK)
		actors.add_child(target)
		target.size = Vector2(64, 64)
		target.disabled = index != 0
		target.pressed.connect(_finish_target.bind(index))
		targets.append(target)
	_position_targets()
	targets[0].grab_focus()


func _position_targets() -> void:
	if targets.is_empty() or sofia.texture == null:
		return
	var image_size := Vector2(sofia.texture.get_size())
	var displayed := image_size * minf(sofia.size.x / image_size.x, sofia.size.y / image_size.y)
	var origin := sofia.position + (sofia.size - displayed) / 2.0
	var short_hair := (phase == "cut" and selected == 2) or cut_choice == 2
	var points := [Vector2(0.25, 0.17), Vector2(0.68, 0.22), Vector2(0.40, 0.25 if short_hair else 0.39)]
	for index in range(targets.size()):
		targets[index].position = origin + displayed * points[index] - Vector2(32, 32)


func _finish_target(index: int) -> void:
	if not working or index != strokes:
		return
	var target := targets[index]
	target.text = "OK"
	target.disabled = true
	strokes += 1
	_sfx("scissors" if phase == "cut" else "dryer")
	sofia.react()
	var action := create_tween()
	action.tween_property(alex, "rotation", -0.025, 0.08)
	action.tween_property(alex, "rotation", 0.025, 0.12)
	action.tween_property(alex, "rotation", 0.0, 0.08)
	if strokes < 3:
		targets[strokes].disabled = false
		targets[strokes].grab_focus()
		return
	working = false
	_clear_targets()
	tool.hide()
	if phase == "cut":
		cut_choice = selected
		phase = "style"
		_show_choices()
		_say("style")
	else:
		style_choice = selected
		phase = "review"
		_show_review()


func _show_review() -> void:
	_update_client()
	alex.show_pose(1)
	phase_title.text = "03 · Revisión final"
	work_hint.text = "¿El cambio representa lo que Sofía pidió?"
	_clear(right_rows)
	right_rows.add_child(_label("Antes de terminar", 33))
	right_rows.add_child(_label("Revisa las condiciones y entrega el look cuando estés listo.", 26, MUTED))
	right_rows.add_child(_label("Corte y color\n%s\n%s" % [level.cut_options[cut_choice].name, level.cut_options[cut_choice].detail], 25))
	right_rows.add_child(_label("Peinado y estilo\n%s" % level.style_options[style_choice].name, 25))
	right_rows.add_child(_button("Finalizar look  →", _evaluate))
	right_rows.add_child(_button("Repetir peinado", func() -> void:
		phase = "style"
		_show_choices()
	, true))
	_say("review")


func _evaluate() -> void:
	var valid := cut_choice >= 0 and cut_choice != 2 and style_choice >= 0 and style_choice != 2
	_result(valid, "¡Reto superado!" if valid else "Volvamos a intentarlo", "success" if valid else "failure")


func _result(passed: bool, heading: String, line: String) -> void:
	if phase == "result":
		return
	phase = "result"
	running = false
	working = false
	_clear_targets()
	tool.hide()
	var stars := (3 if money >= 250 and remaining >= 120 else 2) if passed else 0
	var reward := maxi(0, stars - best_stars) * 50
	if passed and stars > best_stars:
		best_stars = stars
		coins += reward
		var progress := ConfigFile.new()
		progress.load("user://progress.cfg")
		progress.set_value("level_01", "stars", best_stars)
		progress.set_value("player", "coins", coins)
		progress.set_value("player", "unlocked_level", 2)
		if progress.save("user://progress.cfg") != OK:
			get_parent().get_node("Subtitles").show_line("No se pudo guardar el progreso. Revisa el espacio disponible.")
	_clear(right_rows)
	right_rows.add_child(_label(heading, 34, INK if passed else CORAL))
	right_rows.add_child(_label("★".repeat(stars) + "☆".repeat(3 - stars), 54, Color("c6902c")))
	right_rows.add_child(_label("Natural, largo y profesional. ¡Escuchaste a Sofía!" if passed else ("Se acabó el tiempo antes de entregar el look." if line == "timeout" else "El look no respeta el largo, el color natural o la presentación profesional."), 27))
	right_rows.add_child(_label("Presupuesto restante: $%d\nTiempo restante: %s" % [money, _clock()], 25, MUTED))
	if passed:
		right_rows.add_child(_label("+%d monedas\nMejor resultado: %d/3 estrellas" % [reward, best_stars], 25))
		right_rows.add_child(_label("Las monedas se otorgan al mejorar tu récord.", 21, MUTED))
	right_rows.add_child(_button("Volver a jugar" if passed else "Reintentar", _restart))
	alex.show_pose(5 if passed else 0)
	comparison = HBoxContainer.new()
	actors.add_child(comparison)
	comparison.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	comparison.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in range(2):
		var person := Character.new()
		person.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		comparison.add_child(person)
		person.setup(sofia_sheet)
		if index == 1:
			person.texture = sofia.texture
	comparison.hide()
	var result_view_id := comparison.get_instance_id()
	var reveal := create_tween()
	reveal.tween_interval(0.7)
	reveal.tween_callback(func() -> void:
		var result_view := instance_from_id(result_view_id) as Control
		if phase == "result" and is_instance_valid(result_view) and comparison == result_view:
			alex.hide()
			sofia.hide()
			comparison.show()
	)
	phase_title.text = "ANTES                    DESPUÉS"
	work_hint.text = "Primera impresión · Sofía"
	_sfx("success" if passed else "warning")
	_say(line)


func _update_status() -> void:
	status.text = "%s   ·   $%d\nNIVEL 01  /  PRIMERA IMPRESIÓN" % [_clock(), money]
	status.add_theme_color_override("font_color", CORAL if remaining < 30 else INK)


func _clock() -> String:
	var seconds := ceili(remaining)
	return "%02d:%02d" % [floori(float(seconds) / 60.0), seconds % 60]


func _say(id: String) -> void:
	active_line = id
	var entry: Dictionary = dialogue[id]
	var voice_path := "res://assets/audio/voice/%s.wav" % id
	var voice: AudioStream = load(voice_path) if ResourceLoader.exists(voice_path) else null
	get_parent().get_node("Subtitles").show_line(entry.text, entry.speaker, voice, maxf(4.0, entry.text.length() / 18.0))
	mentor.show_pose(1 if entry.speaker == "Ezequiel" else 0)


func _dialogue_finished() -> void:
	mentor.show_pose(0)
	if phase == "intro" and active_line == "intro":
		_say("guide")


func _sfx(id: String) -> void:
	if AudioServer.get_driver_name() == "Dummy":
		return
	effects.stream = load("res://assets/audio/effects/%s.wav" % id)
	effects.play()


func _clear_targets() -> void:
	for target in targets:
		target.queue_free()
	targets.clear()


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _box(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	return box


func _margin(parent: Node, amount: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", amount)
	margin.add_theme_constant_override("margin_top", amount)
	margin.add_theme_constant_override("margin_right", amount)
	margin.add_theme_constant_override("margin_bottom", amount)
	parent.add_child(margin)
	return margin


func _card(parent: Node, width: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	panel.add_theme_stylebox_override("panel", _box(Color(1.0, 0.98, 0.94, 0.97), 20))
	parent.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 14)
	_margin(panel, 26).add_child(rows)
	return rows


func _label(text: String, font_size: int = 26, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _button(text: String, callback: Callable, secondary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size.y = 60
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	var normal := _box(Color("f0eee6") if secondary else GOLD, 12)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("f4cf89")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("d4aa5c")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.pressed.connect(callback)
	return button
