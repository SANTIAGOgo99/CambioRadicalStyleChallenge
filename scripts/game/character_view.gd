class_name SalonCharacter
extends TextureRect

static var frame_metadata: Dictionary = {}

var atlas: Texture2D
var columns := 3
var rows := 2
var pose := 0
var frame_regions: Dictionary = {}
var breathing: Tween
var portrait_mode := false
var speaking := false
var blink_in := 3.0
var blink_time := 0.0
var current_sheet: Texture2D
var face_material: ShaderMaterial


func setup(source: Texture2D, column_count: int = 3, row_count: int = 2) -> void:
	atlas = source
	face_material = ShaderMaterial.new()
	face_material.shader = load("res://assets/ui/character_face.gdshader")
	material = face_material
	blink_in = randf_range(2.8, 5.5)
	if frame_metadata.is_empty():
		frame_metadata = JSON.parse_string(FileAccess.get_file_as_string("res://data/character_frames.json"))
	columns = column_count
	rows = row_count
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_pose(0)
	resized.connect(func() -> void: pivot_offset = Vector2(size.x / 2.0, size.y))
	breathing = create_tween().set_loops()
	breathing.tween_property(self, "scale:y", 1.008, 1.6).set_trans(Tween.TRANS_SINE)
	breathing.tween_property(self, "scale:y", 1.0, 1.6).set_trans(Tween.TRANS_SINE)


func show_pose(index: int, source: Texture2D = null) -> void:
	pose = index
	var sheet := source if source != null else atlas
	current_sheet = sheet
	if sheet == null:
		return
	var cell := Vector2(sheet.get_size()) / Vector2(columns, rows)
	var canvas := Vector2(cell.x * 1.35, cell.y)
	var part := AtlasTexture.new()
	part.atlas = sheet
	part.region = Rect2(Vector2(index % columns, floori(float(index) / columns)) * cell, cell)
	if source == null and frame_regions.has(index):
		part.region = frame_regions[index]
	var entries: Array = frame_metadata.get(sheet.resource_path.get_file(), [])
	if index < entries.size():
		var entry: Dictionary = entries[index]
		var area: Array = entry.region
		part.region = Rect2(float(area[0]), float(area[1]), float(area[2]), float(area[3]))
		# Align original frames by face and feet while keeping the generated PNGs intact.
		part.margin = Rect2(Vector2(canvas.x / 2.0 - float(entry.head_x), canvas.y - float(area[3])), canvas - Vector2(float(area[2]), float(area[3])))
		if portrait_mode and entry.has("portrait"):
			var crop: Array = entry.portrait
			part.region = Rect2(float(crop[0]), float(crop[1]), float(crop[2]), float(crop[3]))
			part.margin = Rect2()
		if entry.has("eyes"):
			var dimensions := Vector2(sheet.get_size())
			face_material.set_shader_parameter("eye_left", Vector2(entry.eyes[0][0], entry.eyes[0][1]) / dimensions)
			face_material.set_shader_parameter("eye_right", Vector2(entry.eyes[1][0], entry.eyes[1][1]) / dimensions)
			face_material.set_shader_parameter("eye_radius", Vector2(entry.eye_size[0], entry.eye_size[1]) / dimensions)
			face_material.set_shader_parameter("mouth_center", Vector2(entry.mouth[0], entry.mouth[1]) / dimensions)
			face_material.set_shader_parameter("mouth_radius", Vector2(entry.mouth_size[0], entry.mouth_size[1]) / dimensions)
	part.filter_clip = true
	texture = part
	face_material.set_shader_parameter("alternate_uniform", sheet.resource_path.ends_with("alex_original.png") and bool(Campaign.state.uniform_alt))


func _process(delta: float) -> void:
	if face_material == null:
		return
	blink_in -= delta
	if blink_in <= 0.0:
		blink_time = 0.18
		blink_in = randf_range(3.0, 5.4)
	blink_time = maxf(0.0, blink_time - delta)
	face_material.set_shader_parameter("blink", sin((blink_time / 0.18) * PI) if blink_time > 0.0 else 0.0)
	face_material.set_shader_parameter("talking", 1.0 if speaking else 0.0)


func set_talking(value: bool) -> void:
	speaking = value


func copy_appearance(other: SalonCharacter) -> void:
	show_pose(other.pose, other.current_sheet)


func react() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.15, 1.12, 1.0), 0.12)
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)
