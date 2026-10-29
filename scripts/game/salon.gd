extends Control

signal request_next
signal request_menu

const Character = preload("res://scripts/game/character_view.gd")
const ToolButton = preload("res://scripts/game/tool_button.gd")
const ToolTarget = preload("res://scripts/game/tool_target.gd")
const INK := Color("193e41")
const MUTED := Color("617477")
const PAPER := Color("fffaf1")
const GOLD := Color("eebd61")
const CORAL := Color("bb6856")

var level: Dictionary
var level_index := 0
var resume_data: Dictionary = {}
var app: Control
var paused := false
var save_in := 5.0
var coupon_armed := false
var trend_armed := false
var trend_used := false
var bad_accessory: Control
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
	level = JSON.parse_string(FileAccess.get_file_as_string("res://data/level_%02d.json" % (level_index + 1)))
	for key: String in ["good_cut", "good_style", "short_cut"]:
		level[key] = (level[key] as Array).map(func(value: Variant) -> int: return int(value))
	dialogue = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	sofia_sheet = load("res://assets/characters/%s_original.png" % level.asset) as Texture2D
	variants = load("res://assets/characters/%s_variants.png" % level.asset) as Texture2D
	alex_sheet = load("res://assets/characters/alex_original.png") as Texture2D
	best_stars = int(Campaign.state.stars[level_index])
	coins = int(Campaign.state.coins)
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
	if not resume_data.is_empty():
		_restore.call_deferred()
	else:
		_restart.call_deferred()


func _process(delta: float) -> void:
	var subtitles = _subs()
	var speaking: String = subtitles.speaker_name if subtitles.active and not paused else ""
	sofia.set_talking(speaking == level.client)
	mentor.set_talking(speaking == "Ezequiel")
	alex.set_talking(speaking == "Alex")
	if is_instance_valid(comparison) and comparison.visible:
		var people := comparison.get_children()
		for index in range(people.size()):
			if people[index] is SalonCharacter:
				people[index].set_talking(index == 1 and speaking == level.client)
	music.volume_db = move_toward(music.volume_db, -21.0 if subtitles.active else -10.0, delta * 25.0)
	if not running or paused:
		return
	save_in -= delta
	if save_in <= 0.0:
		save_in = 5.0
		checkpoint()
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
	left.add_child(_label("Conoce a %s" % level.client, 34))
	left.add_child(_label(level.event, 25, CORAL))
	left.add_child(HSeparator.new())
	left.add_child(_label(level.request, 23))
	left.add_child(_label("• " + "\n• ".join(level.conditions), 21))
	left.add_child(HSeparator.new())
	mentor = Character.new()
	mentor.custom_minimum_size = Vector2(280, 180)
	left.add_child(mentor)
	mentor.portrait_mode = true
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
	var subtitles = _subs()
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
	paused = false
	coupon_armed = false
	trend_armed = false
	trend_used = false
	_clear_targets()
	if is_instance_valid(comparison):
		comparison.queue_free()
		comparison = null
	alex.show()
	sofia.show()
	alex.show_pose(0)
	sofia.show_pose(0)
	phase_title.text = level.title
	work_hint.text = "Alex y %s · salón de Ezequiel" % level.client
	tool.hide()
	_update_status()
	_clear(right_rows)
	right_rows.add_child(_label("Reto %d · %s" % [level_index + 1, level.client], 34))
	right_rows.add_child(_label("Escucha. Imagina. Transforma.", 25, CORAL))
	right_rows.add_child(_label(level.request, 27))
	right_rows.add_child(_label("Tienes %s y $%d. Prueba las opciones gratis y confirma cada servicio antes de aplicarlo." % [_clock(), money], 25, MUTED))
	right_rows.add_child(_label("Necesitas al menos 2 de 3 estrellas. Hay más de una combinación correcta.", 24, MUTED))
	var start := _button("Comenzar reto  →", _begin)
	right_rows.add_child(start)
	_say("intro")
	checkpoint()


func _begin() -> void:
	_sfx("click")
	running = true
	phase = "cut"
	_show_choices()
	_say("cut")
	checkpoint()


func _show_choices() -> void:
	selected = -1
	working = false
	tool.hide()
	work_hint.text = "Prueba una opción antes de confirmarla"
	phase_title.text = "01 · Corte y color" if phase == "cut" else "02 · Peinado y estilo"
	_clear(right_rows)
	right_rows.add_child(_label("Corte y color" if phase == "cut" else "Peinado y estilo", 32))
	right_rows.add_child(_label("Vista previa gratuita. " + ("Kit profesional: servicios 15 % más rápidos." if Campaign.completed(0) else "Escucha lo que pidió la clienta."), 21, MUTED))
	var options: Array = level.cut_options if phase == "cut" else level.style_options
	for index in range(options.size()):
		var option: Dictionary = options[index]
		var callback := _select_option.bind(index)
		var button := _button("%s\n%s\n$%d   ·   %d s" % [option.name, option.detail, option.price, option.seconds], callback, true)
		button.name = "Option%d" % index
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 21)
		button.custom_minimum_size.y = 90
		button.tooltip_text = "%s — %s. $%d, %d segundos." % [option.name, option.detail, option.price, option.seconds]
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		right_rows.add_child(button)
	var bonuses := HBoxContainer.new()
	bonuses.add_theme_constant_override("separation", 10)
	right_rows.add_child(bonuses)
	if int(Campaign.state.coupons) > 0:
		var coupon := _button("Cupón -30 %% (%d)" % Campaign.state.coupons, func() -> void:
			coupon_armed = not coupon_armed
			if selected >= 0:
				_select_option(selected)
			else:
				_show_choices()
		, true)
		coupon.toggle_mode = true
		coupon.button_pressed = coupon_armed
		coupon.add_theme_font_size_override("font_size", 18)
		coupon.custom_minimum_size.y = 42
		bonuses.add_child(coupon)
	if phase == "style" and int(Campaign.state.trends) > 0 and not trend_used:
		var trend := _button("Tendencia (%d)" % Campaign.state.trends, func() -> void:
			trend_armed = not trend_armed
			_update_client(true)
		, true)
		trend.toggle_mode = true
		trend.button_pressed = trend_armed
		trend.add_theme_font_size_override("font_size", 18)
		trend.custom_minimum_size.y = 42
		bonuses.add_child(trend)
	error_label = _label("", 21, CORAL)
	error_label.hide()
	right_rows.add_child(error_label)
	confirm_button = _button("Aplicar cambio", _start_service)
	confirm_button.disabled = true
	right_rows.add_child(confirm_button)
	alex.show_pose(0)
	_update_client()


func _select_option(index: int) -> void:
	if working or paused:
		return
	selected = index
	_sfx("click")
	for option_index in range(3):
		var option := right_rows.get_node("Option%d" % option_index) as Button
		var style := option.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		style.bg_color = GOLD if index == option_index else Color("f0eee6")
		option.add_theme_stylebox_override("normal", style)
	confirm_button.disabled = false
	var choices: Array = level.cut_options if phase == "cut" else level.style_options
	var price := ceili(float(choices[index].price) * (0.7 if coupon_armed else 1.0))
	confirm_button.text = "Confirmar · $%d · %d s" % [price, _service_seconds(choices[index])]
	error_label.hide()
	if level_index == 0 and phase == "style" and index == 2 and cut_choice == 2:
		confirm_button.disabled = true
		error_label.text = "Un corte corto no permite este recogido."
		error_label.show()
	_update_client(true)
	checkpoint()


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
	elif style == 2 and bool(level.get("bad_style_preserves_cut", false)):
		sofia.show_pose(cut if cut < 2 else 3, variants if cut < 2 else sofia_sheet)
	elif style == 2:
		sofia.show_pose(4, variants)
	elif cut == 2:
		sofia.show_pose(5, variants)
	elif cut == 0:
		sofia.show_pose(1 if style == 0 else 2, sofia_sheet if style == 0 else variants)
	else:
		sofia.show_pose(3 if style == 0 else 2, variants if style == 0 else sofia_sheet)
	_update_accessory(style == 2 and level_index == 1, trend_used or (preview and trend_armed))


func _start_service() -> void:
	if selected < 0 or working or paused:
		return
	var options: Array = level.cut_options if phase == "cut" else level.style_options
	selected_service = options[selected].duplicate(true)
	selected_service.price = ceili(float(selected_service.price) * (0.7 if coupon_armed else 1.0))
	selected_service.seconds = _service_seconds(options[selected])
	if money < int(selected_service.price):
		error_label.text = "No alcanza el presupuesto para este servicio."
		error_label.show()
		return
	if remaining <= float(selected_service.seconds):
		error_label.text = "No queda tiempo suficiente para este servicio."
		error_label.show()
		return
	if not Campaign.consume_service_items(coupon_armed, phase == "style" and trend_armed):
		error_label.text = "No se pudo guardar el uso de los objetos."
		error_label.show()
		return
	trend_used = trend_used or (phase == "style" and trend_armed)
	coupon_armed = false
	trend_armed = false
	money -= int(selected_service.price)
	remaining -= float(selected_service.seconds)
	_build_work()
	checkpoint()


func _build_work(done: int = 0) -> void:
	working = true
	strokes = done
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
		target.text = "OK" if index < strokes else str(index + 1)
		target.tooltip_text = "Aplicar herramienta · zona %d" % (index + 1)
		target.add_theme_stylebox_override("normal", _box(GOLD, 32))
		target.add_theme_color_override("font_color", INK)
		actors.add_child(target)
		target.size = Vector2(64, 64)
		target.disabled = index != strokes
		target.pressed.connect(_finish_target.bind(index))
		targets.append(target)
	_position_targets()
	targets[strokes].grab_focus()


func _position_targets() -> void:
	if targets.is_empty() or sofia.texture == null:
		return
	var image_size := Vector2(sofia.texture.get_size())
	var displayed := image_size * minf(sofia.size.x / image_size.x, sofia.size.y / image_size.y)
	var origin := sofia.position + (sofia.size - displayed) / 2.0
	var short_hair: bool = level.short_cut.has(selected if phase == "cut" else cut_choice)
	var points := [Vector2(0.25, 0.17), Vector2(0.68, 0.22), Vector2(0.40, 0.25 if short_hair else 0.39)]
	for index in range(targets.size()):
		targets[index].position = origin + displayed * points[index] - Vector2(32, 32)


func _finish_target(index: int) -> void:
	if not working or index != strokes or paused:
		return
	var target := targets[index]
	target.text = "OK"
	target.disabled = true
	strokes += 1
	var sparks := CPUParticles2D.new()
	actors.add_child(sparks)
	sparks.position = target.position + target.size / 2.0
	sparks.one_shot = true
	sparks.amount = 12
	sparks.lifetime = 0.4
	sparks.direction = Vector2.UP
	sparks.spread = 180
	sparks.initial_velocity_min = 25
	sparks.initial_velocity_max = 80
	sparks.gravity = Vector2(0, 30)
	sparks.scale_amount_min = 2
	sparks.scale_amount_max = 4
	sparks.color = GOLD
	sparks.finished.connect(sparks.queue_free)
	sparks.emitting = true
	_sfx(("scissors" if index == 0 else "tint") if phase == "cut" else "dryer")
	alex.show_pose((2 if index == 0 else 3) if phase == "cut" else 4)
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
	checkpoint()


func _show_review() -> void:
	_update_client()
	alex.show_pose(1)
	phase_title.text = "03 · Revisión final"
	work_hint.text = "¿El cambio representa lo que %s pidió?" % level.client
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
	if paused:
		return
	var valid: bool = level.good_cut.has(cut_choice) and level.good_style.has(style_choice)
	_result(valid, "¡Reto superado!" if valid else "Volvamos a intentarlo", "success" if valid else "failure")


func _result(passed: bool, heading: String, line: String) -> void:
	if phase == "result":
		return
	phase = "result"
	running = false
	working = false
	_clear_targets()
	tool.hide()
	var thrift := money >= int(float(level.budget) * 0.15)
	var fast := remaining >= float(level.seconds) * 0.20
	var partial: bool = level.good_cut.has(cut_choice) or level.good_style.has(style_choice)
	var stars := (3 if thrift and fast else 2) if passed else (1 if partial and line != "timeout" else 0)
	var award := {"saved": true, "reward": 0, "first_clear": false}
	if passed:
		award = Campaign.record_result(level_index, stars, money >= int(float(level.budget) * 0.3), fast)
	else:
		award.saved = Campaign.save_attempt({})
	best_stars = int(Campaign.state.stars[level_index])
	coins = int(Campaign.state.coins)
	var reward: int = award.reward
	_clear(right_rows)
	right_rows.add_child(_label(heading, 34, INK if passed else CORAL))
	right_rows.add_child(_label("★".repeat(stars) + "☆".repeat(3 - stars), 54, Color("c6902c")))
	right_rows.add_child(_label(level.success_text if passed else ("Se acabó el tiempo antes de entregar el look." if line == "timeout" else level.failure_text), 25))
	right_rows.add_child(_label("Presupuesto restante: $%d\nTiempo restante: %s" % [money, _clock()], 25, MUTED))
	if passed:
		right_rows.add_child(_label("+%d monedas\nMejor resultado: %d/3 estrellas" % [reward, best_stars], 25))
		right_rows.add_child(_button("Siguiente clienta →" if level_index < 2 else "Recibir reconocimiento", func() -> void: request_next.emit()))
	if not award.saved:
		right_rows.add_child(_label("No se pudo guardar. Revisa el espacio disponible antes de salir.", 22, CORAL))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	right_rows.add_child(actions)
	var retry := _button("Repetir" if passed else "Reintentar", _restart, true)
	var clients := _button("Clientes", func() -> void: request_menu.emit(), true)
	retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clients.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(retry)
	actions.add_child(clients)
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
			person.copy_appearance(sofia)
			if is_instance_valid(bad_accessory) and bad_accessory.visible:
				var accessory := TextureRect.new()
				person.add_child(accessory)
				accessory.texture = bad_accessory.texture
				accessory.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				accessory.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				accessory.mouse_filter = Control.MOUSE_FILTER_IGNORE
				accessory.anchor_left = 0.5
				accessory.anchor_right = 0.5
				accessory.offset_left = 12
				accessory.offset_right = 12 + bad_accessory.size.x
				accessory.offset_top = 25
				accessory.offset_bottom = 25 + bad_accessory.size.y
	comparison.hide()
	var result_view_id := comparison.get_instance_id()
	var reveal := create_tween()
	reveal.tween_interval(0.7)
	reveal.tween_callback(func() -> void:
		var result_view := instance_from_id(result_view_id) as Control
		if phase == "result" and is_instance_valid(result_view) and comparison == result_view:
			alex.hide()
			sofia.hide()
			if is_instance_valid(bad_accessory):
				bad_accessory.hide()
			comparison.show()
	)
	phase_title.text = "ANTES                    DESPUÉS"
	work_hint.text = "%s · %s" % [level.title, level.client]
	_sfx("success" if passed else "failure")
	_say(line)


func _update_status() -> void:
	status.text = "%s   ·   $%d\nNIVEL %02d  /  %s" % [_clock(), money, level_index + 1, level.title.to_upper()]
	status.add_theme_color_override("font_color", CORAL if remaining < 30 else INK)


func _clock() -> String:
	var seconds := ceili(remaining)
	return "%02d:%02d" % [floori(float(seconds) / 60.0), seconds % 60]


func _say(id: String) -> void:
	active_line = id
	var key: String = str(level.voice_prefix) + id
	var entry: Dictionary = dialogue[key]
	var voice_path := "res://assets/audio/voice/%s.wav" % key
	var voice: AudioStream = load(voice_path) if ResourceLoader.exists(voice_path) else null
	_subs().show_line(entry.text, entry.speaker, voice, maxf(4.0, entry.text.length() / 18.0))
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
	if container is CanvasItem:
		container.modulate.a = 0.3
		container.create_tween().tween_property(container, "modulate:a", 1.0, 0.18)


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
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_margin(panel, 24).add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 12)
	scroll.add_child(rows)
	return rows


func _subs():
	return get_tree().get_first_node_in_group("Subtitles")


func _service_seconds(service: Dictionary) -> int:
	return ceili(float(service.seconds) * (0.85 if Campaign.completed(0) else 1.0))


func checkpoint() -> bool:
	if phase == "result":
		return true
	return Campaign.save_attempt({"level": level_index, "phase": phase,
		"selected": selected, "cut": cut_choice, "style": style_choice,
		"money": money, "time": remaining, "working": working, "strokes": strokes,
		"service": selected_service, "trend_used": trend_used})


func _restore() -> void:
	var saved := resume_data.duplicate(true)
	_restart()
	phase = str(saved.get("phase", "intro"))
	if phase not in ["intro", "cut", "style", "review"]:
		phase = "intro"
	cut_choice = clampi(int(saved.get("cut", -1)), -1, 2)
	style_choice = clampi(int(saved.get("style", -1)), -1, 2)
	money = clampi(int(saved.get("money", level.budget)), 0, int(level.budget))
	remaining = clampf(float(saved.get("time", level.seconds)), 0.0, float(level.seconds))
	trend_used = bool(saved.get("trend_used", false))
	if phase in ["cut", "style"]:
		_show_choices()
		var choice := clampi(int(saved.get("selected", -1)), -1, 2)
		if choice >= 0:
			_select_option(choice)
		if bool(saved.get("working", false)) and choice >= 0:
			selected_service = saved.get("service", {}).duplicate(true)
			if selected_service.has("price") and selected_service.has("seconds"):
				_build_work(clampi(int(saved.get("strokes", 0)), 0, 2))
	elif phase == "review" and cut_choice >= 0 and style_choice >= 0:
		_show_review()
	running = phase != "intro"
	if phase != "intro":
		_say("review" if phase == "review" else phase)
	_update_status()
	checkpoint()


func _update_accessory(large: bool, trend: bool) -> void:
	if not is_instance_valid(bad_accessory):
		var view := TextureRect.new()
		view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		actors.add_child(view)
		bad_accessory = view
	bad_accessory.visible = large or trend
	if not bad_accessory.visible:
		return
	var part := AtlasTexture.new()
	part.atlas = load("res://assets/ui/accessories.svg")
	part.region = Rect2(0, 256 if large else 0, 256, 256)
	bad_accessory.texture = part
	bad_accessory.size = Vector2(100, 100) if large else Vector2(42, 42)
	var displayed := Vector2(sofia.texture.get_size())
	displayed *= minf(sofia.size.x / displayed.x, sofia.size.y / displayed.y)
	bad_accessory.position = sofia.position + (sofia.size - displayed) / 2.0 + displayed * Vector2(0.65, 0.04)


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
	button.add_theme_color_override("font_focus_color", INK)
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
