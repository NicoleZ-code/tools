// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PicPick",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "PicPick", targets: ["PicPick"])],
    targets: [.executableTarget(name: "PicPick", path: "Sources/PicPick")]
)
