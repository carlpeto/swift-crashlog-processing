//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

// On-disk binary format structures for Windows minidump files.
// All fields are little-endian.

struct MinidumpHeader {
    static let signature: UInt32 = 0x504D444D // "PMDM"
    static let versionMask: UInt32 = 0xFFFF
    static let expectedVersion: UInt32 = 0xa793

    var signature: UInt32
    var version: UInt32
    var numberOfStreams: UInt32
    var streamDirectoryRVA: UInt32
    var checksum: UInt32
    var timeDateStamp: UInt32
    var flags: UInt64
}

struct MinidumpDirectory {
    var streamType: UInt32
    var dataSize: UInt32
    var rva: UInt32
}

struct MinidumpLocationDescriptor {
    var dataSize: UInt32
    var rva: UInt32
}

struct MinidumpMemoryDescriptor {
    var startOfMemoryRange: UInt64
    var memory: MinidumpLocationDescriptor
}

struct MinidumpThread {
    var threadId: UInt32
    var suspendCount: UInt32
    var priorityClass: UInt32
    var priority: UInt32
    var environmentBlock: UInt64
    var stack: MinidumpMemoryDescriptor
    var context: MinidumpLocationDescriptor
}

struct MinidumpModule {
    var baseOfImage: UInt64
    var sizeOfImage: UInt32
    var checksum: UInt32
    var timeDateStamp: UInt32
    var moduleNameRVA: UInt32
    var versionInfo: VSFixedFileInfo
    var cvRecord: MinidumpLocationDescriptor
    var miscRecord: MinidumpLocationDescriptor
    var reserved0: UInt64
    var reserved1: UInt64
}

struct VSFixedFileInfo {
    var signature: UInt32
    var structVersion: UInt32
    var fileVersionHigh: UInt32
    var fileVersionLow: UInt32
    var productVersionHigh: UInt32
    var productVersionLow: UInt32
    var fileFlagsMask: UInt32
    var fileFlags: UInt32
    var fileOS: UInt32
    var fileType: UInt32
    var fileSubtype: UInt32
    var fileDateHigh: UInt32
    var fileDateLow: UInt32
}

struct MinidumpExceptionRecord {
    var exceptionCode: UInt32
    var exceptionFlags: UInt32
    var exceptionRecord: UInt64
    var exceptionAddress: UInt64
    var numberOfParameters: UInt32
    var unusedAlignment: UInt32
    var exceptionInformation: (
        UInt64, UInt64, UInt64, UInt64, UInt64,
        UInt64, UInt64, UInt64, UInt64, UInt64,
        UInt64, UInt64, UInt64, UInt64, UInt64)
}

struct MinidumpExceptionStream {
    var threadId: UInt32
    var unusedAlignment: UInt32
    var exceptionRecord: MinidumpExceptionRecord
    var threadContext: MinidumpLocationDescriptor
}

struct MinidumpSystemInfo {
    var processorArchitecture: UInt16
    var processorLevel: UInt16
    var processorRevision: UInt16
    var numberOfProcessors: UInt8
    var productType: UInt8
    var majorVersion: UInt32
    var minorVersion: UInt32
    var buildNumber: UInt32
    var platformId: UInt32
    var csdVersionRVA: UInt32
    var suiteMask: UInt16
    var reserved: UInt16
    var cpu: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
              UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
              UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
}

enum MinidumpStreamType: UInt32 {
    case threadList = 0x0003
    case moduleList = 0x0004
    case memoryList = 0x0005
    case exception = 0x0006
    case systemInfo = 0x0007
    case memory64List = 0x0009
    case miscInfo = 0x000F
    case memoryInfoList = 0x0010
}

enum MinidumpProcessorArchitecture: UInt16 {
    case x86 = 0x0000
    case arm = 0x0005
    case amd64 = 0x0009
    case arm64 = 0x000C
}

enum MinidumpOSPlatform: UInt32 {
    case win32NT = 0x0002
    case unix = 0x8000
    case macOSX = 0x8101
    case iOS = 0x8102
    case linux = 0x8201
    case android = 0x8203
}
