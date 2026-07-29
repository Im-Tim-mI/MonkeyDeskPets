# MonkeyDeskPets macOS and Windows Build & Release Guide

This guide applies to MonkeyDeskPets 2.7.x. It explains how to run the source,
build both platforms, and prepare files for a GitHub Release.

Author: **廷廷小教室、廷廷的家（Tim945）**

> A macOS App or DMG must be built on macOS. A Windows EXE or installer must
> be built on Windows. Run and test the development build on the target
> platform before creating release files.

## 1. Download the project

### With Git

```bash
git clone https://github.com/Im-Tim-mI/MonkeyDeskPets.git
cd MonkeyDeskPets
```

Alternatively, select `Code` → `Download ZIP` on GitHub and extract it. Run
the commands below from the project root containing `apps` and `shared`.
macOS and Windows use `apps/macos/VERSION` and `apps/windows/VERSION`
respectively.

## 2. Project layout

```text
MonkeyDeskPets/
├── apps/
│   ├── macos/                 # Swift / AppKit with its own VERSION
│   └── windows/               # C# / WPF with its own VERSION
├── shared/assets/             # Shared sprites, author, ad, and icons
├── docs/                      # Manuals
├── release/                   # Generated builds; not committed
├── LICENSE
└── NOTICE
```

Do not remove `LICENSE`, `NOTICE`, the additional terms, author information,
official links, or promotional area.

---

# Building for macOS

## 3. macOS requirements

- macOS 13 Ventura or newer
- Xcode 15 or newer
- A Swift 5.9-compatible toolchain
- About 3 GB of free space
- Apple Silicon or Intel Mac

After installing Xcode, open it once and accept its license. Then run:

```bash
xcode-select -p
swift --version
```

If command-line tools are missing:

```bash
xcode-select --install
```

If several Xcode versions are installed:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## 4. Run the macOS development build

From the project root:

```bash
chmod +x apps/macos/scripts/*.sh
cd apps/macos
./scripts/sync-shared-resources.sh
swift run
```

To use Xcode:

1. Open Xcode.
2. Select `File` → `Open`.
3. Open `apps/macos/Package.swift`.
4. Select the `MonkeyDeskPets` scheme.
5. Select `My Mac` as the run destination.
6. Press `▶ Run`.

MonkeyDeskPets does not appear in the Dock. Look for `🐒` in the macOS menu bar.

## 5. Build the macOS App

From the project root:

```bash
chmod +x apps/macos/scripts/*.sh
./apps/macos/scripts/build-app.sh release
```

Output:

```text
apps/macos/dist/MonkeyDeskPets.app
```

Test it:

```bash
open apps/macos/dist/MonkeyDeskPets.app
```

An `.app` is a directory bundle, not a normal single file. For public
distribution, create the DMG below instead of uploading the bare bundle.

## 6. Build the bilingual macOS DMG

From the project root:

```bash
chmod +x apps/macos/scripts/*.sh
./apps/macos/scripts/build-dmg.sh
```

The script automatically:

1. Synchronizes shared assets and license files.
2. Builds the Release App.
3. Generates the monkey `.icns` icon.
4. Generates the Traditional Chinese and English DMG background.
5. Adds `MonkeyDeskPets.app` and an `Applications` shortcut.
6. Arranges the drag-to-install icons.
7. Verifies both the SwiftPM resource bundle and the independent built-in
   sprite fallback inside the App.
8. Verifies the completed App signature.
9. Creates the compressed DMG and SHA-256 file.

The version is read from `apps/macos/VERSION`:

```text
release/MonkeyDeskPets-macOS-v<version>.dmg
release/SHA256SUMS.txt
```

Open the output directory:

```bash
open release
```

Mount the DMG and verify:

- The App and mounted disk use the monkey icon.
- Both Traditional Chinese and English installation instructions appear.
- The `Applications` shortcut works.
- The App launches after being dragged to Applications.

## 7. macOS signing and Gatekeeper

When no certificate is specified, `build-app.sh` removes inherited quarantine
attributes after assembling the complete App and applies an ad-hoc signature.
This verifies file integrity but does not replace an Apple Developer ID.
Gatekeeper may still warn other users after they download the App.

To build with an installed Developer ID Application certificate:

```bash
MACOS_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  ./apps/macos/scripts/build-dmg.sh
```

A public production release must also be notarized by Apple. Inspect the
signature with:

```bash
codesign --verify --deep --strict --verbose=2 \
  apps/macos/dist/MonkeyDeskPets.app
```

The scripts do not store certificate names or passwords. They use a
certificate only when `MACOS_SIGNING_IDENTITY` is explicitly set.

## 8. Common macOS build problems

### `Permission denied`

```bash
chmod +x apps/macos/scripts/*.sh
```

### Unhandled `Info.plist` warning

The current `Package.swift` explicitly excludes the `Info.plist` handled by the
packaging script. If the warning still appears, confirm that you downloaded the
latest project. `build-app.sh` installs the production Info.plist in the bundle.

### `awk: syntax error` or the DMG build stops after mounting

An older `build-dmg.sh` over-escaped slash characters and failed with macOS BSD
awk. Update to v2.7.4 or newer. If MonkeyDeskPets remains mounted after the old
script fails, run:

```bash
hdiutil detach "/Volumes/MonkeyDeskPets"
```

If the volume is not found, it is already detached and you may rerun
`build-dmg.sh`.

### `Finder layout settings (.DS_Store) are still missing`

The current script waits for Finder and retries the layout operation three
times. Do not quit or force-restart Finder while the build is running. If an
old volume is still mounted, run:

```bash
hdiutil detach "/Volumes/MonkeyDeskPets" 2>/dev/null || true
./apps/macos/scripts/build-dmg.sh
```

If Terminal previously reported that Finder could not set `toolbar visible`
with error `-10006`, that Finder version does not allow the toolbar appearance
to be changed. The current script treats toolbar, status bar, and path bar
settings as optional. A rejected decoration setting no longer prevents the
background, icon positions, and `.DS_Store` from being written.

### `MonkeyDeskPets.app is damaged and can't be opened`

Check the App signature first:

```bash
codesign --verify --deep --strict --verbose=2 \
  /Applications/MonkeyDeskPets.app
```

For a locally built or otherwise trusted ad-hoc signed copy, remove its
download quarantine attribute:

```bash
xattr -cr /Applications/MonkeyDeskPets.app
```

To prevent this warning for public downloads, sign with a Developer ID
Application certificate and notarize the release. An ad-hoc signature alone
cannot guarantee that a downloaded App passes Gatekeeper.

### Restore Defaults reports that the built-in sprite is missing

The current App keeps the default sheet both at
`Contents/Resources/person-sprites.png` and inside the SwiftPM resource
bundle. Startup, Lazy Mode, and Restore Defaults use the same multi-path
fallback loader. The build stops instead of producing an App if either
packaged fallback is missing or invalid.

### `Constant must be declared private`

Do not keep duplicate program entry points. The bottom of the file should have
only one set similar to:

```swift
let application = NSApplication.shared
private let delegate = DesktopPetController()
```

If `DesktopPetController` is `private`, a global constant using it must also
be `private`.

### `Invalid redeclaration of 'application'`

There are two declarations of `let application = NSApplication.shared` in the
same scope. Delete the duplicate instead of adding another declaration.

### The App runs but no main window appears

MonkeyDeskPets is a menu-bar app. Look for `🐒` at the upper-right of the screen.

---

# Building for Windows

## 9. Windows requirements

- Windows 10 version 1809 or newer, or Windows 11
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- PowerShell 5.1 or PowerShell 7
- Visual Studio 2026 with the **.NET desktop development** workload recommended
- [Inno Setup 6](https://jrsoftware.org/isdl.php) for installer creation

Open a new PowerShell window after installing the SDK:

```powershell
dotnet --version
```

It should report `8.x.x`. If `dotnet` is still unavailable, restart the
terminal or Windows.

## 10. Run the Windows development build

From the project root:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
cd apps\windows
.\scripts\run-debug.ps1
```

`-Scope Process` affects only the current PowerShell window and is discarded
when the window closes.

To use Visual Studio:

1. Open `apps/windows/MonkeyDeskPets.Windows.sln`.
2. Wait for SDK restore to complete.
3. Select the `Debug` configuration.
4. Select `MonkeyDeskPets.Windows` as the startup project.
5. Press `F5`.

After launch, look in the Windows notification area. Select `^` if the monkey
icon is hidden in the overflow area.

## 11. Build a portable Windows ZIP

### x64 for ordinary Intel or AMD PCs

```powershell
cd apps\windows
.\scripts\build-release.ps1 -Runtime win-x64
```

### Arm64 for Windows on ARM

```powershell
cd apps\windows
.\scripts\build-release.ps1 -Runtime win-arm64
```

The script publishes a self-contained build, so the end user does not need to
install the .NET Runtime separately.

Output:

```text
release\MonkeyDeskPets-Windows-win-x64-v<version>.zip
release\SHA256SUMS-Windows-win-x64.txt
```

Extract the entire ZIP before running `MonkeyDeskPets.exe`. Do not launch it
inside a ZIP preview window.

## 12. Build the bilingual Windows installer

The version is read automatically from `apps/windows/VERSION`. The current
Windows version is `0.3.3`. After installing Inno Setup 6:

```powershell
cd apps\windows
.\scripts\build-installer.ps1 -Runtime win-x64
```

Arm64:

```powershell
.\scripts\build-installer.ps1 -Runtime win-arm64
```

If a portable build does not exist, the installer script first runs
`build-release.ps1`.

Output:

```text
release\MonkeyDeskPets-Windows-win-x64-Setup-v0.3.3.exe
release\SHA256SUMS-Windows-win-x64-Setup.txt
```

The installer includes:

- Traditional Chinese and English UI
- Monkey application and installer icons
- Start menu shortcut
- Desktop launch shortcut, selected by default and optional to the user
- Optional start-with-Windows setting
- Uninstaller

### Complete packaging procedure

1. Confirm that `apps/windows/VERSION` and the `.csproj` version are both
   `0.3.3`.
2. Run **Clean Solution** and **Rebuild Solution** in Visual Studio 2026.
3. Close every running MonkeyDeskPets process.
4. Open PowerShell at the repository root.
5. Run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\apps\windows\scripts\build-installer.ps1 -Runtime win-x64
```

6. Run `release\MonkeyDeskPets-Windows-win-x64-Setup-v0.3.3.exe`.
7. Test both the Traditional Chinese and English installer UI.
8. Keep **Create a desktop shortcut** selected, finish installation, and
   launch the App from the desktop.
9. Verify the notification-area icon, menu, About-page version, and
   uninstaller.
10. Upload the Setup EXE and matching SHA-256 file to the Windows Release.

### Git upload filtering

The root `.gitignore` excludes `.vs`, `bin`, `obj`, `dist`, `release`, `.exe`,
`.dmg`, `.zip`, generated SHA-256 files, and local secrets. Before committing:

```powershell
git status
git check-ignore -v .\release\MonkeyDeskPets-Windows-win-x64-Setup-v0.3.3.exe
```

The installer should be ignored. `.cs`, `.csproj`, `.iss`, `.ps1`, license,
and documentation files should remain available to commit.

## 13. Common Windows build problems

### PowerShell displays mojibake and reports `UnexpectedToken`

Legacy Windows PowerShell 5.1 may interpret a UTF-8 file without BOM as the
system ANSI code page. In project version `0.3.3`, all `.ps1` source files are
ASCII-only and the Traditional Chinese and English instructions are separate
UTF-8 text files. If text such as `摰` still appears, an older script is being
used. Download the latest complete package and replace
`apps/windows/scripts` entirely.

### PowerShell blocks script execution

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

Then run the script again. Do not permanently disable system-wide security
policy just for this project.

### `dotnet` is not recognized

Install the **.NET 8 SDK**, not only the Runtime. Open a new PowerShell window:

```powershell
dotnet --info
```

### Inno Setup cannot be found

Install Inno Setup 6. Its default path is usually:

```text
C:\Program Files (x86)\Inno Setup 6\ISCC.exe
```

### `ChineseTraditional.isl` cannot be found

The Traditional Chinese language file is bundled at
`apps\windows\installer\ChineseTraditional.isl`. It does not need to be
installed in the Inno Setup program directory. If the error still points to:

```text
C:\Program Files (x86)\Inno Setup 6\Languages\ChineseTraditional.isl
```

you are using an older `MonkeyDeskPets.iss`. Download the latest complete
project or confirm that its `[Languages]` entry is:

```ini
Name: "chinesetraditional"; MessagesFile: "{#SourcePath}\ChineseTraditional.isl"
```

The current `build-installer.ps1` also stops immediately when the Inno Setup
compiler fails instead of attempting to hash a missing installer.

### Installer license-page language

The installer loads the license page matching the language selected by the
user:

- Traditional Chinese: `apps\windows\installer\LICENSE-zh-TW.txt`
- English: `apps\windows\installer\LICENSE-en.txt`

Both installer summaries refer to the complete license documents installed
with the application.

### PowerShell reports a `profile.ps1` error before the build

That error comes from the user's PowerShell profile and is unrelated to
MonkeyDeskPets. Run PowerShell without the personal profile:

```powershell
powershell.exe -NoProfile
```

To repair the profile, open it with `notepad $PROFILE` and inspect its first
line for invalid text.

### Windows SmartScreen warning

A new unsigned EXE with few downloads may trigger SmartScreen. Verify the
download source and SHA-256. For production distribution, sign the file with
a Windows code-signing certificate.

### The program starts but no window appears

The Windows edition is a notification-area application. Select `^` on the
taskbar and locate the monkey icon.

### Sprite or license assets are missing

Do not copy a bare EXE out of the development directory. Use the complete ZIP
from `build-release.ps1` or the installer from `build-installer.ps1`.

The release script now verifies that required files such as
`Assets\person-sprites.png` exist before creating the ZIP and stops if any are
missing. A copy of the default sprite sheet is also embedded in the executable
so the application can still start and restore its defaults if the external
default image is accidentally removed.
To avoid differences in how .NET SDK versions publish linked `Content` outside
the project directory, the script explicitly copies shared assets and license
documents into the publish directory after `dotnet publish` completes.

---

# GitHub Actions and releases

## 14. Automatic Windows builds on GitHub

`.github/workflows/windows-build.yml` runs for:

- Pushes to `main`
- Pull requests
- Manual GitHub Actions dispatches

To inspect a build:

1. Open the GitHub repository.
2. Select `Actions`.
3. Select `Windows Build`.
4. Open the latest run.
5. Confirm that `win-x64` and `win-arm64` are green.
6. Download the Artifacts at the bottom of the run page.

If a build fails, expand the red step and retain the complete error output,
not only its final line.

## 15. Recommended GitHub Release assets

macOS:

```text
MonkeyDeskPets-macOS-v<version>.dmg
SHA256SUMS.txt
```

Windows:

```text
MonkeyDeskPets-Windows-win-x64-v<version>.zip
MonkeyDeskPets-Windows-win-x64-Setup-v<version>.exe
SHA256SUMS-Windows-win-x64.txt
SHA256SUMS-Windows-win-x64-Setup.txt
```

If Arm64 is supported in the release, add the equivalent `win-arm64` files.

Release each platform separately. Its tag, title, platform `VERSION`, App
version, and filenames must match:

```text
macOS Tag: macos-v2.7.4
macOS Title: MonkeyDeskPets macOS v2.7.4

Windows Tag: windows-v0.3.3
Windows Title: MonkeyDeskPets Windows v0.3.3
```

## 16. Verify SHA-256

macOS:

```bash
shasum -a 256 release/MonkeyDeskPets-macOS-v2.7.4.dmg
```

Windows:

```powershell
Get-FileHash .\release\MonkeyDeskPets-Windows-win-x64-v0.3.3.zip -Algorithm SHA256
```

The result must exactly match the corresponding `SHA256SUMS` file.

## 17. Pre-release checklist

- [ ] `git status` contains no accidentally omitted changes.
- [ ] `apps/macos/VERSION` matches the macOS application version.
- [ ] `apps/windows/VERSION` matches the Windows application version.
- [ ] The macOS App and DMG launch in a clean user account.
- [ ] The Windows ZIP and Setup installer launch on a test PC.
- [ ] The monkey application icon is displayed.
- [ ] The menu-bar or notification-area icon is displayed.
- [ ] Default sprites, uploads, green screen, and Easy Mode work.
- [ ] Dragging, feeding, Dad, and pet-count controls work.
- [ ] Traditional Chinese and English UI work.
- [ ] The About page shows `廷廷小教室、廷廷的家（Tim945）`.
- [ ] GitHub, Threads, Instagram, Shopee, and Logitech links are clickable.
- [ ] License, NOTICE, additional terms, and promotional assets are preserved.
- [ ] New SHA-256 files are generated and uploaded.

## 18. License notice

MonkeyDeskPets uses the MonkeyDeskPets Noncommercial License 1.0, based on the
PolyForm Noncommercial License 1.0.0. Derivative editions must comply with
`LICENSE`, `NOTICE`, `ADDITIONAL-TERMS-zh-TW.txt`, and all accompanying terms.

Do not remove the author, original project source, About page, official links,
or official promotional area when building or repackaging. Each new derivative
release must use the latest official promotional content available on its
release date. Previously released versions do not require perpetual
retroactive advertising updates.
