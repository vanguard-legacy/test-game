# Changelog

This file summarizes each day of meaningful project work in short, future-facing notes. Keep entries in reverse chronological order, with exactly two sentences per date so the changelog stays readable as the project grows.

## 2026-05-23

We changed reward choices from full-screen gameplay interruptions into a compact non-modal HUD panel so the run keeps moving while players decide. We also added an Auto Wave toggle, expanded speed controls up to 32x, removed infinite stipend fallback rewards, added spawn-wave previews plus enemy health/damage feedback, and extended the smoke test to cover the new flow.

## 2026-05-22

We cleaned up project terminology, added the project reference, tightened validation, and changed the menu/run flow so players can generate seeded maps, restart the same seed, and see loading progress. We also expanded procedural terrain and upgraded the map atmosphere with environment fog, volumetric-style fog banks, shader motion, and real-time rolling fog animation.

## 2026-05-19

We moved development tools into the `tools` directory, fixed the Godot executable setup workflow, improved validation logging, and documented the commit/tag/push release rhythm. We also improved terrain contrast, added shader materials, introduced tower selling and selection, added game-speed controls, increased wave pressure, and clarified changelog/tag expectations.

## 2026-05-18

We made terrain height mechanically meaningful by adding tower bonuses for high ground and placement tooltips that preview the terrain effect. We also expanded the map footprint with a longer winding route, more elevation variety, and changing road widths.

## 2026-05-17

We added strategy-style camera controls, tower unlock rewards, three build slots, multiple tower archetypes, tower hover tooltips, and a scrollable command log. We also stabilized reward drafting, improved middle-mouse panning, added combat smoke validation, and refactored gameplay/HUD/reward/terrain/placement data flow into cleaner typed structures.

## 2026-05-16

We created the initial Godot tower-defense foundation with the design brief, Codex guidance, validation script, core scenes, waves, lives, score, gold, enemies, towers, and player placement. We then split the early game into focused scenes/scripts, added first-pass generated visuals and UI icons, replaced test terrain with procedural terrain and A* pathing, stabilized HUD sizing, and introduced the first menu, upgrades, and balance helpers.
