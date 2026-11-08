#!/usr/bin/env bash
# Every step of every story chain (data/chains.json), one run each, several
# at a time: the step is started on its own map (--quest + --chain-step) and
# has to be finished (event chain_step:<CHAIN>:<n>). Final-boss steps start
# at the end of the night, boss steps after their minute.
#   bash tools/chain_test.sh [path-to-godot-console-exe]
#   ONLY="WHO_IS_BEHIND|THE_PEACE" JOBS=10 bash tools/chain_test.sh
# Prints one line per step; exit code = steps not finished.
GODOT="${1:-/c/Users/john.niccon/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe}"
JOBS="${JOBS:-10}"
cd "$(dirname "$0")/.." || exit 1
export GODOT
OUT="${TMPDIR:-/tmp}/catsurvivors_chains.txt"
python - "${ONLY:-}" <<'PY' | tr -d '\r' > "${TMPDIR:-/tmp}/catsurvivors_chain_runs.txt"
import json, re, sys
only = sys.argv[1]
chains = json.load(open('data/chains.json', encoding='utf-8'))
for cid, c in chains.items():
    if only and not re.fullmatch(only, cid):
        continue
    for i, step in enumerate(c['steps']):
        if 'if' in step:
            continue  # a branch of a choice: the other branch is tested instead
        stage = step.get('stage', c.get('stage', 'any'))
        if stage == 'any':
            stage = 'LIVING_ROOM'
        args = ['--bot', '--god', '--levels=20', '--stage=' + stage, '--quest=' + cid, '--chain-step=%s:%d' % (cid, i)]
        t = 300
        if step['type'] == 'final':
            args += ['--start-minute=19.9', '--catch-up']
            t = 420
        elif step.get('after_minute'):
            args += ['--start-minute=%s' % step['after_minute'], '--catch-up']
            t = 360
        args += ['--bot-time=%d' % t, '--expect=chain_step:%s:%d' % (cid, i + 1)]
        print('%s:%d|%s' % (cid, i + 1, ' '.join(args)))
PY
run_one() {
  local name="${1%%|*}" args="${1#*|}"
  local out
  out=$(timeout 600 "$GODOT" --headless --log-file "${TMPDIR:-/tmp}/catsurvivors_chain.log" --path . -- $args 2>&1)
  local errors
  errors=$(echo "$out" | grep -E "SCRIPT ERROR|Parse Error|ERROR: |TEST: FAIL" | grep -vE "resources still in use|ObjectDB instances leaked" | sort | uniq -c | head -3)
  if [ -n "$errors" ]; then
    printf 'FAIL %s\n%s\n' "$name" "$(echo "$errors" | sed 's/^/     /')"
  else
    printf 'ok   %s\n' "$name"
  fi
}
export -f run_one
xargs -P "$JOBS" -I{} bash -c 'run_one "$@"' _ {} < "${TMPDIR:-/tmp}/catsurvivors_chain_runs.txt" | tee "$OUT"
fail=$(grep -c '^FAIL' "$OUT")
echo "steps: $(grep -c '' "${TMPDIR:-/tmp}/catsurvivors_chain_runs.txt"), not finished: $fail"
exit "$fail"
