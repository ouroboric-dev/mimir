#!/bin/bash
# Checks one task folder of mimir: usage `scripts/check-task.sh <task-dir>`.
# Needs bash and python3 (3.11 or newer). Exit 0: all checks pass. Exit 1: a check failed.
# Exit 2: wrong usage. It never reads or writes anything outside the task folder.
set -euo pipefail

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "usage: check-task.sh <task-dir>" >&2
  exit 2
fi

exec python3 -I - "$1" <<'PY'
import hashlib, json, math, re, sys, tomllib
from pathlib import Path

task = Path(sys.argv[1])
errors = []


def fail(msg):
    errors.append(msg)


def get(d, dotted):
    for part in dotted.split("."):
        if not isinstance(d, dict) or part not in d:
            return None
        d = d[part]
    return d


try:
    cfg = tomllib.loads((task / "task.toml").read_text())
except (OSError, tomllib.TOMLDecodeError) as e:
    print(f"FAIL: task.toml cannot be read: {e}")
    sys.exit(1)

required = [
    "artifacts", "task.name", "task.version", "metadata.brief_sha256", "metadata.suite",
    "metadata.budget_usd", "agent.timeout_sec", "environment.workdir", "verifier.timeout_sec",
    "verifier.environment_mode", "verifier.env.SCORE_WEIGHTS",
]
for key in required:
    if get(cfg, key) is None:
        fail(f"task.toml lacks the key {key}")
if get(cfg, "verifier.environment_mode") not in (None, "separate"):
    fail('verifier.environment_mode must be "separate"')

# The brief hash.
try:
    digest = hashlib.sha256((task / "instruction.md").read_bytes()).hexdigest()
    want = get(cfg, "metadata.brief_sha256")
    if want is not None and want != digest:
        fail(f"brief hash differs: task.toml says {want}, instruction.md is {digest}")
except OSError as e:
    fail(f"instruction.md cannot be read: {e}")

if not (task / "environment" / "Dockerfile").is_file():
    fail("environment/Dockerfile is missing")

# The weights.
weights = {}
raw = get(cfg, "verifier.env.SCORE_WEIGHTS")
if isinstance(raw, str):
    for item in raw.split(","):
        name, sep, val = item.partition("=")
        try:
            if not sep or not name.strip():
                raise ValueError
            if name.strip() in weights:
                fail(f"SCORE_WEIGHTS names {name.strip()} twice")
            weights[name.strip()] = float(val)
        except ValueError:
            fail(f"SCORE_WEIGHTS has a bad item {item!r}")
    if weights and not math.isclose(sum(weights.values()), 1.0, rel_tol=0, abs_tol=1e-9):
        fail(f"SCORE_WEIGHTS sum to {sum(weights.values())}, not 1")
    if any(w < 0 for w in weights.values()):
        fail("SCORE_WEIGHTS has a negative weight")

# The public sample suite, when the task has one.
suite_dir = task / "sample-suite" / "tests"
notes = []
if not (task / "sample-suite").is_dir():
    notes.append("no sample suite: the manifest and spec checks are skipped")
else:
    try:
        man = json.loads((suite_dir / "manifest.json").read_text())
    except (OSError, json.JSONDecodeError) as e:
        man = None
        fail(f"sample-suite/tests/manifest.json cannot be read: {e}")
    if man is not None:
        if man.get("schema") != "ygg.suite/v1":
            fail('manifest schema must be "ygg.suite/v1"')
        if man.get("suite") != get(cfg, "metadata.suite"):
            fail("manifest suite differs from metadata.suite")
        ids, kinds = [], set()
        for sc in man.get("scenarios", []):
            ids.append(sc.get("id"))
            kinds.add(sc.get("kind"))
            if sc.get("kind") not in ("fail-to-pass", "pass-to-pass"):
                fail(f"scenario {sc.get('id')!r} has kind {sc.get('kind')!r}")
            if weights and sc.get("category") not in weights:
                fail(f"scenario {sc.get('id')!r} has category {sc.get('category')!r}, which has no weight")
        if not ids:
            fail("manifest has no scenarios")
        dup = sorted({i for i in ids if ids.count(i) > 1}, key=str)
        if dup:
            fail(f"manifest ids are not unique: {dup}")
        if "fail-to-pass" not in kinds:
            fail("manifest has no fail-to-pass scenario")
        if not (suite_dir / "test.sh").is_file():
            fail("sample-suite/tests/test.sh is missing")
        titles = set()
        specs = sorted(suite_dir.glob("*.spec.*"))
        if not specs:
            fail("sample-suite/tests has no spec file")
        for spec in specs:
            for m in re.finditer(r"""\btest(?:\.\w+)?\(\s*(['"`])((?:\\.|(?!\1).)*)\1""", spec.read_text()):
                titles.add(m.group(2).replace("\\'", "'").replace('\\"', '"'))
        for i in sorted({i for i in ids if i}):
            if i not in titles:
                fail(f"manifest id {i!r} is not a spec title")
        for t in sorted(titles - set(ids)):
            fail(f"spec title {t!r} is not in the manifest")

for n in notes:
    print(f"note: {n}")
if errors:
    for e in errors:
        print(f"FAIL: {e}")
    sys.exit(1)
print(f"ok: {task.name} passes the task checks")
PY
