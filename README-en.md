# MonkeyDeskPets

[繁體中文](README.md) | [English](README-en.md)

Current platform versions:

- **macOS: 2.7.4 (stable)**
- **Windows: 0.3.3**

The platforms use independent version files at `apps/macos/VERSION` and
`apps/windows/VERSION`, so they can be updated separately.

Author: **廷廷小教室、廷廷的家 (Tim945)**

- [GitHub](https://github.com/Im-Tim-mI)
- [Threads](https://www.threads.com/@tim945_1)
- [Instagram](https://www.instagram.com/tim945_1)
- [Author's Official Shopee Store](https://shopee.tw/rr901037)
- [macOS / Windows Build & Release Guide (Traditional Chinese)](docs/BUILD-GUIDE-zh-TW.md)
- [macOS / Windows Build & Release Guide (English)](docs/BUILD-GUIDE-en.md)
- [Create a 4×2 Sprite Sheet with AI (Traditional Chinese)](docs/AI-SPRITE-GUIDE-zh-TW.md)
- [Create a 4×2 Sprite Sheet with AI (English)](docs/AI-SPRITE-GUIDE-en.md)

MonkeyDeskPets is a cross-platform desktop-pet project. It currently provides
a native macOS application and a Windows application built with C# and WPF.

After launch, multiple characters crawl on all fours, jump, climb, hang, rest,
and sleep. They use the screen boundaries and visible application-window edges
as part of their playground.

## Feature Preview

| Full-screen movement and window interaction | Feeding |
|---|---|
| [![Characters moving around the desktop and windows](png/動物.png)](png/動物.png) | [![The nearest character approaching placed food](png/餵食.png)](png/餵食.png) |
| **Call “Dad”** | **Lazy Mode face replacement** |
| [![All characters gather at the bottom and say Dad](png/爸.png)](png/爸.png) | [![A portrait applied to the built-in action poses](png/懶人模式套用後樣子.png)](png/懶人模式套用後樣子.png) |
| **Replace sprite sheet** | **Replace sprite sheet (green screen)** |
| [![Upload a transparent sprite sheet](png/精靈圖範例1.png)](png/精靈圖範例1.png) | [![Upload a green-screen sprite sheet](png/精靈圖範例2.png)](png/精靈圖範例2.png) |

Click an image to view it at full size. To use your own character, upload a
4×2 sprite sheet directly or follow the
[AI sprite-sheet guide](docs/AI-SPRITE-GUIDE-en.md). For a quick face swap,
use the in-app Lazy Mode.

## Advertising / Promotional Information

[![Logitech Logi online flagship gaming-store promotional discount code](png/羅技宣傳優惠碼.png)](https://store.logitech.tw/collections/logitech_gam)

[Logitech Logi Online Flagship Store – Gaming](https://store.logitech.tw/collections/logitech_gam)

> **Relationship disclaimer:** MonkeyDeskPets is an independently developed
> project and is not affiliated with, partnered with, sponsored by, endorsed
> by, or otherwise officially connected with Logitech or Logi. Logitech,
> Logi, related product names, and associated trademarks belong to their
> respective owners. The content above is an independent promotional section
> within this project. Offers, prices, eligibility, and expiration dates are
> subject to the current information shown on the store page.

## Project Structure

```text
MonkeyDeskPets/
├── apps/
│   ├── macos/       # Swift / AppKit; version in apps/macos/VERSION
│   └── windows/     # C# / WPF; version in apps/windows/VERSION
├── shared/
│   └── assets/      # Shared sprites, author image, icon, and advertising
├── LICENSE
└── NOTICE
```

## Features

- Native Swift and AppKit implementation without Electron.
- Automatically reads the first preferred macOS language at startup.
  Traditional and Simplified Chinese locales use Traditional Chinese;
  English and all other locales use English.
- Starts with one character. Add or remove characters from the menu-bar menu.
- **Remove One** plays a cartoon explosion at the removed character's
  location. **Keep Only One** preserves the first character and removes the
  others with simultaneous explosion effects.
- Eight character poses with mirrored left/right movement.
- Select **Feed**, then click anywhere on a screen to place dog food. The
  nearest idle character approaches and eats it.
- Screen-edge collision and visible standard-window top-edge collision.
- Multiple-desktop and full-screen auxiliary-layer support.
- Pause movement, enable dragging, or ignore mouse input. While dragged, a
  character remains in frame 3, and movement, gravity, collision, and other
  animation updates are suspended.
- A six-point movement threshold distinguishes dragging from a normal click.
- Per-frame visible-screen safeguards prevent characters from disappearing
  because of invalid coordinates or display changes.
- Explicitly disables `NSPanel` hide-on-deactivate and application-hiding
  behavior. A health check restores visibility, opacity, images, and valid
  coordinates when needed.
- Uses pre-generated mirrored sprites instead of negative display-layer
  scaling, preventing characters from moving outside their windows while
  turning near the right edge, landing, or sleeping.
- Upload a 4×2 sprite sheet. It is split into frames 0–7 from left to right
  and top to bottom, validated, saved under Application Support at
  `Sprites/Current`, and applied immediately.
- New sprite assets replace the previous set only after complete validation,
  preventing partial updates and unbounded version-directory growth.
- The App bundle permanently contains built-in default sprites. If `Current`
  is missing, incomplete, or damaged, startup falls back to the bundled copy.
- The built-in character uses a redesigned fictional Asian male face and does
  not retain the face, glasses, or identifiable features of the original
  photographed person.
- Uploaded images are sampled around their borders. If at least 60% of border
  samples are highly saturated green, MonkeyDeskPets applies soft-edge
  transparency and green-spill suppression before splitting the eight frames.
- Lazy Mode requires only one clear face photo. On macOS, Vision detects the
  largest face locally and applies it to the eight built-in action positions.
  The photo is not uploaded to a network service.
- Displays only a `🐒` icon in the menu bar and does not occupy the Dock.
- The App and mounted DMG use the original MonkeyDeskPets monkey icon.
- The DMG shows Traditional Chinese and English drag-to-Applications
  instructions with an arrow and arranged icons.

## macOS Requirements

- macOS 13 Ventura or newer.
- Xcode 15 or a compatible Swift 5.9 toolchain.
- Both Apple Silicon and Intel Macs can build from source.

## Build for macOS

```bash
git clone https://github.com/Im-Tim-mI/MonkeyDeskPets.git
cd MonkeyDeskPets
chmod +x apps/macos/scripts/*.sh
./apps/macos/scripts/build-app.sh
open apps/macos/dist/MonkeyDeskPets.app
```

Create the DMG and SHA-256 file:

```bash
chmod +x apps/macos/scripts/*.sh
./apps/macos/scripts/build-dmg.sh
open release
```

Outputs:

```text
release/MonkeyDeskPets-macOS-v2.7.4.dmg
release/SHA256SUMS.txt
```

For development:

```bash
cd apps/macos
./scripts/sync-shared-resources.sh
swift run
```

## Build for Windows

On Windows 10 version 1809 or newer, or Windows 11, install the .NET 8 SDK
and run in PowerShell:

```powershell
cd apps\windows
.\scripts\run-debug.ps1
```

Build the self-contained x64 ZIP:

```powershell
.\scripts\build-release.ps1 -Runtime win-x64
```

After installing Inno Setup 6, build the bilingual installer:

```powershell
.\scripts\build-installer.ps1 -Runtime win-x64
```

The Windows version includes a notification-area menu, multiple characters,
dragging, feeding, the Dad command, explosion removal, 4×2 sprite uploads,
green-screen removal, Lazy Mode face cropping and compositing, standard-window
edge collision, and complete About and license pages. Windows `0.3.3` follows
the macOS design with a 60 FPS state machine, 11/17-second behavior cycles,
gravity, feeding, and Dad-command flows. Face detection and sprite generation
are performed locally.

Windows release files are named from `apps/windows/VERSION`, for example:

```text
release\MonkeyDeskPets-Windows-win-x64-v0.3.3.zip
release\MonkeyDeskPets-Windows-win-x64-Setup-v0.3.3.exe
```

Recommended GitHub Release tags are `macos-v2.7.4` and `windows-v0.3.3`.

## macOS Permissions and Gatekeeper

MonkeyDeskPets reads the system window list to determine the positions of
standard application windows. If macOS requests Screen Recording permission,
granting it provides more complete window information. The application does
not capture, save, or upload screen contents. Characters can still move within
screen boundaries without that permission.

After assembling the complete App, the build script applies an ad-hoc
signature and verifies its integrity. An ad-hoc signature does not replace an
Apple Developer ID. Public releases should be signed with a Developer ID
Application certificate and notarized by Apple. If a trusted local build is
blocked by a download quarantine attribute, run:

```bash
xattr -cr /Applications/MonkeyDeskPets.app
```

See the build and release guide for detailed troubleshooting.

## Operation

Click the `🐒` icon in the menu bar:

- **Add / Remove Character**
- **Keep Only One:** keeps the first character and removes all others with
  explosion effects.
- **About MonkeyDeskPets:** shows the author image, version, author details,
  and vertically arranged GitHub, Threads, Instagram, and official Shopee
  links. The Logitech promotional image and full store URL are clickable, and
  the complete Advertising and Author Information Retention Terms can be
  opened.
- **Feed:** click anywhere on a screen to place food. The nearest character
  approaches it and uses frame 1 while moving backward and forward for about
  2.4 seconds.
- **Upload Sprite Sheet:** choose one 4×2 image to split, save, and apply.
- **Lazy Mode (Upload Face):** choose one face image to generate and apply a
  4×2 sprite sheet.
- **Restore Default Sprites:** after confirmation, removes `Current` and
  custom assets, then immediately returns to the fictional bundled character.
- **Open Sprite Folder:** opens `Current` in Finder, including the source
  image and `frame-0.png` through `frame-7.png`. Green-screen imports also
  include `processed-transparent.png`.
- **Dad:** interrupts every action and quickly brings all characters to the
  bottom of their respective screens in frame 4. The “Dad” speech bubble
  appears only after every character has arrived.
- **Pause / Resume**
- **Toggle Ignore Mouse**
- **Quit**

## Assets and Privacy

`person-sprites.png` is derived from a photograph provided and authorized by
the project owner. Do not use character assets for impersonation, harassment,
or other violations of portrait or personality rights without the subject's
consent.

## Known Limitations

- macOS does not provide a public desktop-icon collision API. MonkeyDeskPets
  therefore treats screen boundaries, the usable area created by the Dock and
  menu bar, and standard application-window edges as obstacles.
- Window-coordinate conversion may require adjustment for some unusual
  multi-display arrangements.
- The animation uses one pose sheet as a lightweight implementation and can
  be extended with additional continuous frames.

## License

This project uses the **MonkeyDeskPets Noncommercial License 1.0**, based on
the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0).
The complete license consists of `LICENSE`,
`POLYFORM-NONCOMMERCIAL-1.0.0.txt`, `ADDITIONAL-TERMS-zh-TW.txt`, and
`NOTICE`. Third-party commercial use is prohibited, and author information,
official links, the About page, and bundled advertising functionality must be
retained. `ADDITIONAL-TERMS-en.txt` is an English translation; if there is any
conflict, the Traditional Chinese terms prevail.
