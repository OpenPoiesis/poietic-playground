// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PoieticPlayground",
    platforms: [ .macOS(.v26), ],
    products: [
        .executable(
            name: "PoieticPlayground",
            targets: ["PoieticPlayground"]),
    ],
    dependencies: [
        .package(url: "https://github.com/openpoiesis/poietic-core", from: "0.10.0"),
        .package(url: "https://github.com/openpoiesis/poietic-flows", from: "0.10.0"),
        .package(url: "https://github.com/openpoiesis/poietic-diagram", from: "0.10.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "PoieticPlayground",
            dependencies: [
                .product(name: "PoieticCore", package: "poietic-core"),
                .product(name: "PoieticFlows", package: "poietic-flows"),
                .product(name: "Diagramming", package: "poietic-diagram"),
                "Csdl3",
                "CIimgui",
                "Cimguifd",
                "Cstb",
                "Ccairo",
            ],
            resources: [
                .copy("Resources/fonts/"),
                .copy("Resources/notations/"),
                .copy("Resources/designs/"),
                .copy("Resources/stock_flow_pictograms.json"),
                .copy("Resources/stock_flow_pictograms-jolly.json"),
            ],
            swiftSettings: [.unsafeFlags([
                "-cxx-interoperability-mode=default",
            ])]
        ),
        .systemLibrary(
            name: "Csdl3",
            pkgConfig: "sdl3",
            providers: [
                .apt(["sdl3-dev"]),
                .brew(["sdl3"])
            ]
        ),
        .systemLibrary(
            name: "Ccairo",
            pkgConfig: "cairo",
            providers: [
                .apt(["cairo-dev"]),
                .brew(["cairo"])
            ]
        ),

        .target(
            name: "CIimgui",
            dependencies: [
                "Csdl3"
            ],
            cxxSettings: [ ],
            linkerSettings: [ ]
        ),
        .target(
            name: "Cimguifd",
            dependencies: [
                "CIimgui"
            ],
            cxxSettings: [
                .define("IMGUIFD_ENABLE_STL=1"),
                .define("IMGUI_DEFINE_MATH_OPERATORS=1"),
            ],
            linkerSettings: [ ]
        ),
        .target(
            name: "Cstb",
            cxxSettings: [ ],
        ),
    ]
)
