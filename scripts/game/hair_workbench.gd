class_name HairWorkbench
extends Control
## Editable illustrated hair. Every cut changes a strand's actual visible geometry.

signal changed
signal tool_sound(name: String)
signal comment(text: String, good: bool)

const STRANDS := 28
const PAINT_ROWS := 48
const BRUSH_RADIUS := Vector2(0.105, 0.048)
const PAPER := Color("fff9ef")
const GOLD := Color("efc36b")
const INK := Color("20494b")
const TOOLS := ["cut", "dye", "comb", "dry"]
const TOOL_NAMES := {"cut": "Tijeras", "dye": "Brocha", "comb": "Peine", "dry": "Secadora"}
# Keep texture references alive until the renderer consumes the draw commands.
const TOOL_SHEET = preload("res://assets/ui/salon_tools.png")
const ACCESSORY_SHEET = preload("res://assets/ui/accessories.svg")

var sheet: Texture2D
var pixels: Image
var cell := Vector2(512, 1024)
var character := "sofia"
var service_phase := "cut"
var choice := 0
var level_index := 0
var current_tool := "cut"
var lengths: Array = []
var dyed: Array = []
var combed: Array = []
var dried: Array = []
var touched: Array = []
var original_lengths: Array = []
var active_strands: Array[int] = []
var target_length := 0.84
var tint := Color.WHITE
var guide := true
var input_enabled := true
var read_only := false
var speaking := false
var errors := 0
var snips := 0
var accessory := false
var cursor := Vector2(-100, -100)
var keyboard_index := 0
var keyboard_height := 0.84
var mouse_inside := false
var dragging := false
var last_local := Vector2(-100, -100)
var sound_in := 0.0
var reaction_in := 0.0
var reaction := ""
var elapsed := 0.0
var undo_stack: Array[Dictionary] = []
var falling: Array[Dictionary] = []
var face_material: ShaderMaterial
var overlay: Control
var backdrop: Control
var paint: Array = []
var paint_cells: Array[int] = []
var paint_image: Image
var paint_texture: ImageTexture
var paint_dirty := true


func setup(asset: String, stage_phase: String, option: int, index: int, saved: Dictionary = {}) -> void:
	character = asset
	service_phase = stage_phase
	choice = option
	level_index = index
	sheet = load("res://assets/characters/%s_layers.png" % asset)
	pixels = sheet.get_image()
	cell = Vector2(sheet.get_width() / 3.0, sheet.get_height())
	lengths.resize(STRANDS)
	lengths.fill(0.965)
	dyed.resize(STRANDS)
	dyed.fill(0.0)
	paint.resize(STRANDS * PAINT_ROWS)
	paint.fill(0.0)
	combed.resize(STRANDS)
	combed.fill(0.0)
	dried.resize(STRANDS)
	dried.fill(0.0)
	touched.resize(STRANDS)
	touched.fill(false)
	original_lengths.resize(STRANDS)
	original_lengths.fill(0.965)
	# Restrict interactions to strands that actually contain hair.
	for index_x in range(STRANDS):
		var x := int((float(index_x) + 0.5) / STRANDS * cell.x)
		for y in range(int(cell.y * 0.62), int(cell.y * 0.9), 8):
			if pixels.get_pixel(int(cell.x) + x, y).a > 0.65:
				active_strands.append(index_x)
				break
		for y in range(int(cell.y * 0.985), int(cell.y * 0.58), -2):
			if pixels.get_pixel(int(cell.x) + x, y).a > 0.65:
				original_lengths[index_x] = float(y) / cell.y
				lengths[index_x] = original_lengths[index_x]
				break
	target_length = (0.82 if index == 1 else 0.85) if option < 2 else 0.61
	if index == 2:
		target_length = [0.65, 0.60, 0.87][option]
	tint = _look_tint(index, option)
	if not saved.is_empty():
		_restore_values(saved)
	current_tool = "cut" if stage_phase == "cut" else "comb"
	if str(saved.get("phase", "")) == stage_phase:
		current_tool = str(saved.get("tool", current_tool))
	elif stage_phase == "style":
		combed.fill(0.0)
		dried.fill(0.0)
	_rebuild_paint_area()
	paint_image = Image.create(STRANDS, PAINT_ROWS, false, Image.FORMAT_RGBA8)
	paint_image.fill(Color(0, 0, 0, 1))
	paint_texture = ImageTexture.create_from_image(paint_image)
	_upload_paint()
	keyboard_height = target_length
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(queue_redraw)
	mouse_exited.connect(func() -> void: mouse_inside = false)
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	face_material = ShaderMaterial.new()
	face_material.shader = load("res://assets/ui/hair_workbench.gdshader")
	face_material.set_shader_parameter("eye_left", Vector2(197, 340) / Vector2(sheet.get_size()))
	face_material.set_shader_parameter("eye_right", Vector2(314, 340) / Vector2(sheet.get_size()))
	face_material.set_shader_parameter("mouth_center", Vector2(257, 434) / Vector2(sheet.get_size()))
	face_material.set_shader_parameter("coat_mask", paint_texture)
	face_material.set_shader_parameter("dye_color", tint)
	face_material.set_shader_parameter("wet_coat", stage_phase == "cut")
	material = face_material
	backdrop = Control.new()
	add_child(backdrop)
	backdrop.show_behind_parent = true
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.draw.connect(_draw_backdrop)
	backdrop.resized.connect(backdrop.queue_redraw)
	overlay = Control.new()
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_draw_overlays)
	queue_redraw()


func _look_tint(index: int, option: int) -> Color:
	var colors: Array = [[Color.WHITE, Color("efbf99"), Color("e48b63")],
		[Color.WHITE, Color("eed2a5"), Color("ed72ae")],
		[Color("72533d"), Color("c88355"), Color.WHITE]]
	return colors[index][option]


func _restore_values(saved: Dictionary) -> void:
	for key: String in ["lengths", "dyed", "combed", "dried", "touched"]:
		var values: Variant = saved.get(key, [])
		if values is Array and values.size() == STRANDS:
			for index in range(STRANDS):
				if key == "touched":
					touched[index] = bool(values[index])
				else:
					self[key][index] = clampf(float(values[index]), 0.0, 1.0)
	errors = maxi(0, int(saved.get("errors", 0)))
	snips = maxi(0, int(saved.get("snips", 0)))
	accessory = bool(saved.get("accessory", false))
	target_length = clampf(float(saved.get("target", target_length)), 0.5, 0.93)
	if saved.has("tint") and saved.tint is String:
		tint = Color.from_string(saved.tint, tint)
	var stored: Variant = saved.get("paint", [])
	if stored is Array and stored.size() == paint.size():
		for index in range(paint.size()):
			paint[index] = clampf(float(stored[index]), 0.0, 1.0)
	else:
		# Version 1.1 saved coverage per strand; keep that already-paid work.
		for index in range(paint.size()):
			paint[index] = float(dyed[index % STRANDS])


func snapshot() -> Dictionary:
	return {"phase": service_phase, "choice": choice, "level": level_index,
		"asset": character, "tool": current_tool, "target": target_length,
		"lengths": lengths.duplicate(), "dyed": dyed.duplicate(), "combed": combed.duplicate(),
		"dried": dried.duplicate(), "touched": touched.duplicate(), "errors": errors,
		"snips": snips, "tint": tint.to_html(), "accessory": accessory, "paint": paint.duplicate()}


func set_tool(id: String) -> void:
	if id not in TOOLS:
		return
	if (service_phase == "cut" and id not in ["cut", "dye"]) or (service_phase == "style" and id not in ["comb", "dry"]):
		return
	current_tool = id
	if id == "dye":
		keyboard_height = 0.68
	dragging = false
	last_local = Vector2(-100, -100)
	changed.emit()
	if not read_only:
		queue_redraw()


func progress_for(id: String) -> float:
	if id == "dye":
		var covered := 0.0
		for index: int in paint_cells:
			covered += float(paint[index])
		return covered / maxf(1.0, paint_cells.size())
	if active_strands.is_empty():
		return 0.0
	var total := 0.0
	for index: int in active_strands:
		match id:
			"cut": total += 1.0 if touched[index] else 0.0
			"dye": total += float(dyed[index])
			"comb": total += float(combed[index])
			"dry": total += float(dried[index])
	return total / active_strands.size()


func target_for(index: int) -> float:
	return minf(target_length, float(original_lengths[index]) - 0.045)


func service_ready() -> bool:
	return progress_for("cut") >= 0.9 and progress_for("dye") >= 0.86 if service_phase == "cut" else progress_for("comb") >= 0.86 and progress_for("dry") >= 0.86


func precision() -> float:
	if active_strands.is_empty():
		return 0.0
	var deviation := 0.0
	for index: int in active_strands:
		deviation += minf(1.0, absf(float(lengths[index]) - target_for(index)) / 0.22)
	return clampf(1.0 - deviation / active_strands.size(), 0.0, 1.0)


func undo_cut() -> void:
	if undo_stack.is_empty() or read_only or not input_enabled:
		return
	var previous: Dictionary = undo_stack.pop_back()
	lengths = previous.lengths.duplicate()
	touched = previous.touched.duplicate()
	errors = int(previous.errors)
	snips = int(previous.snips)
	_rebuild_paint_area()
	falling.clear()
	reaction = "Vamos de nuevo, con calma."
	reaction_in = 2.0
	changed.emit()
	queue_redraw()


func portrait_rect() -> Rect2:
	var scale_factor := minf((size.x - 32.0) / cell.x, (size.y - 20.0) / cell.y)
	var dimensions := cell * maxf(0.1, scale_factor)
	return Rect2(Vector2((size.x - dimensions.x) / 2.0, size.y - dimensions.y), dimensions)


func hair_point(index: int, height: float) -> Vector2:
	var area := portrait_rect()
	return area.position + Vector2((index + 0.5) / STRANDS, height) * area.size


func reachable_point(index: int) -> Vector2:
	# Short bobs expose less hair: painting and keyboard input use a visible strand.
	var preferred := minf(0.68, float(lengths[index]) - 0.03)
	for step in range(48):
		var y := preferred - step * 0.012
		if _hair_hit(Vector2((index + 0.5) / STRANDS, y)):
			return hair_point(index, y)
	return hair_point(index, 0.18)


func _gui_input(event: InputEvent) -> void:
	if not input_enabled or read_only:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		cursor = event.position
		dragging = event.pressed
		if event.pressed:
			grab_focus()
			last_local = cursor
			apply_at(cursor, 0.06)
		accept_event()
	elif event is InputEventMouseMotion:
		cursor = event.position
		mouse_inside = true
		if dragging and current_tool != "cut":
			var distance := cursor.distance_to(last_local)
			if distance > 2.0:
				var steps := maxi(1, ceili(distance / 12.0))
				for step in range(1, steps + 1):
					var at := last_local.lerp(cursor, float(step) / steps)
					apply_at(at, 0.06, cursor - last_local)
				last_local = cursor
		queue_redraw()
	elif event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_4:
			set_tool(TOOLS[event.keycode - KEY_1])
		elif event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT:
			keyboard_index = wrapi(keyboard_index + (-1 if event.keycode == KEY_LEFT else 1), 0, active_strands.size())
			if current_tool == "cut":
				keyboard_height = target_for(active_strands[keyboard_index])
		elif event.keycode == KEY_UP or event.keycode == KEY_DOWN:
			keyboard_height = clampf(keyboard_height + (-0.025 if event.keycode == KEY_UP else 0.025), 0.13 if current_tool == "dye" else 0.51, 0.96)
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			cursor = hair_point(active_strands[keyboard_index], keyboard_height) if current_tool in ["cut", "dye"] else reachable_point(active_strands[keyboard_index])
			apply_at(cursor, 0.35, Vector2(0, 28))
		else:
			return
		mouse_inside = false
		queue_redraw()
		accept_event()


func apply_at(at: Vector2, strength: float, motion: Vector2 = Vector2.ZERO) -> bool:
	if read_only or not input_enabled:
		return false
	var area := portrait_rect()
	var normalized := (at - area.position) / area.size
	if current_tool == "dye":
		return _paint_at(normalized, strength)
	if not _hair_hit(normalized):
		return false
	var middle := clampi(int(normalized.x * STRANDS), 0, STRANDS - 1)
	var did_work := false
	if current_tool == "cut":
		if service_phase != "cut" or normalized.y < 0.50:
			return false
		undo_stack.append({"lengths": lengths.duplicate(), "touched": touched.duplicate(), "errors": errors, "snips": snips})
		if undo_stack.size() > 12:
			undo_stack.pop_front()
		for index in range(maxi(0, middle - 1), mini(STRANDS, middle + 2)):
			if index not in active_strands or normalized.y >= float(lengths[index]) - 0.004:
				continue
			var old_end := float(lengths[index])
			lengths[index] = clampf(normalized.y, 0.5, old_end)
			touched[index] = true
			falling.append({"strip": index, "top": float(lengths[index]), "bottom": old_end,
				"offset": Vector2.ZERO, "velocity": Vector2(randf_range(-35, 35), 30), "life": 1.35})
			did_work = true
		if did_work:
			_rebuild_paint_area()
			snips += 1
			if normalized.y < target_for(middle) - 0.07:
				errors += 1
				_react("Cuidado con el largo. Puedes deshacer ese corte.", false)
			elif snips % 4 == 0:
				_react("¡Así va tomando forma!", true)
	else:
		for index in range(maxi(0, middle - 2), mini(STRANDS, middle + 3)):
			if index not in active_strands:
				continue
			match current_tool:
				"comb":
					if service_phase != "style" or motion.y <= 0.0: continue
					combed[index] = minf(1.0, float(combed[index]) + strength * 2.4)
				"dry":
					if service_phase != "style": continue
					dried[index] = minf(1.0, float(dried[index]) + strength * 1.8)
			did_work = true
	if did_work:
		if sound_in <= 0.0:
			tool_sound.emit({"cut": "scissors", "dye": "tint", "comb": "comb", "dry": "dryer"}[current_tool])
			sound_in = 0.16 if current_tool == "cut" else 0.35
		changed.emit()
		queue_redraw()
	return did_work


func _hair_hit(point: Vector2) -> bool:
	if point.x < 0.0 or point.x >= 1.0 or point.y < 0.12 or point.y >= 0.98:
		return false
	var index := clampi(int(point.x * STRANDS), 0, STRANDS - 1)
	if point.y > float(lengths[index]):
		return false
	var pixel := Vector2i(int((point.x + 1.0) * cell.x), int(point.y * cell.y))
	var front_pixel := Vector2i(int((point.x + 2.0) * cell.x), int(point.y * cell.y))
	# Foreground locks can be painted even beside the face. Skin never receives paint.
	if pixels.get_pixelv(front_pixel).a > 0.65:
		return true
	if point.y >= 0.14 and point.y <= 0.56 and pixels.get_pixel(int(point.x * cell.x), int(point.y * cell.y)).a > 0.65:
		return false
	return pixels.get_pixelv(pixel).a > 0.65


func _rebuild_paint_area() -> void:
	paint_cells.clear()
	for row in range(PAINT_ROWS):
		for column in range(STRANDS):
			var point := Vector2((column + 0.5) / STRANDS, (row + 0.5) / PAINT_ROWS)
			if _hair_hit(point):
				paint_cells.append(row * STRANDS + column)
	_refresh_dye_columns()


func _refresh_dye_columns() -> void:
	var totals: Array = []
	var counts: Array = []
	totals.resize(STRANDS)
	totals.fill(0.0)
	counts.resize(STRANDS)
	counts.fill(0)
	for index: int in paint_cells:
		var column := index % STRANDS
		totals[column] += float(paint[index])
		counts[column] += 1
	for column in range(STRANDS):
		dyed[column] = float(totals[column]) / counts[column] if counts[column] > 0 else 1.0


func _paint_at(point: Vector2, strength: float) -> bool:
	if service_phase != "cut" or point.x < -0.1 or point.x > 1.1 or point.y < 0.0 or point.y > 1.0:
		return false
	var left := clampi(floori((point.x - BRUSH_RADIUS.x) * STRANDS), 0, STRANDS - 1)
	var right := clampi(ceili((point.x + BRUSH_RADIUS.x) * STRANDS), 0, STRANDS - 1)
	var top := clampi(floori((point.y - BRUSH_RADIUS.y) * PAINT_ROWS), 0, PAINT_ROWS - 1)
	var bottom := clampi(ceili((point.y + BRUSH_RADIUS.y) * PAINT_ROWS), 0, PAINT_ROWS - 1)
	var applied := false
	for row in range(top, bottom + 1):
		for column in range(left, right + 1):
			var index := row * STRANDS + column
			if index not in paint_cells:
				continue
			var center := Vector2((column + 0.5) / STRANDS, (row + 0.5) / PAINT_ROWS)
			var distance := ((center - point) / BRUSH_RADIUS).length()
			if distance >= 1.0:
				continue
			var amount := clampf(strength * 14.0, 0.08, 1.0) * (1.0 - smoothstep(0.55, 1.0, distance))
			var value := minf(1.0, float(paint[index]) + amount)
			if value > float(paint[index]) + 0.0001:
				paint[index] = value
				applied = true
	if applied:
		paint_dirty = true
		_refresh_dye_columns()
		if sound_in <= 0.0:
			tool_sound.emit("tint")
			sound_in = 0.35
		changed.emit()
		queue_redraw()
	return applied


func _upload_paint() -> void:
	if paint_texture == null:
		return
	for row in range(PAINT_ROWS):
		for column in range(STRANDS):
			paint_image.set_pixel(column, row, Color(float(paint[row * STRANDS + column]), 0, 0, 1))
	paint_texture.update(paint_image)
	paint_dirty = false


func _react(text: String, good: bool) -> void:
	reaction = text
	reaction_in = 2.4
	comment.emit(text, good)


func _process(delta: float) -> void:
	if not input_enabled and not read_only:
		return
	elapsed += delta
	if paint_dirty:
		_upload_paint()
	sound_in = maxf(0.0, sound_in - delta)
	reaction_in = maxf(0.0, reaction_in - delta)
	if face_material != null:
		var blink := maxf(0.0, 1.0 - absf(fmod(elapsed, 4.3) - 0.13) / 0.10)
		face_material.set_shader_parameter("blink", blink)
		face_material.set_shader_parameter("talking", 1.0 if speaking else 0.0)
		face_material.set_shader_parameter("wet_coat", service_phase == "cut" and not read_only)
	if dragging and current_tool in ["dry", "dye"] and mouse_inside and not read_only:
		apply_at(cursor, delta)
	for part: Dictionary in falling:
		part.life -= delta
		part.velocity.y += 420.0 * delta
		part.offset += part.velocity * delta
	falling = falling.filter(func(part: Dictionary) -> bool: return part.life > 0.0)
	if not read_only:
		queue_redraw()
		if is_instance_valid(overlay):
			overlay.queue_redraw()


func _draw_backdrop() -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.97, 0.94, 0.86, 0.94)
	frame.border_color = Color("d5af6f")
	frame.set_border_width_all(3)
	frame.set_corner_radius_all(30)
	backdrop.draw_style_box(frame, Rect2(Vector2(8, 4), size - Vector2(16, 8)))


func _draw() -> void:
	if sheet == null:
		return
	var area := portrait_rect()
	# Cape first; rear hair lies over it. The face is composited above the hair.
	_draw_layer(area, 0, Rect2(0, 0.53, 1, 0.47))
	for index in range(STRANDS):
		_draw_strand(area, index, 0.0, float(lengths[index]))
	if service_phase == "style" and level_index == 1 and choice == 1:
		_draw_bun(area, _average(dried))
	_draw_layer(area, 0, Rect2(0, 0.14, 1, 0.42))
	# The foreground cap uses the same registration as the bald portrait.
	for index in range(STRANDS):
		_draw_layer(area, 2, Rect2(float(index) / STRANDS, 0, 1.0 / STRANDS + 0.0008, float(lengths[index])))
	for part: Dictionary in falling:
		var shifted := Rect2(area.position + part.offset, area.size)
		_draw_strand(shifted, int(part.strip), float(part.top), float(part.bottom), clampf(float(part.life), 0.0, 1.0))


func _draw_overlays() -> void:
	if sheet == null:
		return
	var area := portrait_rect()
	if service_phase == "style" and (_average(dried) > 0.5 or read_only):
		if accessory or level_index == 1:
			var oversized := level_index == 1 and choice == 2
			var dimension := 0.28 if oversized else 0.10
			var placement := Rect2(area.position + Vector2(0.72, 0.20) * area.size, Vector2.ONE * area.size.x * dimension)
			overlay.draw_texture_rect_region(ACCESSORY_SHEET, placement, Rect2(0, 256 if oversized else 0, 256, 256))
	if read_only:
		return
	if guide and service_phase == "cut" and current_tool == "cut":
		for index: int in active_strands:
			var from := area.position + Vector2(float(index) / STRANDS, target_for(index)) * area.size
			var to := from + Vector2(area.size.x / STRANDS * 0.75, 0)
			overlay.draw_line(from, to, GOLD, 3.0, true)
		var start := area.position + Vector2(0.04, target_length) * area.size
		overlay.draw_string(ThemeDB.fallback_font, start - Vector2(0, 12), "LARGO SOLICITADO", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)
	if guide and current_tool == "dye":
		for index: int in paint_cells:
			if index % 2 == 0 and floori(float(index) / STRANDS) % 3 == 0 and float(paint[index]) < 0.7:
				var point := Vector2((index % STRANDS + 0.5) / STRANDS, (floori(float(index) / STRANDS) + 0.5) / PAINT_ROWS)
				overlay.draw_circle(area.position + point * area.size, 2.6, Color(0.96, 0.52, 0.40, 0.75))
	if reaction_in > 0.0:
		var bubble := Rect2(18, 14, size.x - 36, 60)
		var box := StyleBoxFlat.new()
		box.bg_color = PAPER
		box.set_corner_radius_all(16)
		overlay.draw_style_box(box, bubble)
		overlay.draw_string(ThemeDB.fallback_font, bubble.position + Vector2(14, 37), reaction, HORIZONTAL_ALIGNMENT_CENTER, bubble.size.x - 28, 19, INK)
	if mouse_inside or has_focus():
		var keyboard_at := hair_point(active_strands[keyboard_index], keyboard_height) if current_tool in ["cut", "dye"] else reachable_point(active_strands[keyboard_index])
		var at := cursor if mouse_inside else keyboard_at
		_draw_cursor(at)
	for index in range(active_strands.size()):
		var strand: int = active_strands[index]
		var completed := 1.0 if bool(touched[strand]) else 0.0
		if current_tool != "cut":
			completed = float({"dye": dyed, "comb": combed, "dry": dried}[current_tool][strand])
		var width := (size.x - 52) / active_strands.size()
		var bar := Rect2(26 + index * width, size.y - 13, maxf(1, width - 2), 4)
		overlay.draw_rect(bar, Color("5d9b8e") if completed >= 0.86 else Color("cbbfa9"))
	if has_focus():
		overlay.draw_rect(Rect2(Vector2(10, 6), size - Vector2(20, 12)), GOLD, false, 2.0)


func _draw_layer(area: Rect2, column: int, crop: Rect2, color: Color = Color.WHITE) -> void:
	var destination := Rect2(area.position + crop.position * area.size, crop.size * area.size)
	var source := Rect2((crop.position + Vector2(column, 0)) * cell, crop.size * cell)
	draw_texture_rect_region(sheet, destination, source, color)


func _draw_bun(area: Rect2, amount: float) -> void:
	if amount <= 0.01:
		return
	var center := area.position + Vector2(0.60, 0.16) * area.size
	var radius := Vector2(0.18, 0.065) * area.size * amount
	var polygon := PackedVector2Array()
	var uvs := PackedVector2Array()
	for index in range(48):
		var angle := TAU * index / 48.0
		var unit := Vector2(cos(angle), sin(angle))
		polygon.append(center + unit * radius)
		uvs.append(Vector2((1.25 + unit.x * 0.055) / 3.0, 0.76 + unit.y * 0.045))
	draw_polygon(polygon, PackedColorArray([Color.WHITE]), uvs, sheet)
	for turn in range(4):
		draw_arc(center, radius.x * (0.35 + turn * 0.16), PI * 1.05, TAU * 0.95, 32, Color(0.95, 0.7, 0.42, 0.24 * amount), 1.4, true)


func _draw_strand(area: Rect2, index: int, top: float, bottom: float, alpha: float = 1.0) -> void:
	var sway := (sin(elapsed * 2.0 + index * 0.4) * 0.0018 if not read_only else 0.0)
	if current_tool == "dry" and dragging:
		sway *= 5.0
	var color := Color.WHITE
	color.a = alpha
	var styled := service_phase == "style" and _average(dried) > 0.0
	var updo := styled and level_index == 1 and choice == 1
	var finish_amount := _average(dried) if styled else 0.0
	var visible_bottom := lerpf(bottom, minf(bottom, 0.54), finish_amount) if updo else bottom
	var waves := styled and ((level_index != 1 and choice == 1 and level_index == 0) or (choice == 0 and level_index > 0))
	var bands := 40 if waves else 1
	for band in range(bands):
		var band_top := maxf(top, float(band) / bands)
		var band_bottom := minf(visible_bottom, float(band + 1) / bands)
		if band_bottom <= band_top:
			continue
		var wave := sin(band_top * 24.0 + index * 0.08) * 0.032 * finish_amount if waves else 0.0
		var displaced := Rect2(area.position + Vector2((sway + wave) * area.size.x, 0), area.size)
		var crop := Rect2(float(index) / STRANDS, band_top, 1.0 / STRANDS + 0.0008, band_bottom - band_top + 0.0007)
		_draw_layer(displaced, 1, crop, color)
	# Combed strands catch a restrained highlight; blow-drying adds volume.
	if float(dried[index]) > 0.0 and index in active_strands:
		var p := area.position + Vector2((index + 0.5) / STRANDS, minf(visible_bottom - 0.02, 0.66)) * area.size
		draw_circle(p, 1.4, Color(1.0, 0.93, 0.73, float(dried[index]) * 0.35))


func _draw_cursor(at: Vector2) -> void:
	var color := GOLD if _hair_hit((at - portrait_rect().position) / portrait_rect().size) else Color(0.7, 0.7, 0.7, 0.75)
	if current_tool == "cut":
		var gap := 10.0 + sin(elapsed * 14.0) * (5.0 if dragging else 0.0)
		overlay.draw_circle(at + Vector2(-20, -gap), 7, INK, false, 3, true)
		overlay.draw_circle(at + Vector2(-20, gap), 7, INK, false, 3, true)
		overlay.draw_line(at + Vector2(-12, -gap), at + Vector2(25, gap), color, 4, true)
		overlay.draw_line(at + Vector2(-12, gap), at + Vector2(25, -gap), color, 4, true)
	else:
		overlay.draw_arc(at, 22, 0, TAU, 32, color, 2, true)
		if current_tool == "dye":
			overlay.draw_line(at + Vector2(2, -1), at + Vector2(25, -38), INK, 9, true)
			var bristles := PackedVector2Array([at + Vector2(-14, 3), at + Vector2(5, 14), at + Vector2(14, -2), at + Vector2(-4, -12)])
			overlay.draw_colored_polygon(bristles, Color("c49a69"))
			for strand in range(5):
				overlay.draw_line(at + Vector2(-10 + strand * 4, 5 + strand * 2), at + Vector2(-3 + strand * 3, -5 + strand * 2), PAPER, 1.4, true)
		elif current_tool == "comb":
			overlay.draw_line(at + Vector2(-25, -8), at + Vector2(25, -8), INK, 7, true)
			for tooth in range(9):
				var x := -23.0 + tooth * 5.8
				overlay.draw_line(at + Vector2(x, -6), at + Vector2(x, 17), GOLD, 3, true)
		else:
			var tool_cell := Vector2(TOOL_SHEET.get_size()) / Vector2(3, 1)
			var column := 1 if current_tool == "dye" else 2
			overlay.draw_texture_rect_region(TOOL_SHEET, Rect2(at - Vector2(36, 36), Vector2(72, 72)), Rect2(Vector2(column * tool_cell.x, 0), tool_cell))


func _average(values: Array) -> float:
	var total := 0.0
	for value: Variant in values:
		total += float(value)
	return total / maxf(1.0, values.size())
