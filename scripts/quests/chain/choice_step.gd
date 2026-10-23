extends ChainStep
## A story choice at the spot: the game pauses and asks. The answer is kept
## as the flag "choice:<CHAIN>:<option>", which later steps can need ("if").
## data: options (two keys; texts CHAIN_<ID>_<n>_<option>), ask text
## CHAIN_<ID>_<n>_ASK, look, rewards {option: reward}.

const REACH := 30.0

var _asked := false


func _tick(_delta: float) -> void:
	if _asked or player_dist() > REACH:
		return
	_asked = true
	var options: Array = data.get("options", ["A", "B"])
	var texts: Array = options.map(func(o: String) -> String: return _option_text(o))
	main.ask_choice(title(), tr("CHAIN_%s_%d_ASK" % [chain_id, step_no]), texts, _on_chosen)


## The option's text, plus what its artifact does – from this step's reward or
## from a later step only that option leads to.
func _option_text(option: String) -> String:
	var text := tr("CHAIN_%s_%d_%s" % [chain_id, step_no, option])
	var artifact := str(data.get("rewards", {}).get(option, {}).get("artifact", ""))
	if artifact == "":
		for step: Dictionary in steps(chain_id):
			if step.get("if", "") == "choice:%s:%s" % [chain_id, option]:
				artifact = str(step.get("reward", {}).get("artifact", ""))
				if artifact != "":
					break
	if artifact != "":
		text += "\n" + tr("ARTIFACT_%s_DESC" % artifact)
	return text


func _on_chosen(index: int) -> void:
	var option: String = data.get("options", ["A", "B"])[index]
	Profile.set_flag("choice:%s:%s" % [chain_id, option])
	var reward: Dictionary = data.get("rewards", {}).get(option, {})
	var cost := int(reward.get("cost", 0))
	if cost > 0:
		if Profile.gold < cost:
			main.hud.show_banner(tr("CHAIN_NO_GOLD") % cost, 3.0)
			fail()
			return
		Profile.gold -= cost
	if not reward.is_empty():
		QuestBook._pay(reward)
		main.hud.show_banner(QuestBook.reward_text(reward), 4.0)
	complete()


func _draw() -> void:
	draw_look(Vector2.ZERO, data.get("look", "hint"))
	draw_beacon(Vector2.ZERO, 22.0, Color("c77dff"))
