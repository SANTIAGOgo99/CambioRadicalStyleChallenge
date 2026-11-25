extends Control
## Two real workbench renders, clipped by an accessible before/after slider.

const Workbench = preload("res://scripts/game/hair_workbench.gd")
var before_view: HairWorkbench
var after_view: HairWorkbench
var after_clip: Control
var split := 0.5
var slider: HSlider
var divider: Control


func setup(asset: String, look: Dictionary) -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	before_view = Workbench.new()
	add_child(before_view)
	before_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	before_view.offset_bottom = -65
	before_view.setup(asset, "cut", 0, int(look.get("level", 0)))
	before_view.read_only = true
	before_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	before_view.focus_mode = Control.FOCUS_NONE
	after_clip = Control.new()
	add_child(after_clip)
	after_clip.clip_contents = true
	after_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	after_view = Workbench.new()
	after_clip.add_child(after_view)
	after_view.setup(asset, str(look.get("phase", "cut")), int(look.get("choice", 0)), int(look.get("level", 0)), look)
	after_view.read_only = true
	after_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	after_view.focus_mode = Control.FOCUS_NONE
	divider = Control.new()
	add_child(divider)
	divider.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.draw.connect(_draw_divider)
	slider = HSlider.new()
	add_child(slider)
	slider.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	slider.offset_top = -54
	slider.offset_left = 35
	slider.offset_right = -35
	slider.max_value = 100
	slider.value = 50
	slider.tooltip_text = "Antes y después. Arrastra o usa las flechas para comparar tu trabajo."
	slider.value_changed.connect(func(value: float) -> void:
		split = value / 100.0
		_layout()
	)
	resized.connect(_layout)
	_layout.call_deferred()


func _layout() -> void:
	if not is_instance_valid(after_clip):
		return
	after_clip.position = Vector2.ZERO
	after_clip.size = Vector2(size.x * split, maxf(0.0, size.y - 65))
	after_view.position = Vector2.ZERO
	after_view.size = Vector2(size.x, maxf(0.0, size.y - 65))
	divider.queue_redraw()


func _draw_divider() -> void:
	var x := size.x * split
	divider.draw_line(Vector2(x, 10), Vector2(x, size.y - 65), Color("efc36b"), 3.0)
	divider.draw_circle(Vector2(x, (size.y - 65) / 2), 17, Color("efc36b"))
	divider.draw_string(ThemeDB.fallback_font, Vector2(x - 10, (size.y - 65) / 2 + 7), "↔", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("20494b"))
	divider.draw_string(ThemeDB.fallback_font, Vector2(24, size.y - 73), "DESPUÉS", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("20494b"))
	divider.draw_string(ThemeDB.fallback_font, Vector2(size.x - 95, size.y - 73), "ANTES", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("20494b"))
