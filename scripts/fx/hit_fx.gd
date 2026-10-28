class_name HitFx
extends Node2D
## A quick burst where a weapon hits: a ring that pops open and a few
## sparks in the weapon's colour. Capped so big crowds stay cheap.

const DURATION := 0.18
const MAX_ALIVE := 60
## Base weapon -> colour of its hits.
const COLORS := {
	"SCRATCH": Color("ffd0dc"), "YARN": Color("f28ac0"), "HAIRBALL": Color("c9a26a"),
	"CATNIP": Color("8ee07a"), "FISHBONES": Color("f4f1ea"), "LASER": Color("ff5a5a"),
	"MILK": Color("e8f4ff"), "BELL": Color("ffe066"), "FEATHER": Color("8fd3ff"),
	"MOUSE_TOY": Color("ffb35a"), "COBWEB": Color("f4f4f4"), "SPRINKLER": Color("7ad0ff"),
	"ANTENNA": Color("9ae0ff"), "FROST_FISH": Color("bfefff"),
}

static var alive := 0

var color := Color.WHITE
var _t := 0.0
var _angle := randf() * TAU


static func spawn(parent: Node, at: Vector2, weapon_id: String) -> void:
	if alive >= MAX_ALIVE * Settings.effects_scale() or parent == null:
		return
	var fx := HitFx.new()
	fx.position = at + Vector2(randf_range(-3, 3), randf_range(-3, 3))
	fx.color = COLORS.get(Icons.base_weapon(weapon_id), Color.WHITE)
	parent.add_child(fx)


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 5


func _enter_tree() -> void:
	alive += 1


func _exit_tree() -> void:
	alive -= 1


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / DURATION
	var a := 1.0 - k
	Blit.ring(self, Vector2.ZERO, 4.0 + 9.0 * k, 2.0, Color(color, 0.8 * a))
	Blit.disc(self, Vector2.ZERO, 3.5 * (1.0 - k), Color(1, 1, 1, a))
	for i in 4:
		var d := Vector2.from_angle(_angle + i * TAU / 4.0)
		Blit.line(self, d * (4.0 + 6.0 * k), d * (6.0 + 11.0 * k), Color(color, a), 1.5)
