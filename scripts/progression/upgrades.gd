class_name Upgrades
## Builds the level-up offers and applies the chosen one.
## An offer is a Dictionary: { kind: "weapon"|"passive"|"heal", id, level }.

const HEAL_AMOUNT := 30.0

const STAT_TEXT := {
	"damage": "+%s poškodenie",
	"amount": "+%s projektil",
	"pierce": "+%s prieraz",
	"area": "+%s %% plocha",
	"speed": "+%s %% rýchlosť",
	"duration": "+%s %% trvanie",
	"interval": "%s s cooldown",
}
const PERCENT_STATS := ["area", "speed", "duration"]


static func roll(player: Player, count: int = 3) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for id: String in GameData.weapons:
		var data: Dictionary = GameData.weapons[id]
		var owned := player.get_weapon(id)
		if owned != null:
			if owned.level < owned.max_level():
				pool.append({"kind": "weapon", "id": id, "level": owned.level + 1, "weight": data.get("rarity", 100)})
		elif player.weapon_count() < Player.MAX_WEAPONS:
			pool.append({"kind": "weapon", "id": id, "level": 1, "weight": data.get("rarity", 100)})
	for id: String in GameData.passives:
		var data: Dictionary = GameData.passives[id]
		var lvl: int = player.passives.get(id, 0)
		if lvl == 0 and player.passives.size() >= Player.MAX_PASSIVES:
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


static func title(offer: Dictionary) -> String:
	match offer["kind"]:
		"weapon":
			return GameData.weapons[offer["id"]]["name"]
		"passive":
			return GameData.passives[offer["id"]]["name"]
	return "Sardinka"


static func tag(offer: Dictionary) -> String:
	if offer["kind"] == "heal":
		return ""
	if offer["level"] == 1:
		return "NOVÉ!" if offer["kind"] == "weapon" else "NOVÉ"
	return "Úroveň %d" % offer["level"]


static func description(offer: Dictionary) -> String:
	match offer["kind"]:
		"heal":
			return "Doplní %d zdravia." % HEAL_AMOUNT
		"passive":
			return GameData.passives[offer["id"]]["description"]
	var data: Dictionary = GameData.weapons[offer["id"]]
	if offer["level"] == 1:
		return data["description"]
	var lv: Dictionary = data["levels"][offer["level"] - 1]
	var parts: Array[String] = []
	for key: String in lv:
		if not STAT_TEXT.has(key):
			continue
		var value: float = lv[key]
		var shown: String
		if key in PERCENT_STATS:
			shown = str(roundi(value * 100.0))
		elif key == "interval":
			shown = ("%+.1f" % value).replace(".", ",")
		else:
			shown = str(roundi(value))
		parts.append(STAT_TEXT[key] % shown)
	return ", ".join(parts)


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
