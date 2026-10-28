extends Button

var tool_id := ""


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return not disabled and data is Dictionary and data.get("salon_tool", "") == tool_id


func _drop_data(_at_position: Vector2, _data: Variant) -> void:
	pressed.emit()
