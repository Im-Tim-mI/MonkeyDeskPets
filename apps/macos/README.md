# MonkeyDeskPets for macOS

macOS 版使用 Swift、AppKit 與 Swift Package Manager，支援 macOS 13 以上。

完整的環境安裝、Xcode、App、雙語 DMG、SHA-256與錯誤排除請參閱：

- [macOS／Windows 編譯與發行手冊（繁體中文）](../../docs/BUILD-GUIDE-zh-TW.md)
- [macOS / Windows Build & Release Guide (English)](../../docs/BUILD-GUIDE-en.md)

快速建立 DMG：

```bash
cd ../..
chmod +x apps/macos/scripts/*.sh
./apps/macos/scripts/build-dmg.sh
```
