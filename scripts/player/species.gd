class_name Species
extends Node2D
## How the animals that aren't cats play (the "species" of data/cats.json).
## On top of their instinct each has its own body and a rule of its own, all
## automatic (no button):
## - dog (Ruby): sturdy and steady – more health and armour, a bigger nose
##   (magnet), a little slower.
## - wolf: never alone – two pups run with it and bite whatever comes close.
## - bear: a heavy brawler – much more health and armour, slow, and its
##   close-range weapons (claws, paws, hammers, tails, purr) hit much harder.
## - lion: the king – critical hits, and enemies close to it lose their nerve
##   and slow down.
## - raccoon (Rascal): a thief – luck and gold, and a chest may hold one more
##   upgrade.

const DATA := {
	"dog": {"stats": {"max_hp": 40.0, "armor": 1.0, "magnet": 30.0, "speed": -0.08}},
	"wolf": {"stats": {"speed": 0.05}, "pups": 2, "bite_every": 1.1, "bite_range": 95.0, "bite_damage": 7.0, "bite_per_level": 0.9},
	"bear": {"stats": {"max_hp": 60.0, "armor": 3.0, "speed": -0.15, "melee": 0.3}},
	"lion": {"stats": {"crit_chance": 0.08, "crit_mult": 0.3, "might": 0.05}, "aura": 80.0, "aura_slow": 0.75},
	"raccoon": {"stats": {"luck": 0.15, "greed": 0.2}, "chest_extra": 0.25},
}
## Weapons that hit up close (the bear's are stronger).
const MELEE := ["SCRATCH", "PAW_STOMP", "SQUEAKY_HAMMER", "TAIL_WHIP", "PURR", "CATNIP"]

var player: Player
var kind := ""
var _t := 0.0
var _pups: Array[Node2D] = []


## The species of a cat ("" for a cat).
static func of(cat_id: String) -> String:
	return String(GameData.cats.get(cat_id, {}).get("species", ""))


static func has(cat_id: String) -> bool:
	return DATA.has(Species.of(cat_id))


## The stats a species adds to the cat's own.
static func stats_of(cat_id: String) -> Dictionary:
	return DATA.get(Species.of(cat_id), {}).get("stats", {})


static func value(cat_id: String, key: String, default: float = 0.0) -> float:
	return float(DATA.get(Species.of(cat_id), {}).get(key, default))


func _ready() -> void:
	kind = Species.of(player.cat_id)
	for i in int(DATA[kind].get("pups", 0)):
		var pup := WolfPup.new()
		pup.leader = player
		pup.slot = i
		player.get_parent().add_child.call_deferred(pup)
		_pups.append(pup)


func _exit_tree() -> void:
	for pup in _pups:
		if is_instance_valid(pup):
			pup.queue_free()


func _physics_process(delta: float) -> void:
	if player.is_dead:
		return
	var enemies: EnemyManager = player.get_tree().get_first_node_in_group("enemy_manager")
	if enemies == null:
		return
	_t -= delta
	if _t > 0.0:
		return
	match kind:
		"wolf":
			_t = float(DATA["wolf"]["bite_every"])
			for pup in _pups:
				if is_instance_valid(pup):
					(pup as WolfPup).bite(enemies, float(DATA["wolf"]["bite_damage"]) + float(DATA["wolf"]["bite_per_level"]) * player.level, float(DATA["wolf"]["bite_range"]))
		"lion":
			_t = 0.5
			for e in enemies.query_radius(player.position, float(DATA["lion"]["aura"])):
				if not e.is_boss:
					e.slow_down(float(DATA["lion"]["aura_slow"]), 0.6)
		_:
			_t = 1.0
