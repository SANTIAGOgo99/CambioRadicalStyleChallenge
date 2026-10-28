class_name SalonCharacter
extends TextureRect

static var frame_metadata: Dictionary = {}

var atlas: Texture2D
var columns := 3
var rows := 2
var pose := 0
var frame_regions: Dictionary = {}
var breathing: Tween


func setup(source: Texture2D, column_count: int = 3, row_count: int = 2) -> void:
	atlas = source
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
	if sheet == null:
		return
	var cell := Vector2(sheet.get_size()) / Vector2(columns, rows)
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
		part.margin = Rect2(Vector2(cell.x / 2.0 - float(entry.head_x), cell.y - float(area[3])), cell - Vector2(float(area[2]), float(area[3])))
	part.filter_clip = true
	texture = part


func react() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.15, 1.12, 1.0), 0.12)
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)
