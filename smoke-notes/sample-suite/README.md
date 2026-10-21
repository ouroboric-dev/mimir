# smoke-notes: PUBLIC sample suite

This suite is public. It shows the shape of a hidden suite and tests the grader. It is NOT the
hidden suite that scores runs of this task. Never copy hidden scenarios here.

- `tests/`: `manifest.json`, `test.sh`, `playwright.config.ts` and `notes.spec.ts`. The grader runs
  `bash /tests/test.sh` with this folder (or the hidden one) mounted at `/tests`.
- `reference/`: a tiny solution used only to test this suite. It is not in `environment/`, so no
  agent sees it.
- Scores: `test.sh` prints one line on stdout, `ygg-results/v1 <key> <report>`, when the grader gives it
  `YGG_SCORE_KEY`. The report is Playwright's JSON on a single line. Odin scores that line and never
  reads `results.json`, which `test.sh` still writes for Harbor. The app starts with a clean environment
  (`env -i`), so it never sees the key, and its output goes to a log file, never to stdout. A hidden
  suite does the same.
