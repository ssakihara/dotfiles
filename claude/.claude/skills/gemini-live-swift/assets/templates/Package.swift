// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GeminiLiveVoiceChat",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.8.0")
    ],
    targets: [
        .executableTarget(
            name: "GeminiLiveVoiceChat",
            dependencies: [
                .product(name: "FirebaseAILogic", package: "firebase-ios-sdk")
            ]
        )
    ]
)
