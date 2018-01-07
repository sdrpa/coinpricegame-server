// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
   name: "App",
   dependencies: [
      .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "2.1.0"),
      .package(url: "https://github.com/IBM-Swift/Kitura-WebSocket", from: "1.0.0"),
      .package(url: "https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL", from: "1.0.0"),
      .package(url: "https://github.com/IBM-Swift/Swift-SMTP", from: "1.1.3"),
      .package(url: "https://github.com/IBM-Swift/SwiftyJSON", from: "17.0.0")
   ],
   targets: [
      .target(
         name: "KituraCORS",
         dependencies: ["Kitura"]),
      .target(
         name: "Then",
         dependencies: []),
      .target(
         name: "Server",
         dependencies: [
            "Kitura",
            "Kitura-WebSocket",
            "KituraCORS",
            "SwiftKueryPostgreSQL",
            "SwiftSMTP",
            "SwiftyJSON",
            "Then"]),
      .testTarget(
         name: "ServerTests",
         dependencies: ["Server"]),
      .target(
         name: "App",
         dependencies: ["Server"]),
      .target(
         name: "Datagen",
         dependencies: ["Server"])
   ]
)
