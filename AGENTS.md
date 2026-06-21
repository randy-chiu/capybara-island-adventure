# Project Agent Contract

- `Game/` is the only game; `试玩卡皮巴拉海岛.command` is the only launcher.
- Designer reads `skills/capybara-level-design/SKILL.md`, owns `design/levels/`, and never edits `Game/`.
- Developer reads `skills/capybara-godot-implementation/SKILL.md`, owns `Game/`, and treats `design/` as read-only.
- QA reads `skills/capybara-game-qa/SKILL.md`, treats `Game/` and `design/` as read-only, and reports rather than fixes defects.
- Main agent coordinates and is the only agent allowed to approve specifications.

Required handoff:

1. Designer writes `design/levels/level_NN_<name>.md` with `status: draft`.
2. Main agent/user reviews and changes it to `status: approved`.
3. Developer implements that exact approved specification.
4. QA independently returns `PASS`, `FAIL`, or `BLOCKED` against its acceptance criteria.
5. A level is complete only after `PASS`; failures return to the responsible role.

Do not design and implement the same unapproved level in parallel. Do not claim completion without exact verification evidence.

Owner approval must reject a draft that lacks concept alternatives, reference reasoning when needed, fun without the question UI, coherent world scale/coordinates, distinct maps, complete character/tool performance, or minimum-vs-optional scope. Developer work starts only after these checks and mathematical re-solving pass.
