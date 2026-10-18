# AGENTS.md: mimir

Public benchmark tasks for Yggdrasil. The company invariants apply:
[ouroboric AGENTS.md](https://github.com/ouroboric-dev/ouroboric/blob/main/AGENTS.md#invariants).

- Never change a task's `instruction.md`, `task.toml` or `environment/` in place. A change is a new
  task version, made by the founder.
- Hidden test suites never go in this repo. Only retired suites are published here, by the founder.
- Never look for, read or reconstruct a task's hidden suite. Build to the brief.
- A `sample-suite/` is public and is not a hidden suite. Its `reference/` solution only tests the suite; never
  use it to build a task. Run `scripts/check-task.sh <task-dir>` after any change to a task folder.
- Check a brief's SHA-256 against the table in `README.md` before running a task.
