class_name BotLog
## What happened in a test run, for the checks: game code calls event() at
## the moments worth checking (a boss's arena went up, its second phase
## began...). At the end of a --bot run main calls verify(), which prints
## "TEST: FAIL ..." for every event in --expect=a,b that never happened and
## every one in --expect-not=a,b that did; fail() reports a broken rule
## straight away. Outside test runs nothing is printed.

static var events := {}


static func on() -> bool:
	return "--bot" in GameData.args()


static func event(key: String) -> void:
	if not on():
		return
	if not events.has(key):
		print("BOT: event ", key)
	events[key] = int(events.get(key, 0)) + 1


## A rule that must always hold was broken (printed once per message).
static func fail(msg: String) -> void:
	if not on() or events.has("fail:" + msg):
		return
	events["fail:" + msg] = 1
	print("TEST: FAIL ", msg)


static func verify() -> void:
	for arg: String in GameData.args():
		if arg.begins_with("--expect="):
			for key in arg.trim_prefix("--expect=").split(",", false):
				if not events.has(key):
					print("TEST: FAIL expected event %s never happened" % key)
		elif arg.begins_with("--expect-not="):
			for key in arg.trim_prefix("--expect-not=").split(",", false):
				if events.has(key):
					print("TEST: FAIL event %s should not happen" % key)
