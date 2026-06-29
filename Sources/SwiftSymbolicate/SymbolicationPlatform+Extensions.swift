@_spi(Internal) import Runtime

@_spi(Internal)
extension Backtrace.SymbolicationPlatform {
    var pathSeparator: String {
        switch self {
            case .Windows: "\\"
            default: "/"
        }
    }
}
