class_name Instinct
extends Node2D
## A cat's instinct: a small ability that fires by itself (no button).
## Every playable cat has one; it is kept weak on purpose, a flavour on top
## of the build, not a build of its own. Texts: INSTINCT_<CAT>_NAME / _DESC.

## cat -> values; "every" = seconds between uses, "cd" = cooldown after one.
const DATA := {
	"MICA": {"kills": 25, "cooldown": -0.15, "seconds": 4.0},
	"LUNA": {"every": 30.0, "crit": 0.1, "seconds": 5.0},
	"SNOWBALL": {"every": 20.0, "radius": 90.0, "slow": 0.5, "seconds": 3.0},
	"PIP": {"dodge": 0.12},
	"TIGER": {"below": 0.35, "cd": 45.0, "radius": 110.0, "might": 0.25, "seconds": 6.0},
	"BARON": {"might": 0.2, "seconds": 8.0},
	"CLOVER": {"coin": 0.03},
	"BRUNO": {"every": 15.0},
	"TUCKO": {"below": 0.4, "cd": 60.0, "heal": 0.25},
	"KAPITAN": {"rain_area": 0.1},
	"BOLT": {"every": 6.0, "range": 170.0, "damage": 16.0},
	"STRAY": {"reroll": 1},
	"ANGEL": {},
	"DEVIL": {"chance": 0.04, "radius": 48.0, "damage": 25.0},
}

var player: Player
var enemies: EnemyManager
var cat := ""
var _t := 0.0
var _kills := 0
## Bruno's shield is up; the angel's one rescue is still there.
var shield := false
var _saved := false


func _ready() -> void:
	_t = value("every")
	_connect()


func _connect() -> void:
	enemies = get_tree().get_first_node_in_group("enemy_manager")
	if enemies != null:
		enemies.enemy_killed.connect(_on_kill)
		enemies.elite_killed.connect(_on_elite)


static func has(cat_id: String) -> bool:
	return DATA.has(cat_id)


func value(key: String, default: float = 0.0) -> float:
	return float(DATA.get(cat, {}).get(key, default))


func _physics_process(delta: float) -> void:
	if enemies == null:
		_connect()
	if player == null or player.is_dead or enemies == null:
		return
	_t -= delta
	match cat:
		"LUNA":
			if _t <= 0.0:
				_t = value("every")
				player.bless({"crit_chance": value("crit")}, value("seconds"), "INSTINCT_LUNA_NAME", Color("f2d14e"))
				_fire()
		"SNOWBALL":
			if _t <= 0.0 and enemies.nearest(player.position, value("radius")) != null:
				_t = value("every")
				for e in enemies.query_radius(player.position, value("radius")):
					e.slow_down(value("slow"), value("seconds"))
					e.chill(value("seconds"))
				_ring(value("radius"), Color("8fd3ff"))
				_fire()
				Audio.play("whoosh", -10.0)
		"BRUNO":
			if not shield and _t <= 0.0:
				shield = true
				_fire()
				queue_redraw()
		"TIGER":
			if _t <= 0.0 and player.hp < player.max_hp * value("below"):
				_t = value("cd")
				for e in enemies.query_radius(player.position, value("radius")):
					if not e.is_boss:
						e._knock = (e.position - player.position).normalized() * 260.0
				player.bless({"might": value("might")}, value("seconds"), "INSTINCT_TIGER_NAME", Color("ff8a3d"))
				_fire()
				_ring(value("radius"), Color("ff8a3d"))
				Audio.play("roar", -6.0)
		"TUCKO":
			if _t <= 0.0 and player.hp < player.max_hp * value("below"):
				_t = value("cd")
				player.heal(player.max_hp * value("heal"))
				_fire()
				_ring(30.0, Color("6cc46c"))
				Audio.play("heal", -6.0)
		"BOLT":
			if _t <= 0.0:
				var target := enemies.nearest(player.position, value("range"))
				if target != null:
					_t = value("every")
					target.hit(value("damage") * player.stat("might"), target.position - player.position, 0.3)
					var bolt := ChainBolt.new()
					bolt.points = PackedVector2Array([player.position, target.position])
					player.get_parent().add_child(bolt)
					Audio.play("zap", -14.0)
					_fire()


## How much of a hit lands: Pip may slip away, Bruno's shield takes it whole.
func absorb(amount: float) -> float:
	if cat == "PIP" and randf() < value("dodge"):
		_ring(16.0, Color.WHITE)
		_fire()
		return 0.0
	if cat == "BRUNO" and shield:
		shield = false
		_fire()
		_t = value("every")
		_ring(20.0, Color("c9a882"))
		queue_redraw()
		return 0.0
	return amount


## The angel shrugs off the first deadly hit of a night.
func cheat_death() -> bool:
	if cat != "ANGEL" or _saved:
		return false
	_saved = true
	_fire()
	_ring(60.0, Color("fff3c0"))
	return true


func _on_kill(id: String, pos: Vector2, _xp: float) -> void:
	if player == null or player.is_dead:
		return
	var data: Dictionary = GameData.enemies.get(id, {})
	var boss: bool = data.get("boss", false) or data.get("final", false)
	match cat:
		"MICA":
			_kills += 1
			if _kills >= int(value("kills")):
				_kills = 0
				player.bless({"cooldown": value("cooldown")}, value("seconds"), "INSTINCT_MICA_NAME", Color("ff9a4a"))
				_fire()
		"CLOVER":
			if randf() < value("coin"):
				var pickups := get_tree().get_first_node_in_group("pickups") as Pickups
				if pickups != null:
					pickups.spawn_named("coin", pos, 1.0)
					_fire()
		"BARON":
			if boss:
				_baron()
		"STRAY":
			if boss:
				player.rerolls_left += int(value("reroll"))
				_fire()
				player.inventory_changed.emit()
		"DEVIL":
			if randf() < value("chance"):
				for e in enemies.query_radius(pos, value("radius")):
					e.hit(value("damage") * player.stat("might"), e.position - pos, 0.5, false)
				var ring := RingWave.new()
				ring.enemies = enemies
				ring.position = pos
				ring.max_radius = value("radius")
				ring.expand_time = 0.15
				ring.damage = 0.0
				ring.knockback = 0.0
				ring.color = Color("ff3030")
				_fire()
				player.get_parent().add_child(ring)


func _on_elite(_pos: Vector2) -> void:
	if cat == "BARON" and player != null and not player.is_dead:
		_baron()


func _baron() -> void:
	player.bless({"might": value("might")}, value("seconds"), "INSTINCT_BARON_NAME", Color("4a8fe0"))
	_fire()


## Test runs check that every instinct really fires.
func _fire() -> void:
	BotLog.event("instinct:" + cat)


func _ring(r: float, color: Color) -> void:
	var ring := RingWave.new()
	ring.enemies = enemies
	ring.position = player.position
	ring.max_radius = r
	ring.expand_time = 0.2
	ring.damage = 0.0
	ring.knockback = 0.0
	ring.color = color
	player.get_parent().add_child(ring)


func _process(_delta: float) -> void:
	if shield:
		queue_redraw()


func _draw() -> void:
	# Bruno's shield: a faint ring round the cat while it is up.
	if shield and player != null and not player.is_dead:
		var a := 0.45 + 0.15 * sin(Time.get_ticks_msec() * 0.006)
		draw_arc(Vector2(0, 2), 15.0 * float(player.get("_look")["size"]), 0, TAU, 28, Color(0.85, 0.72, 0.5, a), 1.5)
