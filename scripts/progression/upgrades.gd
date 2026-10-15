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
