class_name BossArena
extends Node2D
## The ground part of a final boss's fight (its "fight" in data/enemies.json):
## - arena "thorns": a ring of thorns grows up round the cat and closes in for
##   a minute (like the Necromancer's arena in Death Must Die), then sinks;
## - arena "water": the sea stands round the fight in a wide ring until the
##   boss falls;
## - "ring": a ring of the wave's enemies comes in every RING_EVERY seconds
##   (the Necromancer's skeletons).
## Inside an arena the cat, the boss and every enemy are kept in.

const START_RADIUS := 520.0
const END_RADIUS := 230.0
const CLOSE_TIME := 60.0
const WATER_RADIUS := 380.0
const RING_EVERY := 15.0
const RING_COUNT := 14
const SINK_TIME := 0.6

var spawner: Spawner
var manager: EnemyManager
var boss: Enemy
## "thorns", "water" or "" (no wall, only the rings of enemies).
var style := "thorns"
var rings := false
var radius := START_RADIUS

var _t := 0.0
var _ring_t := 0.0
## Seconds since the wall started sinking (-1 while it stands).
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
	var taken: bool = style != "" and not manager.arena.is_empty() and manager.arena.get("owner") != self and _t > 0.1
	var over := style == "thorns" and _t >= CLOSE_TIME
	if taken or over or not is_instance_valid(boss) or boss.dead:
		_open()
		return
	if style != "":
		radius = lerpf(START_RADIUS, END_RADIUS, _t / CLOSE_TIME) if style == "thorns" else WATER_RADIUS
		manager.arena = {"center": position, "radius": radius, "inside": true, "owner": self}
		if not BotLog.events.has("arena:" + style):
			BotLog.event("arena:" + style)
		# Nobody gets out (checked in test runs).
		if manager.player.position.distance_to(position) > radius + 2.0:
			BotLog.fail("the cat got out of the %s arena" % style)
		if boss.position.distance_to(position) > radius + 2.0:
			BotLog.fail("the boss got out of the %s arena (%.0f > %.0f, t=%.1f)" % [style, boss.position.distance_to(position), radius, _t])
	if rings:
		_ring_t -= delta
		if _ring_t <= 0.0:
			_ring_t = RING_EVERY
			var r := minf(radius - 50.0, 240.0) if style != "" else 240.0
			spawner.spawn_ring(manager.player.position, r, RING_COUNT)
			BotLog.event("ring")


func _open() -> void:
	BotLog.event("arena_open")
	_sink = 0.0
	if manager.arena.get("owner") == self:
		manager.arena = {}


func _exit_tree() -> void:
	if manager != null and manager.arena.get("owner") == self:
		manager.arena = {}


func _draw() -> void:
	if style == "":
		return
	# Grows up in the first half second, sinks at the end.
	var k := minf(_t * 2.0, 1.0) * (1.0 - clampf(_sink / SINK_TIME, 0.0, 1.0) if _sink >= 0.0 else 1.0)
	if k <= 0.0:
		return
	if style == "water":
		_draw_water(k)
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


## Deep water outside the ring, a lighter foam line rolling along its edge.
func _draw_water(k: float) -> void:
	var r := radius
	draw_arc(Vector2.ZERO, r + 60.0, 0.0, TAU, 96, Color(0.1, 0.3, 0.5, 0.75 * k), 120.0)
	draw_arc(Vector2.ZERO, r + 6.0, 0.0, TAU, 96, Color(0.25, 0.55, 0.75, 0.8 * k), 12.0)
	var n := int(r * TAU / 30.0)
	for i in n:
		var a := TAU * i / n + _t * 0.15
		var p := Vector2.from_angle(a) * (r + 2.0 + sin(_t * 3.0 + i) * 3.0)
		draw_circle(p, 4.0, Color(0.85, 0.95, 1.0, 0.7 * k))
