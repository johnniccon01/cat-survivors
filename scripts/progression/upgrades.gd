class_name Upgrades
## Builds the level-up offers and applies the chosen one.
## An offer is a Dictionary: { kind: "weapon"|"passive"|"heal", id, level }.

const HEAL_AMOUNT := 30.0

## Translation key for each weapon stat shown in level-up descriptions.
const STAT_TEXT := {
	"damage": "STAT_DAMAGE",
	"amount": "STAT_AMOUNT",
	"pierce": "STAT_PIERCE",
	"area": "STAT_AREA",
	"speed": "STAT_SPEED",
	"duration": "STAT_DURATION",
	"interval": "STAT_INTERVAL",
}
const PERCENT_STATS := ["area", "speed", "duration"]


## Picks `count` random offers. With `owned_only`, only items the cat
## already has can show up (used by treasure chests).
static func roll(player: Player, count: int = 3, owned_only: bool = false) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for id: String in GameData.weapons:
		var data: Dictionary = GameData.weapons[id]
		if data.get("evolved", false):
			continue
		var owned := player.get_weapon(id)
		if owned != null:
			if owned.level < owned.max_level():
				pool.append({"kind": "weapon", "id": id, "level": owned.level + 1, "weight": data.get("rarity", 100)})
		elif not owned_only and player.weapon_count() < Player.MAX_WEAPONS and not _has_evolution_of(player, id):
			pool.append({"kind": "weapon", "id": id, "level": 1, "weight": data.get("rarity", 100)})
	for id: String in GameData.passives:
		var data: Dictionary = GameData.passives[id]
		var lvl: int = player.passives.get(id, 0)
		if lvl == 0 and (owned_only or player.passives.size() >= Player.MAX_PASSIVES):
			continue
		if lvl < data["levels"].size():
			pool.append({"kind": "passive", "id": id, "level": lvl + 1, "weight": data.get("rarity", 100)})

	var offers: Array[Dictionary] = []
	while offers.size() < count and not pool.is_empty():
		var pick := _weighted_pick(pool)
		offers.append(pool[pick])
		pool.remove_at(pick)
	if offers.is_empty():
		offers.append({"kind": "heal", "id": "HEAL", "level": 0})
	return offers


static func apply(player: Player, offer: Dictionary) -> void:
	match offer["kind"]:
		"weapon":
			if offer["level"] == 1:
				player.add_weapon(offer["id"])
			else:
				player.level_up_weapon(offer["id"])
		"passive":
			player.add_passive(offer["id"])
		"heal":
			player.heal(HEAL_AMOUNT)


## Opens a treasure chest: evolves a ready weapon first, otherwise levels up
## random owned items. Returns the applied offers (evolutions have
## "evolved": true) for the treasure screen.
static func open_chest(player: Player, count: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for i in count:
		var evo := find_evolution(player)
		if not evo.is_empty():
			player.evolve_weapon(evo["from"], evo["into"])
			results.append({"kind": "weapon", "id": evo["into"], "level": 1, "evolved": true})
			continue
		var offer: Dictionary = roll(player, 1, true)[0]
		apply(player, offer)
		results.append(offer)
	return results


## A weapon at max level whose partner passive is owned, or {} if none.
static func find_evolution(player: Player) -> Dictionary:
	for weapon: Weapon in player.weapons.get_children():
		var evolve: Dictionary = weapon.data.get("evolve", {})
		if evolve.is_empty() or weapon.level < weapon.max_level():
			continue
		if player.passives.has(evolve["with"]):
			return {"from": weapon.id, "into": evolve["into"]}
	return {}


static func _has_evolution_of(player: Player, id: String) -> bool:
	var evolve: Dictionary = GameData.weapons[id].get("evolve", {})
	return not evolve.is_empty() and player.get_weapon(evolve["into"]) != null


## Translated name of a weapon or passive.
static func item_name(kind: String, id: String) -> String:
	return _t("%s_%s_NAME" % [kind.to_upper(), id])


static func title(offer: Dictionary) -> String:
	if offer["kind"] == "heal":
		return _t("HEAL_NAME")
	return item_name(offer["kind"], offer["id"])


static func tag(offer: Dictionary) -> String:
	if offer["kind"] == "heal":
		return ""
	if offer["level"] == 1:
		return _t("TAG_NEW")
	return _t("TAG_LEVEL") % offer["level"]


static func description(offer: Dictionary) -> String:
	var text := _base_description(offer)
	var hint := _evolution_hint(offer)
	return text if hint == "" else "%s
%s" % [text, hint]


## Tells which passive evolves a weapon (shown at its last level) and which
## weapon a passive can evolve.
static func _evolution_hint(offer: Dictionary) -> String:
	match offer["kind"]:
		"weapon":
			var data: Dictionary = GameData.weapons[offer["id"]]
			var evolve: Dictionary = data.get("evolve", {})
			if not evolve.is_empty() and offer["level"] == data["levels"].size():
				return _t("EVOLVE_HINT") % item_name("passive", evolve["with"])
		"passive":
			for id: String in GameData.weapons:
				var evolve: Dictionary = GameData.weapons[id].get("evolve", {})
				if evolve.get("with", "") == offer["id"]:
					return _t("EVOLVE_PAIR") % item_name("weapon", id)
	return ""


static func _base_description(offer: Dictionary) -> String:
	var kind: String = offer["kind"]
	if kind == "heal":
		return _t("HEAL_DESC") % HEAL_AMOUNT
	if kind == "passive" or offer["level"] == 1:
		return _t("%s_%s_DESC" % [kind.to_upper(), offer["id"]])
	var lv: Dictionary = GameData.weapons[offer["id"]]["levels"][offer["level"] - 1]
	var parts: Array[String] = []
	for key: String in lv:
		if not STAT_TEXT.has(key):
			continue
		var value: float = lv[key]
		var shown: String
		if key in PERCENT_STATS:
			shown = str(roundi(value * 100.0))
		elif key == "interval":
			shown = ("%+.1f" % value).replace(".", _t("DECIMAL_SEP"))
		else:
			shown = str(roundi(value))
		parts.append(_t(STAT_TEXT[key]) % shown)
	return ", ".join(parts)


static func _t(key: String) -> String:
	return String(TranslationServer.translate(key))


static func _weighted_pick(pool: Array[Dictionary]) -> int:
	var total := 0.0
	for o in pool:
		total += float(o["weight"])
	var r := randf() * total
	for i in pool.size():
		r -= float(pool[i]["weight"])
		if r <= 0.0:
			return i
	return pool.size() - 1
