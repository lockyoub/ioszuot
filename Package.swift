// swift-tools-version:5.9
/*
 // Swift包配置
 // 作者: MiniMax Agent
 */

import PackageDescription

let package = Package(
    name: "StockTradingApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "StockTradingApp",
            targets: ["StockTradingApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/danielgindi/Charts.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "StockTradingApp",
            dependencies: [
                .product(name: "DGCharts", package: "Charts")
            ],
            path: ".",
            exclude: [
                "Tests",
                "Package.swift"
            ],
            resources: [
                .process("TradingDataModel.xcdatamodeld")
            ]
        ),
        .testTarget(
            name: "StockTradingAppTests",
            dependencies: ["StockTradingApp"],
            path: "Tests"
        ),
    ]
)


