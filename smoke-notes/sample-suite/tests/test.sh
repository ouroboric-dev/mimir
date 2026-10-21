#!/bin/bash
# Runs the sample suite. The grader runs it as `bash /tests/test.sh` with the product in /app, this
# folder at /tests (read-only) and an empty /logs/verifier. It writes /logs/verifier/results.json
# in Playwright's JSON reporter format (for Harbor; Odin does not read it) and, when the grader gives it
# YGG_SCORE_KEY, prints the scores once on stdout as `ygg-results/v1 <key> <report>`, the report on one
# line. That line is what Odin scores. A failing scenario does not fail this script; the results do.
set -euo pipefail

mkdir -p /logs/verifier
rm -rf /grader/suite
cp -r /tests /grader/suite

server=""
cleanup() { [ -n "$server" ] && kill "$server" 2>/dev/null || true; }
trap cleanup EXIT

if [ -x /app/start.sh ]; then
  # The app gets a clean environment, so it never sees YGG_SCORE_KEY, and its output goes to a log file,
  # never to this script's stdout, where the score line is.
  runuser -u app -- env -i PATH="$PATH" HOME="$(getent passwd app | cut -d: -f6)" \
    bash -c 'cd /app && exec ./start.sh' >/logs/verifier/server.log 2>&1 &
  server=$!
fi

up=""
for _ in $(seq 1 60); do
  if curl -fsS -o /dev/null http://localhost:3000/ 2>/dev/null; then up=1; break; fi
  sleep 1
done

cd /grader
if [ -z "$up" ]; then
  echo "the product did not answer on port 3000 within 60 seconds" >&2
fi
PLAYWRIGHT_JSON_OUTPUT_NAME=/logs/verifier/results.json \
  npx playwright test --config suite/playwright.config.ts --reporter=json >/dev/null || true
test -s /logs/verifier/results.json
# The app is stopped before the line is printed (the trap would do it at exit, too late).
cleanup
server=""
if [ -n "${YGG_SCORE_KEY:-}" ]; then
  report="$(node -e 'process.stdout.write(JSON.stringify(JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))))' /logs/verifier/results.json)"
  printf 'ygg-results/v1 %s %s\n' "$YGG_SCORE_KEY" "$report"
fi
