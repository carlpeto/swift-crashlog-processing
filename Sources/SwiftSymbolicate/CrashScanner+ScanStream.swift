
extension CrashScanner {
    /// Convenience method that calls ``start()``, scans the input stream
    /// symbolicating any detected crash logs via their ``LogStreamReaderWriter``,
    /// and then calls ``stop()``.
    ///
    /// - Throws: If reading from the input stream fails.
    public func scanAndProcessStreams() async throws {
        start()

        try await scan { logScanner, data in
            await logScanner.processLog(data: data)
        }

        stop()
    }
}
