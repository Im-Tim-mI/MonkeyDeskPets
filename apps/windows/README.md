# MonkeyDeskPets for Windows（預留）

此目錄保留給未來 Windows 版本。目前尚未包含可執行的 Windows 程式，
因此不應宣稱 Windows 版已完成或可供下載。

## 建議技術

- 語言：C#
- UI：WinUI 3
- 平台：Windows App SDK
- 最低系統：Windows 10 版本 1809 或更新版本
- 發布架構：x64、Arm64

## 預定目錄

```text
apps/windows/
├── MonkeyDeskPets.sln
├── src/
│   └── MonkeyDeskPets.Windows/
├── tests/
└── scripts/
```

## 必須維持的跨平台行為

- 使用 `shared/assets/` 的預設精靈圖、作者圖片與廣告圖片
- 自動偵測系統語系：中文語系顯示繁體中文，其餘語系顯示英文
- 保留「關於」頁面、作者資訊、官方連結、廣告區域及可點擊功能
- 內嵌根目錄的完整授權、附加條款及 NOTICE
- 與 macOS 版本使用相同的 4×2、編號 0～7 精靈圖定義

## 授權

未來 Windows 版本同樣受根目錄的 MonkeyDeskPets Noncommercial License 1.0
約束，不得另行改用會移除作者、官方連結或廣告保留要求的授權。
