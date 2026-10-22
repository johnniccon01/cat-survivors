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
	var halo := Color(1, 1, 1, Enemy.HALO * (4.0 if Settings.high_contrast else 1.0))
	var halo_grow := 5.0 if Settings.high_contrast else 3.0
	var shadow := Color(0, 0, 0, 0.45)
	for e in manager.enemies:
		if e.dead or e.is_prop:
			continue
		var s := absf(e.scale.y)
		var alpha := e.self_modulate.a
		Blit.disc(self, e.position + Vector2(0, -s), e.radius + halo_grow * s, Color(halo, halo.a * alpha))
		Blit.ellipse(self, e.position + Vector2(s, e.radius + 2.0 * s), e.radius + 1.5 * s, 3.0 * s, Color(shadow, shadow.a * alpha))
		# Champion aura, the golden mouse's glow and the ring of an enemy
		# appearing on screen (drawn here, under the sprites, so the crowd's
		# sprites stay one batch).
		if e.champion != "":
			Blit.ellipse(self, e.position + Vector2(0, e.radius + s), e.radius + 4.0 * s, 4.5 * s, Color(e.champion_color, 0.35))
			Blit.ring(self, e.position + Vector2(0, -s), e.radius + 3.5 * s, s, Color(e.champion_color, 0.8))
		if e.id == "GOLDEN_MOUSE":
			for k in 3:
				Blit.disc(self, e.position + Vector2(0, -s), e.radius + (2.0 + k * 3.0) * s, Color(1.0, 0.85, 0.3, 0.12))
		if e.spawn_in > 0.0:
			var t := 1.0 - e.spawn_in / Enemy.SPAWN_IN
			Blit.ring(self, e.position + Vector2(0, e.radius * 0.5), e.radius + (6.75 - 6.0 * t) * s, 1.5 * s, Color(1.0, 0.35, 0.3, 0.8 * alpha))
