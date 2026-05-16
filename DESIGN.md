# Game Design Brief

## Pitch

A 3D tower defense game where terrain height, path width, seasons, and weather materially affect defensive strategy. Enemies push toward an exit across dynamic terrain; if too many reach it, the player loses.

## Genre

- 3D tower defense
- Strategy with action-adjacent spectacle
- Level-based progression with score chasing

## Core Fantasy

Build a layered medieval defense across shifting terrain while waves of mythical enemies try to break through. The player should feel clever for using elevation, chokepoints, weather, and tower upgrades together.

## Theme

High-fantasy medieval with a playful edge:

- Mythical creatures
- Knights in shining armor
- G'wizzards
- Gobbelins
- Gnomes and gknobbelins, with silent g's
- Grues
- Gnu's
- Gkniant boss enemy
- Gnuruk
- Gnogres

The tone should feel adventurous and slightly ridiculous without becoming pure parody.

## Core Game Elements

- Dynamic terrain map
- Height and width as meaningful tactical variables
- Seasonal changes
- Different unit types
- Enemy pathing
- Weather effects
- Upgradable towers
- Level progression with increasing enemy variety and difficulty
- High score tracking
- Loss condition based on enemies reaching the exit

## Mechanical Pillars

### Terrain Matters

Elevation and path width should affect tower placement, line of sight, enemy flow, tower range, projectile arcs, or enemy vulnerability. A high ridge, narrow bridge, valley, or wide road should each create a different defensive puzzle.

### Waves Escalate

Each level should introduce more enemies, different enemy roles, or altered map pressures. Later waves can combine enemy types to test whether the player built a flexible defense.

### Environment Changes Plans

Seasons and weather should change play in readable ways, such as snow slowing enemies, rain affecting projectiles, wind changing projectile paths, fog reducing vision, or summer opening faster routes.

### Towers Grow

Towers should have meaningful upgrades rather than flat number increases only. Upgrades can alter targeting, damage type, area control, range, height interaction, or weather resilience.

## Art Direction

Stylized realism inspired by games such as The Sims, Valheim, and Subnautica:

- Readable silhouettes
- Chunky but believable medieval fantasy forms
- Warm materials and clear color separation
- Expressive enemies with readable roles
- Terrain that is attractive but easy to parse tactically

## Inspirations

- Bloons TD: clear waves, satisfying tower upgrades, score-chasing readability
- Dungeon Defenders: 3D defense spaces and fantasy combat energy
- Orcs Must Die: lanes, traps, chokepoints, and physical enemy movement
- Age of Empires: medieval fantasy-adjacent strategic clarity
- Vampire Survivors: escalating pressure and satisfying enemy volume
- Dota 2 Crownfall/Crown of Thorns inspiration: fantasy tone, progression flavor, and event-like presentation

## Initial Prototype Target

1. One small 3D map with a start, exit, and one elevated area.
2. One enemy type that follows a path to the exit.
3. One tower that can be placed on valid terrain and attacks enemies in range.
4. A life counter that decreases when enemies reach the exit.
5. Basic wave spawning.
6. A simple score value.

The prototype should prove that height, width, and 3D placement are worth building the rest of the game around.

## Current Prototype Direction

- Procedural terrain should keep moving toward smooth, readable height changes rather than blocky test geometry.
- Enemy navigation should be map-driven where possible, with enemies asking the level for a path to the exit.
- The HUD should remain container-based and responsive so panels do not overlap as stats, buttons, and messages grow.
- Scene assets should own visuals; scripts should focus on behavior.
- `CHANGELOG.md` should be updated whenever prototype direction, systems, assets, or validation expectations meaningfully change.
