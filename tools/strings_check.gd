extends SceneTree
## Checks locale/translations.csv (replaces tools/check_strings.py, there is
## no Python here):
##   godot --headless --path . -s res://tools/strings_check.gd
## - every key once, every row has every language (unless all are empty),
## - the %s / %d / %.2f placeholders are the same and in the same order as in
##   English (GDScript fills them by position), and a text that gets
##   formatted has no lone % (it must be %%),
## - no plain space between a number and %, it must not break there,
## - every character can be drawn by the game's font (Chinese is drawn by the
##   system font, so its column is left out),
## - every literal key used in the scripts exists.
## Prints "STRINGS: FAIL ..." per problem and "STRINGS: done, N problems".

const CSV := "res://locale/translations.csv"
## Languages drawn with the system font (the game's font has no such glyphs).
const SYSTEM_FONT := ["zh_CN"]
## Symbols the game's font lacks but the system font draws (arrows, stars...).
const SYMBOLS := "←→↑↓★☆◆◇●○✓×•…■□"

var _problems := 0


func _initialize() -> void:
	var keys := _check_csv()
	_check_used(keys)
	print("STRINGS: done, %d problems" % _problems)
	quit(mini(_problems, 100))


func _fail(msg: String) -> void:
	_problems += 1
	print("STRINGS: FAIL ", msg)


func _check_csv() -> Dictionary:
	var keys := {}
	var font := ThemeDB.fallback_font
	var placeholder := RegEx.create_from_string("%(\\.\\d+)?[sdf]")
	var space_pct := RegEx.create_from_string("[0-9sd] %")
	var f := FileAccess.open(CSV, FileAccess.READ)
	var header := f.get_csv_line()
	var line := 1
	while not f.eof_reached():
		var row := f.get_csv_line()
		line += 1
		if row.size() <= 1 and (row.size() == 0 or row[0] == ""):
			continue
		var key := row[0]
		if keys.has(key):
			_fail("line %d: %s listed twice" % [line, key])
		keys[key] = line
		if row.size() < header.size():
			_fail("line %d: %s has fewer columns than the header" % [line, key])
			continue
		var texts := row.slice(1, header.size())
		if Array(texts).all(func(t: String) -> bool: return t.strip_edges() == ""):
			continue
		var english: String = texts[0]
		var want := _found(placeholder, english)
		var formatted := not want.is_empty()
		for i in texts.size():
			var lang: String = header[i + 1]
			var text: String = texts[i]
			if text.strip_edges() == "":
				_fail("line %d: %s has no %s text" % [line, key, lang])
				continue
			var got := _found(placeholder, text)
			if got != want:
				_fail("line %d: %s placeholders in %s are %s, English has %s" % [line, key, lang, got, want])
			# "8 %" must never break between the number and the % sign.
			if space_pct.search(text) != null:
				_fail("line %d: %s in %s has a plain space before %% (use a non-breaking space)" % [line, key, lang])
			if formatted and "%" in placeholder.sub(text.replace("%%", ""), "", true):
				_fail("line %d: %s in %s has a lone %% (write %%%%)" % [line, key, lang])
			if lang not in SYSTEM_FONT:
				for ch in text:
					var code := ch.unicode_at(0)
					if code > 32 and code != 0xA0 and code < 0x2E80 and ch not in SYMBOLS and not font.has_char(code):
						_fail("line %d: %s in %s: the font can't draw '%s' (U+%04X)" % [line, key, lang, ch, code])
						break
	return keys


func _found(re: RegEx, text: String) -> Array[String]:
	var out: Array[String] = []
	for m in re.search_all(text):
		out.append(m.get_string())
	return out


## Literal keys in the scripts: tr("KEY"), .text = "KEY", label("KEY"...).
func _check_used(keys: Dictionary) -> void:
	var literal := RegEx.create_from_string("(?:tr\\(|\\.text = |label\\(|button\\()\"([A-Z][A-Z0-9_]{3,})\"")
	for path in _scripts("res://scripts"):
		var source := FileAccess.get_file_as_string(path)
		for m in literal.search_all(source):
			var key := m.get_string(1)
			# A prefix that gets glued to an id ("KIND_" + kind) is not a key.
			if not key.ends_with("_") and not keys.has(key):
				_fail("%s: key %s is used but not translated" % [path.get_file(), key])


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir.path_join(sub)))
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			out.append(dir.path_join(file))
	return out
