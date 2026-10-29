class_name Trap
extends Node2D
## A household hazard that hurts enemies and the cat alike, so it can be
## used tactically: lure enemies over it, keep your own paws off it.
##
## Types (data/traps.json):
##   snap  – a mousetrap: snaps on whatever steps in, then re-arms
##   pulse – a zone that switches on and off (hot stove, sparking puddle)
##   jet   – a steam pipe that blasts a line in front of it now and then

const OUTLINE := Color("2b1d14")

var id := ""
var data: Dictionary
var main: Node

## Set up before the full moon: hurts only enemies, never the cat.
var friendly := false
var _type := "snap"
var _active := true
var _timer := 0.0
var _tick := 0.0
var _dir := Vector2.RIGHT
var _t := 0.0
var _flash := 0.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -3


func setup(p_id: String, p_main: Node) -> void:
	id = p_id
	main = p_main
	data = GameData.traps[id]
	_type = data["type"]
	_dir = Vector2.from_angle(randi_range(0, 3) * PI * 0.5)
	# Stagger timers so traps don't all fire in sync.
	_active = _type == "snap"
	_timer = randf_range(0.0, float(data.get("off", 2.0)))


func _physics_process(delta: float) -> void:
	_t += delta
	_flash = maxf(_flash - delta, 0.0)
	match _type:
		"snap":
			_tick_snap(delta)
		_:
			_tick_cycle(delta)
	queue_redraw()


func _tick_snap(delta: float) -> void:
	if not _active:
		_timer -= delta
		if _timer <= 0.0:
			_active = true
		return
	var r := float(data["radius"])
	var victims: Array[Enemy] = main.enemies.query_radius(position, r)
	var cat_in: bool = position.distance_to(main.player.position) < r + Player.RADIUS
	if victims.is_empty() and not cat_in:
		return
	_active = false
	_flash = 0.2
	_timer = float(data["rearm"])
	Audio.play("hit", -4.0, 0.0)
	for e in victims:
		_hurt(e)
	if cat_in and not friendly:
		main.player.take_damage(float(data["player_damage"]))


func _tick_cycle(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_active = not _active
		_timer = float(data["on"] if _active else data["off"])
		_tick = 0.0
	if not _active:
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = float(data["tick"])
	var victims: Array[Enemy]
	var cat_hit := false
	if _type == "jet":
		var to := position + _dir * float(data["length"])
		var w := float(data["width"])
		victims = main.enemies.query_segment(position, to, w)
		var p: Vector2 = main.player.position
		cat_hit = Geometry2D.get_closest_point_to_segment(p, position, to).distance_to(p) < w + Player.RADIUS
	else:
		var r := float(data["radius"])
		victims = main.enemies.query_radius(position, r)
		cat_hit = position.distance_to(main.player.position) < r + Player.RADIUS
	for e in victims:
		_hurt(e)
	if cat_hit and not friendly:
		main.player.take_damage(float(data["player_damage"]))


func _hurt(e: Enemy) -> void:
	e.hit(float(data["damage"]), e.position - position, 0.6, false)
	if e.dead:
		Profile.add_stat("trap_kills")


## Where the trap hurts, always visible: a dashed warning ring (or lane for
## jets) that glows when the trap is live or about to switch on, and a small
## warning sign, so the cat never stands in a trap it can't see.
func _draw_danger() -> void:
	var warn := _active or (_type != "snap" and _timer < 0.8)
	var k := 0.5 + 0.5 * sin(_t * (8.0 if warn else 3.0))
	var color := Color(1.0, 0.3, 0.2) if warn else Color(1.0, 0.75, 0.25)
	var alpha := (0.55 + 0.35 * k) if warn else (0.3 + 0.15 * k)
	if Settings.high_contrast:
		alpha = minf(alpha * 1.5, 1.0)
	if _type == "jet":
		var length := float(data["length"])
		var w := float(data["width"])
		var side := _dir.orthogonal() * w
		var lane := PackedVector2Array([side, _dir * length + side, _dir * length - side, -side])
		draw_colored_polygon(lane, Color(color, 0.08 if warn else 0.04))
		draw_polyline(PackedVector2Array([lane[0], lane[1], lane[2], lane[3], lane[0]]), Color(color, alpha), 1.5)
	else:
		var r := float(data["radius"]) + (2.0 if _type == "snap" else 0.0)
		Blit.disc(self, Vector2.ZERO, r, Color(color, 0.10 if warn else 0.05))
		var dashes := 16
		for i in dashes:
			var a := TAU * i / dashes + _t * 0.4
			draw_arc(Vector2.ZERO, r, a, a + TAU / dashes * 0.55, 4, Color(color, alpha), 2.0)
	# Warning sign above the trap.
	var top := Vector2(0, -float(data.get("radius", 10.0)) - 12.0) if _type != "jet" else Vector2(0, -18)
	var tri := PackedVector2Array([top + Vector2(0, -7), top + Vector2(7, 5), top + Vector2(-7, 5)])
	draw_colored_polygon(tri, Color(color, minf(alpha + 0.2, 1.0)))
	draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color(OUTLINE, 0.8), 1.0)
	Blit.line(self, top + Vector2(0, -3), top + Vector2(0, 1), OUTLINE, 1.5)
	Blit.disc(self, top + Vector2(0, 3), 0.8, OUTLINE)


func _draw() -> void:
	_draw_danger()
	match id:
		"RAKE":
			# Tines down, handle up: steps on it and the handle swings.
			var handle := Vector2(0, -16) if _active else Vector2(-14, -4)
			Blit.line(self, Vector2.ZERO, handle, OUTLINE, 3.0)
			Blit.line(self, Vector2.ZERO, handle, Color("a47a50"), 1.5)
			draw_rect(Rect2(-8, -1, 16, 3), Color("6a6e72"))
			for x in range(-7, 9, 3):
				draw_line(Vector2(x, 2), Vector2(x, 5), Color("9aa0a6"), 1.0)
			if _flash > 0.0:
				Blit.disc(self, Vector2.ZERO, 12.0, Color(1, 1, 1, _flash * 2.0))
		"SPRINKLER":
			var r := float(data["radius"])
			Blit.disc(self, Vector2.ZERO, 5.0, OUTLINE)
			Blit.disc(self, Vector2.ZERO, 4.0, Color("4a8a4a"))
			if _active:
				for k in 8:
					var a := _t * 5.0 + k * TAU / 8.0
					var d := fposmod(_t * 50.0 + k * 7.0, r)
					Blit.disc(self, Vector2.from_angle(a) * d, 1.6, Color(0.7, 0.88, 1.0, 0.8 * (1.0 - d / r)))
				draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, r, r * 0.8, 16), Color(0.5, 0.75, 1.0, 0.12))
		"VENT":
			var side := _dir.orthogonal()
			draw_rect(Rect2(-8, -8, 16, 16), OUTLINE)
			draw_rect(Rect2(-7, -7, 14, 14), Color("8a9096"))
			for k in 3:
				draw_line(Vector2(-5, -4 + k * 4), Vector2(5, -4 + k * 4), Color("4a4e52"), 1.0)
			if _active:
				var length := float(data["length"])
				for k in 6:
					var d := fposmod(_t * 170.0 + k * length / 6.0, length)
					var spread := d / length * float(data["width"])
					Blit.disc(self, _dir * d + side * sin(_t * 6.0 + k) * spread * 0.5, 3.0 + spread * 0.5, Color(1.0, 0.85, 0.7, 0.5 * (1.0 - d / length)))
			elif _timer < 0.6:
				Blit.disc(self, _dir * 8.0, 2.0, Color(1, 0.8, 0.6, 0.6))
		"LIVE_WIRE":
			var r := float(data["radius"])
			draw_polyline(PackedVector2Array([Vector2(-r, -4), Vector2(-r * 0.3, 3), Vector2(r * 0.2, -3), Vector2(r, 4)]), OUTLINE, 3.0)
			draw_polyline(PackedVector2Array([Vector2(-r, -4), Vector2(-r * 0.3, 3), Vector2(r * 0.2, -3), Vector2(r, 4)]), Color("2a2a30"), 1.5)
			Blit.disc(self, Vector2(r, 4), 2.5, Color("c9a24a"))
			if _active:
				for k in 6:
					var a := _t * 11.0 + k * 1.1
					var p1 := Vector2.from_angle(a) * r * 0.7
					Blit.line(self, p1, p1 + Vector2.from_angle(a + 1.4) * 7.0, Color("9ae0ff"), 1.5)
				Blit.disc(self, Vector2.ZERO, r, Color(0.6, 0.9, 1.0, 0.14))
		"FREEZER":
			var side := _dir.orthogonal()
			draw_rect(Rect2(-9, -9, 18, 18), OUTLINE)
			draw_rect(Rect2(-8, -8, 16, 16), Color("e8f0f4"))
			for k in 3:
				draw_line(Vector2(-6, -4 + k * 4), Vector2(6, -4 + k * 4), Color("8ab4d0"), 1.0)
			if _active:
				var length := float(data["length"])
				for k in 7:
					var d := fposmod(_t * 160.0 + k * length / 7.0, length)
					var spread := d / length * float(data["width"])
					Blit.disc(self, _dir * d + side * sin(_t * 5.0 + k) * spread * 0.5, 2.5 + spread * 0.4, Color(0.8, 0.95, 1.0, 0.55 * (1.0 - d / length)))
			elif _timer < 0.6:
				Blit.disc(self, _dir * 9.0, 2.0, Color(0.8, 0.95, 1.0, 0.6))
		"BROKEN_LIGHT":
			var r := float(data["radius"])
			Blit.line(self, Vector2(-r, -2), Vector2(r * 0.8, 3), OUTLINE, 5.0)
			draw_line(Vector2(-r, -2), Vector2(r * 0.8, 3), Color("f4f1ea"), 3.0)
			for k in 3:
				draw_line(Vector2(r * 0.8 + k * 3, 3 + k), Vector2(r * 0.8 + k * 3 + 2, 1 + k), Color("c9d4dc"), 1.0)
			if _active:
				for k in 6:
					var a := _t * 13.0 + k * 1.1
					var p1 := Vector2(r * 0.8, 3) + Vector2.from_angle(a) * 5.0
					Blit.line(self, p1, p1 + Vector2.from_angle(a + 1.2) * 8.0, Color("fff3a0"), 1.5)
				Blit.disc(self, Vector2.ZERO, r, Color(1.0, 0.95, 0.6, 0.14))
		"FISH_HOOK":
			var hook := PackedVector2Array([Vector2(0, -12), Vector2(0, 2), Vector2(-3, 6), Vector2(-7, 4), Vector2(-7, 0)])
			draw_line(Vector2(0, -12), Vector2(0, -26), Color(0.9, 0.9, 0.9, 0.5), 1.0)
			draw_polyline(hook, OUTLINE, 3.0)
			draw_polyline(hook, Color("c9ced2"), 1.5)
			if _active:
				draw_colored_polygon(Shapes.ellipse(Vector2(-6, -2), 3, 2, 8), Color("e07a7a"))
			if _flash > 0.0:
				Blit.disc(self, Vector2.ZERO, 12.0, Color(1, 1, 1, _flash * 2.0))
		"TIDE_POOL":
			var r := float(data["radius"])
			draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, r, r * 0.7, 20), Color(0.25, 0.5, 0.7, 0.45))
			draw_polyline(Shapes.closed(Shapes.ellipse(Vector2.ZERO, r, r * 0.7, 20)), Color(0.15, 0.3, 0.45, 0.6), 1.0)
			if _active:
				for k in 3:
					var f := fposmod(_t * 0.8 + k / 3.0, 1.0)
					draw_polyline(Shapes.closed(Shapes.ellipse(Vector2.ZERO, r * f, r * 0.7 * f, 16)), Color(0.8, 0.6, 1.0, 0.7 * (1.0 - f)), 1.5)
				for k in 4:
					Blit.disc(self, Vector2.from_angle(_t * 1.5 + k * TAU / 4.0) * r * 0.5, 3.0, Color(0.8, 0.5, 1.0, 0.6))
		"ELECTRIC_FLOOR":
			var r := float(data["radius"])
			draw_rect(Rect2(-r, -r * 0.7, r * 2, r * 1.4), Color("3a3e44"))
			for k in 4:
				draw_line(Vector2(-r + 4, -r * 0.7 + 4 + k * r * 0.4), Vector2(r - 4, -r * 0.7 + 4 + k * r * 0.4), Color("6a6e72"), 1.0)
			if _active:
				for k in 6:
					var p1 := Vector2(randf_range(-r, r) * 0.8, randf_range(-r, r) * 0.5)
					Blit.line(self, p1, p1 + Vector2.from_angle(_t * 12.0 + k) * 7.0, Color("9ae0ff"), 1.5)
				draw_rect(Rect2(-r, -r * 0.7, r * 2, r * 1.4), Color(0.6, 0.9, 1.0, 0.18))
		"PRESS_PLATE":
			draw_rect(Rect2(-10, -10, 20, 20), OUTLINE)
			draw_rect(Rect2(-9, -9, 18, 18), Color("c9a24a") if _active else Color("6a6e72"))
			for k in 3:
				draw_line(Vector2(-9 + k * 6, -9), Vector2(-3 + k * 6, 9), Color("2b2b2b"), 2.0)
			if _flash > 0.0:
				Blit.disc(self, Vector2.ZERO, 14.0, Color(1, 1, 1, _flash * 2.0))
		"MOUSETRAP":
			draw_rect(Rect2(-8, -5, 16, 10), OUTLINE)
			draw_rect(Rect2(-7, -4, 14, 8), Color("c9a26a"))
			draw_rect(Rect2(-1, -4, 2, 8), Color("9aa0a6"))
			if _active:
				draw_line(Vector2(-6, -3), Vector2(-6, 3), Color("9aa0a6"), 1.0)
				draw_rect(Rect2(3, -1, 3, 2), Color("f2d14e"))
			else:
				draw_line(Vector2(6, -3), Vector2(6, 3), Color("9aa0a6"), 2.0)
			if _flash > 0.0:
				Blit.disc(self, Vector2.ZERO, 12.0, Color(1, 1, 1, _flash * 2.0))
		"STOVE":
			var r := float(data["radius"])
			draw_rect(Rect2(-r - 4, -r - 4, (r + 4) * 2, (r + 4) * 2), Color("3a3a40"))
			draw_rect(Rect2(-r - 4, -r - 4, (r + 4) * 2, (r + 4) * 2), OUTLINE, false, 1.0)
			var heat := Color("ff5a2a") if _active else Color("5a5a62")
			for k in 3:
				Blit.ring(self, Vector2.ZERO, r * (0.4 + k * 0.25) + 2.0 * 0.5, 2.0, heat)
			if _active:
				Blit.disc(self, Vector2.ZERO, r, Color(1.0, 0.35, 0.1, 0.18 + 0.08 * sin(_t * 12.0)))
		"SPARK_PUDDLE":
			var r := float(data["radius"])
			draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, r, r * 0.7, 16), Color(0.35, 0.55, 0.75, 0.6))
			if _active:
				for k in 5:
					var a := _t * 9.0 + k * 1.3
					var p1 := Vector2.from_angle(a) * r * 0.6 * Vector2(1, 0.7)
					var p2 := p1 + Vector2.from_angle(a + 1.5) * 8.0
					Blit.line(self, p1, p2, Color("fff26b"), 1.5)
				draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, r, r * 0.7, 16), Color(1, 1, 0.5, 0.15))
		"STEAM_PIPE":
			var side := _dir.orthogonal()
			Blit.line(self, -_dir * 10.0, Vector2.ZERO, OUTLINE, 9.0)
			Blit.line(self, -_dir * 10.0, Vector2.ZERO, Color("8a9096"), 6.0)
			Blit.disc(self, Vector2.ZERO, 4.0, Color("5a5e62"))
			if _active:
				var length := float(data["length"])
				for k in 6:
					var d := fposmod(_t * 160.0 + k * length / 6.0, length)
					var spread := d / length * float(data["width"])
					Blit.disc(self, _dir * d + side * sin(_t * 7.0 + k) * spread * 0.5, 3.0 + spread * 0.5, Color(1, 1, 1, 0.55 * (1.0 - d / length)))
			elif _timer < 0.6:
				# Hissing warning before it blows.
				Blit.disc(self, _dir * 6.0, 2.0, Color(1, 1, 1, 0.6))
