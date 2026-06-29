@_spi(SymbolLocation) import Runtime

/// A symbol locator that can fetch symbols from remote servers.
@_spi(SymbolLocation)
public protocol FetchingSymbolLocator: SymbolLocator {
    /// Downloads and caches symbol files for the given images from configured symbol servers.
    ///
    /// - Parameter imageDetails: An array of `(buildId, executableName, platform)` tuples
    ///   identifying each image to fetch symbols for.
    func updateSymbolCache(imageDetails: [(String, String, SymbolServerPlatform)]) async
}
