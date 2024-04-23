// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "Awaiting",
	  platforms: [
	       .macOS(.v10_15), .iOS(.v13),
	    ],
    products: [
		.library(
            name: "Awaiting",
            targets: ["Awaiting"]
		)
    ],
    targets: [
        .target(
            name: "Awaiting",
			path: "Sources"
		),
        .testTarget(
            name: "AwaitingTests",
			dependencies: ["Awaiting"],
			path: "Tests"
		)
    ]
)
