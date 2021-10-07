// swift-tools-version:5.1
//
// Created by James Lawton on 2021-10-06.
// Copyright © 2021 Box Inc. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "BrowseSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "BrowseSDK",
            targets: ["BrowseSDK"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/box/box-ios-sdk.git", .upToNextMajor(from: "4.0.0"))
    ],
    targets: [
        .target(
            name: "BrowseSDK",
            dependencies: [],
            path: "BrowseSDK"
        )
    ]
)
