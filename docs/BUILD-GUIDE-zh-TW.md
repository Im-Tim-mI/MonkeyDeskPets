# MonkeyDeskPets macOS／Windows 編譯與發行手冊

本手冊適用於 MonkeyDeskPets 2.7.x，說明如何從原始碼執行、編譯及建立可供
GitHub Release 使用的發行檔案。

作者：**廷廷小教室、廷廷的家（Tim945）**

> macOS App／DMG 必須在 macOS 編譯；Windows EXE／安裝程式必須在 Windows
> 編譯。建議先完成對應平台的「開發執行」，確認功能正常後再建立發行包。

## 1. 下載專案

### 使用 Git

```bash
git clone https://github.com/Im-Tim-mI/MonkeyDeskPets.git
cd MonkeyDeskPets
```

也可以在 GitHub 按 `Code` → `Download ZIP`。解壓後，後續指令都必須在
包含 `apps`、`shared` 的專案根目錄執行。macOS 與 Windows 分別使用
`apps/macos/VERSION` 與 `apps/windows/VERSION`。

## 2. 專案目錄

```text
MonkeyDeskPets/
├── apps/
│   ├── macos/                 # Swift／AppKit，含獨立 VERSION
│   └── windows/               # C#／WPF，含獨立 VERSION
├── shared/assets/             # 共用精靈、作者、廣告與圖示
├── docs/                      # 手冊
├── release/                   # 建置後產生，不提交 Git
├── LICENSE
└── NOTICE
```

不可刪除 `LICENSE`、`NOTICE`、附加條款、作者資訊、官方連結及推廣區域。

---

# macOS 編譯

## 3. macOS 系統需求

- macOS 13 Ventura 或更新版本
- Xcode 15 或更新版本
- Swift 5.9 相容工具鏈
- 約 3 GB 可用空間
- Apple Silicon 與 Intel Mac 均可建置

安裝 Xcode 後第一次使用，請開啟一次 Xcode並接受授權條款。再於「終端機」執行：

```bash
xcode-select -p
swift --version
```

若 `xcode-select -p` 找不到工具：

```bash
xcode-select --install
```

如果電腦同時安裝多套 Xcode：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## 4. macOS 開發執行

在專案根目錄：

```bash
chmod +x apps/macos/scripts/*.sh
cd apps/macos
./scripts/sync-shared-resources.sh
swift run
```

若要使用 Xcode：

1. 開啟 Xcode。
2. 選擇 `File` → `Open`。
3. 選擇 `apps/macos/Package.swift`。
4. Scheme 選擇 `MonkeyDeskPets`。
5. 執行目標選擇 `My Mac`。
6. 按下 `▶ Run`。

程式啟動後不會出現在 Dock，請在 macOS 選單列尋找 `🐒`。

## 5. 建立 macOS App

回到專案根目錄：

```bash
chmod +x apps/macos/scripts/*.sh
./apps/macos/scripts/build-app.sh release
```

成功後輸出：

```text
apps/macos/dist/MonkeyDeskPets.app
```

測試：

```bash
open apps/macos/dist/MonkeyDeskPets.app
```

不要只把 `.app` 當成一般單一檔案上傳；它實際上是目錄包。公開散布建議建立
DMG，或先以 Finder／`ditto` 壓縮。

## 6. 建立中英雙語 macOS DMG

在專案根目錄執行：

```bash
chmod +x apps/macos/scripts/*.sh
./apps/macos/scripts/build-dmg.sh
```

腳本會自動：

1. 同步共用素材與授權文件。
2. 建立 Release App。
3. 產生猴子 `.icns` 圖示。
4. 產生繁體中文／英文 DMG 安裝背景。
5. 放入 `MonkeyDeskPets.app` 與 `Applications` 捷徑。
6. 排列拖曳安裝圖示。
7. 建立壓縮 DMG 與 SHA-256。

輸出檔名會自動讀取 `apps/macos/VERSION`：

```text
release/MonkeyDeskPets-macOS-v<版本>.dmg
release/SHA256SUMS.txt
```

開啟輸出目錄：

```bash
open release
```

掛載 DMG 後，必須確認：

- App 與掛載磁碟顯示猴子圖示。
- 畫面同時顯示繁體中文與英文拖曳提示。
- `Applications` 捷徑可以使用。
- 將 App 拖入 Applications 後可以啟動。

## 7. macOS 未簽署程式

沒有 Apple Developer ID 簽署時，其他使用者第一次開啟可能看到 Gatekeeper
警告。可在 Finder 對 App 按右鍵，選擇「打開」，再確認一次。

正式公開發行建議使用 Apple Developer ID Application 憑證簽署並完成 Apple
公證。簽署前可檢查：

```bash
codesign --verify --deep --strict --verbose=2 \
  apps/macos/dist/MonkeyDeskPets.app
```

此專案的普通建置腳本不會擅自使用或保存你的開發者憑證。

## 8. macOS 常見錯誤

### `Permission denied`

```bash
chmod +x apps/macos/scripts/*.sh
```

### `Info.plist` unhandled warning

目前的 `Package.swift` 已明確排除由打包腳本處理的 `Info.plist`。如果仍看到警告，
請確認已下載最新版專案；正式 App 的 Info.plist 由 `build-app.sh` 放入 App bundle。

### `awk: syntax error` 或 DMG 停在掛載階段

舊版 `build-dmg.sh` 曾對斜線重複跳脫，導致 macOS BSD awk 解析失敗。請更新到
v2.7.4 或更新版本。若失敗後 Finder 仍掛載著 MonkeyDeskPets，先執行：

```bash
hdiutil detach "/Volumes/MonkeyDeskPets"
```

如果顯示找不到該磁碟，代表已經卸載，可直接重新執行 `build-dmg.sh`。

### `Constant must be declared private`

不要同時保留兩組程式入口。檔案底部應只有一組：

```swift
let application = NSApplication.shared
private let delegate = DesktopPetController()
```

如果 `DesktopPetController` 是 `private`，使用它的全域常數也必須是 `private`。

### `Invalid redeclaration of 'application'`

表示同一作用域內有兩行 `let application = NSApplication.shared`。刪除重複的一行，
不要另外新增第三行。

### App 開啟但沒有主視窗

MonkeyDeskPets 是選單列程式。請查看畫面右上方的 `🐒`，不是 Dock。

---

# Windows 編譯

## 9. Windows 系統需求

- Windows 10 版本 1809 或更新版本，或 Windows 11
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- PowerShell 5.1 或 PowerShell 7
- 建議使用 Visual Studio 2026，工作負載勾選「.NET 桌面開發」
- 建立安裝程式時需安裝 [Inno Setup 6](https://jrsoftware.org/isdl.php)

安裝後開啟新的 PowerShell：

```powershell
dotnet --version
```

應顯示 `8.x.x`。若仍找不到 `dotnet`，重新啟動終端機或 Windows。

## 10. Windows 開發執行

在專案根目錄：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
cd apps\windows
.\scripts\run-debug.ps1
```

`-Scope Process` 只影響目前 PowerShell 視窗，關閉後即失效。

也可以使用 Visual Studio：

1. 開啟 `apps/windows/MonkeyDeskPets.Windows.sln`。
2. 等待 NuGet／SDK 還原完成。
3. 組態選擇 `Debug`。
4. 啟動專案選擇 `MonkeyDeskPets.Windows`。
5. 按 `F5`。

程式啟動後請查看 Windows 通知區；如果猴子圖示被收合，按通知區的 `^`。

## 11. 建立 Windows 可攜式 ZIP

### x64：一般 Intel／AMD Windows 電腦

```powershell
cd apps\windows
.\scripts\build-release.ps1 -Runtime win-x64
```

### Arm64：Windows on ARM

```powershell
cd apps\windows
.\scripts\build-release.ps1 -Runtime win-arm64
```

腳本使用自包含模式，使用者不必另外安裝 .NET Runtime。輸出：

```text
release\MonkeyDeskPets-Windows-win-x64-v<版本>.zip
release\SHA256SUMS-Windows-win-x64.txt
```

ZIP 必須完整解壓後再執行 `MonkeyDeskPets.exe`，不要直接在壓縮檔預覽器中啟動。

## 12. 建立 Windows 中英雙語安裝程式

版本會自動讀取 `apps/windows/VERSION`。目前 Windows 版本為 `0.3.3`。
安裝 Inno Setup 6 後：

```powershell
cd apps\windows
.\scripts\build-installer.ps1 -Runtime win-x64
```

Arm64：

```powershell
.\scripts\build-installer.ps1 -Runtime win-arm64
```

如果尚未建立可攜式版本，安裝腳本會先呼叫 `build-release.ps1`。輸出：

```text
release\MonkeyDeskPets-Windows-win-x64-Setup-v0.3.3.exe
release\SHA256SUMS-Windows-win-x64-Setup.txt
```

安裝程式包含：

- 繁體中文與英文介面
- 猴子應用程式及安裝程式圖示
- 開始功能表捷徑
- 桌面啟動捷徑（安裝時預設勾選，使用者可取消）
- 可選開機自動啟動
- 解除安裝功能

### 完整打包步驟

1. 確認 `apps/windows/VERSION` 與 `.csproj` 版本均為 `0.3.3`。
2. 在 Visual Studio 2026 執行「清除方案」及「重建方案」。
3. 關閉正在執行的 MonkeyDeskPets。
4. 在專案根目錄開啟 PowerShell。
5. 執行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\apps\windows\scripts\build-installer.ps1 -Runtime win-x64
```

6. 執行 `release\MonkeyDeskPets-Windows-win-x64-Setup-v0.3.3.exe`。
7. 分別測試繁體中文與英文安裝介面。
8. 保持「建立桌面捷徑」勾選，完成安裝並從桌面啟動。
9. 確認通知區圖示、選單、關於頁版本及解除安裝均正常。
10. 將 Setup EXE 與對應的 SHA-256 文件上傳至 Windows Release。

### Git 上傳過濾

根目錄 `.gitignore` 已排除 `.vs`、`bin`、`obj`、`dist`、`release`、
`.exe`、`.dmg`、`.zip`、SHA-256 輸出及本機秘密設定。提交前執行：

```powershell
git status
git check-ignore -v .\release\MonkeyDeskPets-Windows-win-x64-Setup-v0.3.3.exe
```

安裝程式應被忽略；`.cs`、`.csproj`、`.iss`、`.ps1`、授權與文件則應正常
出現在可提交內容中。

## 13. Windows 常見錯誤

### PowerShell 顯示亂碼並回報 `UnexpectedToken`

舊版 Windows PowerShell 5.1 可能把 UTF-8 無 BOM 腳本誤判為系統 ANSI
編碼。本專案 `0.3.3` 的 `.ps1` 已改為純 ASCII，繁中與英文說明改為獨立
UTF-8 文字檔。如果仍出現 `摰` 等亂碼，代表使用的是舊腳本；請重新下載
最新版完整包並覆蓋整個 `apps/windows/scripts`。

### PowerShell 禁止執行腳本

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

然後重新執行腳本。不要為了本專案永久關閉整台電腦的安全政策。

### `dotnet` 不是可辨識的命令

安裝的是 **.NET 8 SDK**，不是只有 Runtime。安裝後關閉並重新開啟 PowerShell：

```powershell
dotnet --info
```

### 找不到 Inno Setup

確認已安裝 Inno Setup 6。預設路徑通常是：

```text
C:\Program Files (x86)\Inno Setup 6\ISCC.exe
```

### 找不到 `ChineseTraditional.isl`

本專案已在 `apps\windows\installer\ChineseTraditional.isl` 內附繁體中文
語言檔，不需要把語言檔另外放進 Inno Setup 的安裝目錄。如果錯誤仍指向：

```text
C:\Program Files (x86)\Inno Setup 6\Languages\ChineseTraditional.isl
```

代表目前使用的是舊版 `MonkeyDeskPets.iss`。請重新下載最新版完整專案，
或確認 `[Languages]` 中的繁中設定是：

```ini
Name: "chinesetraditional"; MessagesFile: "{#SourcePath}\ChineseTraditional.isl"
```

新版 `build-installer.ps1` 也會在 Inno Setup 編譯失敗後立即停止，不會再
繼續雜湊一個不存在的安裝程式。

### 安裝程式授權頁語言

安裝程式會依使用者在語言選擇畫面選取的語言載入授權頁：

- 繁體中文：`apps\windows\installer\LICENSE-zh-TW.txt`
- English：`apps\windows\installer\LICENSE-en.txt`

兩份安裝摘要均會指向隨程式安裝的完整授權文件。

### PowerShell 啟動時先出現 `profile.ps1` 錯誤

這是使用者 PowerShell 設定檔的錯誤，與 MonkeyDeskPets 無關。可以先用
不載入個人設定檔的 PowerShell 執行：

```powershell
powershell.exe -NoProfile
```

若要修正設定檔，可用 `notepad $PROFILE` 檢查第一行的無效文字。

### Windows SmartScreen 警告

未使用商業程式碼簽署憑證時，下載次數較少的新 EXE 可能觸發 SmartScreen。
請確認下載來源與 SHA-256。正式散布可購買 Windows Code Signing 憑證簽署。

### 執行後看不到視窗

Windows 版是通知區程式。按工作列通知區的 `^`，尋找猴子圖示。

### 精靈或授權素材缺失

不要只複製開發目錄中的裸 EXE。請使用 `build-release.ps1` 產生的完整 ZIP，
或使用 `build-installer.ps1` 產生的安裝程式。

目前的發行腳本會在建立 ZIP 前確認 `Assets\person-sprites.png` 等必要素材
確實存在；任何檔案缺失都會停止打包。預設精靈圖也會內嵌一份於程式內，
即使外部預設圖片意外遺失，程式仍能啟動並執行「恢復預設精靈圖」。
為避免不同 .NET SDK 對專案外部 `Content` 的 Publish 行為不一致，腳本會
在 `dotnet publish` 完成後直接將共用素材與授權文件複製到發行目錄。

---

# GitHub Actions 與發布

## 14. GitHub 自動編譯 Windows

倉庫內的 `.github/workflows/windows-build.yml` 會在以下情況執行：

- 推送至 `main`
- Pull Request
- GitHub Actions 手動執行

查看方法：

1. 開啟 GitHub 倉庫。
2. 點擊 `Actions`。
3. 選擇 `Windows Build`。
4. 點擊最新一次執行。
5. 確認 `win-x64` 與 `win-arm64` 均為綠色。
6. 在該次執行頁面下方下載 Artifacts。

若編譯失敗，展開紅色步驟並保留完整錯誤文字；不要只截最後一行。

## 15. GitHub Release 建議附件

macOS Release：

```text
MonkeyDeskPets-macOS-v<版本>.dmg
SHA256SUMS.txt
```

Windows Release：

```text
MonkeyDeskPets-Windows-win-x64-v<版本>.zip
MonkeyDeskPets-Windows-win-x64-Setup-v<版本>.exe
SHA256SUMS-Windows-win-x64.txt
SHA256SUMS-Windows-win-x64-Setup.txt
```

如果提供 Arm64，再加入相同名稱的 `win-arm64` 檔案。

兩個平台分開發行。Tag、標題、平台 `VERSION`、App 版本和檔名必須一致：

```text
macOS Tag: macos-v2.7.4
macOS Title: MonkeyDeskPets macOS v2.7.4

Windows Tag: windows-v0.3.3
Windows Title: MonkeyDeskPets Windows v0.3.3
```

## 16. SHA-256 驗證

macOS：

```bash
shasum -a 256 release/MonkeyDeskPets-macOS-v2.7.4.dmg
```

Windows：

```powershell
Get-FileHash .\release\MonkeyDeskPets-Windows-win-x64-v0.3.3.zip -Algorithm SHA256
```

結果必須和對應的 `SHA256SUMS` 文件完全一致。

## 17. 發布前檢查表

- [ ] `git status` 沒有意外遺漏的修改。
- [ ] `apps/macos/VERSION` 與 macOS 程式版本一致。
- [ ] `apps/windows/VERSION` 與 Windows 程式版本一致。
- [ ] macOS App／DMG 可在乾淨帳號啟動。
- [ ] Windows ZIP／Setup 可在測試電腦啟動。
- [ ] 猴子應用程式圖示正常。
- [ ] 通知區／選單列圖示正常。
- [ ] 預設精靈、上傳精靈、綠幕及懶人模式正常。
- [ ] 拖曳、餵食、喊爸與增減人物正常。
- [ ] 中英文介面正常。
- [ ] 關於頁作者名稱為「廷廷小教室、廷廷的家（Tim945）」。
- [ ] GitHub、Threads、Instagram、蝦皮與羅技連結可點擊。
- [ ] LICENSE、NOTICE、附加條款與推廣素材完整保留。
- [ ] SHA-256 已重新產生並一同上傳。

## 18. 授權提醒

MonkeyDeskPets 採 MonkeyDeskPets Noncommercial License 1.0，基於 PolyForm
Noncommercial License 1.0.0。任何二創版本都必須遵守根目錄的 `LICENSE`、
`NOTICE`、`ADDITIONAL-TERMS-zh-TW.txt` 與其他隨附條款。

編譯或重新打包時，不得移除作者、原始專案出處、關於頁、官方連結及官方推廣
區域。二創版本每次發布新版時，必須使用該次發布日的最新官方推廣內容；已發布
舊版本不必因日後推廣內容變更而永久回溯更新。
