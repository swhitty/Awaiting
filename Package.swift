// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "Awaiting",
	  platforms: [
	       .macOS(.v12), .iOS(.v15),
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
            .swiftLanguageMode(.v6)
        ]
    }
}
