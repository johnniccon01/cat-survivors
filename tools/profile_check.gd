extends SceneTree
## Checks the profile's save format handling without touching the player's
## profile: an old profile (no version) is migrated to Profile.SAVE_VERSION
## and keeps its data. Run with -- --ui-test.
##   godot --headless --path . -s res://tools/profile_check.gd -- --ui-test

var _t := 0


func _process(_d: float) -> bool:
	_t += 1
	if _t < 3:
		return false
	var profile := root.get_node("Profile")
	var failures := 0
	var cfg := ConfigFile.new()
	cfg.set_value("shop", "gold", 1234)
	cfg.set_value("cats", "unlocked", ["MICA", "LUNA"])
	var was: int = profile.migrate(cfg)
	if was != 0 or int(cfg.get_value("meta", "version", -1)) != profile.SAVE_VERSION:
		print("PROFILE: FAIL old profile not brought to version %d (was %d)" % [profile.SAVE_VERSION, was])
		failures += 1
	if int(cfg.get_value("shop", "gold", 0)) != 1234 or (cfg.get_value("cats", "unlocked", []) as Array).size() != 2:
		print("PROFILE: FAIL migration lost data")
		failures += 1
	# A profile already at today's version stays as it is.
	if profile.migrate(cfg) != profile.SAVE_VERSION:
		print("PROFILE: FAIL current profile migrated again")
		failures += 1
	# The saved shape carries the version.
	if int(profile.call("_config").get_value("meta", "version", -1)) != profile.SAVE_VERSION:
		print("PROFILE: FAIL saved profile has no version")
		failures += 1
	print("PROFILE: done, %d failures" % failures)
	quit(1 if failures > 0 else 0)
	return true
