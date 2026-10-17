extends ChainStep
## Defeat enemies with traps only: traps are laid around the spot, and every
## enemy a trap finishes off counts. data: count, traps {id, count}.

var _traps: Array[Trap] = []
var _base := 0


func objective() -> String:
	return "%s %d/%d" % [step_text(), _kills(), int(data.get("count", 20))]


func _kills() -> int:
	return Profile.get_stat("trap_kills") - _base if started else 0


func _on_start() -> void:
	_base = Profile.get_stat("trap_kills")
	var traps: Dictionary = data.get("traps", {})
	var n := int(traps.get("count", 6))
	for i in n:
		var trap := Trap.new()
		trap.position = position + Vector2.from_angle(TAU * i / n) * randf_range(60.0, 150.0)
		trap.setup(traps.get("id", "MOUSETRAP"), main)
		main.add_child(trap)
		_traps.append(trap)


func _tick(_delta: float) -> void:
	if started and _kills() >= int(data.get("count", 20)):
		complete()


func _exit_tree() -> void:
	for trap in _traps:
		if is_instance_valid(trap):
			trap.queue_free()


func _draw() -> void:
	draw_beacon(Vector2.ZERO, 150.0 if started else 24.0, Color("f2c14e"))
