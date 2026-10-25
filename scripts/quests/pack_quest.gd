class_name PackQuest
extends Quest
## The pack leaders: a few big, tough enemies with a crown turn up around
## the spot; defeat them all before time runs out.

var _leaders: Array[Enemy] = []
var _left := 0.0


func title() -> String:
	return tr("QUEST_PACK_TITLE")


func objective() -> String:
	if not started:
		return tr("QUEST_PACK_FIND")
	return tr("QUEST_PACK_FIGHT") % [Quest.alive_count(_leaders), ceili(_left)]


func target_position() -> Vector2:
	for e in _leaders:
		if is_instance_valid(e) and not e.dead:
			return e.position
	return position


func _on_start() -> void:
	_left = float(data["time_limit"])
	_leaders = spawn_wave_enemies(int(data["count"]), position, 140.0, 220.0)
	for e in _leaders:
		e.make_elite(float(data["hp_mult"]))
	Audio.play("roar", -4.0, 0.0)


func _tick(delta: float) -> void:
	if not started:
		return
	_left -= delta
	if Quest.alive_count(_leaders) == 0:
		main.pickups.spawn_named("chest", main.player.position + Vector2(0, -24), 0.0)
		complete()
	elif _left <= 0.0:
		fail()


func _draw() -> void:
	if not started:
		# A torn-up patch of ground where the pack gathers.
		draw_circle(Vector2.ZERO, 14.0, Color(0.35, 0.22, 0.12, 0.6))
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 24, Color(0.9, 0.4, 0.3, 0.6), 2.0)
		return
	# A small crown over every leader still standing.
	for e in _leaders:
		if not is_instance_valid(e) or e.dead:
			continue
		var at := e.position - position + Vector2(0, -e.radius * 1.6 - 10.0)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-8, 4), at + Vector2(-8, -4), at + Vector2(-4, 0), at + Vector2(0, -6), at + Vector2(4, 0), at + Vector2(8, -4), at + Vector2(8, 4)]), Color("f2c14e"))
		draw_polyline(PackedVector2Array([at + Vector2(-8, 4), at + Vector2(-8, -4), at + Vector2(-4, 0), at + Vector2(0, -6), at + Vector2(4, 0), at + Vector2(8, -4), at + Vector2(8, 4), at + Vector2(-8, 4)]), OUTLINE, 1.0)
