extends SceneTree
## Clicks on the neighbourhood map like a player would: a place's sign, and
## a building right after dragging the map (the first click must count).
##   godot --path . -s res://tools/map_click_test.gd -- --ui-test

var _screen: Node
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _mouse(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	get_root().push_input(e, true)


func _move(pos: Vector2, rel: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.relative = rel
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_root().push_input(e, true)


func _click(pos: Vector2) -> void:
	_mouse(pos, true)
	await process_frame
	_mouse(pos, false)
	for i in 4:
		await process_frame


func _chosen() -> String:
	var ids: Array = _screen.get("_stage_ids")
	return ids[int(_screen.get("_stage_index"))]


func _run() -> void:
	change_scene_to_file("res://scenes/character_select.tscn")
	for i in 30:
		await process_frame
	_screen = current_scene
	var map: Control = _screen.get("_district")
	var pins: Dictionary = map.get("_pins")
	# 1. The basement's sign.
	await _click((pins["BASEMENT"] as Control).get_global_rect().get_center())
	_check("click on a sign", _chosen(), "BASEMENT")
	# 2. A drag, then straight away a click on the supermarket building.
	var c := map.get_global_rect().get_center()
	_mouse(c, true)
	for i in 5:
		_move(c + Vector2(i * 8, 0), Vector2(8, 0))
		await process_frame
	_mouse(c + Vector2(40, 0), false)
	for i in 30:
		await process_frame
	var view: Rect2 = map.call("view_rect", "SUPERMARKET")
	var px: float = map.get("px")
	# Look straight at the supermarket (clear of the minimap in the corner).
	var cam: Vector2 = view.get_center() - map.call("view_size") * 0.5
	map.set("cam", cam)
	map.set("_cam_to", cam)
	for i in 3:
		await process_frame
	var at := map.get_global_rect().position + (view.get_center() - cam) * px
	await _click(at)
	_check("click on a building right after a drag", _chosen(), "SUPERMARKET")
	print("UI: done, %d failures" % _failures)
	quit()


func _check(what: String, got: String, want: String) -> void:
	if got != want:
		_failures += 1
		print("UI: FAIL %s (got %s, want %s)" % [what, got, want])
