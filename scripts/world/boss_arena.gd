class_name BossArena
extends Node2D
## When a boss arrives, a ring of thorns grows up around the cat and closes in
## for a minute (like the boss arenas in Death Must Die). The cat, the boss
## and every enemy are kept inside; a ring of the wave's enemies comes in at
## the start and again every RING_EVERY seconds. When the minute is over or
## the boss falls, the thorns sink back into the ground.

const START_RADIUS := 520.0
const END_RADIUS := 230.0
const CLOSE_TIME := 60.0
const RING_EVERY := 15.0
const RING_COUNT := 14
const SINK_TIME := 0.6

var spawner: Spawner
var manager: EnemyManager
var boss: Enemy
var radius := START_RADIUS

var _t := 0.0
var _ring_t := 0.0
## Seconds since the thorns started sinking (-1 while they stand).
var _sink := -1.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -2


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _sink >= 0.0:
		_sink += delta
		if _sink >= SINK_TIME:
			queue_free()
		return
	# A duel (or a newer boss) took the arena over.
	var taken: bool = not manager.arena.is_empty() and manager.arena.get("owner") != self and _t > 0.1
	if taken or _t >= CLOSE_TIME or not is_instance_valid(boss) or boss.dead:
		_open()
		return
	radius = lerpf(START_RADIUS, END_RADIUS, _t / CLOSE_TIME)
	manager.arena = {"center": position, "radius": radius, "inside": true, "owner": self}
	_ring_t -= delta
	if _ring_t <= 0.0:
		_ring_t = RING_EVERY
		spawner.spawn_ring(manager.player.position, minf(radius - 50.0, 240.0), RING_COUNT)


func _open() -> void:
	_sink = 0.0
	if manager.arena.get("owner") == self:
		manager.arena = {}


func _exit_tree() -> void:
	if manager != null and manager.arena.get("owner") == self:
		manager.arena = {}


func _draw() -> void:
	# Grows up in the first half second, sinks at the end.
	var k := minf(_t * 2.0, 1.0) * (1.0 - clampf(_sink / SINK_TIME, 0.0, 1.0) if _sink >= 0.0 else 1.0)
	if k <= 0.0:
		return
	var r := radius
	draw_arc(Vector2.ZERO, r + 14.0, 0.0, TAU, 96, Color(0.06, 0.08, 0.05, 0.85 * k), 28.0)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, Color(0.55, 0.15, 0.2, 0.5 * k), 2.0)
	# Thorns pointing in, swaying a little.
	var n := int(r * TAU / 22.0)
	for i in n:
		var a := TAU * i / n
		var out := Vector2.from_angle(a)
		var side := out.orthogonal() * 6.0
		var length := (12.0 + 8.0 * float(i % 3)) * k
		var tip := out * (r - length) + side * sin(_t * 2.0 + i) * 0.4
		draw_colored_polygon(PackedVector2Array([out * (r + 2.0) - side, out * (r + 2.0) + side, tip]), Color(0.12, 0.16, 0.1, k))
