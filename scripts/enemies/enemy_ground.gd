class_name EnemyGround
extends Node2D
## Shadows and the light halo of every enemy, drawn by one node under them
## all. Drawn per enemy they split rendering into thousands of draw calls,
## which slows laptops down in big crowds.

var manager: EnemyManager


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if manager == null:
		return
	var halo := Color(1, 1, 1, Enemy.HALO * (2.2 if Settings.high_contrast else 1.0))
	var shadow := Color(0, 0, 0, 0.45)
	for e in manager.enemies:
		if e.dead or e.is_prop:
			continue
		var s := absf(e.scale.y)
		var alpha := e.self_modulate.a
		draw_circle(e.position + Vector2(0, -s), e.radius + 3.0 * s, Color(halo, halo.a * alpha))
		draw_colored_polygon(Shapes.ellipse(e.position + Vector2(s, e.radius + 2.0 * s), e.radius + 1.5 * s, 3.0 * s, 10), Color(shadow, shadow.a * alpha))
