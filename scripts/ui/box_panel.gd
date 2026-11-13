class_name BoxPanel
extends PanelContainer
## A container with a piece of cardboard ("board", "light", "dark", "red"...)
## drawn behind its content, a degree or two crooked. Extra decorations (strips
## of tape on the corners, a paw stamp) are added with `add_decor`: they sit at
## a corner of the panel and are not part of the layout.

var board: BoxBoard
var tilt := 0.0
var _decor: Array = []


## `pad` is left, top, right, bottom room between the edge and the content.
static func make(kind: String, seed_: int, pad: Vector4 = Vector4(16, 12, 16, 14), tilt_: float = 0.0) -> BoxPanel:
	var p := BoxPanel.new()
	var sb := StyleBoxEmpty.new()
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.tilt = tilt_
	p.board = BoxBoard.make(kind, Vector2.ZERO, Vector2(10, 10), seed_)
	p.add_child(p.board)
	return p


## Puts `node` at `anchor` (0..1 of the panel's size) plus `offset`, `size` big
## and turned by `deg`.
func add_decor(node: Control, anchor: Vector2, offset: Vector2, size_: Vector2, deg: float = 0.0) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	_decor.append([node, anchor, offset, size_, deg])


## Strips of tape across the top corners (and the bottom ones with `bottom`).
func add_corner_tapes(seed_: int, bottom: bool = false) -> void:
	var w := 92.0
	var h := 28.0
	add_decor(BoxBoard.make("tape", Vector2.ZERO, Vector2(w, h), seed_), Vector2(0, 0), Vector2(-w * 0.42, h * 0.1), Vector2(w, h), -38.0)
	add_decor(BoxBoard.make("tape", Vector2.ZERO, Vector2(w, h), seed_ + 1), Vector2(1, 0), Vector2(-w * 0.58, h * 0.1), Vector2(w, h), 40.0)
	if bottom:
		add_decor(BoxBoard.make("tape", Vector2.ZERO, Vector2(w, h), seed_ + 2), Vector2(0, 1), Vector2(-w * 0.42, -h * 1.1), Vector2(w, h), 38.0)
		add_decor(BoxBoard.make("tape", Vector2.ZERO, Vector2(w, h), seed_ + 3), Vector2(1, 1), Vector2(-w * 0.58, -h * 1.1), Vector2(w, h), -40.0)


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	fit_child_in_rect(board, Rect2(Vector2.ZERO, size))
	board.pivot_offset = size * 0.5
	board.rotation_degrees = tilt
	for d: Array in _decor:
		var node: Control = d[0]
		var anchor: Vector2 = d[1]
		fit_child_in_rect(node, Rect2(size * anchor + (d[2] as Vector2), d[3]))
		node.pivot_offset = node.size * 0.5
		node.rotation_degrees = d[4]
