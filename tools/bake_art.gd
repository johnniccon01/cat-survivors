extends SceneTree
## Bakes the weapon and skill icons (Icons.draw_vector, drawn on a 16 grid)
## and the projectiles into small pixel-art pictures in assets/sprites, which
## the game shows scaled up crisp. Needs a window (not --headless), then an
## import:
##   godot --path . -s res://tools/bake_art.gd -- --ui-test
##   godot --headless --path . --import
## (The work is in bake_art_body.gd, loaded once the autoloads are up.)

var _t := 0
var _body: Object


func _process(_d: float) -> bool:
	_t += 1
	if _t == 3:
		_body = load("res://tools/bake_art_body.gd").new()
		_body.call("start", self)
	if _body != null:
		return _body.call("step")
	return false
