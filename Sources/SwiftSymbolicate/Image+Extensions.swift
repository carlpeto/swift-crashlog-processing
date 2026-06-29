@_spi(SymbolLocation) import Runtime
@_spi(Utils) import Runtime

@_spi(SymbolLocation)
extension SymbolLoader.Image {
    var id: String {
        guard let uuid else {
            return ""
        }
        
        return hex(uuid)
    }
}
