class_name Quest
extends Node2D
## Base for a quest: a point of interest placed in the world plus the logic
## that runs once the cat reaches it. Subclasses override title(),
## objective(), _tick() and _draw(), and call complete() or fail().

signal finished(success: bool)

const OUTLINE := Color("2b1d14")

## The Main node (gives access to player, enemies, pickups, spawner, hud).
var main: Node
var quest_id := ""
var data: Dictionary
## Seconds before an unstarted quest disappears (<= 0: never).
var expire_after := 0.0
## True once the cat has reached the point of interest.
var started := false

var _age := 0.0
var _done := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -5


func title() -> String:
	return ""


func objective() -> String:
	return ""


## Where the quest arrow should point.
func target_position() -> Vector2:
	return position


## Distance at which the quest begins.
func start_radius() -> float:
	return float(GameData.quests.get("activate_radius", 240.0))


func player() -> Player:
	return main.player


func player_dist() -> float:
	return position.distance_to(main.player.position)


func complete() -> void:
	if _done:
		return
	_done = true
	main.hud.show_banner(tr("QUEST_DONE"), 2.5)
	Audio.play("quest_done", -4.0, 0.0)
	main.pickups.spawn_named("coin", main.player.position + Vector2(0, 16), 30.0)
	finished.emit(true)
	queue_free()


func fail() -> void:
	if _done:
		return
	_done = true
	main.hud.show_banner(tr("QUEST_FAILED"), 2.5)
	finished.emit(false)
	queue_free()


func _physics_process(delta: float) -> void:
	# A finished quest may still get one more tick before it is freed.
	if _done:
		return
	_age += delta
	if not started:
		if expire_after > 0.0 and _age > expire_after:
			fail()
			return
		if player_dist() < start_radius():
			started = true
			_on_start()
	_tick(delta)
	queue_redraw()


func _on_start() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


## Spawns `count` enemies of the current wave in a ring around `center`.
func spawn_wave_enemies(count: int, center: Vector2, min_r: float, max_r: float, enemy_id: String = "") -> Array[Enemy]:
	var spawned: Array[Enemy] = []
	var wave: Dictionary = main.spawner.current_wave()
	var pool: Array = wave["enemies"]
	var hp_mult: float = main.spawner.hp_multiplier()
	for i in count:
		var id: String = enemy_id if enemy_id != "" else pool.pick_random()
		var pos := center + Vector2.from_angle(TAU * i / count + randf() * 0.3) * randf_range(min_r, max_r)
		var e: Enemy = main.enemies.spawn(id, pos, hp_mult)
		if e != null:
			spawned.append(e)
	return spawned


## Number of enemies in the list still alive.
static func alive_count(list: Array[Enemy]) -> int:
	var n := 0
	for e in list:
		if is_instance_valid(e) and not e.dead:
			n += 1
	return n


## Progress ring around the point of interest.
func draw_progress_ring(radius: float, value: float, color: Color) -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(color, 0.25), 3.0)
	if value > 0.0:
		draw_arc(Vector2.ZERO, radius, -PI * 0.5, -PI * 0.5 + TAU * clampf(value, 0.0, 1.0), 40, color, 3.0)
