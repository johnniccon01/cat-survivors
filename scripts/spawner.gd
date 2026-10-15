class_name Spawner
extends Node
## Spawns enemies just outside the screen following the stage's per-minute
## wave table (data/stages.json). Also owns the run clock: bosses arrive when
## a wave that lists them begins, timed events (rings and swarms) fire at
## their minute, and the final boss comes at duration_minutes.
##
## Difficulty keeps up with the cat: enemy health grows with the cat's level
## and with the Curse power-up, which also brings more and faster enemies.
##
## Pacing: a soft cap limits how many regular enemies are alive at once, and
## calm periods (after a boss falls, plus a short lull every few minutes)
## stop regular spawning so the player can breathe.

signal boss_spawned(boss_id: String)
signal stage_cleared
signal final_boss_spawned(boss: Enemy)
signal event_started(kind: String)

const SPAWN_MARGIN := 40.0
## Enemy health +2 % per cat level above this one.
const LEVEL_SCALING_FROM := 10
const LEVEL_SCALING := 0.02
const ELITE_FROM := 240.0
const ELITE_EVERY := 40.0
const ELITE_HP := 8.0
const RING_RADIUS := 240.0
const SWARM_TIME := 7.0
## Alive-enemy cap for regular spawns: starts here, grows per minute, tops out.
const CAP_BASE := 170
const CAP_PER_MINUTE := 5
const CAP_MAX := 260
const LULL_EVERY := 150.0
const LULL_TIME := 10.0

@export var stage_id := "LIVING_ROOM"

var elapsed := 0.0
## Stops regular spawning (duels, final boss).
var paused := false
## Seconds left of a calm period (no regular spawns, elites or events).
var calm := 0.0

var _player: Player
var _enemies: EnemyManager
var _stage: Dictionary
var _timer := 0.0
var _prop_timer := 1.0
var _elite_timer := ELITE_EVERY
var _wave_minute := -1
var _events_done := 0
var _lull_timer := LULL_EVERY
var _cleared := false


func setup(player: Player, enemies: EnemyManager) -> void:
	_player = player
	_enemies = enemies
	stage_id = Profile.selected_stage
	_stage = GameData.stages[stage_id]


func stage() -> Dictionary:
	return _stage


func duration_minutes() -> float:
	return float(_stage.get("duration_minutes", 30))


func current_wave() -> Dictionary:
	var minute := floori(elapsed / 60.0)
	var waves: Array = _stage["waves"]
	var wave: Dictionary = waves[0]
	for w: Dictionary in waves:
		if int(w["minute"]) <= minute:
			wave = w
	return wave


func calm_for(seconds: float) -> void:
	calm = maxf(calm, seconds)


## How many regular enemies may be alive right now.
func alive_cap() -> int:
	return mini(CAP_BASE + floori(elapsed / 60.0) * CAP_PER_MINUTE, CAP_MAX)


## Jumps the clock (dev tool) without firing every skipped event at once.
func skip_to(seconds: float) -> void:
	elapsed = seconds
	var events: Array = _stage.get("events", [])
	while _events_done < events.size() and float(events[_events_done]["minute"]) * 60.0 <= elapsed:
		_events_done += 1


## Health multiplier for enemies spawned right now.
func hp_multiplier() -> float:
	var level_bonus := maxf(_player.level - LEVEL_SCALING_FROM, 0) * LEVEL_SCALING
	return float(current_wave().get("hp_mult", 1.0)) * (1.0 + level_bonus) * _player.stat("curse")


func _physics_process(delta: float) -> void:
	if _player == null or _player.is_dead:
		return
	elapsed += delta
	if _cleared:
		return
	if elapsed >= duration_minutes() * 60.0:
		_cleared = true
		var final_id: String = _stage.get("final_boss", "")
		if final_id == "":
			stage_cleared.emit()
		else:
			_enemies.clear_all()
			var boss := _enemies.spawn(final_id, _player.position + Vector2(0, -_spawn_radius() * 0.8), _player.stat("curse"))
			final_boss_spawned.emit(boss)
		return
	if paused:
		return
	_tick_props(delta)
	_lull_timer -= delta
	if _lull_timer <= 0.0:
		_lull_timer = LULL_EVERY
		calm_for(LULL_TIME)
	if calm > 0.0:
		calm -= delta
		return
	_tick_events()
	var wave := current_wave()
	var radius := _spawn_radius()
	if int(wave["minute"]) != _wave_minute:
		_wave_minute = int(wave["minute"])
		for boss_id: String in wave.get("bosses", []):
			_spawn(boss_id, _player.position + Vector2.from_angle(randf() * TAU) * radius)
			boss_spawned.emit(boss_id)
	if elapsed >= ELITE_FROM:
		_elite_timer -= delta
		if _elite_timer <= 0.0:
			_elite_timer = ELITE_EVERY
			var elite := _spawn((wave["enemies"] as Array).pick_random(), _player.position + Vector2.from_angle(randf() * TAU) * radius)
			if elite != null:
				elite.make_elite(ELITE_HP)
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = float(wave["interval"]) / _player.stat("curse")
	_enemies.spawn_radius = radius
	_enemies.relocate_distance = radius * 1.5
	# Top up to the wave's minimum at once, then trickle more in until the
	# wave's maximum (default: twice the minimum) is reached.
	var alive := _enemies.enemies.size()
	var cap := roundi(alive_cap() * _player.stat("curse"))
	var minimum := mini(roundi(int(wave["minimum"]) * _player.stat("curse")), cap)
	var maximum := mini(int(wave.get("maximum", roundi(minimum * 1.4))), cap)
	var count := int(wave.get("per_tick", 1)) if alive < maximum else 0
	count = mini(maxi(count, minimum - alive), maxi(cap - alive, 0))
	var pool: Array = wave["enemies"]
	for i in count:
		_spawn(pool.pick_random(), _player.position + Vector2.from_angle(randf() * TAU) * radius)


func _spawn(id: String, pos: Vector2) -> Enemy:
	var enemy := _enemies.spawn(id, pos, hp_multiplier())
	if enemy != null:
		enemy.speed *= 1.0 + (_player.stat("curse") - 1.0) * 0.5
	return enemy


## Timed events from the stage: "ring" surrounds the cat with a closing
## circle, "swarm" sends a pack charging straight across the screen.
func _tick_events() -> void:
	var events: Array = _stage.get("events", [])
	if _events_done >= events.size():
		return
	var ev: Dictionary = events[_events_done]
	if elapsed < float(ev["minute"]) * 60.0:
		return
	_events_done += 1
	var count := roundi(int(ev["count"]) * _player.stat("curse"))
	match ev["type"]:
		"ring":
			for i in count:
				_spawn(ev["enemy"], _player.position + Vector2.from_angle(TAU * i / count) * RING_RADIUS)
		"swarm":
			var from := Vector2.from_angle(randf() * TAU)
			var side := from.orthogonal()
			for i in count:
				var offset := side * randf_range(-120.0, 120.0) - from * randf_range(0.0, 80.0)
				var e := _spawn(ev["enemy"], _player.position + from * _spawn_radius() + offset)
				if e != null:
					e.charge(-from, SWARM_TIME)
	event_started.emit(ev["type"])


## Keeps a few breakable props scattered around, just off screen.
func _tick_props(delta: float) -> void:
	_prop_timer -= delta
	if _prop_timer > 0.0:
		return
	_prop_timer = float(_stage.get("prop_interval", 4.0))
	var kinds: Array = _stage.get("props", [])
	if kinds.is_empty() or _enemies.props.size() >= int(_stage.get("max_props", 6)):
		return
	var dir := Vector2.from_angle(randf() * TAU)
	_enemies.spawn_prop(kinds.pick_random(), _player.position + dir * _spawn_radius() * randf_range(1.0, 1.5))


func _spawn_radius() -> float:
	var view := get_viewport().get_visible_rect().size / _player.camera.zoom
	return view.length() * 0.5 + SPAWN_MARGIN
