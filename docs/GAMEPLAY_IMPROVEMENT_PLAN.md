# Dark Angels: Crusade Command - Visual, Map, Animation Improvement Plan

## Summary

Current battlefield problems come from a mismatch between art and rules:

- All current map images are `1024x1024`, but the game stretches them to a `24x16` grid (`1536x1024`). This distorts the map and makes grid tiles/cover feel detached from the background.
- Cover is currently defined as logical grid positions and drawn over the image, so it can appear on top of pipes, pits, machinery, or non-walkable background details.
- The map image is only decorative. The rules do not know what is a bridge, pit, wall, pipe, floor, door, or elevated platform.
- Units have basic sprite states and movement tween, but still need stronger idle, walk, attack, hit, death, selection, and turn activation feedback.
- A mission does not yet create enough tactical pressure for a 30-minute session.

Decision: **do not use Tiled/TMX for now**. Use the existing image assets and add hand-authored tactical metadata in Dart/JSON: walkable tiles, void tiles, cover tiles, spawn zones, objectives, doors, choke points, and scripted encounter phases.

## Map Fix Plan

### 1. Stop Stretching The Map

Current map assets:

- `assets/images/map.png`: `1024x1024`
- `assets/images/map_hive_city.png`: `1024x1024`
- `assets/images/map_ash_wastes.png`: `1024x1024`

Implementation:

- Change map grid from `24x16` to `16x16` for current assets.
- Keep `tileSize = 64`, so world size becomes `1024x1024`.
- Update `TacticalMap.width` and `TacticalMap.height` to `16`.
- Re-author all marine spawns, enemy spawns, objective tiles, extraction tiles, cover tiles for the `16x16` map.
- Keep camera zoom/pan, but center on `512x512` and clamp view inside the map.

Reason:

- This makes the grid line up 1:1 with the current image pixels.
- It immediately makes the map clearer because the image is no longer stretched.

### 2. Add Terrain Types

Add a terrain layer to `TacticalMap`:

```dart
enum TerrainType {
  floor,
  cover,
  blocker,
  voidTile,
  bridge,
  objective,
  extraction,
}
```

Add fields:

```dart
final Set<GridPosition> walkableTiles;
final Set<GridPosition> voidTiles;
final Set<GridPosition> blockerTiles;
final Set<GridPosition> bridgeTiles;
final Set<GridPosition> softCoverTiles;
final Set<GridPosition> hardCoverTiles;
```

Rules:

- Marines and enemies can move only on `walkableTiles` and `bridgeTiles`.
- `voidTiles` are never walkable.
- `blockerTiles` are never walkable and block line of sight.
- `softCoverTiles` grant damage reduction but may not block movement if they represent low barricades.
- `hardCoverTiles` block movement and block or reduce line of sight.

### 3. Make Map Logic Match The Image

For each current 1024 map, manually mark tiles:

- **Drop Zone Epsilon**: open landing pad, barricades, crate lines, vehicle wrecks.
- **Hive Gate Primus**: bridges/walkways only; green pipe/void areas become blocked.
- **Ash Basilica**: altar lanes, broken columns, ruined cover, extraction edge.

For the screenshot problem specifically:

- Any black gap, pit, lower machinery layer, toxic pipe, or background-only floor should become `voidTile`.
- Walkways and bridges should be `bridgeTiles`.
- Cover should be placed only on actual crates, barricades, pillars, or wall corners.
- If a tile visually contains a large pipe/machine, mark it `blockerTile`.

### 4. Improve Grid Overlay

Current grid overlay is too dominant and reveals the art/grid mismatch.

Implementation:

- Grid line opacity should be reduced by default.
- Show full grid only when choosing `Move`.
- Use color-coded tile overlays:
  - Move: cyan/blue
  - Shoot: amber
  - Melee: red
  - Objective: green pulse
  - Void/blocked: subtle dark red only when debug mode is enabled
- Add a debug toggle in UI: `Show Tactical Layer`.

## Animation And Feedback Plan

### 1. Unit Animation

Current unit state sprites:

- `marine_idle.png`
- `marine_walk.png`
- `marine_attack.png`
- `marine_dead.png`
- `enemy_idle.png`
- `enemy_walk.png`
- `enemy_attack.png`
- `enemy_dead.png`

Implementation:

- Keep `SpriteGroupComponent<UnitState>`.
- Add idle bob and breathing pulse only in idle state.
- Add selected marine ring pulse.
- Add active-turn halo that is stronger than normal selection.
- Add movement tween with `MoveToEffect` duration `0.35-0.5s`.
- Add attack recoil:
  - shooter nudges backward
  - target flashes red/white
  - projectile or muzzle flash appears briefly
- Add death fade/scale/rotate effect before removing dead enemies.

Important:

- If the current `.png` files are static single-frame images, they still can feel animated through bobbing, scaling, flashing, and sprite state swaps.
- Later, replace them with real sprite sheets or frame sequences.

### 2. Turn Activation Feedback

When a marine becomes active:

- Camera pans/focuses to that marine.
- Active ring becomes gold and pulses.
- Unit card on right glows.
- Status text says: `"Cpt. Varro is active - choose Move, Shoot, Melee, Ability, or Overwatch."`
- Play `turn.wav`.

When enemy phase begins:

- UI banner: `Enemy Phase`.
- Camera follows each enemy briefly as it acts.
- Enemy active unit gets red ring.
- Play a low danger cue.

### 3. Audio

Current generated audio exists:

- `select.wav`
- `move.wav`
- `attack.wav`
- `turn.wav`
- `ambient.wav`

Improve with:

- One looping ambient track per mission theme.
- Small UI click sound.
- Footstep/armor servo sound on move.
- Bolter/plasma/flamer variations by weapon type.
- Impact sound when enemy/marine takes damage.
- Mission victory/defeat cue.

Implementation:

- Keep using `flame_audio`.
- Cache all audio in `CrusadeGame.onLoad`.
- Trigger BGM after first user interaction to avoid browser autoplay blocking.
- Add a volume setting connected to `settingsProvider.volume`.

## Gameplay Depth Plan For 30-Minute Missions

The current combat loop is too short because each mission is mostly kill/move. A 30-minute mission needs layered objectives and pressure.

### Mission Structure

Each mission should have 4 phases:

1. **Deployment**
   - Player gets 2-3 safe turns to position the squad.
   - Enemy patrols or sensor markers reveal likely directions.

2. **Primary Objective**
   - Capture, destroy, hold, or interact with a map objective.
   - Objective should force movement across the map, not just camping.

3. **Complication**
   - Reinforcements spawn from side route.
   - Door locks.
   - Visibility drops.
   - A VIP/witness appears.
   - A bridge/route becomes blocked.

4. **Extraction Or Final Stand**
   - Player must reach extraction or survive final waves.
   - Optional secondary objective gives RP but increases danger.

### Tactical Systems To Add

- **Action economy**
  - Each marine gets one activation per squad round.
  - During activation, marine can move once and attack/ability/overwatch once.
  - End Turn moves to next marine.
  - After all 10 marines, enemies activate one by one.

- **Suppression**
  - Heavy Bolter can suppress enemy tiles.
  - Suppressed enemies move fewer tiles or lose attack.

- **Overwatch**
  - If enemy enters range/line of sight during enemy phase, marine fires once.

- **Fog/Revealed Tiles**
  - Hive mission should hide enemies outside sight radius.
  - Auspex ability reveals ambush tiles.

- **Interactables**
  - Techmarine can open/lock doors, activate turret, disable hazard.
  - Apothecary can recover gene-seed for RP.
  - Commander can call orbital strike on marked outdoor tiles.

- **Hazards**
  - Toxic pipe zones damage units ending turn there.
  - Fire zones block movement or apply burn.
  - Void tiles kill or reject movement.

- **Morale/Secret Objective**
  - Secondary objective: destroy evidence or execute witness.
  - Completing it gives RP/CP, failing it changes mission result text.

## Concrete Implementation Steps

### Phase 1 - Repair Map Foundation

1. Change all current maps to `16x16`.
2. Add terrain sets to `TacticalMap`.
3. Update pathfinding to use `isWalkable(tile)`.
4. Add `blocksLineOfSight(tile)`.
5. Re-author map data for the 3 current image assets.
6. Add debug overlay toggle to show walkable/void/cover tiles.

Acceptance:

- Marine cannot walk into pits, pipe gaps, machinery, or background-only areas.
- Cover appears only where the image visually supports cover.
- Map is no longer stretched.

### Phase 2 - Improve Visual Feel

1. Make selected active marine pulse.
2. Add active enemy ring in enemy phase.
3. Add movement tween and camera focus per activation.
4. Add hit flash and attack recoil.
5. Add death animation for enemies.
6. Reduce normal grid opacity.

Acceptance:

- A screenshot should clearly show who is active, where they can go, and why some tiles are blocked.
- Units should feel alive even when idle.

### Phase 3 - Improve Audio

1. Fix BGM start after first click.
2. Add volume setting.
3. Route select/move/attack/turn sounds through a small `AudioService`.
4. Add weapon-specific sound mapping.

Acceptance:

- Selecting a marine, moving, attacking, ending turn, and completing a mission all produce distinct sounds.
- Browser autoplay failure does not break the game.

### Phase 4 - Make One Mission 30 Minutes

Start with `Hive Gate Primus`.

Add:

- 4 objective phases.
- 2 side corridors with ambush spawns.
- One locked door interaction.
- One toxic pipe hazard.
- One extraction phase.
- 2 optional secret objectives.
- Reinforcement timer every 4-5 squad rounds.

Acceptance:

- Mission can last 25-35 minutes on normal difficulty.
- Camping at spawn should fail due to objectives/timers.
- Advancing recklessly should trigger flank/ambush punishment.
- Using cover, overwatch, class abilities, and positioning should feel necessary.

## Files Likely To Change

- `lib/models/tactical_map.dart`
- `lib/providers/game_state_provider.dart`
- `lib/services/pathfinder.dart`
- `lib/game/crusade_game.dart`
- `lib/game/components/grid_overlay_component.dart`
- `lib/game/components/marine_component.dart`
- `lib/game/components/enemy_component.dart`
- `lib/game/components/cover_component.dart`
- `lib/widgets/ui_components.dart`
- `lib/providers/settings_provider.dart`

## Tests To Add

- Unit cannot move into `voidTiles`.
- Unit cannot move into `blockerTiles`.
- Unit can move on `bridgeTiles`.
- Cover damage reduction only applies from valid cover tiles.
- Line of sight is blocked by `blockerTiles`.
- Active marine advances correctly through 10 activations.
- Enemy phase moves enemies only through walkable tiles.
- Debug overlay can be toggled.

## Immediate Priority

Do these first:

1. Convert maps to `16x16`.
2. Add `walkableTiles`, `voidTiles`, and `blockerTiles`.
3. Re-author `Hive Gate Primus` so bridges/voids make sense.
4. Reduce grid opacity and make active unit pulse stronger.
5. Add camera focus on active unit.

This will fix the biggest immersion problem before adding more content.
