#!/bin/bash
# Runs the sample suite. The grader runs it as `bash /tests/test.sh` with the product in /app, this
# folder at /tests (read-only) and an empty /logs/verifier. It writes /logs/verifier/results.json
# in Playwright's JSON reporter format. A failing scenario does not fail this script; the results do.
set -euo pipefail

mkdir -p /logs/verifier
rm -rf /grader/suite
cp -r /tests /grader/suite

server=""
cleanup() { [ -n "$server" ] && kill "$server" 2>/dev/null || true; }
trap cleanup EXIT

if [ -x /app/start.sh ]; then
  runuser -u app -- bash -c 'cd /app && exec ./start.sh' >/logs/verifier/server.log 2>&1 &
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
