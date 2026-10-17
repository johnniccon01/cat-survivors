"""Checks locale/translations.csv: every key has English and Slovak text, the
%s / %d / %.2f placeholders match between the two, no key is listed twice,
and every literal tr("KEY") / translation key used in the code exists.
Run: python tools/check_strings.py   (exit code = number of problems)"""
import csv
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
problems = []

rows = list(csv.reader(open(os.path.join(ROOT, "locale", "translations.csv"), encoding="utf8")))
header, rows = rows[0], rows[1:]
keys = {}
PLACEHOLDER = re.compile(r"%(?:\.\d+)?[sdf]")
for n, row in enumerate(rows, start=2):
    if not row or not row[0]:
        continue
    key = row[0]
    if key in keys:
        problems.append("line %d: %s listed twice (also line %d)" % (n, key, keys[key]))
    keys[key] = n
    if len(row) < 3:
        problems.append("line %d: %s has no Slovak column" % (n, key))
        continue
    en, sk = row[1], row[2]
    if en.strip() == "" and sk.strip() == "":
        continue  # intentionally empty (e.g. a hint that says nothing)
    if sk.strip() == "" or en.strip() == "":
        problems.append("line %d: %s is missing a language" % (n, key))
    if sorted(PLACEHOLDER.findall(en)) != sorted(PLACEHOLDER.findall(sk)):
        problems.append("line %d: %s placeholders differ: %s / %s" % (n, key, PLACEHOLDER.findall(en), PLACEHOLDER.findall(sk)))

# Literal keys used in scripts: tr("KEY"), .text = "KEY", label("KEY", ...).
used = set()
literal = re.compile(r'(?:tr\(|\.text = |label\(|button\()"([A-Z][A-Z0-9_]{3,})"')
for folder, _, files in os.walk(os.path.join(ROOT, "scripts")):
    for f in files:
        if f.endswith(".gd"):
            for m in literal.finditer(open(os.path.join(folder, f), encoding="utf8").read()):
                used.add((m.group(1), f))
for key, f in sorted(used):
    # A prefix that gets glued to an id ("KIND_" + kind) is not a key.
    if key.endswith("_"):
        continue
    if key not in keys:
        problems.append("%s: key %s is used but not translated" % (f, key))

for p in problems:
    print("STRINGS:", p)
print("STRINGS: %d keys, %d problems" % (len(keys), len(problems)))
sys.exit(min(len(problems), 100))
