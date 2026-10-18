# mimir

Public benchmark tasks for [Yggdrasil](https://github.com/ouroboric-dev/yggdrasil), the Ouroboric
software factory. Each task is a frozen product brief that a factory builds from scratch, in
[Harbor](https://github.com/harbor-framework/harbor)'s task format.

| Task                                          | Version | Brief SHA-256                                                      |
| --------------------------------------------- | ------- | ------------------------------------------------------------------ |
| [`client-gallery-lite`](client-gallery-lite/) | 4.0.0   | `bd4b2c7aaf532d51acb3a7edfd5b193d368db8445093b7a24cd80b7ee24d8319` |

A task holds:

- `instruction.md`: the brief. It is frozen: any change makes a new task version.
- `task.toml`: limits, budget and grading settings.
- `environment/`: the machine a build runs on, and the machine it is graded on.

Builds are graded by hidden black-box suites, which are kept private so they don't leak to other
factories or into model training data. When a suite is retired, it is published here with its scores.

## Contributing

Run `uvx pre-commit install` once after cloning, so `gitleaks` checks each commit for secrets.

## Licence

The task files are AGPL-3.0-only; this README and `AGENTS.md` are CC-BY-4.0 (see `REUSE.toml`). The
name "Ouroboric" and the logos are trademarks and are not covered by these licences; see
[TRADEMARKS.md](https://github.com/ouroboric-dev/ouroboric/blob/main/TRADEMARKS.md).
