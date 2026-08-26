// swift-tools-version: 6.0

import AppleProductTypes
import PackageDescription

let package = Package(
    name: "Cascade",
    platforms: [
        .iOS("18.0")
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
            dependencies: ["CascadeEngine"],
            path: "App"
        ),

        .target(
            name: "CascadeEngine",
            path: "Engine"
        ),

        .testTarget(
            name: "CascadeEngineTests",
            dependencies: ["CascadeEngine"],
            path: "Tests/CascadeEngineTests"
        )
    ],
    swiftLanguageModes: [.version("6")]
)
