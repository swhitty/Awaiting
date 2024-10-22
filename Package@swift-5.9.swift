// swift-tools-version:5.9

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
			path: "Sources",
            swiftSettings: .upcomingFeatures
		),
        .testTarget(
            name: "AwaitingTests",
			dependencies: ["Awaiting"],
			path: "Tests",
            swiftSettings: .upcomingFeatures
		)
    ]
)

extension Array where Element == SwiftSetting {

    static var upcomingFeatures: [SwiftSetting] {
        [
            .enableUpcomingFeature("ExistentialAny"),
            .enableExperimentalFeature("StrictConcurrency")
        ]
    }
}
