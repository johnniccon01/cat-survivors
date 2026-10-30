extends SceneTree
## Plays through a few weeks of nights without ever defending and checks
## that sieges are rare and patient: each waits REPORT_DEFEND_NIGHTS nights
## before a raid, quiet nights follow, only the maps won last are besieged
## and a conquered map never is.
##   godot --headless --path . -s res://tools/siege_test.gd -- --ui-test

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(what: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("SIEGE: %s %s" % ["ok  " if ok else "FAIL", what])


func _run() -> void:
	var p: Node = get_root().get_node("Profile")
	p.reports.clear()
	p.siege_calm = 0
	p.kidnapped = "x"
	p.gold = 1000
	var won: Array[String] = ["LIVING_ROOM", "BASEMENT", "GARDEN", "ROOFTOP"]
	p.cleared_stages.assign(won)
	p.territories.assign(["ROOFTOP"])
	p.make_reports()
	var sieges := 0
	var raids := 0
	var nights := 21
	var stages := {}
	for n in nights:
		for r: Dictionary in p.reports:
			if r["kind"] == "defend":
				sieges += 1
				stages[r["stage"]] = true
		var before: int = p.report_news.size()
		p.pass_night()
		for k in range(before, p.report_news.size()):
			if p.report_news[k][0] == "REPORT_NEWS_THEFT":
				raids += 1
	# A siege is on show for 2 nights, then 2-3 quiet ones: 4-5 per siege.
	_check("raids %d in %d nights (4-6)" % [raids, nights], raids >= 4 and raids <= 6)
	_check("each siege waited 2 nights (%d shown, %d raids)" % [sieges, raids], sieges >= raids * 2 and sieges <= raids * 2 + 2)
	_check("only the last won, unconquered maps %s" % [stages.keys()], stages.keys().all(func(s: String) -> bool: return s in ["BASEMENT", "GARDEN"]))
	print("SIEGE: done, %d failures" % _failures)
	quit(1 if _failures > 0 else 0)
