class_name MapHazard
extends Node2D
## A map's own special event (stage "hazard"), on top of its terrain:
## - "train": now and then a red warning lane lights up across the cat's
##   row, a bell rings and a train races through it. It runs over every
##   enemy on the tracks (bosses only get bruised) and hurts the cat too
##   (Station).
## - "low_tide": when the sea goes out it leaves treasures glittering on the
##   wet sand for a while: coins, sometimes a chest (Island).

const TRAIN_FIRST := 35.0
const TRAIN_EVERY := Vector2(30.0, 45.0)
const TRAIN_WARN := 3.0
const TRAIN_PASS := 3.2
## Half the height of the lane the train runs in.
const TRAIN_HALF := 34.0
const TRAIN_DAMAGE := 18.0
## Share of a boss's health a train takes.
const TRAIN_BOSS_HIT := 0.04
const CAR_LEN := 118.0
const CARS := 4
const TREASURES := 3
const TREASURE_TIME := 25.0
const TREASURE_COINS := 6
const TREASURE_CHEST := 0.3

static var current: MapHazard

var kind := ""
var main: Node
var _t := 0.0
var _phase := "wait"
var _phase_t := 0.0
var _lane_y := 0.0
var _dir := 1.0
## The train's front, in world x.
var _front := 0.0
var _from := 0.0
var _to := 0.0
var _hit := {}
var _cat_hit := false
## Low tide: {"pos": Vector2, "t": seconds left}.
var _treasures: Array[Dictionary] = []
var _last_tide := ""
var _forced := -1.0
var _arrow: QuestArrow
var _told := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 8


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null
	if is_instance_valid(_arrow):
		_arrow.queue_free()


func setup(p_kind: String, p_main: Node) -> void:
	kind = p_kind
	main = p_main
	_phase_t = float(GameData.arg("--hazard-at=", str(TRAIN_FIRST)))
	_forced = float(GameData.arg("--hazard-at=", "-1"))
	if kind == "low_tide":
		z_index = -2


## Where the test bot should go for this map's special, if anywhere.
func bot_goal(from: Vector2) -> Vector2:
	var best := Vector2.INF
	for tr_ in _treasures:
		if (tr_["pos"] as Vector2).distance_to(from) < best.distance_to(from):
			best = tr_["pos"]
	return best


## The state for tests and the HUD.
func phase() -> String:
	return _phase


func _physics_process(delta: float) -> void:
	_t += delta
	match kind:
		"train":
			_tick_train(delta)
		"low_tide":
			_tick_low_tide(delta)
	queue_redraw()


func _tick_low_tide(delta: float) -> void:
	var tide := Terrain.current.tide_phase() if Terrain.current != null else ""
	if _forced >= 0.0:
		_forced -= delta
		if _forced < 0.0:
			_spawn_treasures(main.player.position.y)
	elif tide == "fall" and _last_tide != "fall":
		_spawn_treasures(Terrain.current.tide_center())
	_last_tide = tide
	var cat: Vector2 = main.player.position
	for i in range(_treasures.size() - 1, -1, -1):
		var tr_: Dictionary = _treasures[i]
		tr_["t"] -= delta
		if (tr_["pos"] as Vector2).distance_to(cat) < 20.0 + Player.RADIUS:
			_dig_up(tr_["pos"])
			_treasures.remove_at(i)
		elif tr_["t"] <= 0.0:
			_treasures.remove_at(i)
	# The arrow points to the nearest treasure.
	if _treasures.is_empty():
		if is_instance_valid(_arrow):
			_arrow.queue_free()
		return
	var best: Vector2 = _treasures[0]["pos"]
	for tr_ in _treasures:
		if (tr_["pos"] as Vector2).distance_to(cat) < best.distance_to(cat):
			best = tr_["pos"]
	if not is_instance_valid(_arrow):
		_arrow = QuestArrow.new()
		_arrow.color = Color("f2c14e")
		main.hud.add_child(_arrow)
	_arrow.target = best


## Treasures on the sand the sea just left, above and below the dry strip.
func _spawn_treasures(center_y: float) -> void:
	var cat: Vector2 = main.player.position
	for i in TREASURES:
		var side := 1.0 if i % 2 == 0 else -1.0
		var pos := Vector2(cat.x + randf_range(-320.0, 320.0), center_y + side * randf_range(Terrain.TIDE_HALF + 30.0, Terrain.TIDE_HALF + 220.0))
		_treasures.append({"pos": Terrain.fix(pos, 12.0), "t": TREASURE_TIME})
	Audio.play("sparkle", 2.0)
	if not _told:
		_told = true
		main.hud.show_banner(tr("TIDE_TREASURE"), 3.5)
	BotLog.event("tide_treasures")


func _dig_up(pos: Vector2) -> void:
	for i in TREASURE_COINS:
		main.pickups.spawn_named("coin", pos + Vector2.from_angle(TAU * i / TREASURE_COINS) * 14.0, 5.0)
	if randf() < TREASURE_CHEST:
		main.pickups.spawn_named("chest", pos, 0.0)
	Audio.play("chest", -2.0)
	Profile.add_stat("tide_treasures")
	BotLog.event("tide_treasure_found")


func _tick_train(delta: float) -> void:
	_phase_t -= delta
	if _phase == "pass":
		_front = lerpf(_from, _to, clampf(1.0 - _phase_t / TRAIN_PASS, 0.0, 1.0))
		_run_over()
	if _phase_t > 0.0:
		return
	match _phase:
		"wait":
			_phase = "warn"
			_phase_t = TRAIN_WARN
			_lane_y = main.player.position.y + randf_range(-20.0, 20.0)
			_dir = 1.0 if randf() < 0.5 else -1.0
			Audio.play("bell", 2.0, 0.0)
			main.hud.show_banner(tr("TRAIN_WARNING"), 2.5)
			BotLog.event("train_warn")
		"warn":
			_phase = "pass"
			_phase_t = TRAIN_PASS
			var view := _view()
			var length := CAR_LEN * (CARS + 1)
			_from = (view.position.x - 40.0) if _dir > 0.0 else (view.end.x + 40.0)
			_to = (view.end.x + length + 40.0) if _dir > 0.0 else (view.position.x - length - 40.0)
			_front = _from
			_hit.clear()
			_cat_hit = false
			Audio.play("whoosh", 4.0)
			main.player.shake(3.0, TRAIN_PASS)
		"pass":
			_phase = "wait"
			_phase_t = randf_range(TRAIN_EVERY.x, TRAIN_EVERY.y)
			BotLog.event("train_pass")


## Everything between the train's front and its tail, inside the lane.
func _run_over() -> void:
	var tail := _front - _dir * CAR_LEN * (CARS + 1)
	var rect := Rect2(minf(_front, tail), _lane_y - TRAIN_HALF, absf(_front - tail), TRAIN_HALF * 2.0)
	var push := Vector2(_dir, 0.0)
	for e: Enemy in main.enemies.query_rect(rect):
		if e.dead or _hit.has(e.get_instance_id()):
			continue
		_hit[e.get_instance_id()] = true
		if e.is_boss:
			e.hit(e.max_hp * TRAIN_BOSS_HIT, push, 0.0, false)
		else:
			e.hit(e.hp * 10.0 + 1000.0, push, 2.0, false)
			if e.dead:
				Profile.add_stat("train_kills")
	var cat: Player = main.player
	if not _cat_hit and rect.grow(Player.RADIUS).has_point(cat.position):
		_cat_hit = true
		cat.take_damage(TRAIN_DAMAGE)
		# Thrown off the tracks to the nearer side.
		var side := 1.0 if cat.position.y >= _lane_y else -1.0
		cat.position.y = _lane_y + side * (TRAIN_HALF + Player.RADIUS + 4.0)
		cat.shake(6.0, 0.3)
		BotLog.event("train_hit_cat")


func _view() -> Rect2:
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	var rect := get_viewport_rect()
	return Rect2(inv * rect.position, inv.basis_xform(rect.size)).abs().grow(80.0)


func _draw() -> void:
	match kind:
		"train":
			_draw_train()
		"low_tide":
			_draw_treasures()


func _draw_treasures() -> void:
	for tr_ in _treasures:
		var p: Vector2 = tr_["pos"]
		var fade := clampf(float(tr_["t"]) / 3.0, 0.0, 1.0)
		var k := 0.5 + 0.5 * sin(_t * 5.0 + p.x)
		# Wet sand, a half-buried shell and a glint.
		draw_colored_polygon(Shapes.ellipse(p, 18.0, 11.0, 14), Color(0.55, 0.45, 0.3, 0.35 * fade))
		draw_arc(p, 16.0 + k * 4.0, 0.0, TAU, 20, Color(1.0, 0.9, 0.4, (0.35 + 0.4 * k) * fade), 2.0)
		draw_colored_polygon(Shapes.ellipse(p + Vector2(0, 2), 7.0, 5.0, 10), Color(0.17, 0.11, 0.08, fade))
		draw_colored_polygon(Shapes.ellipse(p + Vector2(0, 2), 6.0, 4.0, 10), Color(0.95, 0.75, 0.6, fade))
		for k2 in 4:
			draw_line(p + Vector2(0, 5), p + Vector2(-4.5 + k2 * 3.0, -1), Color(0.8, 0.5, 0.4, fade), 1.0)
		var g := p + Vector2(6, -8)
		var s := 3.0 + 3.0 * k
		draw_line(g - Vector2(s, 0), g + Vector2(s, 0), Color(1, 1, 0.85, fade), 1.5)
		draw_line(g - Vector2(0, s), g + Vector2(0, s), Color(1, 1, 0.85, fade), 1.5)


func _draw_train() -> void:
	if _phase == "wait":
		return
	var view := _view()
	if _phase == "warn":
		var k := 0.5 + 0.5 * sin(_t * 14.0)
		draw_rect(Rect2(view.position.x, _lane_y - TRAIN_HALF, view.size.x, TRAIN_HALF * 2.0), Color(1.0, 0.2, 0.15, 0.10 + 0.12 * k))
		for side: float in [-1.0, 1.0]:
			var y := _lane_y + side * TRAIN_HALF
			var x := floorf(view.position.x / 32.0) * 32.0
			while x < view.end.x:
				draw_line(Vector2(x, y), Vector2(x + 16.0, y), Color(1.0, 0.85, 0.2, 0.6 + 0.4 * k), 3.0)
				x += 32.0
		# Arrows showing where it comes from.
		var at := Vector2(view.position.x + 110.0 if _dir > 0.0 else view.end.x - 110.0, _lane_y)
		for i in 3:
			var p := at + Vector2(_dir * i * 22.0, 0.0)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-_dir * 8.0, -10.0), p + Vector2(_dir * 8.0, 0.0), p + Vector2(-_dir * 8.0, 10.0)]), Color(1.0, 0.3, 0.2, 0.4 + 0.6 * k))
		return
	# The train: a locomotive and its carriages.
	var y0 := _lane_y - TRAIN_HALF + 2.0
	var h := TRAIN_HALF * 2.0 - 4.0
	for i in CARS + 1:
		var back := _front - _dir * CAR_LEN * i
		var x0 := minf(back, back - _dir * (CAR_LEN - 6.0))
		if x0 > view.end.x or x0 + CAR_LEN < view.position.x:
			continue
		var r := Rect2(x0, y0, CAR_LEN - 6.0, h)
		draw_rect(Rect2(r.position + Vector2(4, 6), r.size), Color(0, 0, 0, 0.3))
		draw_rect(r, Color("2b1d14"))
		var body := Color("c0392b") if i == 0 else Color("3a5a8a")
		draw_rect(r.grow(-2.0), body)
		draw_rect(Rect2(r.position.x + 2.0, r.position.y + 2.0, r.size.x - 4.0, 6.0), body.lightened(0.25))
		draw_rect(Rect2(r.position.x + 2.0, r.end.y - 12.0, r.size.x - 4.0, 4.0), Color("e8c02a"))
		if i == 0:
			# The driver's window at the front.
			var wx := r.end.x - 26.0 if _dir > 0.0 else r.position.x + 8.0
			draw_rect(Rect2(wx, r.position.y + 12.0, 18.0, 20.0), Color("8fd0f0"))
			var lamp := Vector2(r.end.x - 4.0 if _dir > 0.0 else r.position.x + 4.0, r.position.y + h * 0.5 + 8.0)
			draw_circle(lamp, 4.0, Color("fff2a0"))
		else:
			var wx := r.position.x + 10.0
			while wx + 18.0 < r.end.x - 6.0:
				draw_rect(Rect2(wx, r.position.y + 14.0, 16.0, 16.0), Color("8fd0f0").darkened(0.15))
				wx += 26.0
	# Speed lines behind it.
	for i in 5:
		var y := y0 + 8.0 + i * (h - 16.0) / 4.0
		var tail := _front - _dir * CAR_LEN * (CARS + 1)
		draw_line(Vector2(tail, y), Vector2(tail - _dir * 60.0, y), Color(1, 1, 1, 0.35), 2.0)
