// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BranchSDK",
    platforms: [
        .iOS(.v9),
        .tvOS(.v9),
    ],
    products: [
        .library(
            name: "BranchSDK",
            targets: ["BranchSDK"]),
    ],
    targets: [
        .target(
            name: "BranchSDK",
            path: "BranchSDK",
            publicHeadersPath: "."
        ),
    ]
)
