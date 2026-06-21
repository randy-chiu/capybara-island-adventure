---
name: capybara-godot-implementation
description: Implement approved Capybara Island Adventure level specifications in the canonical Godot project. Use when modifying Game/ from a design/levels specification.
---

# Capybara Godot Implementation

Act as the implementation engineer. Treat `design/` as read-only.

1. Read `AGENTS.md` and the exact requested approved level specification completely.
2. Stop if it is missing, draft, mathematically inconsistent, or materially ambiguous.
3. Implement only the approved behavior in `Game/` and preserve the single launcher.
4. Bind question quantities to actual scene/game state; avoid contradictory duplicated constants.
5. Add or extend a deterministic headless flow check.
6. Run syntax, gameplay-flow, and regression checks.
7. Report changes, evidence, and deviations without editing the specification.

Never create, edit, rename, delete, or format `design/`. Never change mathematics, story goals, or acceptance criteria. Leave compliance judgment to QA.
