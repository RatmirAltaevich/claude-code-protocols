# My Project

<!-- continuity:start -->
Project lifecycle is managed through `.protocol/`.

Before non-trivial work:
1. Read `.protocol/STATE.md`.
2. Read active and pinned decisions in `.protocol/DECISIONS.md`.
3. Check `.protocol/changes/active/` for open changes.
4. Run verification commands from `.protocol/config.yaml`.

Do not duplicate information obtainable from the code or config files.
<!-- continuity:end -->

## Project-specific restrictions

- Do not update `locked-package` — version conflict, see DECISIONS.md D-001
- Do not commit `.env` files
