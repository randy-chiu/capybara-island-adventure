---
name: capybara-level-design
description: Design and audit complete scene-linked Grade 4 mathematics levels for Capybara Island Adventure, including unique map topology, landmarks, ecology, characters, tools, question props, player actions, curriculum scope, question provenance, difficulty, feedback, and specifications under design/levels/.
---

# Capybara Level Design

Own educational quality and level design. Do not edit `Game/`.

## Required workflow

1. Read `AGENTS.md`, `design/_level_template.md`, and the relevant rows of `design/curriculum_map.md`.
2. Read [question-quality.md](references/question-quality.md) before creating or auditing any question.
3. Read only the relevant files under `design/research/`: Shanghai scope for curriculum placement, AMC 8 research for optional enrichment, and question-bank strategy when planning a sequence. Do not load all research by default.
4. Inspect adjacent level specifications and relevant current gameplay. When the experience pattern is unclear or risks becoming generic, research 2–3 strong genre references from official or primary sources; extract principles, cite them, and never copy a map, character, puzzle, or art.
5. Before drafting, generate at least three materially different concepts. Compare their core fantasy, primary verbs, map structure, environmental logic, mathematical fit, emotional arc, replay/return value, and implementation cost. Record why the selected concept wins and why the others were rejected.
6. State what remains fun if the question UI is removed. Require at least one discovery verb and one consequence verb beyond walking and clicking; otherwise redesign.
7. Design the map and player journey before writing the mathematics. Write `design/levels/level_NN_<name>.md`; keep `status: draft` pending approval.
8. Define the player need before writing the mathematics. Make every number observable, collected, measured, or changed in the world.
9. Create original scene-derived questions by default. Record provenance and licensing for every question.
10. Score difficulty with the reference rubric, verify it against the approved curriculum scope, and adjust concept—not merely arithmetic size—when tuning difficulty.
11. Independently re-solve every question, validate units, world coordinates, scale, distractors, then specify the player-operated consequence, visible evidence, return route, and next-level transition.

## Character-performance rule

For every player verb, specify a performance rather than naming an animation.

- Define anticipation, active motion, contact/result, reaction, and return-to-control timing.
- Cover feet and weight shift, torso posture, hands/held tool, gaze, mouth/eyes/brows, prop motion, sound, particles, and interruption rules.
- Create distinct locomotion for normal ground, slopes, wet ground, and carrying when those surfaces/states exist. Never use a hunched back as generic effort; define safe pose and balance.
- Give success, failure, surprise, concentration, and effort readable facial states when the action calls for them. For fishing, synchronize cast, line, float, bite, pull, fish emergence, landing, collection, and facial reactions.
- State when control is locked, blended, or restored. Keep feedback brisk enough that repeated actions do not become tedious.

## Action-and-evidence rule

Math answers authorize actions; they never perform the work for the player.

- After a correct answer, require meaningful input in the world: carry, place, pour, build, measure, route, or inspect the computed quantity.
- Make action count and placement match the answer. Show remaining work (`2/6`) and change collision/state only after the last required action.
- Keep each result visible: caught items appear physically before entering a persistent inventory/collection display; opened containers reveal their contents; built objects remain in the world.
- Pair every language prompt with an observable response (object, animation, sound, inventory slot, path, or state). Text alone is not evidence.
- Let players revisit unlocked earlier locations without erasing completed work. Specify forward and return travel points.
- Reject decorative clicking: each operation must express the mathematical result or verify it spatially.

## World-design rules

Treat each level as a place, not a reskinned question screen.

1. Give every map a distinct silhouette, scale, elevation profile, biome, palette, traversal pattern, and primary landmark. Do not reuse equal circular islands with swapped props.
2. Draw a top-down layout with approximate dimensions and compass/orientation. Mark arrival, return route, critical path, optional loop, blockers, sightlines, interaction radii, and all question-object positions.
3. Place objects by environmental logic. Camps need shelter, drainage, safe fire clearance, water access, and a reason for their location; fishing needs reachable water, a rod, line, float, fish habitat, and landing space.
4. Specify terrain layers: shoreline/edge, walkable ground, height changes, rocks or cliffs, water or wetland, paths, hazards, and collision boundaries. State what the player can read from each layer.
5. Specify a scene inventory, not vague decoration. For every visible object give quantity, position/zone, relative scale, color/material, state changes, interaction, and gameplay or storytelling purpose.
6. Design vegetation as a coherent local ecology: named plant families, density zones, size variation, color variation, wind/interaction response, and clear paths. Avoid evenly scattered generic trees and flowers.
7. Add ambient life where appropriate. Define species, count, habitat, idle behavior, reaction to the player, and whether it carries information. Animals must not be static ornaments blocking the route.
8. Design functional tools and rewards in full. State silhouette, components, held/placed pose, animation sequence, sounds, before/after states, and inventory representation. If a fish is caught, define the rod, line, float, fish shape/color/fins, water emergence, landing, and collection display.
9. Make question props part of the composition. Their quantities, units, labels, wear, grouping, and placement must be visible before the question and remain consistent afterward.
10. Choreograph discovery with landmarks and sightlines. From each arrival or solved obstacle, show the next meaningful destination without relying only on text or beacons.
11. Separate readability from decoration. Keep interactables visually distinct, preserve camera clearance, avoid occluding numbers, and provide non-color cues for goals and states.
12. Compare the proposal with the two adjacent levels. List at least three concrete visual/spatial differences; redesign if only names, colors, or props differ.

The designer owns specifications, not production assets. Describe enough geometry, scale, placement, state, motion, and purpose that a developer does not need to invent the scene.

## Release gates

Reject a level when any gate fails:

- Knowledge point is not approved in `design/curriculum_map.md`.
- Question could move unchanged to an unrelated scene.
- Required data is unavailable to the player.
- Correct answer only closes UI and does not change gameplay.
- Correct answer automatically completes the computed physical task instead of handing control back for player execution.
- A claimed action or reward exists only as text, with no visible scene or collection evidence.
- An unlocked level cannot return to earlier unlocked locations, unless the narrative explicitly makes the route one-way.
- Map silhouette, scale, elevation, traversal, or biome merely duplicates an adjacent level.
- The specification lacks a top-down layout, dimensions, landmarks, terrain/collision zones, or a complete visible-object inventory.
- Required tools, creatures, rewards, plants, or question props are named without appearance, placement, state, and behavior.
- Prop placement has no environmental logic or blocks camera/readability/navigation.
- The draft jumps to the first idea without comparing alternatives or explaining why the chosen concept best serves play and mathematics.
- Removing the question UI leaves only walking, generic collecting, or decorative clicking.
- A player action is specified only as an animation name and omits body, face, tool, timing, contact evidence, or control transition.
- World dimensions, coordinates, object scale, mathematical units, and collision geometry disagree.
- The specification does not separate minimum shippable interactions from optional polish.
- Difficulty evidence, provenance, full solution, or misconception feedback is missing.
- Scene quantities, answer, animation, inventory, collision, or completion state disagree.

Write only `design/levels/`. Do not mark a level implemented or verified.
