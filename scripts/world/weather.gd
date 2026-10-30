class_name Weather
extends Node2D
## Tonight's weather over the whole neighbourhood (Profile.weather_today);
## maps under a roof don't get any. It changes how the night plays a little:
## rain wets every enemy (lightning jumps between wet ones, fire burns
## weaker), a storm also throws lightning, wind pushes the cat, fog hides the
## edges but teaches more, frost slows everyone and freezes wet enemies.
## Drawing is cheap: one layer of lines and dots in screen space, a shader
## for fog, nothing per enemy.

const KINDS := ["CLEAR", "RAIN", "STORM", "WIND", "FOG", "FROST"]
## How often each comes up (clear nights are the most common).
const WEIGHTS := [4.0, 2.0, 1.0, 1.5, 1.5, 1.0]
const INDOOR := ["LIVING_ROOM", "BASEMENT", "SUPERMARKET", "FACTORY"]
const COLORS := {"CLEAR": "f2d14e", "RAIN": "7ab8f0", "STORM": "b39cff", "WIND": "a8e0b0", "FOG": "c8c8d4", "FROST": "bfe8ff"}

const STORM_EVERY := [10.0, 16.0]
const STORM_WARN := 1.2
const STORM_RADIUS := 46.0
const STORM_DAMAGE := 70.0
const STORM_CAT_DAMAGE := 14.0
const WIND_PUSH := 22.0
const FROST_SLOW := 0.88
const FOG_XP := 0.15
const RAIN_BURN := 0.5

## The weather of the running night ("" or CLEAR when there is none).
static var current := ""

var player: Player
var enemies: EnemyManager
var kind := ""
var _wind := Vector2.ZERO
var _strike_t := 0.0
## Lightning about to strike: [{"at", "t"}].
var _warnings: Array = []
var _flash := 0.0
var _screen: WeatherScreen


static func pick(rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for w: float in WEIGHTS:
		total += w
	var r := rng.randf() * total
	for i in KINDS.size():
		r -= WEIGHTS[i]
		if r <= 0.0:
			return KINDS[i]
	return "CLEAR"


static func indoor(stage_id: String) -> bool:
	return stage_id in INDOOR


## What the weather is tonight on `stage_id` (tests: --weather=KIND).
static func for_stage(stage_id: String) -> String:
	var forced := GameData.arg("--weather=", "")
	if forced != "":
		return forced
	return "CLEAR" if indoor(stage_id) else Profile.weather_today


static func rainy() -> bool:
	return current == "RAIN" or current == "STORM"


func _ready() -> void:
	z_index = 30
	current = kind
	_strike_t = randf_range(STORM_EVERY[0], STORM_EVERY[1])
	_wind = Vector2(1 if randf() < 0.5 else -1, 0.0)
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_screen = WeatherScreen.new()
	_screen.kind = kind
	_screen.wind = _wind
	layer.add_child(_screen)
	if player == null:
		return
	# The night's lasting effects show on the HUD like a blessing.
	var color := Color(COLORS.get(kind, "ffffff"))
	match kind:
		"FOG":
			player.bless({"growth": FOG_XP}, 1e9, "WEATHER_FOG_NAME", color)
		"FROST":
			player.bless({"speed": FROST_SLOW - 1.0}, 1e9, "WEATHER_FROST_NAME", color)
		"RAIN", "STORM":
			# The captain likes it wet.
			player.bless({"area": 0.1} if player.cat_id == "KAPITAN" else {}, 1e9, "WEATHER_%s_NAME" % kind, color)
		"WIND":
			player.bless({}, 1e9, "WEATHER_WIND_NAME", color)
	BotLog.event("weather:" + kind)


func _exit_tree() -> void:
	current = ""


func _physics_process(delta: float) -> void:
	if player == null or player.is_dead:
		return
	if kind == "WIND":
		player.pull += _wind * WIND_PUSH
	if kind == "STORM":
		_strike_t -= delta
		if _strike_t <= 0.0:
			_strike_t = randf_range(STORM_EVERY[0], STORM_EVERY[1])
			# Mostly among the enemies round the cat, now and then right by it.
			var off := Vector2.from_angle(randf() * TAU) * (randf_range(0.0, 40.0) if randf() < 0.3 else randf_range(60.0, 170.0))
			_warnings.append({"at": player.position + off, "t": STORM_WARN})
		for i in range(_warnings.size() - 1, -1, -1):
			var w: Dictionary = _warnings[i]
			w["t"] = float(w["t"]) - delta
			if float(w["t"]) <= 0.0:
				_strike(w["at"])
				_warnings.remove_at(i)
		queue_redraw()
	_flash = maxf(_flash - delta, 0.0)
	_screen.flash = _flash


func _strike(at: Vector2) -> void:
	_flash = 0.15
	Audio.play("thunder", -4.0, 0.1)
	BotLog.event("weather:lightning")
	if enemies != null:
		for e in enemies.query_radius(at, STORM_RADIUS):
			e.hit(STORM_DAMAGE if not e.is_boss else e.max_hp * 0.02, e.position - at, 0.6, false)
	if player.position.distance_to(at) < STORM_RADIUS:
		player.take_damage(STORM_CAT_DAMAGE)
	var bolt := ChainBolt.new()
	bolt.points = PackedVector2Array([at + Vector2(randf_range(-30, 30), -260), at + Vector2(randf_range(-12, 12), -120), at])
	get_parent().add_child(bolt)


func _draw() -> void:
	# The red ring where lightning is about to come down.
	for w: Dictionary in _warnings:
		var k := 1.0 - float(w["t"]) / STORM_WARN
		var at: Vector2 = w["at"]
		draw_circle(at, STORM_RADIUS, Color(1.0, 0.25, 0.2, 0.08 + 0.12 * k))
		draw_arc(at, STORM_RADIUS, 0, TAU, 32, Color(1.0, 0.3, 0.25, 0.5 + 0.4 * k), 1.5)
		draw_arc(at, STORM_RADIUS * k, 0, TAU, 32, Color(1.0, 0.85, 0.6, 0.6), 1.0)


## A small picture of `kind` (forecast on the map, HUD), radius `r`.
static func draw_icon(ci: CanvasItem, c: Vector2, r: float, kind: String) -> void:
	var outline := Color("2b1d14")
	var cloud := func(at: Vector2, col: Color) -> void:
		for p: Array in [[Vector2(-0.45, 0.1), 0.38], [Vector2(0.05, -0.15), 0.48], [Vector2(0.5, 0.12), 0.34]]:
			ci.draw_circle(at + (p[0] as Vector2) * r, float(p[1]) * r + 1.0, outline)
		for p: Array in [[Vector2(-0.45, 0.1), 0.38], [Vector2(0.05, -0.15), 0.48], [Vector2(0.5, 0.12), 0.34]]:
			ci.draw_circle(at + (p[0] as Vector2) * r, float(p[1]) * r, col)
	match kind:
		"RAIN", "STORM":
			cloud.call(c + Vector2(0, -0.2 * r), Color("c8d0dc") if kind == "RAIN" else Color("8a86a0"))
			if kind == "RAIN":
				for i in 3:
					var x := (i - 1) * 0.4 * r
					ci.draw_line(c + Vector2(x, 0.4 * r), c + Vector2(x - 0.15 * r, 0.8 * r), Color("7ab8f0"), 1.5)
			else:
				var bolt := PackedVector2Array([c + Vector2(0.05, 0.2) * r, c + Vector2(-0.2, 0.6) * r, c + Vector2(0.05, 0.6) * r, c + Vector2(-0.15, 1.0) * r])
				ci.draw_polyline(bolt, Color("f2d14e"), 2.0)
		"WIND":
			for i in 3:
				var y := (i - 1) * 0.42 * r
				var w := r * (0.9 - absf(i - 1) * 0.2)
				ci.draw_line(c + Vector2(-w, y), c + Vector2(w * 0.6, y), Color("a8e0b0"), 2.0)
				ci.draw_arc(c + Vector2(w * 0.6, y - 0.18 * r), 0.18 * r, -PI * 0.5, PI * 0.5, 8, Color("a8e0b0"), 2.0)
		"FOG":
			for i in 3:
				var y := (i - 1) * 0.4 * r
				ci.draw_line(c + Vector2(-0.85 * r + i * 0.1 * r, y), c + Vector2(0.85 * r - i * 0.1 * r, y), Color("c8c8d4"), 2.5)
		"FROST":
			for i in 3:
				var d := Vector2.from_angle(i * PI / 3.0) * r * 0.85
				ci.draw_line(c - d, c + d, Color("bfe8ff"), 2.0)
			ci.draw_circle(c, 0.18 * r, Color.WHITE)
		_:
			ci.draw_circle(c, 0.55 * r + 1.0, outline)
			ci.draw_circle(c, 0.55 * r, Color("f2d14e"))
			for i in 8:
				var d := Vector2.from_angle(i * TAU / 8.0)
				ci.draw_line(c + d * 0.72 * r, c + d * 0.98 * r, Color("f2d14e"), 1.5)
