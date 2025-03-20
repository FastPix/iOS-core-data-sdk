// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageName = "FastpixiOSVideoDataCore"

let package = Package(
    name: packageName,
    products: [
        .library(
            name: packageName,
            targets: [packageName]
        ),
    ],
    targets: [
        .target(
            name: packageName
        ),
        .testTarget(
            name: "\(packageName)Tests",
            dependencies: [.target(name: packageName)]
        ),
    ]
)
