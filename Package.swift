// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "QuickTranslate",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm/", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "QuickTranslate",
            dependencies: [
                "HotKey",
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
            ],
            path: "Sources/QuickTranslate"
        ),
    ]
)
