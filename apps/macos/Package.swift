// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MonkeyDeskPets",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MonkeyDeskPets", targets: ["MonkeyDeskPets"])
    ],
    targets: [
        .executableTarget(
            name: "MonkeyDeskPets",
            resources: [
                .copy("person-sprites.png"),
                .copy("author-avatar.png"),
                .copy("logitech-ad.jpeg"),
                .copy("PolyForm-Noncommercial-1.0.0.txt"),
                .copy("NOTICE.txt"),
                .copy("ADDITIONAL-TERMS-zh-TW.txt"),
                .copy("ADDITIONAL-TERMS-en.txt"),
                .copy("MonkeyDeskPets-Noncommercial-License-1.0.txt")
            ]
        )
    ]
)
