class_name Spawner
extends Node
## Spawns enemies just outside the screen following the stage's per-minute
## wave table (data/stages.json). Also owns the run clock: bosses arrive when
## a wave that lists them begins, and the stage is cleared after
## duration_minutes.

signal boss_spawned(boss_id: String)
signal stage_cleared

const SPAWN_MARGIN := 40.0

@export var stage_id := "LIVING_ROOM"

var elapsed := 0.0

var _player: Player
var _enemies: EnemyManager
var _stage: Dictionary
var _timer := 0.0
var _prop_timer := 1.0
var _wave_minute := -1
var _cleared := false


func setup(player: Player, enemies: EnemyManager) -> void:
	_player = player
	_enemies = enemies
	_stage = GameData.stages[stage_id]


func current_wave() -> Dictionary:
	var minute := floori(elapsed / 60.0)
	var waves: Array = _stage["waves"]
	var wave: Dictionary = waves[0]
	for w: Dictionary in waves:
		if int(w["minute"]) <= minute:
			wave = w
	return wave


func _physics_process(delta: float) -> void:
	if _player == null or _player.is_dead:
		return
	if _cleared:
		return
	elapsed += delta
	if elapsed >= float(_stage.get("duration_minutes", 30)) * 60.0:
		_cleared = true
		stage_cleared.emit()
		return
	_tick_props(delta)
	var wave := current_wave()
	var radius := _spawn_radius()
	if int(wave["minute"]) != _wave_minute:
		_wave_minute = int(wave["minute"])
		var hp_mult_boss := float(wave.get("hp_mult", 1.0))
		for boss_id: String in wave.get("bosses", []):
			_enemies.spawn(boss_id, _player.position + Vector2.from_angle(randf() * TAU) * radius, hp_mult_boss)
			boss_spawned.emit(boss_id)
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = float(wave["interval"])
	_enemies.spawn_radius = radius
	_enemies.relocate_distance = radius * 1.5
	# Top up to the wave's minimum at once, then trickle more in until the
	# wave's maximum (default: twice the minimum) is reached.
	var alive := _enemies.enemies.size()
	var minimum := int(wave["minimum"])
	var maximum := mini(int(wave.get("maximum", minimum * 2)), EnemyManager.MAX_ENEMIES - 50)
	var count := int(wave.get("per_tick", 1)) if alive < maximum else 0
	count = maxi(count, minimum - alive)
	var pool: Array = wave["enemies"]
	var hp_mult := float(wave.get("hp_mult", 1.0))
	for i in count:
		var dir := Vector2.from_angle(randf() * TAU)
		_enemies.spawn(pool.pick_random(), _player.position + dir * radius, hp_mult)


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
