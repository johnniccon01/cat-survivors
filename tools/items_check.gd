extends Node
## Checks the gear system (Items, Profile) from inside a run, where the
## autoloads exist: `-- --bot --items-test --bot-time=5` (main starts it).
## Prints "TEST: FAIL ..." for every problem (see BotLog) and
## "TEST: items checked" at the end. Never saves the profile (--bot).


func run(main: Node) -> void:
	_check_rolls()
	_check_legendaries()
	_check_worn(main.player)
	_check_profile()
	print("TEST: items checked")


## 10 000 random items: known base, the right slot, sane stats, readable text.
func _check_rolls() -> void:
	var data: Dictionary = GameData.items
	var rarities := {}
	for i in 10000:
		var item := Items.roll(1.0 + (i % 3) * 0.5)
		rarities[item["rarity"]] = int(rarities.get(item["rarity"], 0)) + 1
		var info := Items.info(item)
		if info.is_empty():
			BotLog.fail("item with unknown base %s" % item["base"])
			continue
		if item["slot"] != info["slot"] or item["slot"] not in Items.slots():
			BotLog.fail("item %s in the wrong slot %s" % [item["base"], item["slot"]])
		var stats: Dictionary = item["stats"]
		var want := 1 + int(data["rarities"][item["rarity"]]["extra"])
		if stats.size() != want:
			BotLog.fail("%s %s has %d stats, wants %d" % [item["rarity"], item["base"], stats.size(), want])
		if not stats.has(info["stat"]):
			BotLog.fail("item %s lacks its main stat %s" % [item["base"], info["stat"]])
		for stat: String in stats:
			var range_: Array = data["affixes"][stat]
			var mult := float(data["rarities"][item["rarity"]]["mult"])
			var lo := minf(float(range_[0]), float(range_[1])) * mult
			var hi := maxf(float(range_[0]), float(range_[1])) * mult
			var v := float(stats[stat])
			if v < lo - 1.0 or v > hi + 1.0 or v == 0.0:
				BotLog.fail("item %s rolled %s = %s (range %s..%s)" % [item["base"], stat, v, lo, hi])
		_check_text(item)
	for r in ["common", "rare"]:
		if int(rarities.get(r, 0)) == 0:
			BotLog.fail("no %s item in 10 000 rolls" % r)
	if int(rarities.get("legendary", 0)) > 0:
		BotLog.fail("legendaries came from random rolls")


## Every final boss has its legendary, with a name and a description.
func _check_legendaries() -> void:
	for stage_id: String in GameData.stages:
		var boss: String = GameData.stages[stage_id].get("final_boss", "")
		if boss != "" and Items.legendary_of(boss) == "":
			BotLog.fail("final boss %s has no legendary item" % boss)
	for id: String in GameData.items["legendaries"]:
		var item := Items.legendary(id)
		if not GameData.enemies.has(GameData.items["legendaries"][id]["boss"]):
			BotLog.fail("legendary %s comes from an unknown boss" % id)
		for stat: String in item["stats"]:
			if not Player.BASE_STATS.has(stat):
				BotLog.fail("legendary %s has unknown stat %s" % [id, stat])
		_check_text(item)


func _check_text(item: Dictionary) -> void:
	var text := Items.item_name(item) + " " + Items.describe(item)
	for key in ["ITEM_", "ISTAT_", "RARITY_", "%s", "%d"]:
		if key in text:
			BotLog.fail("untranslated text for %s: %s" % [item["base"], text.replace("\n", " | ")])
			return


## Banking, the full stash, wearing, melting, the timer rule and a save
## round trip (in memory only).
func _check_profile() -> void:
	var saved_items: Array = Profile.items.duplicate(true)
	var saved_worn: Dictionary = Profile.equipped_items.duplicate()
	var saved_gold := Profile.gold
	Profile.items.clear()
	Profile.equipped_items.clear()
	var found: Array = []
	for i in Profile.ITEM_STASH + 3:
		found.append(Items.roll())
	var melted := Profile.bank_items(found)
	if Profile.items.size() != Profile.ITEM_STASH or melted <= 0:
		BotLog.fail("a full stash kept %d items and melted %d gold" % [Profile.items.size(), melted])
	var uids := {}
	for item: Dictionary in Profile.items:
		uids[int(item["uid"])] = true
	if uids.size() != Profile.items.size() or uids.has(0):
		BotLog.fail("banked items don't have unique uids")
	# Wearing: one per slot, a second toggle takes it off.
	var first: Dictionary = Profile.items[0]
	Profile.toggle_item(int(first["uid"]))
	if Profile.worn_item(first["slot"]).get("uid") != first["uid"]:
		BotLog.fail("toggle_item did not put the item on")
	Profile.toggle_item(int(first["uid"]))
	if not Profile.worn_item(first["slot"]).is_empty():
		BotLog.fail("toggle_item did not take the item off")
	# Melting a worn item frees its slot.
	Profile.toggle_item(int(first["uid"]))
	var gold_before := Profile.gold
	Profile.salvage_item(int(first["uid"]))
	if not Profile.worn_item(first["slot"]).is_empty() or Profile.gold != gold_before + Items.salvage_gold(first):
		BotLog.fail("melting a worn item did not free the slot or pay")
	# Two ability timers keep the shorter one.
	Profile.items.clear()
	Profile.equipped_items.clear()
	Profile.bank_items([Items.legendary("POWER_CORD"), Items.legendary("KRAKEN_PEARL")])
	for item: Dictionary in Profile.items:
		Profile.toggle_item(int(item["uid"]))
	var bonus := Profile.item_bonus()
	if Profile.equipped_items.size() != 1:
		BotLog.fail("two collars worn at once")
	if bonus.has("pulse_magnet") and bonus.has("freeze_every"):
		BotLog.fail("both collars count at once")
	# Save round trip.
	var cfg := ConfigFile.new()
	cfg.set_value("items", "owned", Profile.items)
	cfg.set_value("items", "equipped", Profile.equipped_items)
	var back := ConfigFile.new()
	back.parse(cfg.encode_to_text())
	if back.get_value("items", "owned", []) != Profile.items or back.get_value("items", "equipped", {}) != Profile.equipped_items:
		BotLog.fail("items don't survive saving and loading")
	# A broken old profile: unknown bases and dangling slots are dropped.
	Profile.items.append({"uid": 999, "base": "NO_SUCH_ITEM", "slot": "HAT", "rarity": "common", "stats": {}})
	Profile.equipped_items["HAT"] = 999
	Profile.equipped_items["VEST"] = 12345
	Profile._clean_items()
	if not Profile.item_by_uid(999).is_empty() or Profile.equipped_items.has("HAT") or Profile.equipped_items.has("VEST"):
		BotLog.fail("_clean_items left a broken item or slot")
	Profile.items = saved_items
	Profile.equipped_items = saved_worn
	Profile.gold = saved_gold


## The worn gear (--gear=...) really changes the cat: on a fresh test profile
## its stats are the base, its own bonus and the gear, nothing else.
func _check_worn(player: Player) -> void:
	var gear := Profile.item_bonus()
	var own: Dictionary = GameData.cats[player.cat_id].get("bonus", {})
	for key: String in gear:
		var want := float(Player.BASE_STATS[key]) + float(own.get(key, 0.0)) + float(gear[key])
		if absf(player.stats[key] - want) > 0.001:
			BotLog.fail("worn gear gives %s = %s, the cat has %s" % [key, want, player.stats[key]])
	if not gear.is_empty():
		print("TEST: worn gear checked (%s)" % ", ".join(gear.keys()))
