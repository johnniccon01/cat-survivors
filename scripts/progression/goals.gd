class_name Goals
## Long-term goals (data/goals.json): each sums one or more lifetime stats
## from the profile and pays out gold or a charm once the target is reached.


static func progress(id: String) -> int:
	var total := 0
	for stat: String in GameData.goals[id]["stats"]:
		total += Profile.get_stat(stat)
	return total


static func target(id: String) -> int:
	return int(GameData.goals[id]["target"])


static func is_done(id: String) -> bool:
	return id in Profile.goals_done


## Pays out every goal that has just been reached; returns their ids.
static func check() -> Array[String]:
	var finished: Array[String] = []
	for id: String in GameData.goals:
		if is_done(id) or progress(id) < target(id):
			continue
		Profile.goals_done.append(id)
		var reward: Dictionary = GameData.goals[id]["reward"]
		if reward.has("gold"):
			Profile.gold += int(reward["gold"])
		if reward.has("charm"):
			var charm: String = reward["charm"]
			if Profile.has_charm(charm):
				Profile.gold += Profile.DUPLICATE_CHARM_GOLD * 2
			else:
				Profile.charms.append(charm)
		finished.append(id)
	if not finished.is_empty():
		Profile.save()
	return finished


## Translated reward text, e.g. "300 gold" or "Charm: Lucky Bell".
static func reward_text(id: String) -> String:
	var reward: Dictionary = GameData.goals[id]["reward"]
	if reward.has("charm"):
		return TranslationServer.translate("GOAL_REWARD_CHARM") % TranslationServer.translate("CHARM_%s_NAME" % reward["charm"])
	return TranslationServer.translate("GOAL_REWARD_GOLD") % int(reward.get("gold", 0))
