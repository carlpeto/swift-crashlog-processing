import Foundation
import Runtime

@_spi(CrashLog) import Runtime
@_spi(Internal) import Runtime
@_spi(SymbolLocation) import Runtime
@_spi(Formatting) import Runtime

fileprivate let decoder = JSONDecoder()

public extension CrashLog {
    /// Decodes a ``CrashLog`` from JSON data.
    ///
    /// - Parameter json: The JSON-encoded crash log data.
    /// - Returns: The decoded crash log.
    /// - Throws: If decoding fails.
    static func loadFromJSON(_ json: Data) throws -> CrashLog {
        try decoder.decode(CrashLog.self, from: json)
    }

    /// The symbolication platform inferred from the crash log's `platform` string.
    var symbolicationPlatform: Backtrace.SymbolicationPlatform {
        if platform.contains("macOS") {
            return .Darwin
        } else if platform.contains("Linux") {
            return .Linux
        } else if platform.contains("Windows") {
            return .Windows
        } else {
            print("unable to parse platform")
            return .default
        }
    }
    
    /// The ``SymbolServerPlatform`` for this crash log, for use with symbol server lookups.
    var symbolServerPlatform: SymbolServerPlatform {
        if platform.contains("macOS") {
            return .Darwin
        } else if platform.contains("Linux") {
            return .Linux
        } else if platform.contains("Windows") {
            return .Windows
        } else {
            print("unable to parse platform for symbol server")
            return .Linux
        }
    }

    /// The build ID, executable name, and platform for each image in the crash log.
    @_spi(Formatting)
    var imageDetails: [(String, String, SymbolServerPlatform)] {
        guard let images else { return [] }

        let platform = symbolServerPlatform

        return images.compactMap { (image) -> (String, String, SymbolServerPlatform)? in
            guard let buildId = image.buildId, let name = image.name else {
                return nil
            }

            return (buildId, name, platform)
        }
    }
}
