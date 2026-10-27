#!/usr/bin/env bash
# Runs the parse check and every two-player playthrough in tests/.
# Usage: GODOT=/path/to/godot tests/run_all.sh   (from the project folder)
set -u
GODOT="${GODOT:-godot}"
LOG="${TMPDIR:-/tmp}/villa-argo-tests"
mkdir -p "$LOG"
status=0
"$GODOT" --headless --path . -s tests/parse_all.gd 2>&1 | grep -E "PARSE|BAD" || status=1
for t in tests/book*_pass_*.gd; do
	name=$(basename "$t" .gd)
	"$GODOT" --headless --path . -s "$t" -- host > "$LOG/$name.host.log" 2>&1 &
	host=$!
	sleep 2
	"$GODOT" --headless --path . -s "$t" -- client > "$LOG/$name.client.log" 2>&1
	c=$?
	wait $host
	h=$?
	passes=$(cat "$LOG/$name.host.log" "$LOG/$name.client.log" | grep -c PASS)
	if [ $h -eq 0 ] && [ $c -eq 0 ]; then
		echo "ok    $name ($passes checks)"
	else
		echo "FAIL  $name (logs in $LOG)"
		grep -h "FAIL\|SCRIPT ERROR" "$LOG/$name.host.log" "$LOG/$name.client.log" | head -5
		status=1
	fi
done
exit $status
