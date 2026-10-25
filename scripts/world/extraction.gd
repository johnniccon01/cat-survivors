class_name Extraction
extends Node2D
## A cat flap that opens for a short time after a boss falls or a quest is
## done. Stay inside it for CHANNEL_TIME seconds (enemies rush in meanwhile)
## to slip out and end the run safely, keeping all gold and loot.

signal escaped
signal closed

const OPEN_TIME := 60.0
const CHANNEL_TIME := 3.0
const RADIUS := 36.0
const PRESSURE_EVERY := 1.0
const OUTLINE := Color("2b1d14")
const GLOW := Color("6cd48a")

var main: Node
var time_left := OPEN_TIME
var progress := 0.0

var _pressure := 0.0
var _t := 0.0
var _done := false
var _declined := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -4


func _physics_process(delta: float) -> void:
	if _done:
		return
	_t += delta
	time_left -= delta
	if time_left <= 0.0:
		_done = true
		closed.emit()
		queue_free()
		return
	var inside: bool = position.distance_to(main.player.position) < RADIUS
	# After "stay", the flap waits until the cat steps out before asking again.
	if _declined:
		_declined = inside
		inside = false
	if inside:
		progress += delta / CHANNEL_TIME
		# The house doesn't want you to leave: enemies pour in while you squeeze through.
		_pressure -= delta
		if _pressure <= 0.0:
			_pressure = PRESSURE_EVERY
			var wave: Dictionary = main.spawner.current_wave()
			for i in 3:
				main.enemies.spawn((wave["enemies"] as Array).pick_random(), position + Vector2.from_angle(randf() * TAU) * 150.0, main.spawner.hp_multiplier())
	else:
		progress = maxf(progress - delta * 0.3, 0.0)
	if progress >= 1.0:
		_ask()
	queue_redraw()


## Leaving ends the run, so the cat is asked first (an easy thing to walk into).
func _ask() -> void:
	_done = true
	main.ask_choice(tr("EXTRACT_ASK_TITLE"), tr("EXTRACT_ASK"), [tr("EXTRACT_YES"), tr("EXTRACT_NO")],
			func(index: int) -> void:
				if index == 0:
					escaped.emit()
				else:
					_done = false
					_declined = true
					progress = 0.0)


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 4.0)
	draw_circle(Vector2.ZERO, RADIUS + 8.0, Color(GLOW, 0.12 + 0.1 * pulse))
	# Door with a cat flap.
	draw_rect(Rect2(-22, -40, 44, 56), OUTLINE)
	draw_rect(Rect2(-20, -38, 40, 52), Color("8a5a3b"))
	draw_rect(Rect2(-16, -34, 32, 20), Color("7a4e33"))
	draw_circle(Vector2(14, -8), 2.0, Color("f2c14e"))
	draw_rect(Rect2(-10, -2, 20, 16), OUTLINE)
	draw_rect(Rect2(-9, -1, 18, 14), Color("3a2a22"))
	draw_rect(Rect2(-9, -1, 18, 3), Color("5a4a3a"))
	# Paw prints leading in.
	for i in 3:
		draw_circle(Vector2(-4 + (i % 2) * 8, 24 + i * 9), 2.0, Color(GLOW, 0.7))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 40, Color(GLOW, 0.5), 2.0)
	if progress > 0.0:
		draw_arc(Vector2.ZERO, RADIUS, -PI * 0.5, -PI * 0.5 + TAU * progress, 40, GLOW, 4.0)
