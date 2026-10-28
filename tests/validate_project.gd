extends SceneTree
## Checks project setup and the empty UI at several window sizes.

var failures: PackedStringArray = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_expect(root.content_scale_size == Vector2i(1920, 1080), "Design size: 1920 x 1080")
	_expect(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS, "Canvas items scaling")
	_expect(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_EXPAND, "Expand aspect ratio")
	_expect(not root.unresizable, "Resizable window")
	_expect(root.content_scale_size.x > root.content_scale_size.y, "Landscape design")

	var main_path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	var main_scene := load(main_path) as PackedScene
	if main_scene == null:
		failures.append("Main scene could not be loaded")
		_finish()
		return

	var scene_instance := main_scene.instantiate()
	root.add_child(scene_instance)
	current_scene = scene_instance
	_expect(current_scene is Node2D, "2D root scene")
	var interface := current_scene.get_node_or_null("UI/Interface") as Control
	if interface == null:
		failures.append("UI root is missing")
		_finish()
		return

	for window_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080), Vector2i(1280, 1024)]:
		root.size = window_size
		await process_frame
		await process_frame
		var viewport_size := root.get_visible_rect().size
		_expect(viewport_size.x > 0 and viewport_size.y > 0, "Positive viewport size")
		_expect(interface.position.is_equal_approx(Vector2.ZERO), "UI origin at %s" % window_size)
		_expect(interface.size.is_equal_approx(viewport_size), "UI fills viewport at %s" % window_size)
		print("Layout checked: window=%s viewport=%s UI=%s" % [window_size, viewport_size, interface.size])

	_finish()


func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: project setup, main scene and responsive UI")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
