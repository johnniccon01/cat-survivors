class_name WolfPup
extends Node2D
## A wolf pup running beside the wolf (Species "wolf"): it keeps to one side
## of it and, when told, leaps at the nearest enemy close by and bites.

const LOOK_SCALE := 0.55

var leader: Player
## 0 = left of the wolf, 1 = right.
var slot := 0
var _look := {}
var _walk := 0.0
var _facing := 1
var _leap := 0.0
var _leap_to := Vector2.ZERO


func _ready() -> void:
	z_index = 2
	_look = CatArt.look("WOLF")
	if is_instance_valid(leader):
		position = leader.position


func _physics_process(delta: float) -> void:
	if not is_instance_valid(leader):
		queue_free()
		return
	var home := leader.position + Vector2(-26.0 if slot == 0 else 26.0, 14.0)
	var target := _leap_to if _leap > 0.0 else home
	_leap = maxf(_leap - delta, 0.0)
	var step := target - position
	var speed := 520.0 if _leap > 0.0 else maxf(step.length() * 6.0, 0.0)
	if step.length() > 1.0:
		position += step.normalized() * minf(speed * delta, step.length())
		_walk += delta
		if absf(step.x) > 0.5:
			_facing = 1 if step.x > 0.0 else -1
	queue_redraw()


## Leaps at the nearest enemy within `reach` of the wolf and bites it.
func bite(enemies: EnemyManager, damage: float, reach: float) -> void:
	var target := enemies.nearest(leader.position, reach)
	if target == null:
		return
	_leap_to = target.position
	_leap = 0.25
	target.hit(damage * leader.stat("might"), (target.position - position).normalized(), 0.6)
	BotLog.event("wolf_pup_bite")


func _draw() -> void:
	CatArt.draw(self, _look, _facing, _walk, false, false, "normal", Vector2.ZERO, LOOK_SCALE)
