class_name QuestBook
## The quest book (data/questbook.json): quest lines in the style of Halls of
## Torment, each a chain of steps checked against the profile - lifetime
## counters ("stat"), a single flag ("flag") or how many flags share a prefix
## ("flags", e.g. every "evolved:..." weapon). Steps pay out gold, a charm or
## a new cat. Profile.questbook stores how many steps of each line are done.
## A line with "cat" is named after that cat; one with "text" shares its step
## texts (QB_<text>_<n>) with other lines.


static func lines() -> Dictionary:
	return GameData.questbook.get("lines", {})


static func line_name(id: String) -> String:
	var cat: String = lines()[id].get("cat", "")
	return _t("CAT_%s_NAME" % cat) if cat != "" else _t("QB_%s_NAME" % id)


## Text of step n (1-based).
static func step_text(id: String, n: int) -> String:
	return _t("QB_%s_%d" % [lines()[id].get("text", id), n])


static func steps_done(id: String) -> int:
	return int(Profile.questbook.get(id, 0))


static func step_count(id: String) -> int:
	return (lines()[id]["tiers"] as Array).size()


static func is_complete(id: String) -> bool:
	return steps_done(id) >= step_count(id)


## The step the line is on now, or {} when the line is finished.
static func current(id: String) -> Dictionary:
	var tiers: Array = lines()[id]["tiers"]
	var n := steps_done(id)
	return tiers[n] if n < tiers.size() else {}


static func progress(step: Dictionary) -> int:
	match step.get("type", "stat"):
		"flag":
			return 1 if Profile.has_flag(step["flag"]) else 0
		"flags":
			var prefix: String = step["prefix"]
			return Profile.flags.filter(func(f: String) -> bool: return f.begins_with(prefix)).size()
	var total := 0
	for key: String in step["keys"]:
		total += Profile.get_stat(key)
	return total


static func target(step: Dictionary) -> int:
	return int(step.get("target", 1))


## Secret lines stay hidden until their first step has been reached.
static func is_hidden(id: String) -> bool:
	if not lines()[id].get("secret", false) or steps_done(id) > 0:
		return false
	var first: Dictionary = lines()[id]["tiers"][0]
	return progress(first) < target(first)


## Pays out every step that has just been reached (several in a row if
## possible). Returns [line id, step number (1-based)] pairs.
static func check() -> Array[Array]:
	var finished: Array[Array] = []
	for id: String in lines():
		while not is_complete(id):
			var step := current(id)
			if progress(step) < target(step):
				break
			Profile.questbook[id] = steps_done(id) + 1
			_pay(step["reward"])
			finished.append([id, steps_done(id)])
	if not finished.is_empty():
		Profile.save()
	return finished


static func _pay(reward: Dictionary) -> void:
	if reward.has("gold"):
		Profile.gold += int(reward["gold"])
	if reward.has("charm"):
		var charm: String = reward["charm"]
		if Profile.has_charm(charm):
			Profile.gold += Profile.DUPLICATE_CHARM_GOLD * 2
		else:
			Profile.charms.append(charm)
	if reward.has("cat"):
		Profile.unlock(reward["cat"])


static func reward_text(reward: Dictionary) -> String:
	if reward.has("cat"):
		return _t("QB_REWARD_CAT") % _t("CAT_%s_NAME" % reward["cat"])
	if reward.has("charm"):
		return _t("GOAL_REWARD_CHARM") % _t("CHARM_%s_NAME" % reward["charm"])
	return _t("GOAL_REWARD_GOLD") % int(reward.get("gold", 0))


## "Quest: Night Watch (step 2) – 200 gold"
static func completed_text(entry: Array) -> String:
	var id: String = entry[0]
	var n: int = entry[1]
	var reward: Dictionary = lines()[id]["tiers"][n - 1]["reward"]
	return _t("QB_COMPLETED") % [line_name(id), n, reward_text(reward)]


static func _t(key: String) -> String:
	return TranslationServer.translate(key)
