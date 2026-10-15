class_name Spawner
extends Node
## Spawns enemies just outside the screen following the stage's per-minute
## wave table (data/stages.json). Also owns the run clock.

const SPAWN_MARGIN := 40.0

@export var stage_id := "LIVING_ROOM"

var elapsed := 0.0

var _player: Player
var _enemies: EnemyManager
var _stage: Dictionary
var _timer := 0.0


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
	elapsed += delta
	_timer -= delta
	if _timer > 0.0:
		return
	var wave := current_wave()
	_timer = float(wave["interval"])
	var radius := _spawn_radius()
	_enemies.spawn_radius = radius
	_enemies.relocate_distance = radius * 1.5
	# Top up to the wave's minimum at once, then trickle more in until the
	# wave's maximum (default: twice the minimum) is reached.
	var alive := _enemies.enemies.size()
	var minimum := int(wave["minimum"])
	var maximum := int(wave.get("maximum", minimum * 2))
	var count := int(wave.get("per_tick", 1)) if alive < maximum else 0
	count = maxi(count, minimum - alive)
	var pool: Array = wave["enemies"]
	var hp_mult := float(wave.get("hp_mult", 1.0))
	for i in count:
		var dir := Vector2.from_angle(randf() * TAU)
		_enemies.spawn(pool.pick_random(), _player.position + dir * radius, hp_mult)


func _spawn_radius() -> float:
	var view := get_viewport().get_visible_rect().size / _player.camera.zoom
	return view.length() * 0.5 + SPAWN_MARGIN
