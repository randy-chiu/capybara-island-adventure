# Question Quality and Difficulty Standard

## 1. Question sources

Use this priority order:

1. **Original scene-derived question**: derive quantities and relationships from the actual level state. This is the default.
2. **Original curriculum variant**: create a new question from an approved knowledge point, then adapt all data and consequences to the scene.
3. **Licensed or public-domain source**: use only when provenance and reuse rights are recorded.

Do not copy or lightly rewrite commercial textbooks, exercise books, websites, or unknown online banks. A familiar mathematical model is allowed; copied wording, distinctive data, diagrams, or answer sets are not.

Record for every question:

- `source_type`: `original_scene`, `original_variant`, `licensed`, or `public_domain`
- `source_reference`: originating scene state or external citation
- `license`: `project_original` or exact reuse terms
- author/designer and review date

## 2. Curriculum scope

Use only knowledge points marked `approved` in `design/curriculum_map.md`. Do not infer grade suitability from memory. If the map is missing or pending, block the specification and request curriculum review.

Check prerequisites explicitly. A level may review earlier content but must not silently require a later-grade technique.

## 3. Difficulty scoring

Score each dimension from 0–2:

| Dimension | 0 | 1 | 2 |
|---|---|---|---|
| Concept | direct recall/review | current-grade single concept | combines concepts or unfamiliar application |
| Reasoning steps | 1 step | 2 linked steps | 3+ linked steps |
| Information selection | all data directly relevant | select/organize data | infer a hidden relationship or reject distractor data |
| Representation | same form as learned | translate text ↔ diagram/state | coordinate multiple representations |
| Calculation load | routine exact arithmetic | multi-operation/check needed | high error risk despite age-appropriate operations |

Total classification:

- `A` 0–2: onboarding/review
- `B` 3–5: standard mastery
- `C` 6–8: meaningful challenge
- `D` 9–10: extension; use sparingly and provide scaffolding

Difficulty is not determined by larger numbers. Prefer deeper observation, data selection, representation, and reasoning while keeping computation manageable.

For a normal level, target a progression such as `A/B → B → B/C`. Do not place `D` as a mandatory first exposure. Record the intended score and justify each nonzero dimension.

## 4. Mathematical validation

Before approval:

1. Solve from scratch twice using different representations or methods where possible.
2. Confirm one unambiguous answer, unit, constraints, and any rounding rule.
3. Substitute the answer back into the scene state and verify the outcome.
4. Check that no option becomes correct under a reasonable alternate interpretation.
5. Map each distractor to a real misconception; remove random distractors.
6. Check that hints reduce one reasoning barrier without revealing the answer immediately.

## 5. Gameplay validation

A valid game question must satisfy all five links:

`player goal → observable evidence → mathematical decision → player/world action → visible verification`

If any link is absent, redesign the interaction before tuning wording.

## 6. Language and child suitability

- Use short concrete sentences and stable terminology.
- Separate story flavor from mathematical conditions.
- Avoid trick wording, unstated conventions, frightening failure, or shame-based feedback.
- Diagnose the idea, not the child: explain what must be reconsidered and allow retry.
