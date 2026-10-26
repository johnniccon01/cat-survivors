extends SceneTree
## Helps with locale/translations.csv (no Python here, so Godot does it):
##   godot --headless --path . -s res://tools/translations_tool.gd -- dump OUT.tsv
##     writes "key<TAB>english" for every row (to translate)
##   godot --headless --path . -s res://tools/translations_tool.gd -- merge IN.tsv
##     IN.tsv starts with a header "key<TAB>es<TAB>ru..." and then one row per
##     key (a line break inside a text is written as a backslash and n);
##     those columns are added to (or updated in) the CSV
##   godot --headless --path . -s res://tools/translations_tool.gd -- missing CODE
##     prints the keys that have no text yet in that language
## Afterwards run the import so the .translation files are rebuilt.

const CSV := "res://locale/translations.csv"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	match args[0] if args.size() > 0 else "":
		"dump":
			_dump(args[1])
		"merge":
			_merge(args[1])
		"missing":
			_missing(args[1])
		_:
			print("usage: dump OUT.tsv | merge IN.tsv | missing CODE")
	quit()


func _read() -> Array:
	var rows: Array = []
	var f := FileAccess.open(CSV, FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() == 1 and line[0] == "":
			continue
		rows.append(Array(line))
	return rows


func _write(rows: Array) -> void:
	var f := FileAccess.open(CSV, FileAccess.WRITE)
	for row: Array in rows:
		f.store_csv_line(PackedStringArray(row))


func _dump(out: String) -> void:
	var rows := _read()
	var f := FileAccess.open(out, FileAccess.WRITE)
	for i in range(1, rows.size()):
		f.store_line("%s\t%s" % [rows[i][0], rows[i][1]])
	print("dumped %d rows" % (rows.size() - 1))


func _merge(path: String) -> void:
	var rows := _read()
	var header: Array = rows[0]
	var f := FileAccess.open(path, FileAccess.READ)
	var codes := f.get_line().strip_edges().split("\t")
	var cols := {}
	for c in range(1, codes.size()):
		var code := codes[c]
		if code not in header:
			header.append(code)
			for r in range(1, rows.size()):
				rows[r].append("")
		cols[code] = header.find(code)
	var by_key := {}
	for r in range(1, rows.size()):
		while rows[r].size() < header.size():
			rows[r].append("")
		by_key[rows[r][0]] = r
	var done := 0
	var unknown: Array[String] = []
	while not f.eof_reached():
		var line := f.get_line()
		if line.strip_edges() == "":
			continue
		var parts := line.split("\t")
		if not by_key.has(parts[0]):
			unknown.append(parts[0])
			continue
		for c in range(1, mini(parts.size(), codes.size())):
			# A line break is written as \n in the TSV.
			rows[by_key[parts[0]]][cols[codes[c]]] = parts[c].replace("\\n", "\n")
		done += 1
	_write(rows)
	print("merged %d rows into %s" % [done, ", ".join(cols.keys())])
	if not unknown.is_empty():
		print("UNKNOWN KEYS: ", unknown)


func _missing(code: String) -> void:
	var rows := _read()
	var col: int = rows[0].find(code)
	var n := 0
	for r in range(1, rows.size()):
		if col < 0 or rows[r].size() <= col or rows[r][col] == "":
			print(rows[r][0])
			n += 1
	print("%d missing in %s" % [n, code])
