# Windows / macOS Behavior Parity Specification

The Windows edition uses the macOS edition as its behavioral reference.
Platform UI technologies differ, but character states, timing, speed, sprite
indices, and feature priority must remain aligned.

## Shared states and sprites

| Index | State |
|---:|---|
| 0 | Crawl A |
| 1 | Crawl B / eating |
| 2 | Climb |
| 3 | Hang / dragging |
| 4 | Monkey crouch / Dad |
| 5 | Leap |
| 6 | Sit |
| 7 | Sleep |

## Core parameters

- Update rate: 60 FPS.
- Obstacle refresh: every 0.35 seconds.
- Gravity: 28 velocity points per second; Windows uses a positive value because
  its Y axis points downward.
- Leap window: once per 11-second character-age cycle.
- Leap guard: at least 1.4 seconds between special leaps.
- Rest phase: seconds 14 through 16 of each 17-second cycle.
- Special-pose hold: 0.65 seconds.
- Food approach speed: 165 points per second.
- Eating threshold: 86 points.
- Eating duration: 2.4 seconds.
- Dad landing speed: 720 points per second.
- Dad speech duration: 2 seconds.
- Explosion fade: 0.65 seconds.

## Feature priority

1. A dragged character uses sprite 3 and suspends physics and other animation.
2. During Dad landing, every character not being dragged uses sprite 4; the
   group waits until every character reaches the bottom.
3. During Dad speech, every character remains on sprite 4.
4. A character with an assigned food prioritizes approaching and eating it.
5. Pause suspends ordinary behavior.
6. Otherwise, normal gravity, leaps, rests, screen edges, and window collisions
   apply.

## Native platform differences

- macOS uses AppKit, the menu bar, and Core Graphics window data.
- Windows uses WPF, the notification area, and Win32 `EnumWindows`.
- macOS uses Vision for face detection; Windows uses local image-region
  analysis.
- Mixed-DPI Windows multi-monitor layouts still require real-device validation
  because Win32 pixels and WPF coordinates can differ.

Every user-visible menu, prompt, error, and About-page item must be available in
Traditional Chinese and English. All Chinese locales display Traditional
Chinese; every other locale displays English.
