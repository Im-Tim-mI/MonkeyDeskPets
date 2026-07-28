//
// MonkeyDeskPets
// Copyright © 2026 廷廷小教室、廷廷的家（Tim945）
//
// Licensed under the MonkeyDeskPets Noncommercial License 1.0,
// based on PolyForm Noncommercial License 1.0.0.
// See LICENSE, NOTICE, and ADDITIONAL-TERMS-zh-TW.txt.
//
// Author, attribution, About-page, official-link, and bundled-advertising
// notices must not be removed except with prior written permission.
//

import AppKit
import CoreGraphics
import ImageIO
import QuartzCore
import UniformTypeIdentifiers
import Vision

private let characterSize = CGSize(width: 156, height: 156)
private let petWindowSize = CGSize(width: 156, height: 167)
private let appVersion = "2.7.4"
private let dragPose: Pose = .hang

private enum AppLanguage {
    case traditionalChinese
    case english

    static let current: AppLanguage = {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
        return preferred.hasPrefix("zh") ? .traditionalChinese : .english
    }()
}

private func localized(_ traditionalChinese: String, _ english: String) -> String {
    AppLanguage.current == .traditionalChinese ? traditionalChinese : english
}

private var retentionTermsText: String {
    localized(
"""
廣告與作者資訊保留條款

本附加條款是取得、使用、修改、重製及散布 MonkeyDeskPets
授權的必要條件，並與 PolyForm Noncommercial License 1.0.0
共同構成完整授權。

任何人使用、修改、重製或散布本軟體，即表示接受並同意遵守
PolyForm Noncommercial License 1.0.0、本附加條款及 NOTICE。

若本附加條款與 PolyForm Noncommercial License 1.0.0 發生牴觸，
就 MonkeyDeskPets 而言，以本附加條款為準。

任何人使用、修改、重製或散布本軟體及其衍生版本時，均必須完整保留：

1. 作者名稱「廷廷小教室、廷廷的家（Tim945）」；
2. 原始專案名稱「MonkeyDeskPets」與出處連結
   「https://github.com/Im-Tim-mI/MonkeyDeskPets」；
3. 程式內的「關於」頁面、作者資訊，以及原始版本所列的
   GitHub、Threads、Instagram、蝦皮官方商店或其後由著作權人指定的官方連結；
4. 原始版本內由著作權人設置的廣告區域、廣告顯示功能及相關連結。

未經著作權人事先書面同意，不得刪除、隱藏、遮蔽、停用、
繞過、替換或竄改上述作者資訊及廣告功能。

允許為相容性、版面配置或錯誤修正而調整廣告顯示方式，
但不得使廣告難以辨識、無法操作或實質上不再顯示。

衍生版本公開發布或散布時，必須採用該發布日由著作權人於官方專案倉庫
公布的最新版官方推廣內容。發布完成後，無須僅因官方推廣內容日後變更
而回溯更新舊版本；但衍生版本日後發布新版、更新版或重新打包版本時，
必須採用該次發布日的最新版官方推廣內容。

廣告內容及連結由著作權人指定。第三方不得將其替換成自己的
廣告、追蹤程式或營利內容。為遵守本條款而顯示指定的官方推廣內容，
本身不視為被授權者對本軟體的商業使用。

Copyright © 2026 廷廷小教室、廷廷的家（Tim945）
""",
"""
Advertising and Author Information Retention Terms

These Additional Terms are necessary conditions for obtaining a license to
access, use, modify, reproduce, and distribute MonkeyDeskPets. Together with
the PolyForm Noncommercial License 1.0.0, they constitute the complete license.

Anyone who uses, modifies, reproduces, or distributes this software accepts
and agrees to comply with the PolyForm Noncommercial License 1.0.0, these
Additional Terms, and NOTICE.

If these Additional Terms conflict with the PolyForm Noncommercial License
1.0.0, these Additional Terms control with respect to MonkeyDeskPets.

Anyone who uses, modifies, reproduces, or distributes this software or a
derivative version must retain all of the following:

1. The author name "廷廷小教室、廷廷的家（Tim945）";
2. The original project name "MonkeyDeskPets" and source link
   "https://github.com/Im-Tim-mI/MonkeyDeskPets";
3. The in-app About page, author information, and the GitHub, Threads,
   Instagram, and official Shopee store links listed in the original version,
   or official links later designated by the copyright holder;
4. Advertising areas, advertising display functionality, and related links
   placed in the original version by the copyright holder.

Without the copyright holder's prior written consent, the items above may not
be removed, hidden, obscured, disabled, bypassed, replaced, or altered.

The advertising presentation may be adjusted for compatibility, layout, or
bug fixes, but the advertising must remain identifiable, operable, and
substantively visible.

When a derivative version is publicly released or distributed, it must use the
latest official promotional content published by the copyright holder in the
official project repository as of that release date. After release, previously
published versions do not need to be retroactively updated solely because the
official promotional content later changes. A new, updated, or repackaged
derivative release must use the latest content as of its own release date.

Advertising content and links are designated by the copyright holder. Third
parties may not replace them with their own advertisements, trackers, or
revenue-generating content. Displaying designated official promotional content
solely to comply with these terms does not by itself constitute commercial use
of the software by the licensee.

Copyright © 2026 廷廷小教室、廷廷的家（Tim945）
"""
    )
}

private let authorGitHubURL = URL(
    string: "https://github.com/Im-Tim-mI"
)!
private let authorThreadsURL = URL(string: "https://www.threads.com/@tim945_1")!
private let authorInstagramURL = URL(string: "https://www.instagram.com/tim945_1")!
private let authorShopeeURL = URL(string: "https://shopee.tw/rr901037")!
private let logitechStoreURL = URL(
    string: "https://store.logitech.tw/collections/logitech_gam"
)!

private enum Pose: Int, CaseIterable {
    case crawlA = 0
    case crawlB = 1
    case climb = 2
    case hang = 3
    case crouch = 4
    case leap = 5
    case sit = 6
    case sleep = 7
}

private final class DragSurfaceView: NSView {
    var onDragChanged: ((Bool) -> Void)?
    private let dragThreshold: CGFloat = 6
    private var initialMouseLocation: NSPoint?
    private var initialWindowOrigin: NSPoint?
    private var recognizedAsDrag = false

    override var mouseDownCanMoveWindow: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        guard let window, !window.ignoresMouseEvents else { return }
        initialMouseLocation = NSEvent.mouseLocation
        initialWindowOrigin = window.frame.origin
        recognizedAsDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window, !window.ignoresMouseEvents,
              let initialMouseLocation, let initialWindowOrigin else { return }

        let currentMouseLocation = NSEvent.mouseLocation
        let deltaX = currentMouseLocation.x - initialMouseLocation.x
        let deltaY = currentMouseLocation.y - initialMouseLocation.y
        let movementSquared = deltaX * deltaX + deltaY * deltaY

        if !recognizedAsDrag, movementSquared >= dragThreshold * dragThreshold {
            recognizedAsDrag = true
            self.initialMouseLocation = currentMouseLocation
            self.initialWindowOrigin = window.frame.origin
            onDragChanged?(true)
            return
        }

        if recognizedAsDrag {
            window.setFrameOrigin(
                NSPoint(
                    x: initialWindowOrigin.x + deltaX,
                    y: initialWindowOrigin.y + deltaY
                )
            )
        }
    }

    override func mouseUp(with event: NSEvent) {
        if recognizedAsDrag { onDragChanged?(false) }
        initialMouseLocation = nil
        initialWindowOrigin = nil
        recognizedAsDrag = false
    }
}

private final class FoodView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bowlRect = NSRect(x: 5, y: 5, width: bounds.width - 10, height: 25)
        NSColor(calibratedRed: 0.28, green: 0.48, blue: 0.72, alpha: 1).setFill()
        NSBezierPath(roundedRect: bowlRect, xRadius: 10, yRadius: 10).fill()

        NSColor(calibratedRed: 0.35, green: 0.18, blue: 0.07, alpha: 1).setFill()
        let kibbleCenters = [
            NSPoint(x: 14, y: 29), NSPoint(x: 23, y: 34),
            NSPoint(x: 32, y: 30), NSPoint(x: 40, y: 35),
            NSPoint(x: 48, y: 29)
        ]
        for center in kibbleCenters {
            NSBezierPath(ovalIn: NSRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)).fill()
        }
    }
}

private final class FoodWindow: NSPanel {
    init(center: CGPoint) {
        let size = CGSize(width: 62, height: 52)
        super.init(
            contentRect: NSRect(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2,
                width: size.width,
                height: size.height
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        contentView = FoodView(frame: NSRect(origin: .zero, size: size))
        orderFrontRegardless()
    }
}

private final class Food {
    let window: FoodWindow
    weak var claimedBy: Pet?

    init(at point: CGPoint) {
        window = FoodWindow(center: point)
    }

    var center: CGPoint {
        CGPoint(x: window.frame.midX, y: window.frame.midY)
    }
}

private final class PlacementView: NSView {
    var onPlace: ((CGPoint) -> Void)?

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        onPlace?(window.convertPoint(toScreen: event.locationInWindow))
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }
}

private final class PlacementWindow: NSPanel {
    init(screen: NSScreen, onPlace: @escaping (CGPoint) -> Void) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = NSColor.black.withAlphaComponent(0.001)
        hasShadow = false
        level = .screenSaver
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        let placementView = PlacementView(frame: NSRect(origin: .zero, size: screen.frame.size))
        placementView.onPlace = onPlace
        contentView = placementView
        orderFrontRegardless()
    }
}

private final class ExplosionView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let outerRadius = min(bounds.width, bounds.height) * 0.46
        let innerRadius = outerRadius * 0.48
        let rayCount = 18
        let burst = NSBezierPath()

        for index in 0..<(rayCount * 2) {
            let angle = CGFloat(index) * .pi / CGFloat(rayCount) - .pi / 2
            let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            if index == 0 {
                burst.move(to: point)
            } else {
                burst.line(to: point)
            }
        }
        burst.close()
        NSColor.systemOrange.setFill()
        burst.fill()

        let core = NSBezierPath(
            ovalIn: CGRect(
                x: center.x - innerRadius,
                y: center.y - innerRadius,
                width: innerRadius * 2,
                height: innerRadius * 2
            )
        )
        NSColor.systemYellow.setFill()
        core.fill()

        NSColor.white.withAlphaComponent(0.9).setFill()
        NSBezierPath(
            ovalIn: CGRect(
                x: center.x - 10,
                y: center.y - 6,
                width: 20,
                height: 20
            )
        ).fill()
    }
}

private final class ExplosionWindow: NSPanel {
    init(center: CGPoint) {
        let size = CGSize(width: 130, height: 130)
        super.init(
            contentRect: CGRect(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2,
                width: size.width,
                height: size.height
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        canHide = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        contentView = ExplosionView(frame: CGRect(origin: .zero, size: size))
        orderFrontRegardless()
    }
}

private final class ExternalLinkButton: NSButton {
    private let destinationURL: URL

    init(label: String, displayedURL: String, destinationURL: URL) {
        self.destinationURL = destinationURL
        super.init(frame: .zero)
        let styledTitle = NSMutableAttributedString(
            string: label,
            attributes: [
                .foregroundColor: NSColor.black,
                .font: NSFont.systemFont(ofSize: 11.5, weight: .medium),
                .underlineStyle: 0
            ]
        )
        styledTitle.append(
            NSAttributedString(
                string: displayedURL,
                attributes: [
                    .foregroundColor: NSColor.linkColor,
                    .font: NSFont.systemFont(ofSize: 11.5, weight: .medium),
                    .underlineStyle: 0
                ]
            )
        )
        attributedTitle = styledTitle
        target = self
        action = #selector(openDestination)
        isBordered = false
        setButtonType(.momentaryPushIn)
        toolTip = destinationURL.absoluteString
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func openDestination() {
        NSWorkspace.shared.open(destinationURL)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}

private final class ClickableImageView: NSImageView {
    var destinationURL: URL?

    override func mouseUp(with event: NSEvent) {
        guard let destinationURL else { return }
        NSWorkspace.shared.open(destinationURL)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}

private final class AboutWindow: NSPanel {
    init(version: String) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 800),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        title = localized("關於 MonkeyDeskPets", "About MonkeyDeskPets")
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        center()

        let root = NSView(frame: NSRect(x: 0, y: 0, width: 720, height: 800))
        contentView = root

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: root.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: root.bottomAnchor, constant: -22)
        ])

        let avatar = NSImageView()
        avatar.imageScaling = .scaleProportionallyUpOrDown
        avatar.wantsLayer = true
        avatar.layer?.cornerRadius = 65
        avatar.layer?.masksToBounds = true
        if let url = Bundle.module.url(forResource: "author-avatar", withExtension: "png") {
            avatar.image = NSImage(contentsOf: url)
        }
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 130),
            avatar.heightAnchor.constraint(equalToConstant: 130)
        ])
        stack.addArrangedSubview(avatar)

        let name = NSTextField(
            labelWithString: localized("MonkeyDeskPets 桌面猴群", "MonkeyDeskPets Desktop Pets")
        )
        name.font = .systemFont(ofSize: 23, weight: .bold)
        stack.addArrangedSubview(name)

        let details = NSTextField(
            labelWithString: localized(
                "版本：\(version)\n作者：廷廷小教室、廷廷的家（Tim945）",
                "Version: \(version)\nAuthor: 廷廷小教室、廷廷的家（Tim945）"
            )
        )
        details.alignment = .center
        details.font = .systemFont(ofSize: 14)
        stack.addArrangedSubview(details)

        let links = NSStackView(views: [
            ExternalLinkButton(
                label: "github:",
                displayedURL: "https://github.com/Im-Tim-mI",
                destinationURL: authorGitHubURL
            ),
            ExternalLinkButton(
                label: "threads:",
                displayedURL: "https://www.threads.com/@tim945_1",
                destinationURL: authorThreadsURL
            ),
            ExternalLinkButton(
                label: "IG:",
                displayedURL: "https://www.instagram.com/tim945_1",
                destinationURL: authorInstagramURL
            ),
            ExternalLinkButton(
                label: localized("作者官方商店（蝦皮）：", "Official Shopee Store:"),
                displayedURL: "https://shopee.tw/rr901037",
                destinationURL: authorShopeeURL
            )
        ])
        links.orientation = .vertical
        links.alignment = .leading
        links.distribution = .fill
        links.spacing = 4
        stack.addArrangedSubview(links)

        let notice = NSTextField(wrappingLabelWithString: localized(
            "MonkeyDeskPets Noncommercial License 1.0\n基於 PolyForm Noncommercial License 1.0.0\n禁止商用，且必須保留作者資訊、官方連結與隨附廣告。",
            "MonkeyDeskPets Noncommercial License 1.0\nBased on PolyForm Noncommercial License 1.0.0\nCommercial use is prohibited; author details, official links, and bundled advertising must be retained."
        ))
        notice.alignment = .center
        notice.font = .systemFont(ofSize: 13, weight: .medium)
        notice.textColor = .secondaryLabelColor
        notice.maximumNumberOfLines = 3
        stack.addArrangedSubview(notice)

        let ad = ClickableImageView()
        ad.destinationURL = logitechStoreURL
        ad.imageScaling = .scaleProportionallyUpOrDown
        ad.toolTip = localized(
            "前往羅技 Logi 網路旗艦店－電競專區",
            "Open the Logitech Logi Online Flagship Store – Gaming"
        )
        if let url = Bundle.module.url(forResource: "logitech-ad", withExtension: "jpeg") {
            ad.image = NSImage(contentsOf: url)
        }
        NSLayoutConstraint.activate([
            ad.widthAnchor.constraint(equalToConstant: 560),
            ad.heightAnchor.constraint(equalToConstant: 315)
        ])
        stack.addArrangedSubview(ad)

        let storeLink = ExternalLinkButton(
            label: localized(
                "羅技Logi 網路旗艦店-電競專區：",
                "Logitech Logi Online Flagship Store - Gaming: "
            ),
            displayedURL: "https://store.logitech.tw/collections/logitech_gam",
            destinationURL: logitechStoreURL
        )
        stack.addArrangedSubview(storeLink)

        let termsButton = NSButton(
            title: localized(
                "查看完整「廣告與作者資訊保留條款」",
                "View Full Advertising and Attribution Terms"
            ),
            target: self,
            action: #selector(showRetentionTerms)
        )
        termsButton.bezelStyle = .rounded
        stack.addArrangedSubview(termsButton)
    }

    @objc private func showRetentionTerms() {
        let alert = NSAlert()
        alert.messageText = localized(
            "廣告與作者資訊保留條款",
            "Advertising and Author Information Retention Terms"
        )
        alert.informativeText = retentionTermsText
        alert.addButton(withTitle: localized("確定", "OK"))
        alert.runModal()
    }
}

private final class PetWindow: NSPanel {
    private let containerView = DragSurfaceView()
    let imageView = NSImageView()
    private let speechLabel = NSTextField(labelWithString: localized("爸", "Dad"))
    private var hideSpeechTask: DispatchWorkItem?

    init(frame: NSRect) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        hidesOnDeactivate = false
        canHide = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        ignoresMouseEvents = true
        isMovable = false
        isMovableByWindowBackground = false
        containerView.frame = NSRect(origin: .zero, size: frame.size)
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.clear.cgColor
        contentView = containerView

        imageView.frame = NSRect(origin: .zero, size: characterSize)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = false
        imageView.wantsLayer = true
        containerView.addSubview(imageView)

        speechLabel.frame = NSRect(x: 54, y: 137, width: 48, height: 30)
        speechLabel.alignment = .center
        speechLabel.font = .boldSystemFont(ofSize: 18)
        speechLabel.textColor = .labelColor
        speechLabel.backgroundColor = .white
        speechLabel.drawsBackground = true
        speechLabel.isBezeled = false
        speechLabel.isEditable = false
        speechLabel.isSelectable = false
        speechLabel.wantsLayer = true
        speechLabel.layer?.cornerRadius = 12
        speechLabel.layer?.borderWidth = 1
        speechLabel.layer?.borderColor = NSColor.black.withAlphaComponent(0.15).cgColor
        speechLabel.isHidden = true
        containerView.addSubview(speechLabel)
        orderFrontRegardless()
    }

    var onDragChanged: ((Bool) -> Void)? {
        get { containerView.onDragChanged }
        set { containerView.onDragChanged = newValue }
    }

    func sayDad() {
        hideSpeechTask?.cancel()
        speechLabel.isHidden = false
        speechLabel.stringValue = localized("爸", "Dad")
        orderFrontRegardless()

        let task = DispatchWorkItem { [weak self] in
            self?.speechLabel.isHidden = true
        }
        hideSpeechTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: task)
    }

    func prepareDadLanding() {
        hideSpeechTask?.cancel()
        speechLabel.isHidden = true
    }
}

private final class Pet {
    let window: PetWindow
    var velocity: CGVector
    var pose: Pose = .crawlA
    var age = Double.random(in: 0...20)
    var poseClock = 0.0
    var isBeingDragged = false
    weak var targetFood: Food?
    var eatingTimeRemaining = 0.0
    var eatingAnchor: CGPoint?
    var eatingDirection = CGVector(dx: 1, dy: 0)
    var facingLeft = false

    init(at point: CGPoint, velocity: CGVector) {
        self.velocity = velocity
        window = PetWindow(frame: NSRect(origin: point, size: petWindowSize))
        facingLeft = velocity.dx < 0
    }
}

private final class DesktopPetController: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var pets: [Pet] = []
    private var frames: [NSImage] = []
    private var mirroredFrames: [NSImage] = []
    private var obstacles: [CGRect] = []
    private var obstacleClock = 0.0
    private var paused = false
    private var ignoreClicks = true
    private var isDadLanding = false
    private var dadSpeakingTimeRemaining = 0.0
    private var foods: [Food] = []
    private var placementWindows: [PlacementWindow] = []
    private var explosionWindows: [ExplosionWindow] = []
    private var aboutWindow: AboutWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        frames = loadFrames()
        guard frames.count == Pose.allCases.count else {
            showFatalError(localized(
                "無法載入人物動畫素材 person-sprites.png",
                "Unable to load the character sprite asset person-sprites.png."
            ))
            return
        }
        mirroredFrames = frames.compactMap { mirroredImage($0) }
        guard mirroredFrames.count == Pose.allCases.count else {
            showFatalError(localized(
                "無法建立人物鏡像動畫素材",
                "Unable to create mirrored character sprites."
            ))
            return
        }
        configureMenu()
        addPet()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick(deltaTime: 1.0 / 60.0)
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func configureMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🐒"
        statusItem.button?.toolTip = localized("桌面猴群", "MonkeyDeskPets")
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        let count = NSMenuItem(
            title: localized("目前人物：\(pets.count)", "Characters: \(pets.count)"),
            action: nil,
            keyEquivalent: ""
        )
        count.isEnabled = false
        menu.addItem(count)
        let version = NSMenuItem(
            title: localized("版本：\(appVersion)", "Version: \(appVersion)"),
            action: nil,
            keyEquivalent: ""
        )
        version.isEnabled = false
        menu.addItem(version)
        menu.addItem(.separator())
        menu.addItem(
            withTitle: localized("增加一人", "Add Character"),
            action: #selector(addPetFromMenu),
            keyEquivalent: "+"
        )
        menu.addItem(
            withTitle: localized("減少一人", "Remove Character"),
            action: #selector(removePet),
            keyEquivalent: "-"
        )
        menu.addItem(
            withTitle: localized("只保留一人", "Keep Only One"),
            action: #selector(keepOnlyOnePet),
            keyEquivalent: "1"
        )
        menu.addItem(
            withTitle: localized("餵食", "Feed"),
            action: #selector(beginFoodPlacement),
            keyEquivalent: "f"
        )
        menu.addItem(
            withTitle: localized("爸", "Dad"),
            action: #selector(sayDad),
            keyEquivalent: "d"
        )
        menu.addItem(
            withTitle: localized("上傳精靈圖", "Upload Sprite Sheet"),
            action: #selector(uploadSpriteSheet),
            keyEquivalent: "u"
        )
        menu.addItem(
            withTitle: localized("懶人模式（上傳臉部）", "Easy Mode (Upload Face)"),
            action: #selector(uploadFaceForLazyMode),
            keyEquivalent: "l"
        )
        menu.addItem(
            withTitle: localized("恢復預設精靈圖", "Restore Default Sprites"),
            action: #selector(restoreDefaultSprites),
            keyEquivalent: "r"
        )
        menu.addItem(
            withTitle: localized("開啟精靈圖目錄", "Open Sprite Folder"),
            action: #selector(openSpriteDirectory),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: paused
                ? localized("繼續玩耍", "Resume")
                : localized("暫停", "Pause"),
            action: #selector(togglePause),
            keyEquivalent: "p"
        )
        let clickItem = NSMenuItem(
            title: ignoreClicks
                ? localized("允許拖曳人物", "Enable Character Dragging")
                : localized("忽略滑鼠（推薦）", "Ignore Mouse (Recommended)"),
            action: #selector(toggleMouse),
            keyEquivalent: "i"
        )
        menu.addItem(clickItem)
        menu.addItem(.separator())
        menu.addItem(
            withTitle: localized("關於 MonkeyDeskPets", "About MonkeyDeskPets"),
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: localized("結束桌面猴群", "Quit MonkeyDeskPets"),
            action: #selector(quit),
            keyEquivalent: "q"
        )
        for item in menu.items { item.target = self }
        statusItem.menu = menu
    }

    @objc private func addPetFromMenu() { addPet() }

    @objc private func showAbout() {
        if aboutWindow == nil {
            aboutWindow = AboutWindow(version: appVersion)
        }
        NSApp.activate(ignoringOtherApps: true)
        aboutWindow?.center()
        aboutWindow?.makeKeyAndOrderFront(nil)
    }

    private func addPet() {
        guard !frames.isEmpty, let screen = NSScreen.main else { return }
        let area = screen.visibleFrame
        let origin = CGPoint(
            x: Double.random(in: area.minX...(area.maxX - petWindowSize.width)),
            y: Double.random(in: area.minY...(area.maxY - petWindowSize.height))
        )
        let direction = Bool.random() ? 1.0 : -1.0
        let pet = Pet(
            at: origin,
            velocity: CGVector(dx: direction * Double.random(in: 75...135), dy: Double.random(in: -15...25))
        )
        pet.window.ignoresMouseEvents = ignoreClicks
        pet.window.onDragChanged = { [weak self, weak pet] isDragging in
            guard let self, let pet else { return }
            pet.isBeingDragged = isDragging
            pet.velocity = .zero
            pet.poseClock = 0
            if isDragging {
                pet.pose = dragPose
                pet.window.prepareDadLanding()
                self.setPoseImage(pet, pose: dragPose)
            } else {
                pet.velocity = .zero
                pet.pose = .crouch
            }
        }
        setPoseImage(pet, pose: .crawlA)
        pets.append(pet)
        assignAvailableFood()
        rebuildMenu()
    }

    @objc private func removePet() {
        guard let pet = pets.popLast() else { return }
        explodeAndRemove(pet)
        assignAvailableFood()
        rebuildMenu()
    }

    @objc private func keepOnlyOnePet() {
        guard pets.count > 1 else { return }
        let removedPets = Array(pets.dropFirst())
        pets = [pets[0]]
        removedPets.forEach(explodeAndRemove)
        assignAvailableFood()
        rebuildMenu()
    }

    private func explodeAndRemove(_ pet: Pet) {
        if let food = pet.targetFood {
            food.claimedBy = nil
            pet.targetFood = nil
        }
        let center = CGPoint(x: pet.window.frame.midX, y: pet.window.frame.midY)
        pet.window.close()

        let explosion = ExplosionWindow(center: center)
        explosion.alphaValue = 1
        explosionWindows.append(explosion)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.65
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            explosion.animator().alphaValue = 0
        } completionHandler: { [weak self, weak explosion] in
            guard let self, let explosion else { return }
            explosion.close()
            self.explosionWindows.removeAll { $0 === explosion }
        }
    }

    @objc private func sayDad() {
        guard !pets.isEmpty else { return }
        isDadLanding = true
        dadSpeakingTimeRemaining = 0
        pets.forEach { pet in
            if pet.isBeingDragged {
                pet.velocity = .zero
                pet.pose = dragPose
                pet.window.prepareDadLanding()
                setPoseImage(pet, pose: dragPose)
                return
            }
            pet.pose = .crouch
            pet.poseClock = 0
            pet.velocity = CGVector(dx: 0, dy: -720)
            pet.window.prepareDadLanding()
            setPoseImage(pet, pose: .crouch)
        }
    }

    @objc private func beginFoodPlacement() {
        cancelFoodPlacement()
        placementWindows = NSScreen.screens.map { screen in
            PlacementWindow(screen: screen) { [weak self] point in
                self?.placeFood(at: point)
            }
        }
    }

    @objc private func uploadSpriteSheet() {
        let panel = NSOpenPanel()
        panel.title = localized("選擇 4×2 精靈圖", "Choose a 4×2 Sprite Sheet")
        panel.message = localized(
            "圖片將依照由左到右、由上到下拆分為編號 0～7。",
            "The image will be split into frames 0–7 from left to right, top to bottom."
        )
        panel.prompt = localized("上傳並套用", "Upload and Apply")
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        NSApp.activate(ignoringOtherApps: true)
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.importAndActivateSpriteSheet(from: url)
        }
    }

    @objc private func uploadFaceForLazyMode() {
        let panel = NSOpenPanel()
        panel.title = localized("懶人模式：選擇臉部照片", "Easy Mode: Choose a Face Photo")
        panel.message = localized(
            "程式會在本機偵測最大臉部，套入內建角色並生成新的 4×2 精靈圖。",
            "The app detects the largest face locally, applies it to the built-in character, and generates a new 4×2 sprite sheet."
        )
        panel.prompt = localized("生成並套用", "Generate and Apply")
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        NSApp.activate(ignoringOtherApps: true)
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.generateSpritesFromFace(at: url)
        }
    }

    @objc private func openSpriteDirectory() {
        do {
            let directory = try spriteStorageRoot()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            NSWorkspace.shared.open(directory)
        } catch {
            showMessage(
                title: localized("無法開啟精靈圖目錄", "Unable to Open Sprite Folder"),
                message: error.localizedDescription
            )
        }
    }

    @objc private func restoreDefaultSprites() {
        let confirmation = NSAlert()
        confirmation.messageText = localized("恢復預設精靈圖？", "Restore Default Sprites?")
        confirmation.informativeText = localized(
            "目前的自訂精靈圖與懶人模式生成素材將被刪除。",
            "The current custom sprites and Easy Mode generated assets will be deleted."
        )
        confirmation.alertStyle = .warning
        confirmation.addButton(withTitle: localized("恢復預設", "Restore Defaults"))
        confirmation.addButton(withTitle: localized("取消", "Cancel"))
        guard confirmation.runModal() == .alertFirstButtonReturn else { return }

        do {
            guard let url = Bundle.module.url(
                forResource: "person-sprites",
                withExtension: "png"
            ), let source = CGImageSourceCreateWithURL(url as CFURL, nil),
               let sheet = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw spriteError(localized(
                    "找不到程式內建的預設精靈圖。",
                    "The built-in default sprite sheet could not be found."
                ))
            }
            let defaultFrames = splitSpriteSheet(sheet).map {
                NSImage(cgImage: $0, size: characterSize)
            }
            let defaultMirroredFrames = defaultFrames.compactMap { mirroredImage($0) }
            guard defaultFrames.count == Pose.allCases.count,
                  defaultMirroredFrames.count == Pose.allCases.count else {
                throw spriteError(localized(
                    "內建預設精靈圖不完整。",
                    "The built-in default sprite sheet is incomplete."
                ))
            }

            let root = try spriteStorageRoot()
            let current = root.appendingPathComponent("Current", isDirectory: true)
            if FileManager.default.fileExists(atPath: current.path) {
                try FileManager.default.removeItem(at: current)
            }
            removeObsoleteSpriteDirectories(in: root, keeping: nil)

            frames = defaultFrames
            mirroredFrames = defaultMirroredFrames
            pets.forEach { setPoseImage($0, pose: $0.pose) }
            showMessage(
                title: localized("已恢復預設", "Defaults Restored"),
                message: localized(
                    "所有角色已切換回內建預設精靈圖。",
                    "All characters now use the built-in default sprites."
                )
            )
        } catch {
            showMessage(
                title: localized("恢復預設失敗", "Failed to Restore Defaults"),
                message: error.localizedDescription
            )
        }
    }

    private func importAndActivateSpriteSheet(from sourceURL: URL) {
        do {
            guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
                  let sheet = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw spriteError(localized(
                    "無法讀取選擇的圖片。",
                    "The selected image could not be read."
                ))
            }

            let greenScreenResult = removeGreenScreenIfNeeded(from: sheet)
            let processedSheet = greenScreenResult.image
            let croppedImages = splitSpriteSheet(processedSheet)
            guard croppedImages.count == Pose.allCases.count else {
                throw spriteError(localized(
                    "圖片無法拆分為完整的 4×2、共 8 張精靈圖。",
                    "The image could not be split into a complete 4×2 set of eight sprites."
                ))
            }

            let root = try spriteStorageRoot()
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            let stagingDirectory = root.appendingPathComponent(
                ".incoming-\(UUID().uuidString)",
                isDirectory: true
            )
            try FileManager.default.createDirectory(
                at: stagingDirectory,
                withIntermediateDirectories: true
            )

            do {
                try writePNG(sheet, to: stagingDirectory.appendingPathComponent("original.png"))
                if greenScreenResult.didRemoveBackground {
                    try writePNG(
                        processedSheet,
                        to: stagingDirectory.appendingPathComponent("processed-transparent.png")
                    )
                }
                for (index, image) in croppedImages.enumerated() {
                    try writePNG(
                        image,
                        to: stagingDirectory.appendingPathComponent("frame-\(index).png")
                    )
                }
                guard loadFrames(from: stagingDirectory)?.count == Pose.allCases.count else {
                    throw spriteError(localized(
                        "保存後驗證失敗，舊素材未被修改。",
                        "Validation after saving failed. The previous assets were not changed."
                    ))
                }
            } catch {
                try? FileManager.default.removeItem(at: stagingDirectory)
                throw error
            }

            let importedFrames = croppedImages.map {
                NSImage(cgImage: $0, size: characterSize)
            }
            let importedMirroredFrames = importedFrames.compactMap { mirroredImage($0) }
            guard importedMirroredFrames.count == Pose.allCases.count else {
                try? FileManager.default.removeItem(at: stagingDirectory)
                throw spriteError(localized(
                    "已拆分圖片，但建立鏡像精靈圖時失敗。",
                    "The image was split, but mirrored sprites could not be created."
                ))
            }

            let currentDirectory = try replaceCurrentSprites(
                with: stagingDirectory,
                in: root
            )
            frames = importedFrames
            mirroredFrames = importedMirroredFrames
            pets.forEach { setPoseImage($0, pose: $0.pose) }
            showMessage(
                title: localized("精靈圖已套用", "Sprite Sheet Applied"),
                message: greenScreenResult.didRemoveBackground
                    ? localized(
                        "已偵測綠幕、自動透明化並保存 frame-0.png～frame-7.png：\n\(currentDirectory.path)",
                        "A green screen was detected and made transparent. Frames 0–7 were saved to:\n\(currentDirectory.path)"
                    )
                    : localized(
                        "未偵測到綠幕；已直接保存 frame-0.png～frame-7.png：\n\(currentDirectory.path)",
                        "No green screen was detected. Frames 0–7 were saved directly to:\n\(currentDirectory.path)"
                    )
            )
        } catch {
            showMessage(
                title: localized("精靈圖上傳失敗", "Sprite Upload Failed"),
                message: error.localizedDescription
            )
        }
    }

    private func generateSpritesFromFace(at faceURL: URL) {
        do {
            guard let faceImage = NSImage(contentsOf: faceURL),
                  let faceCGImage = faceImage.cgImage(
                    forProposedRect: nil,
                    context: nil,
                    hints: nil
                  ) else {
                throw spriteError(localized(
                    "無法讀取臉部圖片。",
                    "The face image could not be read."
                ))
            }
            guard let faceRect = detectLargestFace(in: faceCGImage) else {
                throw spriteError(localized(
                    "照片中找不到清楚的正面臉部，請改用光線充足、臉部完整的照片。",
                    "No clear frontal face was found. Use a well-lit photo showing the complete face."
                ))
            }
            guard let templateURL = Bundle.module.url(
                forResource: "person-sprites",
                withExtension: "png"
            ), let templateSource = CGImageSourceCreateWithURL(templateURL as CFURL, nil),
               let template = CGImageSourceCreateImageAtIndex(templateSource, 0, nil) else {
                throw spriteError(localized(
                    "找不到程式內建的預設精靈圖。",
                    "The built-in default sprite sheet could not be found."
                ))
            }
            guard let generatedSheet = composeFace(
                faceCGImage,
                faceRect: faceRect,
                onto: template
            ) else {
                throw spriteError(localized(
                    "臉部合成失敗，原本素材未被修改。",
                    "Face compositing failed. The previous assets were not changed."
                ))
            }

            let croppedImages = splitSpriteSheet(generatedSheet)
            guard croppedImages.count == Pose.allCases.count else {
                throw spriteError(localized(
                    "生成的 4×2 精靈圖無法完整拆成 8 張。",
                    "The generated 4×2 sprite sheet could not be split into eight complete frames."
                ))
            }

            let importedFrames = croppedImages.map {
                NSImage(cgImage: $0, size: characterSize)
            }
            let importedMirroredFrames = importedFrames.compactMap { mirroredImage($0) }
            guard importedMirroredFrames.count == Pose.allCases.count else {
                throw spriteError(localized(
                    "建立鏡像精靈圖失敗。",
                    "Failed to create mirrored sprites."
                ))
            }

            let root = try spriteStorageRoot()
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            let staging = root.appendingPathComponent(
                ".incoming-\(UUID().uuidString)",
                isDirectory: true
            )
            try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)

            do {
                try writePNG(
                    faceCGImage,
                    to: staging.appendingPathComponent("source-face.png")
                )
                try writePNG(
                    generatedSheet,
                    to: staging.appendingPathComponent("original.png")
                )
                try writePNG(
                    generatedSheet,
                    to: staging.appendingPathComponent("generated-4x2.png")
                )
                for (index, image) in croppedImages.enumerated() {
                    try writePNG(
                        image,
                        to: staging.appendingPathComponent("frame-\(index).png")
                    )
                }
                guard loadFrames(from: staging)?.count == Pose.allCases.count else {
                    throw spriteError(localized(
                        "保存後驗證失敗，原本素材未被修改。",
                        "Validation after saving failed. The previous assets were not changed."
                    ))
                }
            } catch {
                try? FileManager.default.removeItem(at: staging)
                throw error
            }

            let current = try replaceCurrentSprites(with: staging, in: root)
            frames = importedFrames
            mirroredFrames = importedMirroredFrames
            pets.forEach { setPoseImage($0, pose: $0.pose) }
            showMessage(
                title: localized("懶人模式已完成", "Easy Mode Complete"),
                message: localized(
                    "已在本機生成 4×2 精靈圖並立即套用：\n\(current.path)",
                    "A 4×2 sprite sheet was generated locally and applied immediately:\n\(current.path)"
                )
            )
        } catch {
            showMessage(
                title: localized("懶人模式失敗", "Easy Mode Failed"),
                message: error.localizedDescription
            )
        }
    }

    private func detectLargestFace(in image: CGImage) -> CGRect? {
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        guard let observation = request.results?.max(by: {
            $0.boundingBox.width * $0.boundingBox.height
                < $1.boundingBox.width * $1.boundingBox.height
        }) else { return nil }

        let normalized = observation.boundingBox
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        var rect = CGRect(
            x: normalized.minX * width,
            y: (1 - normalized.maxY) * height,
            width: normalized.width * width,
            height: normalized.height * height
        )
        rect = rect.insetBy(dx: -rect.width * 0.10, dy: -rect.height * 0.08)
        return rect.intersection(CGRect(x: 0, y: 0, width: width, height: height))
    }

    private func composeFace(
        _ faceImage: CGImage,
        faceRect: CGRect,
        onto template: CGImage
    ) -> CGImage? {
        guard let croppedFace = faceImage.cropping(to: faceRect) else { return nil }
        let width = template.width
        let height = template.height
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue
                | CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(
            template,
            in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        )

        let targetFaces: [(CGRect, CGFloat)] = [
            (CGRect(x: 0.171, y: 0.086, width: 0.047, height: 0.103), 0),
            (CGRect(x: 0.387, y: 0.089, width: 0.047, height: 0.103), 0),
            (CGRect(x: 0.575, y: 0.032, width: 0.046, height: 0.102), -0.20),
            (CGRect(x: 0.834, y: 0.108, width: 0.046, height: 0.103), 0),
            (CGRect(x: 0.101, y: 0.543, width: 0.049, height: 0.107), 0),
            (CGRect(x: 0.374, y: 0.520, width: 0.048, height: 0.104), -0.12),
            (CGRect(x: 0.594, y: 0.531, width: 0.050, height: 0.108), 0.12),
            (CGRect(x: 0.911, y: 0.699, width: 0.051, height: 0.108), -1.42)
        ]

        for (normalizedRect, angle) in targetFaces {
            let target = CGRect(
                x: normalizedRect.minX * CGFloat(width),
                y: (1 - normalizedRect.maxY) * CGFloat(height),
                width: normalizedRect.width * CGFloat(width),
                height: normalizedRect.height * CGFloat(height)
            )
            context.saveGState()
            context.translateBy(x: target.midX, y: target.midY)
            context.rotate(by: angle)
            let localRect = CGRect(
                x: -target.width / 2,
                y: -target.height / 2,
                width: target.width,
                height: target.height
            )
            context.addEllipse(in: localRect.insetBy(dx: -2.5, dy: -2.5))
            context.clip()
            context.interpolationQuality = .high
            context.draw(croppedFace, in: localRect)
            context.restoreGState()
        }
        return context.makeImage()
    }

    private func cancelFoodPlacement() {
        placementWindows.forEach { $0.close() }
        placementWindows.removeAll()
    }

    private func placeFood(at point: CGPoint) {
        cancelFoodPlacement()
        foods.append(Food(at: point))
        assignAvailableFood()
    }

    private func assignAvailableFood() {
        for food in foods where food.claimedBy == nil {
            guard let nearestPet = pets
                .filter({ $0.targetFood == nil })
                .min(by: {
                    squaredDistance(from: petCenter($0), to: food.center) <
                    squaredDistance(from: petCenter($1), to: food.center)
                }) else { continue }
            food.claimedBy = nearestPet
            nearestPet.targetFood = food
            nearestPet.eatingTimeRemaining = 0
            nearestPet.eatingAnchor = nil
        }
    }

    @objc private func togglePause() {
        paused.toggle()
        rebuildMenu()
    }

    @objc private func toggleMouse() {
        ignoreClicks.toggle()
        pets.forEach { $0.window.ignoresMouseEvents = ignoreClicks }
        rebuildMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func tick(deltaTime dt: Double) {
        recoverPetWindows()

        if isDadLanding {
            updateDadLanding(deltaTime: dt)
            return
        }

        if dadSpeakingTimeRemaining > 0 {
            dadSpeakingTimeRemaining = max(0, dadSpeakingTimeRemaining - dt)
            pets.forEach { pet in
                guard !pet.isBeingDragged else {
                    pet.velocity = .zero
                    pet.pose = dragPose
                    setPoseImage(pet, pose: dragPose)
                    return
                }
                pet.pose = .crouch
                pet.velocity = .zero
                setPoseImage(pet, pose: .crouch)
            }
            return
        }

        guard !paused else { return }

        obstacleClock += dt
        if obstacleClock >= 0.35 {
            obstacleClock = 0
            obstacles = currentWindowObstacles()
        }

        for pet in pets {
            if pet.isBeingDragged {
                pet.window.orderFrontRegardless()
                continue
            }
            if updateFeeding(pet, deltaTime: dt) {
                ensurePetIsVisible(pet)
                continue
            }
            pet.age += dt
            pet.poseClock += dt
            updateBehavior(pet, dt: dt)
            resolveScreenEdges(pet)
            resolveWindowCollisions(pet)
            ensurePetIsVisible(pet)
            pet.window.setFrameOrigin(pet.window.frame.origin)
            updatePose(pet)
        }
    }

    private func recoverPetWindows() {
        for pet in pets {
            let window = pet.window

            if window.alphaValue != 1 {
                window.alphaValue = 1
            }
            if window.imageView.image == nil, !frames.isEmpty {
                pet.pose = .crawlA
                setPoseImage(pet, pose: .crawlA)
            }
            if !pet.isBeingDragged {
                ensurePetIsVisible(pet)
            }
            if !window.isVisible || !window.occlusionState.contains(.visible) {
                window.orderFrontRegardless()
            }
        }
    }

    private func updateFeeding(_ pet: Pet, deltaTime dt: Double) -> Bool {
        guard let food = pet.targetFood else { return false }

        if pet.eatingTimeRemaining > 0 {
            let eatingDuration = 2.4
            let elapsed = eatingDuration - pet.eatingTimeRemaining
            pet.eatingTimeRemaining = max(0, pet.eatingTimeRemaining - dt)
            pet.velocity = .zero
            pet.pose = .crawlB
            pet.facingLeft = pet.eatingDirection.dx < 0
            setPoseImage(pet, pose: .crawlB)

            if let anchor = pet.eatingAnchor {
                let forwardBackwardOffset = CGFloat(sin(elapsed * .pi * 4)) * 7
                var frame = pet.window.frame
                frame.origin.x = anchor.x + pet.eatingDirection.dx * forwardBackwardOffset
                frame.origin.y = anchor.y + pet.eatingDirection.dy * forwardBackwardOffset
                pet.window.setFrame(frame, display: false)
            }

            if pet.eatingTimeRemaining == 0 {
                if let anchor = pet.eatingAnchor {
                    pet.window.setFrameOrigin(anchor)
                }
                food.window.close()
                foods.removeAll { $0 === food }
                pet.targetFood = nil
                pet.eatingAnchor = nil
                pet.poseClock = 0
                assignAvailableFood()
            }
            return true
        }

        let petPosition = petCenter(pet)
        let deltaX = food.center.x - petPosition.x
        let deltaY = food.center.y - petPosition.y
        let distance = (deltaX * deltaX + deltaY * deltaY).squareRoot()

        if distance <= 86 {
            pet.eatingTimeRemaining = 2.4
            pet.eatingAnchor = pet.window.frame.origin
            if distance > 0 {
                pet.eatingDirection = CGVector(dx: deltaX / distance, dy: deltaY / distance)
            } else {
                pet.eatingDirection = CGVector(dx: pet.velocity.dx < 0 ? -1 : 1, dy: 0)
            }
            pet.velocity = .zero
            pet.pose = .crawlB
            pet.facingLeft = pet.eatingDirection.dx < 0
            setPoseImage(pet, pose: .crawlB)
            return true
        }

        let speed: CGFloat = 165
        let step = min(speed * dt, distance)
        let movementX = deltaX / distance * step
        let movementY = deltaY / distance * step
        var frame = pet.window.frame
        frame.origin.x += movementX
        frame.origin.y += movementY
        pet.window.setFrame(frame, display: false)
        pet.velocity = CGVector(dx: movementX / dt, dy: movementY / dt)
        pet.age += dt
        pet.pose = Int(pet.age * 7) % 2 == 0 ? .crawlA : .crawlB
        setPoseImage(pet, pose: pet.pose)
        return true
    }

    private func updateDadLanding(deltaTime dt: Double) {
        var allPetsReachedBottom = true

        for pet in pets {
            if pet.isBeingDragged {
                allPetsReachedBottom = false
                continue
            }
            guard let screen = screenContaining(pet.window.frame) ?? NSScreen.main else { continue }
            var frame = pet.window.frame
            let bottom = screen.visibleFrame.minY

            if frame.minY > bottom {
                allPetsReachedBottom = false
                frame.origin.y = max(bottom, frame.origin.y - 720 * dt)
                pet.window.setFrame(frame, display: false)
            }

            pet.pose = .crouch
            pet.velocity = .zero
            setPoseImage(pet, pose: .crouch)
            pet.window.setFrameOrigin(pet.window.frame.origin)
        }

        guard allPetsReachedBottom else { return }

        isDadLanding = false
        dadSpeakingTimeRemaining = 2.0
        pets.forEach { pet in
            pet.pose = .crouch
            pet.poseClock = 0
            pet.window.sayDad()
        }
    }

    private func updateBehavior(_ pet: Pet, dt: Double) {
        var frame = pet.window.frame
        pet.velocity.dy -= 28 * dt

        if Int(pet.age) % 11 == 0 && pet.poseClock > 1.4 {
            pet.velocity.dy = Double.random(in: 115...185)
            pet.velocity.dx *= Double.random(in: 0.85...1.18)
            pet.pose = .leap
            pet.poseClock = 0
        }

        if Int(pet.age) % 17 >= 14 {
            pet.velocity.dx *= 0.975
            pet.pose = Int(pet.age) % 17 == 16 ? .sleep : .sit
        } else {
            if pet.pose == .sit || pet.pose == .sleep {
                pet.pose = .crawlA
                pet.poseClock = 0
            }
            if abs(pet.velocity.dx) < 45 {
                pet.velocity.dx = (Bool.random() ? 1 : -1) * Double.random(in: 70...120)
            }
        }

        frame.origin.x += pet.velocity.dx * dt
        frame.origin.y += pet.velocity.dy * dt
        pet.window.setFrame(frame, display: false)
    }

    private func resolveScreenEdges(_ pet: Pet) {
        guard let screen = screenContaining(pet.window.frame) ?? NSScreen.main else { return }
        let bounds = screen.visibleFrame
        var frame = pet.window.frame

        if frame.minX <= bounds.minX {
            frame.origin.x = bounds.minX
            pet.velocity.dx = abs(pet.velocity.dx)
            pet.pose = .climb
            pet.poseClock = 0
        } else if frame.maxX >= bounds.maxX {
            frame.origin.x = bounds.maxX - frame.width
            pet.velocity.dx = -abs(pet.velocity.dx)
            pet.pose = .climb
            pet.poseClock = 0
        }
        if frame.minY <= bounds.minY {
            frame.origin.y = bounds.minY
            pet.velocity.dy = abs(pet.velocity.dy) * 0.45
        } else if frame.maxY >= bounds.maxY {
            frame.origin.y = bounds.maxY - frame.height
            pet.velocity.dy = -abs(pet.velocity.dy) * 0.55
            pet.pose = .hang
            pet.poseClock = 0
        }
        pet.window.setFrame(frame, display: false)
    }

    private func resolveWindowCollisions(_ pet: Pet) {
        var frame = pet.window.frame
        let feet = CGRect(x: frame.minX + 28, y: frame.minY, width: frame.width - 56, height: 25)
        for obstacle in obstacles where feet.intersects(obstacle) {
            let overlap = obstacle.maxY - frame.minY
            guard overlap > 0, overlap < 40, pet.velocity.dy <= 0 else { continue }
            frame.origin.y = obstacle.maxY
            pet.velocity.dy = Double.random(in: 5...24)
            pet.velocity.dx *= Bool.random() ? 1 : -1
            pet.pose = .crouch
            pet.poseClock = 0
            pet.window.setFrame(frame, display: false)
            break
        }
    }

    private func updatePose(_ pet: Pet) {
        let next: Pose
        switch pet.pose {
        case .crawlA, .crawlB:
            next = Int(pet.age * 7) % 2 == 0 ? .crawlA : .crawlB
        case .sit, .sleep:
            next = pet.pose
        case .climb, .hang, .crouch, .leap:
            next = pet.pose
            if pet.poseClock > 0.65 {
                pet.pose = .crawlA
                pet.poseClock = 0
            }
        }
        setPoseImage(pet, pose: next)
    }

    private func currentWindowObstacles() -> [CGRect] {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]],
              let primaryHeight = NSScreen.screens.first?.frame.height else { return [] }

        return list.compactMap { info in
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? Int,
                  ownerPID != Int(ProcessInfo.processInfo.processIdentifier),
                  let layer = info[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let dict = info[kCGWindowBounds as String] as? [String: Any],
                  let windowRect = CGRect(dictionaryRepresentation: dict as CFDictionary),
                  windowRect.width > 120, windowRect.height > 80 else { return nil }
            return CGRect(
                x: windowRect.minX,
                y: primaryHeight - windowRect.minY - windowRect.height,
                width: windowRect.width,
                height: windowRect.height
            )
        }
    }

    private func screenContaining(_ frame: NSRect) -> NSScreen? {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return nil }

        if let intersecting = screens.max(by: {
            $0.visibleFrame.intersection(frame).area < $1.visibleFrame.intersection(frame).area
        }), intersecting.visibleFrame.intersection(frame).area > 0 {
            return intersecting
        }

        let center = CGPoint(x: frame.midX, y: frame.midY)
        return screens.min {
            squaredDistance(from: center, to: $0.visibleFrame) <
            squaredDistance(from: center, to: $1.visibleFrame)
        }
    }

    private func ensurePetIsVisible(_ pet: Pet) {
        var frame = pet.window.frame

        guard frame.origin.x.isFinite, frame.origin.y.isFinite,
              frame.width.isFinite, frame.height.isFinite,
              frame.width > 0, frame.height > 0 else {
            guard let screen = NSScreen.main else { return }
            frame = NSRect(
                x: screen.visibleFrame.midX - petWindowSize.width / 2,
                y: screen.visibleFrame.minY,
                width: petWindowSize.width,
                height: petWindowSize.height
            )
            pet.velocity = .zero
            pet.window.setFrame(frame, display: false)
            return
        }

        guard let screen = screenContaining(frame) ?? NSScreen.main else { return }
        let bounds = screen.visibleFrame
        frame.origin.x = min(max(frame.origin.x, bounds.minX), bounds.maxX - frame.width)
        frame.origin.y = min(max(frame.origin.y, bounds.minY), bounds.maxY - frame.height)
        pet.window.setFrame(frame, display: false)
    }

    private func squaredDistance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(max(rect.minX - point.x, 0), point.x - rect.maxX)
        let dy = max(max(rect.minY - point.y, 0), point.y - rect.maxY)
        return dx * dx + dy * dy
    }

    private func squaredDistance(from lhs: CGPoint, to rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return dx * dx + dy * dy
    }

    private func petCenter(_ pet: Pet) -> CGPoint {
        CGPoint(x: pet.window.frame.midX, y: pet.window.frame.midY)
    }

    private func loadFrames() -> [NSImage] {
        if let customFrames = loadLatestCustomFrames() {
            return customFrames
        }

        let url = Bundle.module.url(forResource: "person-sprites", withExtension: "png")
        guard let url, let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let sheet = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return [] }
        return splitSpriteSheet(sheet).map { NSImage(cgImage: $0, size: characterSize) }
    }

    private func splitSpriteSheet(_ sheet: CGImage) -> [CGImage] {
        guard sheet.width >= 4, sheet.height >= 2 else { return [] }
        return (0..<8).compactMap { index in
            let column = index % 4
            let row = index / 4
            let x0 = column * sheet.width / 4
            let x1 = (column + 1) * sheet.width / 4
            let y0 = row * sheet.height / 2
            let y1 = (row + 1) * sheet.height / 2
            let rect = CGRect(
                x: CGFloat(x0),
                y: CGFloat(y0),
                width: CGFloat(x1 - x0),
                height: CGFloat(y1 - y0)
            )
            return sheet.cropping(to: rect)
        }
    }

    private func removeGreenScreenIfNeeded(
        from source: CGImage
    ) -> (image: CGImage, didRemoveBackground: Bool) {
        let width = source.width
        let height = source.height
        guard width > 0, height > 0 else { return (source, false) }

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue
            | CGImageAlphaInfo.premultipliedLast.rawValue
        var renderedImage: CGImage?

        pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo
            ) else { return }
            context.draw(
                source,
                in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
            )
            renderedImage = context.makeImage()
        }
        guard renderedImage != nil else { return (source, false) }

        func unpremultipliedColor(at pixelIndex: Int) -> (Double, Double, Double, Double) {
            let offset = pixelIndex * 4
            let alpha = Double(pixels[offset + 3])
            guard alpha > 0 else { return (0, 0, 0, 0) }
            let scale = 255.0 / alpha
            return (
                min(255, Double(pixels[offset]) * scale),
                min(255, Double(pixels[offset + 1]) * scale),
                min(255, Double(pixels[offset + 2]) * scale),
                alpha
            )
        }

        func isStrongGreen(_ color: (Double, Double, Double, Double)) -> Bool {
            let (red, green, blue, alpha) = color
            let competingColor = max(red, blue)
            return alpha >= 32
                && green >= 90
                && green - competingColor >= 35
                && green >= competingColor * 1.28
        }

        let sampleStep = max(1, min(width, height) / 180)
        var borderSamples = 0
        var greenBorderSamples = 0

        for x in stride(from: 0, to: width, by: sampleStep) {
            for y in [0, max(0, height - 1)] {
                borderSamples += 1
                if isStrongGreen(unpremultipliedColor(at: y * width + x)) {
                    greenBorderSamples += 1
                }
            }
        }
        for y in stride(from: 0, to: height, by: sampleStep) {
            for x in [0, max(0, width - 1)] {
                borderSamples += 1
                if isStrongGreen(unpremultipliedColor(at: y * width + x)) {
                    greenBorderSamples += 1
                }
            }
        }

        guard borderSamples > 0,
              Double(greenBorderSamples) / Double(borderSamples) >= 0.60 else {
            return (source, false)
        }

        for pixelIndex in 0..<(width * height) {
            let offset = pixelIndex * 4
            let (red, green, blue, originalAlpha) = unpremultipliedColor(at: pixelIndex)
            guard originalAlpha > 0, green >= 70 else { continue }

            let greenExcess = green - max(red, blue)
            guard greenExcess > 22 else { continue }

            let opacityFactor = max(0, min(1, (92 - greenExcess) / 70))
            let newAlpha = originalAlpha * opacityFactor
            if newAlpha <= 0.5 {
                pixels[offset] = 0
                pixels[offset + 1] = 0
                pixels[offset + 2] = 0
                pixels[offset + 3] = 0
                continue
            }

            let despilledGreen = min(green, max(red, blue) + 12)
            pixels[offset] = UInt8(max(0, min(255, red * newAlpha / 255)))
            pixels[offset + 1] = UInt8(max(0, min(255, despilledGreen * newAlpha / 255)))
            pixels[offset + 2] = UInt8(max(0, min(255, blue * newAlpha / 255)))
            pixels[offset + 3] = UInt8(max(0, min(255, newAlpha)))
        }

        var transparentImage: CGImage?
        pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo
            ) else { return }
            transparentImage = context.makeImage()
        }
        return (transparentImage ?? source, transparentImage != nil)
    }

    private func spriteStorageRoot() throws -> URL {
        let applicationSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return applicationSupport
            .appendingPathComponent("MonkeyDeskPets", isDirectory: true)
            .appendingPathComponent("Sprites", isDirectory: true)
    }

    private func loadLatestCustomFrames() -> [NSImage]? {
        guard let root = try? spriteStorageRoot() else { return nil }
        let currentDirectory = migrateLatestLegacySetIfNeeded(in: root)
            ?? root.appendingPathComponent("Current", isDirectory: true)
        return loadFrames(from: currentDirectory)
    }

    private func loadFrames(from directory: URL) -> [NSImage]? {
        let images: [NSImage] = (0..<8).compactMap { index in
            let url = directory.appendingPathComponent("frame-\(index).png")
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                return nil
            }
            return NSImage(cgImage: image, size: characterSize)
        }
        return images.count == Pose.allCases.count ? images : nil
    }

    private func replaceCurrentSprites(with staging: URL, in root: URL) throws -> URL {
        let fileManager = FileManager.default
        let current = root.appendingPathComponent("Current", isDirectory: true)
        let backup = root.appendingPathComponent(
            ".previous-\(UUID().uuidString)",
            isDirectory: true
        )

        if fileManager.fileExists(atPath: current.path) {
            try fileManager.moveItem(at: current, to: backup)
        }

        do {
            try fileManager.moveItem(at: staging, to: current)
        } catch {
            if fileManager.fileExists(atPath: backup.path) {
                try? fileManager.moveItem(at: backup, to: current)
            }
            throw error
        }

        try? fileManager.removeItem(at: backup)
        removeObsoleteSpriteDirectories(in: root, keeping: current)
        return current
    }

    private func migrateLatestLegacySetIfNeeded(in root: URL) -> URL? {
        let fileManager = FileManager.default
        let current = root.appendingPathComponent("Current", isDirectory: true)
        if fileManager.fileExists(atPath: current.path) {
            removeObsoleteSpriteDirectories(in: root, keeping: current)
            return current
        }

        guard let entries = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        let legacySets = entries
            .filter { $0.lastPathComponent.hasPrefix("set-") }
            .sorted {
                let left = (try? $0.resourceValues(
                    forKeys: [.contentModificationDateKey]
                ).contentModificationDate) ?? .distantPast
                let right = (try? $1.resourceValues(
                    forKeys: [.contentModificationDateKey]
                ).contentModificationDate) ?? .distantPast
                return left > right
            }

        guard let latest = legacySets.first(where: {
            loadFrames(from: $0)?.count == Pose.allCases.count
        }) else {
            removeObsoleteSpriteDirectories(in: root, keeping: nil)
            return nil
        }

        do {
            try fileManager.moveItem(at: latest, to: current)
            removeObsoleteSpriteDirectories(in: root, keeping: current)
            return current
        } catch {
            return nil
        }
    }

    private func removeObsoleteSpriteDirectories(in root: URL, keeping current: URL?) {
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) else { return }

        for entry in entries where entry != current {
            let name = entry.lastPathComponent
            if name.hasPrefix("set-")
                || name.hasPrefix(".incoming-")
                || name.hasPrefix(".previous-") {
                try? fileManager.removeItem(at: entry)
            }
        }
    }

    private func writePNG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw spriteError(localized(
                "無法建立 PNG 檔案：\(url.lastPathComponent)",
                "Unable to create PNG file: \(url.lastPathComponent)"
            ))
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw spriteError(localized(
                "無法保存 PNG 檔案：\(url.lastPathComponent)",
                "Unable to save PNG file: \(url.lastPathComponent)"
            ))
        }
    }

    private func spriteError(_ message: String) -> NSError {
        NSError(
            domain: "MonkeyDeskPets.SpriteImport",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }

    private func showMessage(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }

    private func mirroredImage(_ image: NSImage) -> NSImage? {
        guard let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        guard let context = CGContext(
            data: nil,
            width: source.width,
            height: source.height,
            bitsPerComponent: 8,
            bytesPerRow: source.width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.translateBy(x: CGFloat(source.width), y: 0)
        context.scaleBy(x: -1, y: 1)
        context.draw(
            source,
            in: CGRect(
                x: 0,
                y: 0,
                width: CGFloat(source.width),
                height: CGFloat(source.height)
            )
        )
        guard let mirrored = context.makeImage() else { return nil }
        return NSImage(cgImage: mirrored, size: image.size)
    }

    private func setPoseImage(_ pet: Pet, pose: Pose) {
        if pet.velocity.dx < -0.01 {
            pet.facingLeft = true
        } else if pet.velocity.dx > 0.01 {
            pet.facingLeft = false
        }

        let sourceFrames = pet.facingLeft ? mirroredFrames : frames
        guard pose.rawValue < sourceFrames.count else { return }
        pet.window.imageView.layer?.setAffineTransform(.identity)
        pet.window.imageView.image = sourceFrames[pose.rawValue]
    }

    private func showFatalError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = localized(
            "桌面猴群無法啟動",
            "MonkeyDeskPets Could Not Start"
        )
        alert.informativeText = message
        alert.runModal()
        NSApp.terminate(nil)
    }
}

private extension NSRect {
    var area: CGFloat { width * height }
}

private let application = NSApplication.shared
private let delegate = DesktopPetController()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
