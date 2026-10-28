extends ChainStep
## A named boss waits at the spot. data: enemy, hp_mult, look (what the spot
## looks like before), rule "no_heal" (picking up a heart fails the step),
## solo (the other enemies vanish and stay away until the fight ends;
## always on with "no_heal"), time_limit (0 = none).

var _boss: Enemy
var _left := 0.0
var _solo := false


func objective() -> String:
	if started and float(data.get("time_limit", 0.0)) > 0.0:
		return "%s · %s" % [step_text(), timer_text(_left)]
	return step_text()


func target_position() -> Vector2:
	return _boss.position if is_instance_valid(_boss) else position


func _on_start() -> void:
	var id: String = data["enemy"]
	_solo = bool(data.get("solo", false)) or data.get("rule", "") == "no_heal"
	if _solo:
		main.enemies.clear_all()
		main.spawner.paused = true
	_boss = main.enemies.spawn(id, position, main.spawner.hp_multiplier() * float(data.get("hp_mult", 1.0)))
	main.spawner.toughen(_boss)
	_left = float(data.get("time_limit", 0.0))
	main.enemies.enemy_killed.connect(_on_killed)
	if data.get("rule", "") == "no_heal":
		main.pickups.heart_collected.connect(_on_heal)
	Audio.play("roar", -4.0, 0.0)


func _tick(delta: float) -> void:
	if not started or float(data.get("time_limit", 0.0)) <= 0.0:
		return
	_left -= delta
	if _left <= 0.0:
		if is_instance_valid(_boss) and not _boss.dead:
			main.enemies.despawn(_boss)
		fail()


func _on_killed(enemy_id: String, _pos: Vector2, _xp: float) -> void:
	if enemy_id == data["enemy"]:
		complete()


func _on_heal() -> void:
	if is_instance_valid(_boss) and not _boss.dead:
		main.enemies.despawn(_boss)
	main.hud.show_banner(tr("CHAIN_HEALED"), 3.0)
	fail()


func _draw() -> void:
	if not started:
		draw_look(Vector2.ZERO, data.get("look", "hint"))
		draw_beacon(Vector2.ZERO, 26.0, Color("e04646"))


func _exit_tree() -> void:
	if _solo:
		main.spawner.paused = false
