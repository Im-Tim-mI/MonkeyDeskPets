# Shared Resources

`shared/assets/` 是 macOS 與未來 Windows 版本的共用素材來源：

- `person-sprites.png`：正式預設 4×2 精靈圖
- `person-sprites-chroma.png`：綠幕測試／參考素材
- `author-avatar.png`：關於頁作者圖片
- `logitech-ad.jpeg`：關於頁廣告圖片
- `app-icon-1024.png`：App 與 DMG 使用的 1024×1024 猴子主圖示

macOS 建置前會由 `apps/macos/scripts/sync-shared-resources.sh` 將正式素材與
根目錄授權文件同步到 Swift Package 資源目錄。未來 Windows 建置腳本也必須
採用相同來源，避免兩個平台使用不同作者資訊、廣告或預設精靈圖。

DMG 的繁體中文／英文安裝背景由
`apps/macos/scripts/generate-dmg-background.swift` 在建置時使用 macOS
系統字型產生，因此不需要保存額外的背景點陣圖。
