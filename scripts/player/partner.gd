class_name Partner
extends Node
## The dog partner (from the Wild on): a dog chosen before the night runs
## with the cat as a companion and uses one ability of its own now and then.
## Who can come and what each does: data/partners.json; the dog's look and
## weapon come from data/cats.json like any companion's. Texts:
## PARTNER_<ID>_DESC (the dog's name is CAT_<ID>_NAME).

var main: Node
var dog: Player
var id := ""
var _t := 4.0


## Districts where a partner comes along.
const DISTRICTS := ["wild", "company"]


static func data(partner: String) -> Dictionary:
	return GameData.partners.get(partner, {})


## Whether `partner` has joined the cat for good (its "requires": "cat:ID",
## "stage:ID" or "flag:NAME").
static func available(partner: String) -> bool:
	var need: String = data(partner).get("requires", "")
	if need.begins_with("cat:"):
		return Profile.is_unlocked(need.substr(4))
	if need.begins_with("stage:"):
		return need.substr(6) in Profile.cleared_stages
	if need.begins_with("flag:"):
		return Profile.has_flag(need.substr(5))
	return need == ""


static func all_available() -> Array[String]:
	var out: Array[String] = []
	for p: String in GameData.partners:
		if available(p):
			out.append(p)
	return out


func _physics_process(delta: float) -> void:
	var player: Player = main.player
	if player == null or player.is_dead or not is_instance_valid(dog):
		return
	_t -= delta
	if _t > 0.0:
		return
	var d := data(id)
	var enemies: EnemyManager = main.enemies
	var power := 1.0 + player.level * 0.08
	match String(d.get("skill", "")):
		"bark":
			# Ruby barks: the crowd round her is pushed back and slowed.
			if enemies.nearest(dog.position, d["radius"]) == null:
				return
			for e in enemies.query_radius(dog.position, d["radius"]):
				if not e.is_boss:
					e._knock = (e.position - dog.position).normalized() * 240.0
				e.slow_down(0.6, 1.5)
			_ring(dog.position, d["radius"], Color("f2c14e"), 0.0)
			Audio.play("roar", -12.0, 0.4)
		"barrel":
			# The Saint Bernard's barrel: a drink when the cat is hurt.
			if player.hp > player.max_hp * 0.9:
				return
			player.heal(player.max_hp * d["heal"])
			_ring(player.position, 60.0, Color("7cf0b8"), 0.0)
		"hose":
			# Dotty the dalmatian sprays water round her.
			if enemies.nearest(dog.position, d["radius"]) == null:
				return
			for e in enemies.query_radius(dog.position, d["radius"]):
				e.slow_down(0.5, 2.0)
			_ring(dog.position, d["radius"], Color("6ab8f0"), d["damage"] * power)
			Audio.play("whoosh", -10.0)
		"command":
			# The General's command: a blast round the cat.
			if enemies.nearest(player.position, d["radius"]) == null:
				return
			_ring(player.position, d["radius"], Color("ff9a88"), d["damage"] * power)
			Audio.play("roar", -8.0, 0.1)
	_t = d.get("every", 10.0)
	BotLog.event("partner_skill:" + id)


func _ring(at: Vector2, r: float, color: Color, damage: float) -> void:
	var ring := RingWave.new()
	ring.enemies = main.enemies
	ring.position = at
	ring.max_radius = r
	ring.expand_time = 0.3
	ring.damage = damage
	ring.knockback = 2.0 if damage > 0.0 else 0.0
	ring.color = color
	main.add_child(ring)
