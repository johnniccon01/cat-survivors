class_name Shrine
extends Node2D
## A cat shrine that turns up on the map now and then (Death Must Die-like).
## Stand next to it for a moment to wake it:
##   MIGHT   – stronger attacks for a while
##   HASTE   – faster paws and weapons for a while
##   MILK    – heals and keeps healing for a while
##   FORTUNE – a shower of gold and every kibble on the map flies to you
##   CURSED  – guards appear; beat them all for a treasure chest

const OUTLINE := Color("2b1d14")
const RADIUS := 48.0
const WAKE_TIME := 2.0
const BLESS_SECONDS := 45.0
const CURSED_GUARDS := 5
const CURSED_LIMIT := 75.0
## Forgotten shrines crumble after a while.
const LIFETIME := 100.0
const KINDS := {"MIGHT": 3.0, "HASTE": 3.0, "MILK": 2.0, "FORTUNE": 2.0, "CURSED": 2.5}
const COLORS := {
	"MIGHT": Color("ff5a4a"), "HASTE": Color("6cc8ff"), "MILK": Color("8ee07a"),
	"FORTUNE": Color("f2c14e"), "CURSED": Color("b06aff"),
}

var kind := "MIGHT"
var main: Node
var used := false
var _wake := 0.0
var _t := 0.0
var _gone := 0.0
var _guards: Array[Enemy] = []
var _guard_t := 0.0


static func random_kind() -> String:
	var total := 0.0
	for k: String in KINDS:
		total += float(KINDS[k])
	var r := randf() * total
	for k: String in KINDS:
		r -= float(KINDS[k])
		if r <= 0.0:
			return k
	return "MIGHT"


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -3
	add_to_group("shrine")


func color() -> Color:
	return COLORS.get(kind, Color.WHITE)


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	var cat: Player = main.player
	if used:
		if not _guards.is_empty():
			_tick_guards(delta)
		else:
			_gone += delta
			if _gone > 3.0:
				queue_free()
		return
	if _t > LIFETIME or cat.position.distance_to(position) > 1600.0:
		queue_free()
		return
	if not cat.is_dead and cat.position.distance_to(position) < RADIUS:
		_wake += delta
		if _wake >= WAKE_TIME:
			_activate(cat)
	else:
		_wake = maxf(_wake - delta * 0.5, 0.0)


func _activate(cat: Player) -> void:
	used = true
	Profile.add_stat("shrines")
	Audio.play("bell", -2.0, 0.0)
	match kind:
		"MIGHT":
			cat.bless({"might": 0.3}, BLESS_SECONDS)
		"HASTE":
			cat.bless({"speed": 0.2, "cooldown": -0.15}, BLESS_SECONDS)
		"MILK":
			cat.heal(cat.max_hp * 0.4)
			cat.bless({"regen": 1.5}, BLESS_SECONDS)
		"FORTUNE":
			for i in 12:
				main.pickups.spawn_named("coin", position + Vector2.from_angle(TAU * i / 12.0) * 26.0, 5.0)
			main.pickups.pull_all_xp()
		"CURSED":
			for i in CURSED_GUARDS:
				var guard: Enemy = main.spawner.spawn_guard(position + Vector2.from_angle(TAU * i / CURSED_GUARDS + randf()) * 230.0)
				if guard != null:
					_guards.append(guard)
	main.hud.show_banner(tr("SHRINE_%s_DONE" % kind), 4.0)
	print("SHRINE: %s activated" % kind)


func _tick_guards(delta: float) -> void:
	_guard_t += delta
	for i in range(_guards.size() - 1, -1, -1):
		if not is_instance_valid(_guards[i]) or _guards[i].dead:
			_guards.remove_at(i)
	if not _guards.is_empty() and _guard_t < CURSED_LIMIT:
		return
	if _guard_t < CURSED_LIMIT:
		main.pickups.spawn_named("chest", position, 0.0)
		for i in 8:
			main.pickups.spawn_named("coin", position + Vector2.from_angle(TAU * i / 8.0) * 22.0, 5.0)
		main.hud.show_banner(tr("SHRINE_CURSED_WON"), 3.5)
		print("SHRINE: CURSED cleared")
	_guards.clear()


func _draw() -> void:
	var c := color()
	var fade := 1.0 - clampf(_gone / 3.0, 0.0, 1.0)
	modulate.a = fade
	if not used:
		# The circle to stand in, and how far it has woken up.
		draw_circle(Vector2.ZERO, RADIUS, Color(c, 0.08 + 0.04 * sin(_t * 3.0)))
		draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 40, Color(c, 0.55), 2.0)
		if _wake > 0.0:
			draw_arc(Vector2.ZERO, RADIUS + 5.0, -PI * 0.5, -PI * 0.5 + TAU * _wake / WAKE_TIME, 40, c.lightened(0.3), 4.0)
	elif not _guards.is_empty():
		draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 40, Color(c, 0.35 + 0.25 * sin(_t * 8.0)), 3.0)
	# Stone plinth with a little cat statue and a glowing gem.
	draw_colored_polygon(Shapes.ellipse(Vector2(0, 14), 20, 6), Color(0, 0, 0, 0.4))
	draw_rect(Rect2(-15, -2, 30, 16), OUTLINE)
	draw_rect(Rect2(-14, -1, 28, 14), Color("8c8478"))
	draw_rect(Rect2(-14, -1, 28, 3), Color("a8a094"))
	var body := Color("6a6258") if used else Color("b8b0a4")
	draw_circle(Vector2(0, -12), 9.0, OUTLINE)
	draw_circle(Vector2(0, -12), 8.0, body)
	draw_circle(Vector2(0, -24), 6.5, OUTLINE)
	draw_circle(Vector2(0, -24), 5.5, body)
	for side: float in [-1.0, 1.0]:
		var ear := PackedVector2Array([Vector2(side * 2, -28), Vector2(side * 6.5, -34), Vector2(side * 6, -25)])
		draw_colored_polygon(ear, body)
	var glow := 0.5 + 0.5 * sin(_t * 4.0)
	if not used:
		draw_circle(Vector2(0, -12), 6.0 + glow * 3.0, Color(c, 0.25))
	draw_circle(Vector2(0, -12), 3.5, c if not used else c.darkened(0.6))
	draw_circle(Vector2(-1, -13), 1.2, Color(1, 1, 1, 0.8 if not used else 0.2))
