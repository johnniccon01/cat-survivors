class_name BoxBoard
extends Control
## One decoration of the shoe-box look, drawn in code: a piece of cardboard
## ("board", "light", "dark"), a strip of tape ("tape"), a red marker line
## ("scribble") or a paw stamp ("stamp"). Turn it with `rotation_degrees`;
## labels can be added as children and turn with it. Paw bullets
## (`bullets`: centres, in its own coordinates) are drawn on top.

var kind := "board"
var look_seed := 1
var bullets: Array[Vector2] = []
var bullet_size := 20.0


static func make(kind_: String, pos: Vector2, size_: Vector2, seed_: int, deg: float = 0.0) -> BoxBoard:
	var b := BoxBoard.new()
	b.kind = kind_
	b.look_seed = seed_
	b.position = pos
	b.size = size_
	b.rotation_degrees = deg
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.resized.connect(func() -> void: b.pivot_offset = b.size * 0.5)
	b.pivot_offset = size_ * 0.5
	return b


func _draw() -> void:
	match kind:
		"board":
			BoxStyle.draw_board(self, size, look_seed, Color("cfa06b"), Color("a67444"))
		"light":
			BoxStyle.draw_board(self, size, look_seed, Color("f7ecd0"), Color("eadbb4"), Transform2D.IDENTITY, Vector2(5, 6), Color(0.31, 0.19, 0.08, 0.07))
		"dark":
			BoxStyle.draw_board(self, size, look_seed, Color("6f4b2b"), Color("563a22"), Transform2D.IDENTITY, Vector2(5, 6), Color(0, 0, 0, 0.18))
		"tape":
			BoxStyle.draw_tape(self, size, look_seed)
		"scribble":
			BoxStyle.draw_scribble(self, size.x, size.y, look_seed)
		"stamp":
			BoxStyle.draw_paw_stamp(self, size * 0.5, minf(size.x, size.y) * 0.9, look_seed, Color("cfa06b"))
	for p in bullets:
		BoxStyle.draw_paw(self, p, bullet_size, BoxStyle.RED, -12.0)
