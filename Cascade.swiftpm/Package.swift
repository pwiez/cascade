// swift-tools-version: 6.0

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Cascade",
    platforms: [
        .iOS("26.0")
    ],
    products: [
        .iOSApplication(
            name: "Cascade",
            targets: ["AppModule"],
            bundleIdentifier: "pwiez.cascade",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .pad
            ],
            supportedInterfaceOrientations: [
                .landscapeRight,
                .landscapeLeft,
                .portrait,
                .portraitUpsideDown
            ],
            appCategory: .education
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ],
    swiftLanguageVersions: [.version("6")]
)
