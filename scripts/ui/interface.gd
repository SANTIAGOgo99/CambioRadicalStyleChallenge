extends Control

const Character = preload("res://scripts/game/character_view.gd")
const INK := Color("193e41")
const PAPER := Color("fffaf1")
const GOLD := Color("eebd61")
const MUTED := Color("617477")

@onready var settings_panel: AudioSettingsPanel = $SettingsPanel
@onready var settings_button: Button = $SettingsButton
@onready var slot: Control = $GameSlot
@onready var modal_layer: Control = $ModalLayer
@onready var subtitles = $Subtitles

var current_game
var view := ""
var modal_kind := ""
var cancel_modal: Callable
var return_to_pause := false
var screen: Control
var view_characters: Array[SalonCharacter] = []
var story_step := 0
var music := AudioStreamPlayer.new()
var clicks := AudioStreamPlayer.new()
var lines: Dictionary


func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_window().title = "Cambio Radical: Style Challenge"
	settings_button.pressed.connect(_settings_or_pause)
	settings_panel.closed.connect(_settings_closed)
	subtitles.line_finished.connect(_story_line_finished)
	lines = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	music.bus = &"Music"
	clicks.bus = &"Effects"
	add_child(music)
	add_child(clicks)
	_show_splash.call_deferred()


func _process(delta: float) -> void:
	music.volume_db = move_toward(music.volume_db, -22.0 if subtitles.active else -11.0, delta * 25.0)
	for person in view_characters:
		if is_instance_valid(person):
			person.set_talking(subtitles.active and subtitles.speaker_name == str(person.get_meta("speaker", "")))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit()


func _exit_tree() -> void:
	music.stop()
	music.stream = null
	clicks.stop()
	clicks.stream = null


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		Settings.set_fullscreen(not Settings.fullscreen)
		Settings.save_settings()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if settings_panel.visible:
			settings_panel.close()
		elif modal_kind == "pause":
			_resume()
		elif not modal_kind.is_empty():
			var action := cancel_modal
			_close_modal()
			if action.is_valid():
				action.call()
		elif view == "game":
			_show_pause()
		elif view == "menu":
			_confirm("¿Salir del juego? Tus avances guardados se conservarán.", _quit)
		else:
			show_menu()
		get_viewport().set_input_as_handled()


func _settings_or_pause() -> void:
	if view == "game":
		_show_pause()
	else:
		_open_settings()


func _open_settings(from_pause: bool = false) -> void:
	return_to_pause = from_pause
	_close_modal()
	settings_button.disabled = true
	settings_panel.open()


func _settings_closed() -> void:
	settings_button.disabled = false
	if return_to_pause and view == "game":
		_show_pause()
	else:
		settings_button.grab_focus()
	return_to_pause = false


func _clear_view(next_view: String) -> void:
	if is_instance_valid(current_game):
		current_game.checkpoint()
	current_game = null
	view_characters.clear()
	subtitles.clear()
	subtitles.set_paused(false)
	_close_modal()
	for child in slot.get_children():
		slot.remove_child(child)
		child.queue_free()
	view = next_view
	settings_button.text = "Pausa" if next_view == "game" else "Ajustes"
	settings_button.disabled = false
	screen = Control.new()
	slot.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop := TextureRect.new()
	screen.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = load("res://assets/backgrounds/salon_original.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := ColorRect.new()
	screen.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.12, 0.13, 0.48)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.modulate.a = 0.0
	screen.create_tween().tween_property(screen, "modulate:a", 1.0, 0.25)
	_set_music("menu_loop")


func _base_view(title: String, subtitle: String) -> HBoxContainer:
	var margin := MarginContainer.new()
	screen.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 64
	margin.offset_right = -64
	margin.offset_top = 36
	margin.offset_bottom = -205
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)
	margin.add_child(layout)
	var heading := _label(title, 48, PAPER)
	heading.custom_minimum_size.x = 900
	layout.add_child(heading)
	layout.add_child(_label(subtitle, 25, Color("e5ded0")))
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 28)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)
	return body


func _show_splash() -> void:
	_clear_view("splash")
	var body := _base_view("CAMBIO RADICAL", "S T Y L E   C H A L L E N G E")
	var rows := _panel(body, 850)
	rows.add_child(_label("Cada cambio empieza\npor escuchar.", 58))
	rows.add_child(_label("Una historia de creatividad, estilo y primeras impresiones.", 29, MUTED))
	rows.add_child(_button("Entrar al salón  →", show_menu))
	_portrait(body, "alex_original", 0, Vector2(600, 620), "Alex")
	get_tree().create_timer(2.3).timeout.connect(_splash_timeout)


func _splash_timeout() -> void:
	if view == "splash":
		show_menu()


func show_menu() -> void:
	_clear_view("menu")
	var body := _base_view("CAMBIO RADICAL", "Style Challenge · el salón de Ezequiel")
	var rows := _panel(body, 780)
	rows.add_child(_label("Tu camino a Hair Designer", 39))
	rows.add_child(_label("Escucha a cada clienta. Crea un look que la represente. Haz que cada detalle cuente.", 27, MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	rows.add_child(grid)
	var new_button := _button("Nueva partida", _new_game)
	new_button.name = "NewGame"
	grid.add_child(new_button)
	var continue_button := _button("Continuar partida", _continue_game)
	continue_button.name = "Continue"
	continue_button.disabled = not Campaign.has_progress()
	grid.add_child(continue_button)
	grid.add_child(_button("Elegir clienta", show_levels, true))
	grid.add_child(_button("Cómo jugar", show_instructions, true))
	grid.add_child(_button("Recompensas", show_rewards, true))
	grid.add_child(_button("Créditos", show_credits, true))
	rows.add_child(_label("Tres clientas. Tres retos. Tu propio estilo.", 25, MUTED))
	if Campaign.state.story_complete:
		rows.add_child(_button("Ver tu reconocimiento", show_finale, true))
	rows.add_child(_button("Salir", func() -> void: _confirm("¿Salir del juego?", _quit), true))
	_portrait(body, "alex_original", 0, Vector2(600, 630), "Alex")
	new_button.grab_focus()


func _new_game() -> void:
	if Campaign.has_progress():
		_confirm("Nueva partida borrará estrellas, monedas y el reto en curso. ¿Comenzar de cero?", _start_new_game)
	else:
		_start_new_game()


func _start_new_game() -> void:
	if not Campaign.new_game():
		_message("No se pudo guardar la nueva partida. Revisa el espacio disponible.")
		return
	show_story()


func _continue_game() -> void:
	var attempt: Dictionary = Campaign.state.attempt
	if not attempt.is_empty():
		load_level(clampi(int(attempt.get("level", 0)), 0, 2), true)
	elif Campaign.state.story_complete:
		show_levels()
	else:
		load_level(Campaign.next_level())


func show_story() -> void:
	_clear_view("story")
	story_step = 0
	var body := _base_view("Un nuevo comienzo", "Alex comienza a trabajar en el salón de Ezequiel.")
	_portrait(body, "alex_original", 1, Vector2(450, 620), "Alex")
	var rows := _panel(body, 610)
	rows.add_child(_label("Escuchar es parte del arte.", 40))
	rows.add_child(_label("Tu meta es aprender a interpretar a cada clienta y convertirte en Hair Designer.", 29))
	rows.add_child(_label("Ezequiel te acompañará. Sofía será tu primera clienta.", 27, MUTED))
	rows.add_child(_button("Atender a Sofía  →", func() -> void: load_level(0)))
	_portrait(body, "ezequiel_original", 1, Vector2(490, 570), "Ezequiel", true)
	_say("story_intro")


func show_levels() -> void:
	_clear_view("levels")
	var body := _base_view("Elige a tu próxima clienta", "Cada reto se desbloquea al conseguir al menos dos estrellas en el anterior.")
	for index in range(3):
		var level: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/level_%02d.json" % (index + 1)))
		var rows := _panel(body, 520)
		rows.add_child(_label("%02d  ·  %s" % [index + 1, level.title], 31))
		_portrait(rows, str(level.asset) + "_original", 5 if Campaign.completed(index) else 0, Vector2(320, 370), str(level.client))
		rows.add_child(_label("%s · %s" % [level.client, level.event], 25))
		var stars := int(Campaign.state.stars[index])
		rows.add_child(_label("★".repeat(stars) + "☆".repeat(3 - stars), 38, Color("b58126")))
		var button := _button("Repetir reto" if Campaign.completed(index) else "Comenzar reto", load_level.bind(index))
		button.disabled = not Campaign.unlocked(index)
		if button.disabled:
			button.text = "Completa el nivel anterior"
			button.add_theme_font_size_override("font_size", 21)
		rows.add_child(button)
	_add_back()


func load_level(index: int, resume_attempt: bool = false) -> void:
	if not Campaign.unlocked(index):
		_message("Completa el reto anterior para desbloquear a esta clienta.")
		return
	var saved: Dictionary = Campaign.state.attempt.duplicate(true) if resume_attempt else {}
	_clear_view("game")
	screen.hide()
	music.stop()
	current_game = load("res://scenes/game/salon.tscn").instantiate()
	current_game.level_index = index
	current_game.resume_data = saved
	current_game.app = self
	slot.add_child(current_game)
	current_game.modulate.a = 0.0
	current_game.create_tween().tween_property(current_game, "modulate:a", 1.0, 0.25)
	current_game.request_next.connect(_next_level)
	current_game.request_menu.connect(show_levels)


func _next_level() -> void:
	if not is_instance_valid(current_game):
		return
	var index: int = current_game.level_index
	if index < 2:
		load_level(index + 1)
	else:
		show_finale()


func show_instructions() -> void:
	_clear_view("instructions")
	var body := _base_view("El arte de un buen cambio", "Se juega con ratón. También puedes navegar con Tab y confirmar con Enter o Espacio.")
	var rows := _panel(body, 1000)
	for item: String in ["01 · Escucha la petición y revisa sus condiciones.", "02 · Prueba opciones: el espejo de vista previa es gratuito.", "03 · Confirma el precio y tiempo antes de aplicar un servicio.", "04 · Arrastra la herramienta a las zonas 1, 2 y 3, en orden.", "05 · Revisa el resultado y entrega un look que cumpla la petición."]:
		rows.add_child(_label(item, 29))
	rows.add_child(_label("Esc abre la pausa; F11 cambia la pantalla completa. La pausa detiene el reloj y la voz. Se guarda el reto en curso y puedes continuarlo después.", 25, MUTED))
	var tools := TextureRect.new()
	tools.texture = load("res://assets/ui/salon_tools.png")
	tools.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tools.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tools.custom_minimum_size = Vector2(600, 330)
	body.add_child(tools)
	_add_back()


func show_rewards() -> void:
	_clear_view("rewards")
	var body := _base_view("Tu colección de logros", "%d monedas · las recompensas de estrellas se conceden al mejorar tu récord." % Campaign.state.coins)
	var rows := _panel(body, 840)
	rows.add_child(_label("Insignias", 37))
	for badge: String in ["Primer cambio", "Buen presupuesto", "Contra reloj", "Estrella dorada", "Diseñador de eventos", "Hair Designer"]:
		rows.add_child(_label(("★  " if Campaign.state.badges.has(badge) else "☆  ") + badge, 28, INK if Campaign.state.badges.has(badge) else MUTED))
	var shop := _panel(body, 740)
	shop.add_child(_label("Herramientas de progreso", 35))
	shop.add_child(_label("Espejo de prueba · vistas previas gratuitas", 25))
	shop.add_child(_label("Kit profesional · servicios 15 % más rápidos" if Campaign.completed(0) else "Kit profesional · completa el primer nivel", 25))
	shop.add_child(_label("Cupones: %d · Tendencias: %d" % [Campaign.state.coupons, Campaign.state.trends], 26, MUTED))
	var coupon := _button("Comprar cupón -30 % · 60 monedas", _buy.bind("coupons"), true)
	coupon.disabled = Campaign.state.coins < 60
	shop.add_child(coupon)
	var trend := _button("Ficha de tendencia · 80 monedas", _buy.bind("trends"), true)
	trend.disabled = Campaign.state.coins < 80 or not Campaign.completed(1)
	shop.add_child(trend)
	shop.add_child(_label("La ficha añade un detalle especial al look. Se usa una vez por reto. Mariana desbloquea la colección de tendencias.", 23, MUTED))
	var uniform := _button("Uniforme: " + ("Berenjena" if Campaign.state.uniform_alt else "Verde salón"), _toggle_uniform, true)
	uniform.disabled = not Campaign.completed(1)
	shop.add_child(uniform)
	_add_back()


func _buy(item: String) -> void:
	if Campaign.purchase(item):
		_sfx("coin")
		show_rewards()
	else:
		_message("No se pudo completar la compra. Comprueba tus monedas y el espacio disponible.")


func _toggle_uniform() -> void:
	Campaign.state.uniform_alt = not Campaign.state.uniform_alt
	if Campaign.save() != OK:
		Campaign.state.uniform_alt = not Campaign.state.uniform_alt
		_message("No se pudo guardar el uniforme.")
	else:
		show_rewards()


func show_credits() -> void:
	_clear_view("credits")
	var body := _base_view("Créditos", "Cambio Radical: Style Challenge · Creación de Videojuegos")
	var rows := _panel(body, 1120)
	rows.add_child(_label("Héctor Santiago Hernández", 40))
	rows.add_child(_label("Propuesta, historia y proyecto académico\nUniversidad Tecnológica de la Huasteca Hidalguense", 28))
	rows.add_child(_label("Proyecto transversal: Ezequiel Castillo Ángeles Hair Designer.", 24, MUTED))
	rows.add_child(_label("Desarrollo en Godot 4.7.2 y GDScript. Arte original generado para este videojuego; no se utilizan las imágenes de referencia de los PDF como personajes.", 26, MUTED))
	rows.add_child(_label("Música y efectos originales sintetizados. Voces sintéticas españolas de Windows: Sabina y Raúl. El juego funciona sin conexión a internet.", 26, MUTED))
	rows.add_child(_label("Godot Engine y sus dependencias se distribuyen bajo sus licencias correspondientes, incluidas con la entrega.", 23, MUTED))
	_portrait(body, "ezequiel_original", 0, Vector2(460, 540), "Ezequiel", true)
	_add_back()


func show_finale() -> void:
	if not Campaign.state.story_complete:
		show_levels()
		return
	_clear_view("finale")
	_set_music("celebration_loop")
	story_step = 0
	var body := _base_view("¡Hair Designer!", "Tres clientas satisfechas. Un nuevo comienzo para Alex.")
	_portrait(body, "alex_original", 5, Vector2(430, 600), "Alex")
	var certificate := _panel(body, 690)
	certificate.add_child(_label("★  RECONOCIMIENTO  ★", 33, Color("a57324")))
	certificate.add_child(_label("Alex", 68))
	certificate.add_child(_label("Hair Designer del salón", 39))
	certificate.add_child(_label("Por escuchar, crear y cuidar cada detalle.\n\nSofía · Mariana · Valeria", 28, MUTED))
	certificate.add_child(_button("Volver a elegir clienta", show_levels))
	certificate.add_child(_button("Menú principal", show_menu, true))
	_portrait(body, "ezequiel_expressions", 1, Vector2(460, 570), "Ezequiel")
	var confetti := CPUParticles2D.new()
	screen.add_child(confetti)
	confetti.position = Vector2(get_viewport_rect().size.x / 2.0, -20)
	confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confetti.emission_rect_extents = Vector2(get_viewport_rect().size.x * 0.48, 10)
	confetti.direction = Vector2(0, 1)
	confetti.spread = 65
	confetti.gravity = Vector2(0, 280)
	confetti.initial_velocity_min = 60
	confetti.initial_velocity_max = 150
	confetti.amount = 110
	confetti.lifetime = 5
	confetti.scale_amount_min = 3
	confetti.scale_amount_max = 7
	var colors := Gradient.new()
	colors.colors = PackedColorArray([GOLD, Color("db7868"), Color("5faca0")])
	confetti.color_ramp = colors
	confetti.emitting = true
	_sfx("success")
	_say("final_ezequiel")


func _story_line_finished() -> void:
	if view == "story" and story_step == 0:
		story_step = 1
		_say("story_alex")
	elif view == "finale" and story_step == 0:
		story_step = 1
		_say("final_alex")


func _show_pause() -> void:
	if not is_instance_valid(current_game):
		return
	current_game.paused = true
	current_game.checkpoint()
	subtitles.set_paused(true)
	_modal("Pausa", "Tu reto está guardado. El tiempo y los diálogos están detenidos.", [
		["Reanudar", _resume], ["Ajustes", func() -> void: _open_settings(true)],
		["Reiniciar reto", func() -> void: _confirm("¿Reiniciar este reto? Se perderán los servicios aplicados en este intento.", _restart_level, true)],
		["Elegir clienta", show_levels], ["Menú principal", show_menu]
	])
	modal_kind = "pause"


func _resume() -> void:
	_close_modal()
	if is_instance_valid(current_game):
		current_game.paused = false
	subtitles.set_paused(false)


func _restart_level() -> void:
	_close_modal()
	subtitles.set_paused(false)
	if is_instance_valid(current_game):
		current_game.paused = false
		current_game._restart()


func _confirm(text: String, action: Callable, back_to_pause: bool = false) -> void:
	_modal("Confirmar", text, [["Confirmar", func() -> void:
		_close_modal()
		action.call()
	], ["Cancelar", func() -> void:
		_close_modal()
		if back_to_pause:
			_show_pause()
	]])
	modal_kind = "confirm"
	cancel_modal = _show_pause if back_to_pause else Callable()


func _message(text: String) -> void:
	_modal("Aviso", text, [["Aceptar", _close_modal]])
	modal_kind = "message"


func _modal(title: String, text: String, actions: Array) -> void:
	_close_modal()
	settings_button.disabled = true
	var dim := ColorRect.new()
	modal_layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	var center := CenterContainer.new()
	modal_layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rows := _panel(center, 850)
	rows.add_child(_label(title, 42))
	rows.add_child(_label(text, 27, MUTED))
	var buttons: Array[Control] = []
	for action: Array in actions:
		var button := _button(str(action[0]), action[1], buttons.size() > 0)
		rows.add_child(button)
		buttons.append(button)
	for index in range(buttons.size()):
		var previous := buttons[(index - 1 + buttons.size()) % buttons.size()].get_path()
		var next := buttons[(index + 1) % buttons.size()].get_path()
		buttons[index].focus_previous = previous
		buttons[index].focus_next = next
		buttons[index].focus_neighbor_top = previous
		buttons[index].focus_neighbor_left = previous
		buttons[index].focus_neighbor_bottom = next
		buttons[index].focus_neighbor_right = next
	buttons[0].grab_focus()


func _close_modal() -> void:
	for child in modal_layer.get_children():
		modal_layer.remove_child(child)
		child.queue_free()
	modal_kind = ""
	cancel_modal = Callable()
	settings_button.disabled = false


func _quit() -> void:
	if is_instance_valid(current_game) and not current_game.checkpoint():
		_message("No se pudo guardar el reto. Revisa el espacio disponible antes de salir.")
		return
	Settings.save_settings()
	get_tree().quit()


func _say(key: String) -> void:
	var line: Dictionary = lines[key]
	subtitles.show_line(line.text, line.speaker, load("res://assets/audio/voice/%s.wav" % key))


func _set_music(track: String) -> void:
	var path := "res://assets/audio/music/%s.wav" % track
	if music.stream != null and music.stream.resource_path == path:
		if not music.playing and AudioServer.get_driver_name() != "Dummy":
			music.play()
		return
	music.stop()
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/music/salon_loop.wav"
	var audio := load(path) as AudioStreamWAV
	audio.loop_mode = AudioStreamWAV.LOOP_FORWARD
	audio.loop_end = audio.data.size() / 2
	music.stream = audio
	if AudioServer.get_driver_name() != "Dummy":
		music.play()


func _sfx(key: String) -> void:
	if AudioServer.get_driver_name() != "Dummy":
		clicks.stream = load("res://assets/audio/effects/%s.wav" % key)
		clicks.play()


func _add_back() -> void:
	var back := _button("← Menú principal", show_menu, true)
	screen.add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	back.offset_left = 64
	back.offset_top = -170
	back.offset_right = 350
	back.offset_bottom = -100


func _portrait(parent: Node, asset: String, pose: int, minimum: Vector2, speaker: String, closeup: bool = false) -> SalonCharacter:
	var person := Character.new()
	person.portrait_mode = closeup
	person.custom_minimum_size = minimum
	person.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(person)
	person.setup(load("res://assets/characters/%s.png" % asset) as Texture2D, 2 if asset.begins_with("ezequiel_") else 3, 1 if asset.begins_with("ezequiel_") else 2)
	person.show_pose(pose)
	person.set_meta("speaker", speaker)
	view_characters.append(person)
	return person


func _panel(parent: Node, width: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(PAPER, 22))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 18)
	margin.add_child(rows)
	return rows


func _label(text: String, size: int = 28, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _box(color: Color, radius: int = 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _button(text: String, action: Callable, secondary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size.y = 66
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 26)
	for state: String in ["normal", "hover", "pressed"]:
		var style := _box((Color("efede5") if secondary else GOLD) if state == "normal" else Color("f4cf89"))
		style.content_margin_left = 20
		style.content_margin_right = 20
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		button.add_theme_stylebox_override(state, style)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, INK)
	button.pressed.connect(func() -> void:
		_sfx("click")
		action.call()
	)
	return button
