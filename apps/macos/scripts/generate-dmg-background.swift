import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("用法：swift generate-dmg-background.swift <輸出 PNG 路徑>\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

let canvasSize = NSSize(width: 640, height: 400)
let image = NSImage(size: canvasSize)
image.lockFocus()

let canvas = NSRect(origin: .zero, size: canvasSize)
let gradient = NSGradient(
    starting: NSColor(calibratedRed: 0.96, green: 0.98, blue: 1.0, alpha: 1),
    ending: NSColor(calibratedRed: 0.82, green: 0.91, blue: 1.0, alpha: 1)
)!
gradient.draw(in: canvas, angle: -90)

func drawCentered(_ text: String, y: CGFloat, height: CGFloat, font: NSFont, color: NSColor) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    text.draw(
        in: NSRect(x: 20, y: y, width: canvasSize.width - 40, height: height),
        withAttributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
    )
}

let titleColor = NSColor(calibratedWhite: 0.13, alpha: 1)
let subtitleColor = NSColor(calibratedWhite: 0.27, alpha: 1)
drawCentered(
    "安裝 MonkeyDeskPets",
    y: 334,
    height: 38,
    font: .systemFont(ofSize: 26, weight: .bold),
    color: titleColor
)
drawCentered(
    "Install MonkeyDeskPets",
    y: 306,
    height: 26,
    font: .systemFont(ofSize: 17, weight: .semibold),
    color: titleColor
)
drawCentered(
    "將 MonkeyDeskPets 拖入「Applications」資料夾",
    y: 276,
    height: 24,
    font: .systemFont(ofSize: 15, weight: .medium),
    color: subtitleColor
)
drawCentered(
    "Drag MonkeyDeskPets to the Applications folder",
    y: 253,
    height: 22,
    font: .systemFont(ofSize: 13, weight: .regular),
    color: subtitleColor
)

let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 246, y: 169))
arrow.line(to: NSPoint(x: 342, y: 169))
arrow.line(to: NSPoint(x: 342, y: 136))
arrow.line(to: NSPoint(x: 416, y: 190))
arrow.line(to: NSPoint(x: 342, y: 244))
arrow.line(to: NSPoint(x: 342, y: 211))
arrow.line(to: NSPoint(x: 246, y: 211))
arrow.close()
NSColor(calibratedRed: 0.16, green: 0.47, blue: 0.92, alpha: 0.92).setFill()
arrow.fill()

drawCentered(
    "MonkeyDeskPets Noncommercial License 1.0",
    y: 42,
    height: 18,
    font: .systemFont(ofSize: 10, weight: .regular),
    color: NSColor(calibratedWhite: 0.42, alpha: 1)
)

image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("錯誤：無法產生 DMG 背景圖片。\n", stderr)
    exit(1)
}

try pngData.write(to: outputURL, options: .atomic)
print("完成：\(outputURL.path)")
