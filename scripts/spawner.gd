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
## Pacing works on a spawn budget (like Achilles Survivor): every enemy has a
## cost (a bubble 0.5, a slipper 4), and new enemies only come while the
## living ones cost less than the budget. So the screen holds lots of weak
## enemies or fewer strong ones. The budget is re-rolled every half minute
## inside a range that grows with time, multiplied by the stage's authored
## per-minute intensity (quiet minutes around cat flaps, spikes before
## bosses, like Vampire Survivors' wave tables), and eased off a bit while
## the cat is low on health. Calm periods (after a boss falls,
## plus a lull every few minutes) stop regular spawning. Spawn rate, lulls,
## events and boss arrivals all get a little randomness so runs differ.

signal boss_spawned(boss_id: String)
signal stage_cleared
signal final_boss_spawned(boss: Enemy)
signal event_started(kind: String)

const SPAWN_MARGIN := 40.0
## Enemy health +3.5 % per cat level above this one.
const LEVEL_SCALING_FROM := 10
const LEVEL_SCALING := 0.022
## Enemies hit harder as the night goes on, slowly at first and then faster
## (damage x(1 + 0.006 * minute²): x1.15 at 5, x1.6 at 10, x2.35 at 15, x3.4
## at 20) and get a little faster (+1.5 % per minute, at most +30 %), so a
## strong late-game cat still has to watch out.
const DAMAGE_PER_MINUTE_SQ := 0.0045
const CHAMPION_PER_MINUTE := 0.004
## Endless night tuning.
const ENDLESS_HP_PER_MINUTE := 0.6
## Extra enemy speed per endless minute, up to ENDLESS_SPEED_MAX on top.
const ENDLESS_SPEED_PER_MINUTE := 0.03
const ENDLESS_SPEED_MAX := 0.4
const ENDLESS_BOSS_EVERY := 150.0
const CHAMPION_MAX := 0.06
const SPEED_PER_MINUTE := 0.0075
const SPEED_MAX_BONUS := 0.15
const ELITE_FROM := 240.0
const ELITE_HP := 8.0
const RING_RADIUS := 240.0
const SWARM_TIME := 7.0
## Budget ranges by minute: [minute, low, high], interpolated.
const CAP_RANGES := [[0, 70, 120], [5, 150, 200], [12, 250, 330], [17, 300, 400]]
const CAP_REROLL := [30.0, 60.0]
const LULL_EVERY := [120.0, 180.0]
const LULL_TIME := [8.0, 14.0]
const BOSS_DELAY := [0.0, 20.0]
## Breather after a wave boss falls before a held-back one comes.
const BOSS_GAP := [6.0, 12.0]
const EVENT_JITTER := 0.5
const ELITE_EVERY_RANGE := [30.0, 50.0]
## Budget multiplier while the cat is below this share of health.
const MERCY_HP := 0.35
const MERCY := 0.8

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
var _elite_timer: float = ELITE_EVERY_RANGE[1]
var _wave_minute := -1
var _events_done := 0
var _lull_timer := 150.0
var _cap := 100
var _cap_timer := 0.0
var _events: Array = []
var _pending_bosses: Array = []
var _boss_timer := 0.0
var _wave_bosses: Array = []
var _traps: Array[Trap] = []
var _trap_timer := 2.0
var _cleared := false
## Endless night: after the final boss the night just goes on.
var endless := false
var _endless_from := 0.0
var _endless_boss_t := 0.0


func setup(player: Player, enemies: EnemyManager) -> void:
	_player = player
	_enemies = enemies
	stage_id = Profile.selected_stage
	_stage = GameData.stages[stage_id]
	darkness = Profile.darkness_for(stage_id)
	_lull_timer = randf_range(LULL_EVERY[0], LULL_EVERY[1])
	# Every run shifts the timed events a little.
	for ev: Dictionary in _stage.get("events", []):
		var e := ev.duplicate()
		e["minute"] = maxf(float(e["minute"]) + randf_range(-EVENT_JITTER, EVENT_JITTER), 0.5)
		_events.append(e)
	_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["minute"] < b["minute"])


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


## Spawn budget right now: rolled range x minute intensity x curse x mercy.
func alive_cap() -> int:
	var b := _cap * intensity() * _player.stat("curse") * minf(1.0 + 0.04 * endless_minutes(), 1.6) * (1.0 + DARKNESS_CROWD * darkness)
	if _player.hp < _player.max_hp * MERCY_HP:
		b *= MERCY
	return roundi(b)


## The stage's authored intensity for the current minute (1.0 if none).
func intensity() -> float:
	var curve: Array = _stage.get("intensity", [])
	if curve.is_empty():
		return 1.0
	return float(curve[mini(floori(elapsed / 60.0), curve.size() - 1)])


func _roll_cap() -> void:
	var minute := elapsed / 60.0
	var lo := float(CAP_RANGES[0][1])
	var hi := float(CAP_RANGES[0][2])
	for i in CAP_RANGES.size():
		var r: Array = CAP_RANGES[i]
		if minute >= r[0]:
			lo = r[1]
			hi = r[2]
			if i + 1 < CAP_RANGES.size():
				var nxt: Array = CAP_RANGES[i + 1]
				var k: float = (minute - float(r[0])) / float(nxt[0] - r[0])
				lo = lerpf(r[1], nxt[1], k)
				hi = lerpf(r[2], nxt[2], k)
	_cap = randi_range(roundi(lo), roundi(hi))
	_cap_timer = randf_range(CAP_REROLL[0], CAP_REROLL[1])


## Jumps the clock (dev tool) without firing every skipped event at once.
func skip_to(seconds: float) -> void:
	elapsed = seconds
	while _events_done < _events.size() and float(_events[_events_done]["minute"]) * 60.0 <= elapsed:
		_events_done += 1
	_roll_cap()


## Per darkness level: enemy health, damage and numbers, and gold.
const DARKNESS_HP := 0.18
const DARKNESS_DAMAGE := 0.1
const DARKNESS_CROWD := 0.06
const DARKNESS_GOLD := 0.25
var darkness := 0
const EARLY_EASE := 0.7
const CHALLENGE_FROM := 6.0
const CHALLENGE_FULL := 20.0
const EASE_UNTIL := 6.0


## Health multiplier for enemies spawned right now.
## Enemies are tougher while a story ally (Bruno) walks with you.
var ally_hp_mult := 1.0


func hp_multiplier() -> float:
	var level_bonus := maxf(_player.level - LEVEL_SCALING_FROM, 0) * LEVEL_SCALING
	return float(current_wave().get("hp_mult", 1.0)) * (1.0 + level_bonus) * _player.stat("curse") * endless_factor() * early_ease() * challenge() * (1.0 + DARKNESS_HP * darkness) * ally_hp_mult


## The map's challenge ("challenge" in stages.json): later maps grow tougher
## from minute CHALLENGE_FROM to CHALLENGE_FULL, so only a well built cat
## wins there.
func challenge() -> float:
	var full := float(stage().get("challenge", 1.0))
	var k := clampf((elapsed / 60.0 - CHALLENGE_FROM) / (CHALLENGE_FULL - CHALLENGE_FROM), 0.0, 1.0)
	return lerpf(1.0, full, k)


## Later maps start gentler: enemies there have 30 % less health and hit
## 30 % softer at the start of the night, back to full by minute EASE_UNTIL, so a fresh cat
## can survive the first boss.
func early_ease() -> float:
	if stage_id == "LIVING_ROOM" or elapsed >= EASE_UNTIL * 60.0:
		return 1.0
	return lerpf(EARLY_EASE, 1.0, elapsed / (EASE_UNTIL * 60.0))


## Endless night: +60 % enemy health for every minute past the final boss.
func endless_factor() -> float:
	return 1.0 + ENDLESS_HP_PER_MINUTE * endless_minutes() if endless else 1.0


func endless_minutes() -> float:
	return maxf(elapsed - _endless_from, 0.0) / 60.0 if endless else 0.0


## Starts the endless night after the final boss has fallen.
func start_endless() -> void:
	endless = true
	_cleared = false
	paused = false
	_endless_from = elapsed
	_endless_boss_t = ENDLESS_BOSS_EVERY * 0.5
	calm_for(6.0)


## Every boss the stage's waves can send.
func _stage_bosses() -> Array:
	var ids: Array = []
	for w: Dictionary in _stage["waves"]:
		for b: String in w.get("bosses", []):
			if b not in ids:
				ids.append(b)
	return ids


func _physics_process(delta: float) -> void:
	if _player == null or _player.is_dead:
		return
	elapsed += delta
	_enemies.damage_mult = (1.0 + DAMAGE_PER_MINUTE_SQ * pow(elapsed / 60.0, 2.0)) * early_ease() * sqrt(challenge()) * (1.0 + DARKNESS_DAMAGE * darkness) * float(_stage.get("damage_mult", 1.0))
	_enemies.speed_mult = 1.0 + minf(SPEED_PER_MINUTE * elapsed / 60.0, SPEED_MAX_BONUS) + minf(ENDLESS_SPEED_PER_MINUTE * endless_minutes(), ENDLESS_SPEED_MAX)
	if _cleared:
		return
	if endless:
		_endless_boss_t -= delta
		if _endless_boss_t <= 0.0 and calm <= 0.0:
			_endless_boss_t = ENDLESS_BOSS_EVERY
			var pool := _stage_bosses()
			if not pool.is_empty():
				var boss_id: String = pool.pick_random()
				_spawn(boss_id, _player.position + Vector2.from_angle(randf() * TAU) * _spawn_radius())
				boss_spawned.emit(boss_id)
	elif elapsed >= duration_minutes() * 60.0:
		_cleared = true
		var final_id: String = _stage.get("final_boss", "")
		if final_id == "":
			stage_cleared.emit()
		else:
			_enemies.clear_all()
			# The final boss carries the map's challenge too (a bit less than the rest).
			var boss := _enemies.spawn(final_id, _player.position + Vector2(0, -_spawn_radius() * 0.8), _player.stat("curse") * pow(challenge(), 0.8))
			final_boss_spawned.emit(boss)
		return
	if paused:
		return
	_tick_props(delta)
	_tick_traps(delta)
	_cap_timer -= delta
	if _cap_timer <= 0.0:
		_roll_cap()
	_lull_timer -= delta
	if _lull_timer <= 0.0:
		_lull_timer = randf_range(LULL_EVERY[0], LULL_EVERY[1])
		calm_for(randf_range(LULL_TIME[0], LULL_TIME[1]))
	if calm > 0.0:
		calm -= delta
		return
	_tick_events()
	var wave := current_wave()
	var radius := _spawn_radius()
	if int(wave["minute"]) != _wave_minute:
		_wave_minute = int(wave["minute"])
		# Bosses arrive a little after their wave starts, not on the dot.
		_pending_bosses.append_array(wave.get("bosses", []))
		_boss_timer = randf_range(BOSS_DELAY[0], BOSS_DELAY[1])
	for i in range(_wave_bosses.size() - 1, -1, -1):
		if not is_instance_valid(_wave_bosses[i]) or _wave_bosses[i].dead:
			_wave_bosses.remove_at(i)
	# Wave bosses come one at a time: the next waits until the last one falls.
	if not _pending_bosses.is_empty() and _wave_bosses.is_empty():
		_boss_timer -= delta
		if _boss_timer <= 0.0:
			var boss_id: String = _pending_bosses.pop_front()
			var boss := _spawn(boss_id, _player.position + Vector2.from_angle(randf() * TAU) * radius)
			if boss != null:
				_wave_bosses.append(boss)
			boss_spawned.emit(boss_id)
			_boss_timer = randf_range(BOSS_GAP[0], BOSS_GAP[1])
	if elapsed >= ELITE_FROM:
		_elite_timer -= delta
		if _elite_timer <= 0.0:
			_elite_timer = randf_range(ELITE_EVERY_RANGE[0], ELITE_EVERY_RANGE[1])
			var elite := _spawn((wave["enemies"] as Array).pick_random(), _player.position + Vector2.from_angle(randf() * TAU) * radius)
			if elite != null:
				elite.make_elite(ELITE_HP)
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = float(wave["interval"]) * randf_range(0.75, 1.25) / _player.stat("curse")
	_enemies.spawn_radius = radius
	_enemies.relocate_distance = radius * 1.5
	# Top up to the wave's minimum at once, then trickle in per_tick more,
	# always staying inside the budget.
	var budget := float(alive_cap())
	var minimum := minf(float(wave["minimum"]) * _player.stat("curse") * intensity(), budget)
	var pool: Array = wave["enemies"]
	var trickle := int(wave.get("per_tick", 1))
	var guard := 0
	while guard < 200:
		guard += 1
		var id: String = pool.pick_random()
		var cost := float(GameData.enemies[id].get("cost", 1.0))
		if _enemies.budget_used + cost > budget:
			break
		if _enemies.budget_used >= minimum:
			if trickle <= 0:
				break
			trickle -= 1
		_spawn(id, _player.position + Vector2.from_angle(randf() * TAU) * radius)


## A tough guard from the current wave (cursed shrines).
func spawn_guard(pos: Vector2) -> Enemy:
	var enemy := _spawn((current_wave()["enemies"] as Array).pick_random(), pos)
	if enemy != null:
		enemy.make_elite(ELITE_HP * 0.6)
	return enemy


func _spawn(id: String, pos: Vector2) -> Enemy:
	var enemy := _enemies.spawn(id, pos, hp_multiplier())
	if enemy != null:
		enemy.speed *= 1.0 + (_player.stat("curse") - 1.0) * 0.5
		if not enemy.is_boss and randf() < champion_chance():
			enemy.make_champion(GameData.champions.keys().pick_random())
	return enemy


## Share of regular spawns that come as champions: none in the first two
## minutes, then +0.4 % per minute up to 6 % (x curse).
func champion_chance() -> float:
	if "--champions" in GameData.args():
		return 0.5
	var minute := elapsed / 60.0
	return clampf((minute - 2.0) * CHAMPION_PER_MINUTE, 0.0, CHAMPION_MAX) * _player.stat("curse")


## Timed events from the stage: "ring" surrounds the cat with a closing
## circle, "swarm" sends a pack charging straight across the screen.
func _tick_events() -> void:
	if _events_done >= _events.size():
		return
	var ev: Dictionary = _events[_events_done]
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


## Keeps a few traps around the cat (they stay put; far ones are removed).
func _tick_traps(delta: float) -> void:
	for i in range(_traps.size() - 1, -1, -1):
		var t: Variant = _traps[i]
		if not is_instance_valid(t):
			_traps.remove_at(i)
		elif (t as Trap).position.distance_to(_player.position) > _spawn_radius() * 2.5:
			(t as Trap).queue_free()
			_traps.remove_at(i)
	_trap_timer -= delta
	if _trap_timer > 0.0:
		return
	_trap_timer = randf_range(4.0, 8.0)
	var kinds: Array = _stage.get("traps", [])
	if kinds.is_empty() or _traps.size() >= int(_stage.get("max_traps", 5)):
		return
	var trap := Trap.new()
	trap.position = Terrain.fix(_player.position + Vector2.from_angle(randf() * TAU) * _spawn_radius() * randf_range(0.9, 1.4), 30.0)
	trap.setup(kinds.pick_random(), get_parent())
	get_parent().add_child(trap)
	_traps.append(trap)


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
