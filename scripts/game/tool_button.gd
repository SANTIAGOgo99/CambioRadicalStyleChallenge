extends Button

var tool_id := ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	if disabled:
		return null
	var preview := TextureRect.new()
	preview.texture = icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(160, 160)
	preview.size = Vector2(160, 160)
	set_drag_preview(preview)
	return {"salon_tool": tool_id}
