class_name MapHazard
extends Node2D
## A map's own special event (stage "hazard"), on top of its terrain:
## - "train": now and then a red warning lane lights up across the cat's
##   row, a bell rings and a train races through it. It runs over every
##   enemy on the tracks (bosses only get bruised) and hurts the cat too
##   (Station).
## - "low_tide": when the sea goes out it leaves treasures glittering on the
##   wet sand for a while: coins, sometimes a chest (Island).
## - "graves": fog drifts over the graves; now and then a few graves around
##   the cat start to glow and crack. Sit on one a moment to seal it (a burst
##   of XP); the ones left open let ghosts out (Cemetery).
## - "pigeon_thief": now and then a fat pigeon swoops through, gobbling up
##   the kibbles on the floor, then flies off with them. Catch it before it
##   gets away and it drops everything it took, and more (Park).
## - "flood": like the train, but a wave of sewer water rushes down a lane:
##   it washes away the small fry and knocks the cat aside (Sewer).
## - "shunting": like the train, but a slow row of freight wagons pushed
##   along the yard (Railyard).
## - "crane": the crane drops loads on marked spots around the cat; whatever
##   stands there gets squashed (Construction site).
## - "fireflies": swarms of fireflies light up the dark forest; catch them
##   for experience and a little health, all of a swarm for coins (Forest).

const TRAIN_FIRST := 35.0
const TRAIN_EVERY := Vector2(30.0, 45.0)
const TRAIN_WARN := 3.0
## Half the height of the lane the train runs in.
const TRAIN_HALF := 34.0
## Share of a boss's health a train takes.
const TRAIN_BOSS_HIT := 0.04
const CAR_LEN := 118.0
const TREASURES := 3
const TREASURE_TIME := 25.0
const TREASURE_COINS := 6
const TREASURE_CHEST := 0.3
const GRAVE_FIRST := 40.0
const GRAVE_EVERY := Vector2(35.0, 50.0)
const GRAVE_WARN := 8.0
const GRAVES := 3
const GRAVE_SEAL := 1.5
const GRAVE_RADIUS := 22.0
const GRAVE_GHOSTS := 4
const GRAVE_XP := 12.0
const FOG_PATCHES := 7
const THIEF_FIRST := 45.0
const THIEF_EVERY := Vector2(40.0, 55.0)
const THIEF_REACH := 48.0
## A caught thief gives back this much of what it took.
const THIEF_BONUS := 1.5
const THIEF_COINS := 8
## Lane hazards that work like the train: kind -> [pass seconds, carriages,
## cat damage, warning text].
const LANES := {
	"train": [3.2, 4, 18.0, "TRAIN_WARNING"],
	"flood": [2.6, 5, 12.0, "FLOOD_WARNING"],
	"shunting": [6.0, 3, 22.0, "SHUNTING_WARNING"],
}
const CRANE_FIRST := 30.0
const CRANE_EVERY := Vector2(18.0, 28.0)
const CRANE_WARN := 2.6
const CRANE_SPOTS := 3
const CRANE_RADIUS := 38.0
const CRANE_DAMAGE := 16.0
const CRANE_BOSS_HIT := 0.03
const FIREFLY_FIRST := 25.0
const FIREFLY_EVERY := Vector2(28.0, 38.0)
const FIREFLY_COUNT := 5
const FIREFLY_TIME := 22.0
const FIREFLY_XP := 10.0
const FIREFLY_HEAL := 2.0
const FIREFLY_COINS := 6

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
## Graves: {"pos": Vector2, "seal": 0..GRAVE_SEAL, "sealed": bool}.
var _graves: Array[Dictionary] = []
var _fog: Node2D
var _thief: Enemy
var _thief_out := false
var _stolen := 0.0
## Crane: {"pos": Vector2, "t": seconds until it drops}; dropped loads lie a
## moment as {"pos", "left", "look"}.
var _drops: Array[Dictionary] = []
var _debris: Array[Dictionary] = []
## Fireflies: {"pos": Vector2, "base": Vector2}, and the swarm's time left.
var _flies: Array[Dictionary] = []
var _flies_t := 0.0
var _flies_caught := 0


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
	elif kind == "pigeon_thief":
		_phase_t = float(GameData.arg("--hazard-at=", str(THIEF_FIRST)))
		main.enemies.enemy_killed.connect(_on_enemy_killed)
		main.enemies.escaped.connect(_on_escaped)
	elif kind == "crane":
		_phase_t = float(GameData.arg("--hazard-at=", str(CRANE_FIRST)))
	elif kind == "fireflies":
		_phase_t = float(GameData.arg("--hazard-at=", str(FIREFLY_FIRST)))
	elif kind == "graves":
		z_index = -2
		_phase_t = float(GameData.arg("--hazard-at=", str(GRAVE_FIRST)))
		# Fog drifts over everyone, so it has its own layer on top.
		_fog = Node2D.new()
		_fog.z_index = 9
		_fog.draw.connect(_draw_fog)
		add_child(_fog)


## Where the test bot should go for this map's special, if anywhere.
func bot_goal(from: Vector2) -> Vector2:
	var best := Vector2.INF
	for tr_ in _treasures:
		if (tr_["pos"] as Vector2).distance_to(from) < best.distance_to(from):
			best = tr_["pos"]
	for g in _graves:
		if not g["sealed"] and (g["pos"] as Vector2).distance_to(from) < best.distance_to(from):
			best = g["pos"]
	if is_instance_valid(_thief) and not _thief.dead and _thief.position.distance_to(from) < 400.0:
		best = _thief.position
	for f in _flies:
		if (f["pos"] as Vector2).distance_to(from) < best.distance_to(from):
			best = f["pos"]
	return best


## The state for tests and the HUD.
func phase() -> String:
	return _phase


func _physics_process(delta: float) -> void:
	_t += delta
	match kind:
		"train", "flood", "shunting":
			_tick_train(delta)
		"crane":
			_tick_crane(delta)
		"fireflies":
			_tick_fireflies(delta)
		"low_tide":
			_tick_low_tide(delta)
		"graves":
			_tick_graves(delta)
			_fog.queue_redraw()
		"pigeon_thief":
			_tick_thief(delta)
	queue_redraw()


func _tick_thief(delta: float) -> void:
	if is_instance_valid(_thief) and not _thief.dead:
		var got: float = main.pickups.steal_xp(_thief.position, THIEF_REACH)
		if got > 0.0:
			_stolen += got
			Audio.play("pop", -10.0)
		return
	if _thief_out:
		# Gone without being caught (flew off, or too far away).
		_on_escaped("PIGEON_THIEF", Vector2.ZERO)
	_phase_t -= delta
	if _phase_t > 0.0:
		return
	_phase_t = randf_range(THIEF_EVERY.x, THIEF_EVERY.y)
	# It lands close to the cat, then flees, gobbling kibbles on its way.
	var cat: Vector2 = main.player.position
	_thief = main.spawner._spawn("PIGEON_THIEF", cat + Vector2.from_angle(randf() * TAU) * 130.0)
	if _thief == null:
		return
	_thief_out = true
	_stolen = 0.0
	main.hud.show_banner(tr("PIGEON_THIEF_WARNING"), 3.0)
	Audio.play("whoosh", 0.0)
	BotLog.event("thief_came")


func _on_enemy_killed(enemy_id: String, pos: Vector2, _xp: float) -> void:
	if enemy_id != "PIGEON_THIEF" or not _thief_out:
		return
	var back := _stolen * THIEF_BONUS + 10.0
	for i in 6:
		main.pickups.spawn_xp(pos + Vector2.from_angle(TAU * i / 6.0) * 18.0, back / 6.0)
	for i in THIEF_COINS:
		main.pickups.spawn_named("coin", pos + Vector2.from_angle(TAU * i / THIEF_COINS + 0.3) * 30.0, 4.0)
	_stolen = 0.0
	_thief = null
	_thief_out = false
	Audio.play("chest", -2.0)
	Profile.add_stat("pigeon_thieves")
	main.hud.show_banner(tr("PIGEON_THIEF_CAUGHT"), 2.5)
	BotLog.event("thief_caught")


func _on_escaped(enemy_id: String, _pos: Vector2) -> void:
	if enemy_id != "PIGEON_THIEF" or not _thief_out:
		return
	_thief = null
	_thief_out = false
	if _stolen > 0.0:
		main.hud.show_banner(tr("PIGEON_THIEF_GONE") % roundi(_stolen), 2.5)
	_stolen = 0.0
	BotLog.event("thief_escaped")


func _tick_graves(delta: float) -> void:
	_phase_t -= delta
	var cat: Vector2 = main.player.position
	for g in _graves:
		if g["sealed"]:
			continue
		if (g["pos"] as Vector2).distance_to(cat) < GRAVE_RADIUS + Player.RADIUS:
			g["seal"] += delta
			if g["seal"] >= GRAVE_SEAL:
				g["sealed"] = true
				for i in 4:
					main.pickups.spawn_xp(g["pos"] + Vector2.from_angle(TAU * i / 4.0) * 16.0, GRAVE_XP)
				Audio.play("sparkle", 0.0)
				Profile.add_stat("graves_sealed")
				BotLog.event("grave_sealed")
		else:
			g["seal"] = maxf(g["seal"] - delta * 0.5, 0.0)
	if _phase_t > 0.0:
		return
	if _phase == "wait":
		_phase = "rise"
		_phase_t = GRAVE_WARN
		_graves.clear()
		for i in GRAVES:
			var pos := cat + Vector2.from_angle(TAU * i / GRAVES + randf_range(-0.5, 0.5)) * randf_range(140.0, 240.0)
			_graves.append({"pos": Terrain.fix(pos, 20.0), "seal": 0.0, "sealed": false})
		Audio.play("thunder", -4.0)
		if not _told:
			_told = true
			main.hud.show_banner(tr("GRAVES_WARNING"), 3.5)
		BotLog.event("graves_rise")
	else:
		_phase = "wait"
		_phase_t = randf_range(GRAVE_EVERY.x, GRAVE_EVERY.y)
		for g in _graves:
			if g["sealed"]:
				continue
			for i in GRAVE_GHOSTS:
				main.spawner._spawn("GHOST", g["pos"] + Vector2.from_angle(TAU * i / GRAVE_GHOSTS) * 12.0)
			BotLog.event("graves_open")
		_graves.clear()


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
		_front = lerpf(_from, _to, clampf(1.0 - _phase_t / _pass_time(), 0.0, 1.0))
		_run_over()
	if _phase_t > 0.0:
		return
	match _phase:
		"wait":
			_phase = "warn"
			_phase_t = TRAIN_WARN
			_lane_y = main.player.position.y + randf_range(-20.0, 20.0)
			_dir = 1.0 if randf() < 0.5 else -1.0
			Audio.play("bell" if kind != "flood" else "whoosh", 2.0, 0.0)
			main.hud.show_banner(tr(LANES[kind][3]), 2.5)
			BotLog.event("train_warn")
		"warn":
			_phase = "pass"
			_phase_t = _pass_time()
			var view := _view()
			var length := CAR_LEN * (_cars() + 1)
			_from = (view.position.x - 40.0) if _dir > 0.0 else (view.end.x + 40.0)
			_to = (view.end.x + length + 40.0) if _dir > 0.0 else (view.position.x - length - 40.0)
			_front = _from
			_hit.clear()
			_cat_hit = false
			Audio.play("whoosh", 4.0)
			main.player.shake(3.0, _pass_time())
		"pass":
			_phase = "wait"
			_phase_t = randf_range(TRAIN_EVERY.x, TRAIN_EVERY.y)
			BotLog.event("train_pass")


## Everything between the train's front and its tail, inside the lane.
func _pass_time() -> float:
	return float(LANES.get(kind, LANES["train"])[0])


## Carriages behind the front one.
func _cars() -> int:
	return int(LANES.get(kind, LANES["train"])[1])


func _run_over() -> void:
	var tail := _front - _dir * CAR_LEN * (_cars() + 1)
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
		cat.take_damage(float(LANES.get(kind, LANES["train"])[2]))
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
		"train", "flood", "shunting":
			_draw_train()
		"crane":
			_draw_crane()
		"fireflies":
			_draw_fireflies()
		"low_tide":
			_draw_treasures()
		"graves":
			_draw_graves()
		"pigeon_thief":
			_draw_thief()


## A bulging sack over the thief shows how much it carries.
func _draw_thief() -> void:
	if not is_instance_valid(_thief) or _thief.dead:
		return
	var p := _thief.position + Vector2(0, -26)
	var r := 5.0 + minf(_stolen / 20.0, 6.0)
	draw_circle(p, r + 1.0, Color("2b1d14"))
	draw_circle(p, r, Color("d8c08a"))
	draw_line(p + Vector2(-2, -r), p + Vector2(2, -r - 3), Color("2b1d14"), 1.5)
	if _stolen > 0.0:
		draw_circle(p, 2.0, Color("5ad1e6"))


func _draw_graves() -> void:
	var k := 0.5 + 0.5 * sin(_t * 6.0)
	for g in _graves:
		var p: Vector2 = g["pos"]
		if g["sealed"]:
			draw_arc(p, GRAVE_RADIUS, 0.0, TAU, 24, Color(0.6, 1.0, 0.7, 0.5), 2.0)
			continue
		var left := clampf(_phase_t / GRAVE_WARN, 0.0, 1.0)
		# A cracked mound glowing green, brighter as it gets ready to open.
		draw_colored_polygon(Shapes.ellipse(p, GRAVE_RADIUS, GRAVE_RADIUS * 0.6, 16), Color(0.29, 0.23, 0.19, 0.9))
		draw_colored_polygon(Shapes.ellipse(p, GRAVE_RADIUS * 0.8, GRAVE_RADIUS * 0.45, 16), Color(0.4, 1.0, 0.55, (0.15 + 0.35 * k) * (1.2 - left)))
		var mound := FloorChunk.art("grave_mound")
		if mound != null:
			draw_texture(mound, p - Vector2(25, 41))
			draw_colored_polygon(Shapes.ellipse(p, GRAVE_RADIUS * 0.8, GRAVE_RADIUS * 0.45, 16), Color(0.4, 1.0, 0.55, (0.1 + 0.25 * k) * (1.2 - left)))
		else:
			var stone := Rect2(p + Vector2(-7, -26), Vector2(14, 16))
			draw_rect(stone.grow(1.0), Color("2b1d14"))
			draw_rect(stone, Color("8a8a92"))
			draw_line(p + Vector2(0, -23), p + Vector2(0, -14), Color("5a5a62"), 1.5)
			draw_line(p + Vector2(-3, -20), p + Vector2(3, -20), Color("5a5a62"), 1.5)
		draw_polyline(PackedVector2Array([p + Vector2(-10, -3), p + Vector2(-3, 1), p + Vector2(2, -4), p + Vector2(9, 2)]), Color(0.75, 1.0, 0.8, 0.9), 1.5)
		# How long until it opens, and how far the seal has come.
		draw_arc(p, GRAVE_RADIUS + 4.0, -PI * 0.5, -PI * 0.5 + TAU * left, 24, Color(1.0, 0.45, 0.35, 0.8), 2.0)
		if g["seal"] > 0.0:
			draw_arc(p, GRAVE_RADIUS - 3.0, -PI * 0.5, -PI * 0.5 + TAU * g["seal"] / GRAVE_SEAL, 24, Color(0.6, 1.0, 0.7, 1.0), 3.0)


## Soft fog banks drifting slowly through the view.
func _draw_fog() -> void:
	var view := _view()
	for i in FOG_PATCHES:
		var speed := 12.0 + i * 3.0
		var w := view.size.x + 400.0
		var x := view.position.x - 200.0 + fposmod(_t * speed + i * 383.0 - view.position.x, w)
		var y := view.position.y - 100.0 + fposmod(i * 211.0 - view.position.y, view.size.y + 200.0)
		var r := 90.0 + (i % 3) * 30.0
		for j in 3:
			_fog.draw_colored_polygon(Shapes.ellipse(Vector2(x + j * r * 0.6, y + sin(_t * 0.4 + i + j) * 10.0), r, r * 0.45, 18), Color(0.85, 0.9, 0.95, 0.07))


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
	if kind == "flood":
		_draw_wave(view)
		return
	# The train: a locomotive and its carriages.
	var y0 := _lane_y - TRAIN_HALF + 2.0
	var h := TRAIN_HALF * 2.0 - 4.0
	for i in _cars() + 1:
		var back := _front - _dir * CAR_LEN * i
		var x0 := minf(back, back - _dir * (CAR_LEN - 6.0))
		if x0 > view.end.x or x0 + CAR_LEN < view.position.x:
			continue
		var r := Rect2(x0, y0, CAR_LEN - 6.0, h)
		draw_rect(Rect2(r.position + Vector2(4, 6), r.size), Color(0, 0, 0, 0.3))
		var pic := FloorChunk.art("train_freight" if kind == "shunting" else ("train_loco" if i == 0 else "train_car"))
		if pic != null:
			# Drawn heading right; mirrored when the train comes the other way.
			var size := r.size + Vector2(2, 2)
			if _dir > 0.0:
				draw_texture_rect(pic, Rect2(r.position - Vector2.ONE, size), false)
			else:
				draw_texture_rect(pic, Rect2(r.position.x + r.size.x + 1.0, r.position.y - 1.0, -size.x, size.y), false)
			continue
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
		var tail := _front - _dir * CAR_LEN * (_cars() + 1)
		draw_line(Vector2(tail, y), Vector2(tail - _dir * 60.0, y), Color(1, 1, 1, 0.35), 2.0)


## Where the test bot should keep out of (a crane's marked spots).
func danger_spots() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for d in _drops:
		out.append(d["pos"])
	return out


## The sewer wave: a long band of brown water with a foaming front.
func _draw_wave(view: Rect2) -> void:
	var tail := _front - _dir * CAR_LEN * (_cars() + 1)
	var x0 := maxf(minf(_front, tail), view.position.x)
	var x1 := minf(maxf(_front, tail), view.end.x)
	if x1 <= x0:
		return
	var band := Rect2(x0, _lane_y - TRAIN_HALF, x1 - x0, TRAIN_HALF * 2.0)
	var water := FloorChunk.art("terrain_sewage")
	if water != null:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		draw_texture_rect_region(water, band, Rect2(band.position + Vector2(-_t * 140.0 * _dir, 0), band.size), Color(1, 1, 1, 0.92))
	else:
		draw_rect(band, Color(0.35, 0.42, 0.28, 0.9))
	# Foam where it breaks, and spray.
	for k in 9:
		var y := _lane_y - TRAIN_HALF + k * TRAIN_HALF * 2.0 / 8.0
		var fx := _front + _dir * (4.0 + 6.0 * sin(_t * 18.0 + k))
		draw_circle(Vector2(fx, y), 7.0 + 2.0 * sin(_t * 11.0 + k * 2.0), Color(0.92, 0.95, 0.85, 0.85))
	for k in 6:
		var p := Vector2(_front + _dir * randf_range(-30.0, 8.0), _lane_y + randf_range(-TRAIN_HALF, TRAIN_HALF))
		draw_circle(p, randf_range(1.5, 3.0), Color(0.85, 0.9, 0.8, 0.7))


func _tick_crane(delta: float) -> void:
	_phase_t -= delta
	for i in range(_debris.size() - 1, -1, -1):
		_debris[i]["left"] -= delta
		if _debris[i]["left"] <= 0.0:
			_debris.remove_at(i)
	for i in range(_drops.size() - 1, -1, -1):
		var d: Dictionary = _drops[i]
		d["t"] -= delta
		if d["t"] <= 0.0:
			_crane_drop(d["pos"])
			_drops.remove_at(i)
	if _phase_t > 0.0:
		return
	_phase_t = randf_range(CRANE_EVERY.x, CRANE_EVERY.y)
	var cat: Vector2 = main.player.position
	for i in CRANE_SPOTS:
		# One where the cat is heading, the others round about.
		var pos: Vector2 = cat + main.player.velocity * 0.6 if i == 0 else cat + Vector2.from_angle(randf() * TAU) * randf_range(90.0, 200.0)
		_drops.append({"pos": Terrain.fix(pos, 20.0), "t": CRANE_WARN + i * 0.35})
	Audio.play("warning", -4.0)
	if not _told:
		_told = true
		main.hud.show_banner(tr("CRANE_WARNING"), 3.0)
	BotLog.event("crane_warn")


## A load lands: everything under it is squashed, bosses only bruised.
func _crane_drop(pos: Vector2) -> void:
	for e: Enemy in main.enemies.query_radius(pos, CRANE_RADIUS):
		if e.dead:
			continue
		if e.is_boss:
			e.hit(e.max_hp * CRANE_BOSS_HIT, Vector2.ZERO, 0.0, false)
		else:
			e.hit(e.hp * 10.0 + 1000.0, (e.position - pos).normalized(), 1.5, false)
			if e.dead:
				Profile.add_stat("crane_kills")
	var cat: Player = main.player
	if cat.position.distance_to(pos) < CRANE_RADIUS + Player.RADIUS:
		cat.take_damage(CRANE_DAMAGE)
		BotLog.event("crane_hit_cat")
	cat.shake(4.0, 0.25)
	Audio.play("break", 0.0)
	_debris.append({"pos": pos, "left": 1.2, "look": randi() % 3})
	BotLog.event("crane_drop")


func _draw_crane() -> void:
	for d in _drops:
		var p: Vector2 = d["pos"]
		var k := 1.0 - clampf(float(d["t"]) / CRANE_WARN, 0.0, 1.0)
		# The load's shadow grows as it comes down, with a warning ring.
		draw_colored_polygon(Shapes.ellipse(p, maxf(CRANE_RADIUS * k, 1.0), maxf(CRANE_RADIUS * 0.7 * k, 1.0), 20), Color(0, 0, 0, 0.35 * k))
		draw_arc(p, CRANE_RADIUS, 0.0, TAU, 32, Color(1.0, 0.75, 0.2, 0.5 + 0.4 * sin(_t * 14.0)), 3.0)
		draw_line(p + Vector2(0, -400), p + Vector2(0, -CRANE_RADIUS * (1.0 - k) - 10.0), Color(0.2, 0.2, 0.22, 0.5), 1.5)
	for d in _debris:
		var pic := FloorChunk.art(["crane_load_bricks", "crane_load_pipes", "crane_load_crate"][int(d["look"])])
		var fade := clampf(float(d["left"]) / 0.4, 0.0, 1.0)
		if pic != null:
			draw_texture(pic, (d["pos"] as Vector2) - (pic.get_size() * 0.5).floor(), Color(1, 1, 1, fade))
		draw_arc(d["pos"], CRANE_RADIUS * (1.6 - float(d["left"]) * 0.5), 0.0, TAU, 28, Color(0.85, 0.75, 0.6, 0.4 * fade), 4.0)


func _tick_fireflies(delta: float) -> void:
	var cat: Vector2 = main.player.position
	if not _flies.is_empty():
		_flies_t -= delta
		for i in range(_flies.size() - 1, -1, -1):
			var f: Dictionary = _flies[i]
			# Curious: once the cat is near they drift towards it.
			var base: Vector2 = f["base"]
			if base.distance_to(cat) < 160.0:
				f["base"] = base.move_toward(cat, 35.0 * delta)
			f["pos"] = (f["base"] as Vector2) + Vector2(sin(_t * 1.3 + i * 2.0) * 20.0, cos(_t * 1.7 + i) * 14.0)
			if (f["pos"] as Vector2).distance_to(cat) < 24.0 + Player.RADIUS:
				_catch_firefly(f["pos"])
				_flies.remove_at(i)
		if _flies.is_empty() and _flies_caught >= FIREFLY_COUNT:
			for i in FIREFLY_COINS:
				main.pickups.spawn_named("coin", cat + Vector2.from_angle(TAU * i / FIREFLY_COINS) * 30.0, 4.0)
			Audio.play("chest", -2.0)
			main.hud.show_banner(tr("FIREFLIES_ALL"), 2.5)
			BotLog.event("fireflies_all")
		if _flies_t <= 0.0:
			_flies.clear()
		return
	_phase_t -= delta
	if _phase_t > 0.0:
		return
	_phase_t = randf_range(FIREFLY_EVERY.x, FIREFLY_EVERY.y)
	_flies_t = FIREFLY_TIME
	_flies_caught = 0
	var around := Vector2.from_angle(randf() * TAU)
	for i in FIREFLY_COUNT:
		var base := Terrain.fix(cat + around.rotated(randf_range(-1.2, 1.2)) * randf_range(110.0, 220.0), 12.0)
		_flies.append({"pos": base, "base": base})
	Audio.play("sparkle", 0.0)
	if not _told:
		_told = true
		main.hud.show_banner(tr("FIREFLIES_COME"), 3.0)
	BotLog.event("fireflies_come")


func _catch_firefly(pos: Vector2) -> void:
	_flies_caught += 1
	main.pickups.spawn_xp(pos, FIREFLY_XP)
	main.player.heal(FIREFLY_HEAL)
	Audio.play("pop", -6.0)
	Profile.add_stat("fireflies")
	BotLog.event("firefly_caught")


func _draw_fireflies() -> void:
	for i in _flies.size():
		var p: Vector2 = _flies[i]["pos"]
		var blink := 0.6 + 0.4 * sin(_t * 6.0 + i * 1.7)
		draw_circle(p, 22.0, Color(0.9, 1.0, 0.4, 0.08 * blink))
		draw_circle(p, 10.0, Color(0.9, 1.0, 0.45, 0.22 * blink))
		draw_circle(p, 3.0, Color(1.0, 1.0, 0.7, blink))
		draw_circle(p + Vector2(-3, -2), 2.0, Color(0.8, 0.9, 1.0, 0.5))
		draw_circle(p + Vector2(3, -2), 2.0, Color(0.8, 0.9, 1.0, 0.5))
