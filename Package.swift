// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

// import class Foundation.ProcessInfo
import PackageDescription

// You can run tests build using a suitable custom toolchain like...
// export TOOLCHAINS=/Users/carlpeto/Code/swift-project/build/Ninja-RelWithDebInfoAssert/toolchain-macosx-arm64/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain


// #if DebugStandardLibrary
// let buildTypeFolder = "Ninja-RelWithDebInfoAssert+stdlib-DebugAssert"
// #else
let buildTypeFolder = "Ninja-RelWithDebInfoAssert"
// #endif

#if os(macOS)
let swiftUnsafeFlags = 
                    [
                        "-I/Users/carlpeto/Code/swift-project/build/\(buildTypeFolder)/swift-macosx-arm64/lib/swift/macosx",
                        "-L/Users/carlpeto/Code/swift-project/build/\(buildTypeFolder)/swift-macosx-arm64/lib/swift/macosx",
                    ]

let swiftCrashMeUnsafeFlags: [String] = []

let linkerUnsafeFlags =
                [
                    "-L/Users/carlpeto/Code/swift-project/build/\(buildTypeFolder)/swift-macosx-arm64/lib/swift/macosx",
                    "-Xlinker","-force_load",
                    "-Xlinker","/Users/carlpeto/Code/swift-project/build/\(buildTypeFolder)/swift-macosx-arm64/lib/swift/macosx/libswiftRuntime.dylib"
                ]

let unitTestSwiftUnsafeFlags =
                    [
                        "-I/Users/carlpeto/Code/swift-project/build/\(buildTypeFolder)/swift-macosx-arm64/lib/swift/macosx",
                        "-L/Users/carlpeto/Code/swift-project/build/\(buildTypeFolder)/swift-macosx-arm64/lib/swift/macosx",
                        "-plugin-path",
                        "/Users/carlpeto/Code/swift-project/build/\(buildTypeFolder)/swifttesting-macosx-arm64/swift",
                        "-plugin-path",
                        "/Users/carlpeto/Code/swift-project/build/\(buildTypeFolder)/swifttestingmacros-macosx-arm64",
                    ]

let unitTestLinkerUnsafeFlags =
                [
                    "-L/Users/carlpeto/Code/swift-project/build/\(buildTypeFolder)/swift-macosx-arm64/lib/swift/macosx",
                    "-L/Users/carlpeto/Code/swift-project/build/\(buildTypeFolder)/swifttesting-macosx-arm64/lib",
                    "-L/Users/carlpeto/Code/swift-project/build/\(buildTypeFolder)/swifttestingmacros-macosx-arm64",
                    "-Xlinker","-force_load",
                    "-Xlinker","/Users/carlpeto/Code/swift-project/build/\(buildTypeFolder)/swift-macosx-arm64/lib/swift/macosx/libswiftRuntime.dylib",
                    "-Xlinker","-rpath",
                    "-Xlinker","/Users/carlpeto/Code/swift-project/build/\(buildTypeFolder)/swift-macosx-arm64/lib/swift/macosx",
                ]

#elseif os(Linux)
let swiftUnsafeFlags = 
                    [
                        "-I/home/build-user/swift-project/build/\(buildTypeFolder)/swift-linux-aarch64/lib/swift/linux",
                        "-L/home/build-user/swift-project/build/\(buildTypeFolder)/swift-linux-aarch64/lib/swift/linux",
                    ]

let swiftCrashMeUnsafeFlags: [String] = []

let linkerUnsafeFlags =
                [
                    "-L/home/build-user/swift-project/build/\(buildTypeFolder)/swift-linux-aarch64/lib/swift/linux",
                    // "-Xlinker","-force_load",
                    // "-Xlinker","/home/build-user/swift-project/build/\(buildTypeFolder)/swift-linux-aarch64/lib/swift/linux/libswiftRuntime.so"
                ]

let unitTestSwiftUnsafeFlags =
                    [
                        "-I/home/build-user/swift-project/build/\(buildTypeFolder)/swift-linux-aarch64/lib/swift/linux",
                        "-L/home/build-user/swift-project/build/\(buildTypeFolder)/swift-linux-aarch64/lib/swift/linux",
                        "-plugin-path",
                        "/home/build-user/swift-project/build/\(buildTypeFolder)/swifttesting-linux-aarch64/swift",
                        "-plugin-path",
                        "/home/build-user/swift-project/build/\(buildTypeFolder)/sswifttestingmacros-linux-aarch64",
                    ]

let unitTestLinkerUnsafeFlags =
                [
                    "-L/home/build-user/swift-project/build/\(buildTypeFolder)/swift-linux-aarch64/lib/swift/linux",
                    "-L/home/build-user/swift-project/build/\(buildTypeFolder)/swifttesting-linux-aarch64/lib",
                    "-L/home/build-user/swift-project/build/\(buildTypeFolder)/swifttestingmacros-linux-aarch64",
                    // "-Xlinker","-force_load",
                    // "-Xlinker","/home/build-user/swift-project/build/\(buildTypeFolder)/swift-linux-aarch64/lib/swift/linux/libswiftRuntime.so"
                ]

#elseif os(Windows)
let swiftUnsafeFlags = 
                    [
                        "-I/S:\\Program Files\\Swift\\Platforms\\Windows.platform\\Developer\\SDKs\\Windows.sdk\\usr\\lib\\swift\\windows",
                        "-L/S:\\Program Files\\Swift\\Platforms\\Windows.platform\\Developer\\SDKs\\Windows.sdk\\usr\\lib\\swift\\windows",
                    ]

let swiftCrashMeUnsafeFlags = 
[
    "-debug-info-format=codeview",
]

let linkerUnsafeFlags =
                [
                    "-L/S:\\Program Files\\Swift\\Platforms\\Windows.platform\\Developer\\SDKs\\Windows.sdk\\usr\\lib\\swift\\windows",
                    // "/DEBUG", // only needed for link.exe ?
                    // "-Xlinker","-force_load",
                    // "-Xlinker","/home/build-user/swift-project/build/\(buildTypeFolder)/swift-linux-aarch64/lib/swift/linux/libswiftRuntime.so"
                ]

let unitTestSwiftUnsafeFlags: [String] = []
let unitTestLinkerUnsafeFlags: [String] = []

#endif

var products: [PackageDescription.Product] =
[
    .executable(
        name: "swift-symbolicate",
        targets: ["swift-symbolicate"]
    ),
    .executable(
        name: "crashMe",
        targets: ["crashMe"]
    ),
    .executable(
        name: "crashMeOpenFds",
        targets: ["crashMeOpenFds"]
    ),
    .library(name: "Minidump", targets: ["Minidump"]),
    .library(name: "MSVCNameDemangler", targets: ["MSVCNameDemangler"]),
    .library(name: "SwiftSymbolicate", type: .dynamic, targets: [
        "SwiftSymbolicate",
    ]),
]

var targets: [PackageDescription.Target] =
[
    .target(
        name: "Minidump"
    ),
    .target(
        name: "MSVCNameDemangler",
        swiftSettings: [
            .interoperabilityMode(.Cxx)
        ]
    ),
    .target(
        name: "SwiftSymbolicate",
        dependencies: ["Minidump", "MSVCNameDemangler"],
        swiftSettings: [
            .interoperabilityMode(.Cxx),
            // .define("DEBUG_SCANNER"),
            // .define("DEBUG_RECOGNIZER"),
            .unsafeFlags(swiftUnsafeFlags)
        ],
        linkerSettings: [
            .unsafeFlags(linkerUnsafeFlags)
        ]
    ),
    .executableTarget(
        name: "swift-symbolicate",
        dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            "SwiftSymbolicate"
        ],
        swiftSettings: [
            .interoperabilityMode(.Cxx),
            .unsafeFlags(swiftUnsafeFlags)
        ],
        linkerSettings: [
            .unsafeFlags(linkerUnsafeFlags)
        ]
    ),
    .executableTarget(
        name: "crashMe",
        swiftSettings: [
            .unsafeFlags(swiftCrashMeUnsafeFlags)
        ]
    ),
    .executableTarget(
        name: "crashMeOpenFds",
        swiftSettings: [
            .unsafeFlags(swiftCrashMeUnsafeFlags)
        ]
    ),
]

products.append(
    .executable(
        name: "crashMeMultithreaded",
        targets: ["crashMeMultithreaded"]
    )
)

targets.append(contentsOf: [
    .target(
        name: "CxxCrashHelper",
        publicHeadersPath: "include"
    ),
    .executableTarget(
        name: "crashMeMultithreaded",
        dependencies: ["CxxCrashHelper"]
    ),
])

#if os(Windows)
products.append(
    .executable(
        name: "index-pdb-files",
        targets: ["index-pdb-files"]
    )
)
targets.append(
    .executableTarget(
        name: "index-pdb-files",
        dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            "SwiftSymbolicate"
        ],
        swiftSettings: [
            .interoperabilityMode(.Cxx),
            .unsafeFlags(swiftUnsafeFlags)
        ],
        linkerSettings: [
            .unsafeFlags(linkerUnsafeFlags)
        ]
    )
)
#endif

#if os(macOS) || os(Linux)
let testTargetDeps: [PackageDescription.Target.Dependency] =
[
    "swift-symbolicate",
    .target(name: "SwiftSymbolicate"),
    "crashMe",
    "crashMeOpenFds",
    "crashMeMultithreaded",
    .product(name: "Subprocess", package: "swift-subprocess")
]
#elseif os(Windows)
let testTargetDeps: [PackageDescription.Target.Dependency] =
[
    "swift-symbolicate",
    .target(name: "SwiftSymbolicate"),
    "crashMe",
    "crashMeMultithreaded",
    .product(name: "Subprocess", package: "swift-subprocess")
]
#endif

let testTarget: PackageDescription.Target =
    .testTarget(
        name: "swift-symbolicateTests",
        dependencies: testTargetDeps,
        swiftSettings: [
            .interoperabilityMode(.Cxx),
            .unsafeFlags(unitTestSwiftUnsafeFlags)
        ],
        linkerSettings: [
            .unsafeFlags(unitTestLinkerUnsafeFlags)
        ]
    )

targets.append(testTarget)

let package = Package(
    name: "swift-symbolicate",
    platforms: [
        .macOS(.v26),
    ],
    products: products,
    traits: [
        .trait(name: "TestSymbolicating"),
        .trait(name: "TestGeneral"),
        .trait(name: "TestIntegrations"),
        .trait(name: "DebuggingSymbolicator"),
        .trait(name: "DebugStandardLibrary"),
        .trait(name: "Betax86Registers"),
        .default(enabledTraits: ["TestSymbolicating","TestGeneral"])],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", branch: "main", traits: ["SubprocessFoundation"]),
    ],
    targets: targets
)
