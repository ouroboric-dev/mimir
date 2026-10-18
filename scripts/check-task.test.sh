#!/bin/bash
# Tests scripts/check-task.sh on copies of the real tasks, each broken in one way.
# Run: bash scripts/check-task.test.sh   Exit 0 when every case behaves.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
check="$root/scripts/check-task.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failed=0

# expect <name> <exit code> <text in the output> <task dir>
expect() {
  local name="$1" code="$2" text="$3" dir="$4" out rc=0
  out="$("$check" "$dir" 2>&1)" || rc=$?
  if [ "$rc" -ne "$code" ] || ! grep -qF -- "$text" <<<"$out"; then
    echo "FAIL $name: exit $rc (want $code), output: $out"
    failed=1
  else
    echo "ok   $name"
  fi
}

# fresh <name>: a clean copy of smoke-notes in $work/<name>
fresh() { mkdir "$work/$1" && cp -r "$root/smoke-notes/." "$work/$1/"; }

expect "smoke-notes passes" 0 "passes the task checks" "$root/smoke-notes"
expect "a task without a sample suite says so" 0 "no sample suite" "$root/client-gallery-lite"
expect "no argument is a usage error" 2 "usage" "$work/missing"

fresh brief
echo "one more line" >>"$work/brief/instruction.md"
expect "a changed brief" 1 "brief hash differs" "$work/brief"

fresh dup
sed -i 's/"id": "delete a note"/"id": "add and list a note"/' "$work/dup/sample-suite/tests/manifest.json"
expect "a repeated id" 1 "not unique" "$work/dup"

fresh nospec
sed -i "s/test('delete a note'/test('remove a note'/" "$work/nospec/sample-suite/tests/notes.spec.ts"
expect "a manifest id with no spec" 1 "is not a spec title" "$work/nospec"
expect "a spec with no manifest id" 1 "is not in the manifest" "$work/nospec"

fresh weights
sed -i 's/security=0.4/security=0.5/' "$work/weights/task.toml"
expect "weights that do not sum to 1" 1 "not 1" "$work/weights"

fresh key
sed -i '/^environment_mode/d' "$work/key/task.toml"
expect "a missing required key" 1 "lacks the key verifier.environment_mode" "$work/key"

fresh mode
sed -i 's/environment_mode = "separate"/environment_mode = "shared"/' "$work/mode/task.toml"
expect "a wrong environment mode" 1 'must be "separate"' "$work/mode"

fresh cat
sed -i 's/"category": "security"/"category": "speed"/' "$work/cat/sample-suite/tests/manifest.json"
expect "a category with no weight" 1 "has no weight" "$work/cat"

fresh suite
sed -i 's/"suite": "v1"/"suite": "v2"/' "$work/suite/sample-suite/tests/manifest.json"
expect "a manifest of another suite than the task names" 1 "manifest suite differs" "$work/suite"

fresh f2p
sed -i 's/"kind": "fail-to-pass"/"kind": "pass-to-pass"/' "$work/f2p/sample-suite/tests/manifest.json"
expect "a manifest with no fail-to-pass scenario" 1 "no fail-to-pass scenario" "$work/f2p"

exit "$failed"
