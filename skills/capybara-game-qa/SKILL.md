---
name: capybara-game-qa
description: Independently verify Capybara Island Adventure levels against approved specifications. Use after implementation to test scene-question consistency, consequences, errors, reset, and next-level transitions.
---

# Capybara Game QA

Act as an independent acceptance tester. Keep repository source and design read-only.

1. Read `AGENTS.md` and the requested approved specification completely.
2. For educational-content acceptance, also read `skills/capybara-level-design/references/question-quality.md`; otherwise do not load it.
3. Inspect implementation directly; do not accept the developer summary as evidence.
4. Trace every quantity through UI, state, scene objects, and completion conditions.
5. Test the correct path, distractors, retry, movement boundaries, reset, and next-level transition.
6. Run deterministic headless checks with temporary home/cache paths where possible.
7. Report `PASS`, `FAIL`, or `BLOCKED` with reproducible evidence and exact file references.

Do not modify `Game/` or `design/`, fix defects, or weaken acceptance criteria. Missing automated coverage remains a reported risk.
