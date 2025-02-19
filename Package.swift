// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftRecord",
	platforms: [
		.iOS(.v15),
		.macCatalyst(.v14),
		],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftRecord",
            targets: ["SwiftRecord"]
        ),
    ],
	targets: [
		.target(
			name: "SwiftRecord")
		]
	]
)
