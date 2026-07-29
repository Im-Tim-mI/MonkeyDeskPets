# MonkeyDeskPets for Windows

目前版本：**0.3.3**

Windows 版使用 C#、WPF 與 .NET 8，支援 Windows 10 版本 1809 以上及
Windows 11。程式採通知區常駐模式，不會顯示一般主視窗。

完整的 SDK 安裝、Visual Studio、ZIP、雙語安裝程式、GitHub Actions 與錯誤
排除請參閱：

- [macOS／Windows 編譯與發行手冊（繁體中文）](../../docs/BUILD-GUIDE-zh-TW.md)
- [macOS / Windows Build & Release Guide (English)](../../docs/BUILD-GUIDE-en.md)
- [Windows／macOS 行為一致性規格（繁體中文）](../../docs/WINDOWS-MACOS-PARITY-zh-TW.md)
- [Windows / macOS Behavior Parity Specification (English)](../../docs/WINDOWS-MACOS-PARITY-en.md)

## 已完成

- 以 macOS 版為基準的 60 FPS 單一狀態迴圈；不再使用固定秒數重新抽選
  全螢幕目標
- 與 macOS 相同的角色年齡週期：11 秒跳躍節奏、17 秒休息／睡眠節奏、
  1.4 秒跳躍保護與 0.65 秒特殊姿勢保持
- 與 macOS 相同的重力、螢幕邊緣反彈、視窗頂緣落腳與碰撞後方向變化
- 預設一名桌面寵物，通知區選單可增加、減少或只保留一人
- 減少人物時顯示與 macOS 相同的 18 尖角爆炸及 0.65 秒淡出效果
- 透明置頂人物視窗、螢幕邊界保護及一般應用程式視窗頂緣碰撞
- 滑鼠拖曳門檻；拖曳時固定使用編號 3，並暫停該人物動作
- 「餵食」後可連續放置多份狗糧，依 macOS 邏輯分派給最近的空閒角色；
  接近、2.4 秒進食及前後擺動參數均與 macOS 一致
- 「爸」以每秒 720 點讓所有人物使用編號 4 降到底部，全部抵達後才顯示
  2 秒對話；拖曳中的角色會使集合等待
- 上傳、覆蓋與恢復預設 4×2 精靈圖
- 綠幕精靈圖邊界判定、自動透明化與綠色溢色抑制
- 「懶人模式」上傳單張臉部照片後，在本機自動偵測主要臉部區域、
  生成 4×2 八姿勢精靈圖並立即套用
- 中文語系顯示繁體中文，其餘語系顯示英文
- 關於頁、作者資訊、GitHub、Threads、Instagram、作者蝦皮官方商店、
  羅技推廣圖片和完整授權條款
- x64／Arm64 自包含單檔發行腳本

## 目前差異

Windows 懶人模式使用本機膚色與主要臉部區域分析，不使用 macOS Vision；
照片不會上傳網路。Windows 使用 WPF、通知區及 Win32 視窗座標，macOS
使用 AppKit、選單列及 Core Graphics；多螢幕使用不同 DPI 縮放比例時，
Windows 視窗碰撞座標仍可能需要依實際配置微調。

## 開發執行

安裝 [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)，在
PowerShell 執行：

```powershell
cd apps\windows
.\scripts\run-debug.ps1
```

也可使用 Visual Studio 2022 開啟 `MonkeyDeskPets.Windows.sln`。

## 建立可攜式發行包

```powershell
cd apps\windows
.\scripts\build-release.ps1 -Runtime win-x64
```

Arm64：

```powershell
.\scripts\build-release.ps1 -Runtime win-arm64
```

輸出：

```text
release\MonkeyDeskPets-Windows-win-x64-v0.3.3.zip
release\SHA256SUMS-Windows-win-x64.txt
```

## 建立安裝程式

先安裝 Inno Setup 6，並先執行 `build-release.ps1`，然後：

```powershell
.\scripts\build-installer.ps1 -Runtime win-x64
```

輸出：

```text
release\MonkeyDeskPets-Windows-win-x64-Setup-v0.3.3.exe
```

安裝程式提供繁體中文與英文介面；「建立桌面啟動捷徑」預設勾選，使用者
仍可在安裝時取消。

## 授權

Windows 版本同樣受根目錄的 MonkeyDeskPets Noncommercial License 1.0
約束，必須保留作者、專案出處、關於頁面、官方連結與推廣區域。
