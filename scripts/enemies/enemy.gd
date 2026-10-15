class_name Enemy
extends Node2D
## One enemy. Movement and collision are driven centrally by EnemyManager
## (much cheaper than hundreds of physics bodies); this node only stores
## state and draws itself.

const KNOCK_SPEED := 120.0
const KNOCK_DECAY := 600.0
const OUTLINE := Color("2b1d14")

var id := ""
var max_hp := 1.0
var hp := 1.0
var speed := 30.0
var damage := 1.0
var radius := 6.0
var xp := 1.0
var knockback_resist := 0.0
var dead := false
var is_prop := false
var is_boss := false
var manager: EnemyManager

var _shape := "sock"
## "chase" (default), "dash" (winds up, then lunges) or "shooter" (keeps its
## distance and spits laser dots).
var _behavior := "chase"
var _cat_id := ""
var _state := "chase"
var _state_t := 2.0
var _dash_dir := Vector2.ZERO
var _shoot_t := 1.5
var _ring_t := 3.0
var _blink_t := 0.0
var _suck_t := 6.0
var _summon_t := 4.0
var _minion := ""
## Final boss special: "suck" (pulls the cat in) or "roar" (rings of shots).
var _final_mode := "suck"
var _base_scale := 1.0
var _stripes := false
var _color := Color.WHITE
var _accent := Color.GRAY
var _knock := Vector2.ZERO
var _flash := 0.0
var _wobble := randf() * TAU


func setup(p_id: String, data: Dictionary, p_manager: EnemyManager) -> void:
	id = p_id
	manager = p_manager
	max_hp = data.get("hp", 1.0)
	hp = max_hp
	speed = data.get("speed", 30.0)
	damage = data.get("damage", 1.0)
	radius = data.get("radius", 6.0)
	xp = data.get("xp", 1.0)
	knockback_resist = data.get("knockback_resist", 0.0)
	_shape = data.get("shape", "sock")
	_stripes = data.get("stripes", false)
	_color = Color(data.get("color", "#ffffff"))
	_accent = Color(data.get("accent", "#888888"))
	is_boss = data.get("boss", false)
	_behavior = data.get("behavior", "chase")
	_cat_id = data.get("cat", "")
	_minion = data.get("minion", "")
	_final_mode = data.get("final_mode", "suck")
	_base_scale = data.get("scale", 1.0)
	scale = Vector2(_base_scale, _base_scale)


## Turns a regular enemy into a tougher, bigger quest guard.
func make_elite(hp_factor: float) -> void:
	max_hp *= hp_factor
	hp = max_hp
	radius *= 1.5
	_base_scale *= 1.5
	scale = Vector2(_base_scale, _base_scale)
	knockback_resist = maxf(knockback_resist, 0.7)
	is_boss = true


func tick(delta: float, target: Vector2, push: Vector2) -> void:
	var dir := (target - position).normalized()
	var move := dir * speed
	match _behavior:
		"dash":
			move = _tick_dash(delta, dir)
		"shooter":
			move = _tick_shooter(delta, target, dir)
		"final":
			move = _tick_final(delta, target, dir)
	position += (move + _knock + push) * delta
	_knock = _knock.move_toward(Vector2.ZERO, KNOCK_DECAY * delta)
	if absf(dir.x) > 0.2:
		scale.x = signf(dir.x) * _base_scale
	if _shape == "cat":
		_wobble += delta * (12.0 if move.length_squared() > 1.0 else 3.0)
		rotation = sin(_wobble * 6.0) * 0.15 if _state == "windup" else 0.0
		queue_redraw()
	else:
		_wobble += delta * speed * 0.15
		rotation = sin(_wobble) * 0.12
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			queue_redraw()


func _tick_dash(delta: float, dir: Vector2) -> Vector2:
	_state_t -= delta
	match _state:
		"windup":
			if _state_t <= 0.0:
				_state = "dash"
				_state_t = 0.45
				_dash_dir = dir
			return Vector2.ZERO
		"dash":
			if _state_t <= 0.0:
				_state = "chase"
				_state_t = randf_range(1.4, 2.0)
				# Lands with a ring of hairballs.
				for i in 6:
					manager.spawn_bullet(position, Vector2.from_angle(TAU * i / 6.0 + randf()), damage * 0.4, "hair")
			return _dash_dir * speed * 5.0
	if _state_t <= 0.0:
		_state = "windup"
		_state_t = 0.45
	return dir * speed


## Final boss: alternates chasing, sucking the cat in and spitting out
## minions; below half health it starts lunging too.
func _tick_final(delta: float, target: Vector2, dir: Vector2) -> Vector2:
	_summon_t -= delta
	if _summon_t <= 0.0 and _minion != "":
		_summon_t = 7.0
		for i in 6:
			manager.spawn(_minion, position + Vector2.from_angle(TAU * i / 6.0) * radius * 1.2)
	if _final_mode == "roar":
		_suck_t -= delta
		if _suck_t <= 0.0:
			_suck_t = 5.0
			for i in 16:
				manager.spawn_bullet(position, Vector2.from_angle(TAU * i / 16.0 + _wobble), damage * 0.4, "hair")
		if hp < max_hp * 0.5:
			return _tick_dash(delta, dir)
		return dir * speed
	if _state == "suck":
		_state_t -= delta
		manager.player.pull = (position - target).normalized() * 70.0
		queue_redraw()
		if _state_t <= 0.0:
			_state = "chase"
			_suck_t = 8.0
			queue_redraw()
		return dir * speed * 0.3
	if _state == "chase":
		_suck_t -= delta
		if _suck_t <= 0.0:
			_state = "suck"
			_state_t = 2.5
			return Vector2.ZERO
	if hp < max_hp * 0.5 and _state != "suck":
		return _tick_dash(delta, dir)
	return dir * speed


func _tick_shooter(delta: float, target: Vector2, dir: Vector2) -> Vector2:
	var dist := position.distance_to(target)
	_shoot_t -= delta
	_ring_t -= delta
	_blink_t -= delta
	if _shoot_t <= 0.0:
		_shoot_t = 1.2
		# Below 60 % health it fires a fan of three.
		var spread := [0.0] if hp > max_hp * 0.5 else [-0.3, 0.0, 0.3]
		for a: float in spread:
			manager.spawn_bullet(position, dir.rotated(a), damage * 0.4)
	if _ring_t <= 0.0:
		_ring_t = 5.5
		for i in 10:
			manager.spawn_bullet(position, Vector2.from_angle(TAU * i / 10.0), damage * 0.4)
	if dist < 45.0 and _blink_t <= 0.0:
		# Too close: blink away to the other side of the cat.
		_blink_t = 2.5
		position = target - dir * 130.0
		_flash = 0.15
		return Vector2.ZERO
	if dist < 100.0:
		return -dir * speed
	if dist > 150.0:
		return dir * speed
	return dir.orthogonal() * speed * 0.6


func hit(amount: float, direction: Vector2, knockback: float) -> void:
	if dead:
		return
	hp -= amount
	_flash = 0.08
	queue_redraw()
	_knock = direction.normalized() * KNOCK_SPEED * knockback * (1.0 - knockback_resist)
	if hp <= 0.0:
		dead = true
		manager.on_enemy_dead(self)


func _draw() -> void:
	var body := _color
	if _flash > 0.0:
		# Bosses get hit constantly; a lighter tint keeps them recognisable.
		body = _color.lightened(0.4) if is_boss else Color.WHITE
	var r := radius / _base_scale
	draw_colored_polygon(Shapes.ellipse(Vector2(1, r + 2), r, 2), Color(0, 0, 0, 0.25))
	match _shape:
		"dust":
			_draw_dust(body)
		"box":
			_draw_box(body)
		"plant":
			_draw_plant(body)
		"bubble":
			_draw_bubble(body)
		"roomba":
			_draw_roomba(body)
		"slipper":
			_draw_slipper(body)
		"vacuum":
			_draw_vacuum(body)
			if _state == "suck":
				for i in 8:
					var a := TAU * i / 8.0 + _wobble
					draw_line(Vector2.from_angle(a) * 30.0, Vector2.from_angle(a) * 14.0, Color(0.85, 0.9, 1.0, 0.6), 1.0)
		"rat":
			_draw_rat(body)
		"spider":
			_draw_spider(body)
		"moth":
			_draw_moth(body)
		"paint_can":
			_draw_paint_can(body)
		"cat":
			CatArt.draw(self, CatArt.look(_cat_id), 1, _wobble, _flash > 0.0, false, "angry")
		_:
			_draw_sock(body)
	if is_boss:
		if _shape != "cat":
			_draw_crown(Vector2(0, -r - 6))
		var w := 20.0
		draw_rect(Rect2(-w * 0.5 - 0.5, r + 4, w + 1, 2.5), OUTLINE)
		draw_rect(Rect2(-w * 0.5, r + 4.5, w * maxf(hp, 0.0) / max_hp, 1.5), Color("e04646"))


func _draw_sock(body: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(-5, -10), Vector2(3, -10), Vector2(3, 2), Vector2(9, 3),
		Vector2(10, 6), Vector2(8, 9), Vector2(-3, 9), Vector2(-5, 6),
	])
	draw_colored_polygon(pts, body)
	draw_rect(Rect2(-5, -10, 8, 3), _accent)
	if _stripes:
		draw_rect(Rect2(-5, -4, 8, 2), _accent)
		draw_rect(Rect2(-5, 1, 8, 2), _accent)
	draw_colored_polygon(Shapes.ellipse(Vector2(7, 6), 2, 2, 8), _accent)
	draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
	# Grumpy face
	draw_rect(Rect2(-3, -6, 1, 2), OUTLINE)
	draw_rect(Rect2(0, -6, 1, 2), OUTLINE)
	draw_line(Vector2(-4, -8), Vector2(-2, -7), OUTLINE, 1.0)
	draw_line(Vector2(2, -8), Vector2(0, -7), OUTLINE, 1.0)


func _draw_dust(body: Color) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		var r := radius + (1.5 if i % 2 == 0 else -0.5)
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	draw_colored_polygon(pts, body)
	draw_polyline(Shapes.closed(pts), _accent, 1.0)
	for e: Vector2 in [Vector2(-2, -1), Vector2(2, -1)]:
		draw_circle(e, 1.8, Color.WHITE)
		draw_rect(Rect2(e + Vector2(0, -0.5), Vector2(1, 1)), OUTLINE)


func _draw_box(body: Color) -> void:
	var r := Rect2(-8, -9, 16, 15)
	draw_rect(r, body)
	draw_rect(Rect2(-8, -9, 16, 4), body.darkened(0.15))
	draw_rect(Rect2(-1.5, -9, 3, 15), _accent)
	draw_rect(r, OUTLINE, false, 1.0)
	draw_line(Vector2(-8, -5), Vector2(8, -5), OUTLINE, 1.0)


func _draw_plant(body: Color) -> void:
	for leaf: Vector2 in [Vector2(-6, -12), Vector2(0, -15), Vector2(6, -12), Vector2(-3, -9), Vector2(3, -9)]:
		var pts := PackedVector2Array([Vector2(0, -4), leaf + Vector2(-2, 1), leaf, leaf + Vector2(2, 1)])
		draw_colored_polygon(pts, _accent)
		draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
	var pot := PackedVector2Array([Vector2(-6, -5), Vector2(6, -5), Vector2(4, 6), Vector2(-4, 6)])
	draw_colored_polygon(pot, body)
	draw_rect(Rect2(-7, -6, 14, 3), body.lightened(0.15))
	draw_polyline(Shapes.closed(pot), OUTLINE, 1.0)


func _draw_crown(at: Vector2) -> void:
	var pts := PackedVector2Array([
		at + Vector2(-5, 3), at + Vector2(-5, -2), at + Vector2(-2.5, 0), at + Vector2(0, -3),
		at + Vector2(2.5, 0), at + Vector2(5, -2), at + Vector2(5, 3),
	])
	draw_colored_polygon(pts, Color("f2c14e"))
	draw_polyline(Shapes.closed(pts), OUTLINE, 0.6)
	draw_rect(Rect2(at + Vector2(-0.5, 0.5), Vector2(1, 1)), Color("e04646"))


func _draw_bubble(body: Color) -> void:
	draw_circle(Vector2.ZERO, radius, Color(body, 0.45))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Color(1, 1, 1, 0.8), 1.0)
	draw_arc(Vector2.ZERO, radius - 2, PI * 1.1, PI * 1.5, 6, Color(1, 1, 1, 0.9), 1.0)
	draw_rect(Rect2(-2, -1, 1, 1), OUTLINE)
	draw_rect(Rect2(1, -1, 1, 1), OUTLINE)


func _draw_roomba(body: Color) -> void:
	var r := 9.0
	draw_circle(Vector2(0, 1), r + 1, OUTLINE)
	draw_circle(Vector2(0, 1), r, body.darkened(0.2))
	draw_circle(Vector2(0, 0), r - 1, body)
	draw_arc(Vector2(0, 0), r - 3, -PI * 0.35, PI * 0.35, 8, body.lightened(0.3), 1.0)
	# Angry LED eyes
	draw_line(Vector2(1, -3), Vector2(4, -2), _accent, 1.0)
	draw_line(Vector2(1, 1), Vector2(4, 0), _accent, 1.0)
	draw_circle(Vector2(-3, 0), 1.5, _accent)


func _draw_slipper(body: Color) -> void:
	var sole := Shapes.ellipse(Vector2(0, 3), 10, 5)
	draw_colored_polygon(sole, _accent)
	draw_polyline(Shapes.closed(sole), OUTLINE, 1.0)
	var strap := PackedVector2Array([Vector2(-1, -2), Vector2(8, -2), Vector2(9, 5), Vector2(-2, 5)])
	draw_colored_polygon(strap, body)
	draw_polyline(Shapes.closed(strap), OUTLINE, 1.0)
	draw_circle(Vector2(9, -2), 3.0, Color.WHITE)
	draw_rect(Rect2(2, 0, 1, 2), OUTLINE)
	draw_rect(Rect2(5, 0, 1, 2), OUTLINE)
	draw_line(Vector2(1, -1), Vector2(3, 0), OUTLINE, 1.0)
	draw_line(Vector2(7, -1), Vector2(5, 0), OUTLINE, 1.0)


func _draw_vacuum(body: Color) -> void:
	# Upright vacuum cleaner with a grumpy face on the bag.
	draw_line(Vector2(-2, -14), Vector2(-2, -4), OUTLINE, 3.0)
	draw_line(Vector2(-2, -14), Vector2(-2, -4), _accent, 1.0)
	draw_line(Vector2(-4, -14), Vector2(0, -14), OUTLINE, 2.0)
	var bag := PackedVector2Array([Vector2(-6, -8), Vector2(4, -8), Vector2(6, 4), Vector2(-7, 4)])
	draw_colored_polygon(bag, body)
	draw_polyline(Shapes.closed(bag), OUTLINE, 1.0)
	draw_rect(Rect2(-9, 4, 18, 4), _accent)
	draw_rect(Rect2(-9, 4, 18, 4), OUTLINE, false, 1.0)
	draw_circle(Vector2(-6, 9), 1.5, OUTLINE)
	draw_circle(Vector2(6, 9), 1.5, OUTLINE)
	draw_rect(Rect2(-3, -4, 1, 2), OUTLINE)
	draw_rect(Rect2(1, -4, 1, 2), OUTLINE)
	draw_line(Vector2(-4, -6), Vector2(-2, -5), OUTLINE, 1.0)
	draw_line(Vector2(3, -6), Vector2(1, -5), OUTLINE, 1.0)
	draw_line(Vector2(-2, 1), Vector2(2, 1), OUTLINE, 1.0)


func _draw_rat(body: Color) -> void:
	var sway := sin(_wobble * 2.0) * 2.0
	draw_polyline(PackedVector2Array([Vector2(-7, 1), Vector2(-11, -1 + sway), Vector2(-14, 2 + sway)]), _accent, 1.0)
	var b := Shapes.ellipse(Vector2(-1, 1), 7, 4.5)
	draw_colored_polygon(b, body)
	draw_polyline(Shapes.closed(b), OUTLINE, 1.0)
	var head := PackedVector2Array([Vector2(3, -3), Vector2(9, 1), Vector2(3, 4)])
	draw_colored_polygon(head, body)
	draw_polyline(Shapes.closed(head), OUTLINE, 1.0)
	draw_circle(Vector2(3, -3), 2.2, OUTLINE)
	draw_circle(Vector2(3, -3), 1.5, _accent)
	draw_rect(Rect2(5, -1, 1, 1), Color("e04646"))
	draw_rect(Rect2(9, 0, 1, 1), _accent)


func _draw_spider(body: Color) -> void:
	var step := sin(_wobble * 3.0) * 1.5
	for side: float in [-1.0, 1.0]:
		for i in 4:
			var root := Vector2(-3 + i * 2.0, 0)
			var knee := root + Vector2((i - 1.5) * 3.0, side * 5.0 + (step if i % 2 == 0 else -step))
			var foot := knee + Vector2((i - 1.5) * 2.0, side * 3.0)
			draw_polyline(PackedVector2Array([root, knee, foot]), OUTLINE, 1.0)
	draw_circle(Vector2(-2, 0), 4.5, OUTLINE)
	draw_circle(Vector2(-2, 0), 3.7, body)
	draw_circle(Vector2(3, 0), 3.0, OUTLINE)
	draw_circle(Vector2(3, 0), 2.3, body.lightened(0.1))
	draw_rect(Rect2(-3, -1, 2, 2), _accent)
	for e: Vector2 in [Vector2(4, -1), Vector2(4, 1), Vector2(5, 0)]:
		draw_rect(Rect2(e, Vector2(1, 1)), Color("e04646"))


func _draw_moth(body: Color) -> void:
	var flap := absf(sin(_wobble * 4.0))
	for side: float in [-1.0, 1.0]:
		var wing := Shapes.ellipse(Vector2(0, side * (3.0 + flap * 2.0)), 5.0, 2.0 + flap * 2.0, 10)
		draw_colored_polygon(wing, body)
		draw_polyline(Shapes.closed(wing), _accent, 1.0)
	draw_line(Vector2(-4, 0), Vector2(4, 0), OUTLINE, 2.0)
	draw_line(Vector2(4, 0), Vector2(7, -2), OUTLINE, 1.0)
	draw_line(Vector2(4, 0), Vector2(7, 2), OUTLINE, 1.0)


func _draw_paint_can(body: Color) -> void:
	draw_rect(Rect2(-6, -6, 12, 12), body)
	draw_rect(Rect2(-6, -2, 12, 5), _accent)
	draw_rect(Rect2(-6, -6, 12, 12), OUTLINE, false, 1.0)
	draw_arc(Vector2(0, -6), 5.0, PI, TAU, 8, OUTLINE, 1.0)
	draw_rect(Rect2(2, 6, 3, 2), _accent)
