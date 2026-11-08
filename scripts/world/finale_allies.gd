class_name FinaleAllies
extends Node
## The last fight: everyone the cats won over on the way comes to help.
## While the director's bulldozer is up, every few seconds the next ally
## turns up for a moment, says so, and hits the machine (and everything
## near it). Who comes: the friends that joined (Ruby, Rascal, Wolf, Bear,
## Lion...), the General after the peace, the parrot once it changed sides.

const EVERY := 9.0
## Each ally hits for this share of the boss's health.
const SHARE := 0.025

var main: Node
var boss: Enemy
var _queue: Array[String] = []
var _t := 4.0


## The allies who come, in the order they joined the story.
static func roster() -> Array[String]:
	var out: Array[String] = []
	for cat: String in ["RUBY", "RASCAL", "SHADOW", "SPARKY", "WOLF", "BEAR", "LION"]:
		if Profile.is_unlocked(cat):
			out.append(cat)
	if Profile.has_flag("dog_peace"):
		out.append("GENERAL")
	if Profile.has_flag("parrot_friend"):
		out.append("PARROT")
	# Always somebody: the cat's own family comes at least.
	if out.is_empty():
		out.append("MICA")
	return out


func _physics_process(delta: float) -> void:
	if not is_instance_valid(boss) or boss.dead:
		queue_free()
		return
	_t -= delta
	if _t > 0.0:
		return
	_t = EVERY
	if _queue.is_empty():
		_queue = roster()
	var ally: String = _queue.pop_front()
	var name_key := "ENEMY_PARROT_NAME" if ally == "PARROT" else "CAT_%s_NAME" % ally
	main.hud.show_banner(tr("FINALE_ALLY") % tr(name_key), 2.5)
	var ring := RingWave.new()
	ring.enemies = main.enemies
	ring.position = boss.position
	ring.max_radius = 160.0
	ring.expand_time = 0.4
	ring.damage = 30.0 * (1.0 + main.player.level * 0.1)
	ring.knockback = 3.0
	ring.color = Color("7cf0b8")
	main.add_child(ring)
	boss.hit(boss.max_hp * SHARE, Vector2.ZERO, 0.0, false)
	Audio.play("roar", -8.0, 0.3)
	BotLog.event("finale_ally:" + ally)
