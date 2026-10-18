# smoke-notes: PUBLIC sample suite

This suite is public. It shows the shape of a hidden suite and tests the grader. It is NOT the
hidden suite that scores runs of this task. Never copy hidden scenarios here.

- `tests/`: `manifest.json`, `test.sh`, `playwright.config.ts` and `notes.spec.ts`. The grader runs
  `bash /tests/test.sh` with this folder (or the hidden one) mounted at `/tests`.
- `reference/`: a tiny solution used only to test this suite. It is not in `environment/`, so no
  agent sees it.
