// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "GoMotoApp",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "GoMotoApp",
            targets: ["GoMotoApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/googlemaps/google-maps-ios-sdk.git", from: "7.0.0"),
        .package(url: "https://github.com/googlemaps/google-maps-ios-utils.git", from: "4.1.0"),
        .package(url: "https://github.com/stripe/stripe-ios.git", from: "22.0.0"),
        .package(url: "https://github.com/youtube/youtube-ios-player-helper.git", from: "0.2.4"),
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "GoMotoApp",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "GoogleMaps", package: "google-maps-ios-sdk"),
                .product(name: "GoogleMapsUtils", package: "google-maps-ios-utils"),
                .product(name: "Stripe", package: "stripe-ios"),
                .product(name: "youtube-ios-player-helper", package: "youtube-ios-player-helper"),
                .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI")
            ]
        )
    ]
)
