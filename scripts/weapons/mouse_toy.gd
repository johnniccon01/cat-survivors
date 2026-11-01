extends Weapon
## Myška na kľúčik: lets wind-up mice loose; each scurries off in a wobbly
## line (towards a random nearby enemy if there is one) and bumps through
## a few enemies. Robo-Mouse homes in on enemies and explodes.

const RANGE := 200.0


func shoot(_index: int) -> void:
	Audio.play("throw", -14.0 - (6.0 if player.is_companion() else 0.0))
	var dir := Vector2.from_angle(randf() * TAU)
	var targets := enemies.query_radius(player.position, RANGE)
	# Chase combo: the mice go for what the laser dot marked.
	var chase := player.has_combo("CHASE")
	var marked := targets.filter(func(e: Enemy) -> bool: return e.mark_t > 0.0) if chase else []
	if not marked.is_empty():
		dir = (marked.pick_random().position - player.position).normalized()
	elif not targets.is_empty():
		dir = (targets.pick_random().position - player.position).normalized().rotated(randf_range(-0.3, 0.3))
	var mouse := ToyMouse.new()
	mouse.source = self
	mouse.enemies = enemies
	mouse.position = player.position + Vector2(0, 4)
	mouse.velocity = dir * proj_speed()
	mouse.damage = damage()
	mouse.knockback = stat("knockback", 0.4)
	mouse.pierce = int(stat("pierce", 1.0))
	mouse.lifetime = duration()
	mouse.scale_k = area()
	mouse.robo = data.get("robo", false)
	mouse.chase = chase
	mouse.blast_radius = 52.0 * area()
	world.add_child(mouse)
