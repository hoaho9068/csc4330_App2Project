# Changelog — Diving Invaders Feature

## Summary

Added a new gameplay feature: **diving invaders**. These are bonus
enemies that spawn one at a time at the top of the screen, fall straight
down at a fixed speed (independent of the main grid formation), and
disappear once they pass the bottom edge of the screen. The player can
shoot them out of the air for bonus points before they escape.

This is separate from the existing side-to-side grid of invaders — that
formation's behavior (marching left/right, stepping down, ending the game
if it reaches the player) is unchanged.

## Files changed

### `lib/game/game_config.dart`
Added tunable constants for the new feature at the end of the class:
- `divingInvaderSpeed` — vertical fall speed (px/sec).
- `divingInvaderMinInterval` / `divingInvaderMaxInterval` — random range
  (in seconds) between spawns of new diving invaders.
- `divingInvaderPoints` — score awarded for shooting one down.

### `lib/game/game_state.dart`
- Added `divingInvaders`, a list kept separate from the main `invaders`
  grid so it doesn't interfere with the win condition
  (`invaders.every((i) => !i.alive)`) or the game-over condition (an
  invader reaching the player's row).
- Added `_divingSpawnCooldown`, a timer that counts down to the next
  spawn; reset in both the constructor's implicit initial state and in
  `restart()`.
- Added `_updateDivingInvaders(dt)`:
  - Counts down `_divingSpawnCooldown`; when it hits zero, spawns a new
    `Invader` at a random x position with `y = -invaderHeight` (just
    above the visible screen) and picks a new random interval for the
    next spawn.
  - Moves every diving invader straight down by
    `divingInvaderSpeed * dt`.
  - Removes any diving invader whose `y` has passed
    `_arenaSize.height` (i.e., it fully exited the bottom of the
    screen) — this is the "disappear/hide at the bottom" behavior.
  - Called from `update()` right after `_updateInvaderFire(dt)`.
- Updated `_handleCollisions()` so a player bullet that overlaps a diving
  invader removes it and awards `GameConfig.divingInvaderPoints`, in
  addition to the existing logic for the main grid.
- Updated `restart()` to clear `divingInvaders` and reset
  `_divingSpawnCooldown` along with the other round-start state.

### `lib/game/game_painter.dart`
- Added a distinct paint color (`Colors.orangeAccent`) for diving
  invaders so they read visually as a different enemy type from the
  green grid invaders.
- Added a draw loop over `gameState.divingInvaders` (drawn after the
  main grid, before the player) so they render on top of the formation
  but below the player/bullets.

## Notes / things you may want to tweak

- Diving invaders currently don't shoot at the player — they're purely a
  visual/scoring feature. If you want them to also fire bullets, that
  logic would go alongside `_updateInvaderFire`.
- Because they live in a separate list from the main grid, they don't
  affect win/lose conditions at all — letting one reach the bottom has
  no penalty, it just disappears. If you'd rather cost the player a life
  when one escapes, that check can be added inside
  `_updateDivingInvaders` right before the `removeWhere` call.
- All timing/speed/point values are in `GameConfig` so they're easy to
  balance without touching the game logic.
