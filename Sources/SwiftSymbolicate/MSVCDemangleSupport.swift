#if !os(Windows)

import Runtime
@_spi(CrashLog) import Runtime

import MSVCNameDemangler

extension CrashLog {
    /// Runs the MSVC C++ demangler over `demangledName` for every backtrace
    /// frame whose raw symbol begins with `?`. Used after symbolication on
    /// non-Windows hosts so MSVC-mangled C++ names in Windows crash logs show
    /// up readable in JSON output (Swift's runtime demangler doesn't handle
    /// the MSVC scheme).
    mutating func demangleMSVCSymbolNames() {
        for tIdx in threads.indices {
            for fIdx in threads[tIdx].frames.indices {
                guard let raw = threads[tIdx].frames[fIdx].symbol,
                      raw.hasPrefix("?") else { continue }
                let demangled = demangleMSVC(raw)
                if demangled != raw {
                    threads[tIdx].frames[fIdx].demangledName = demangled
                }
            }
        }
    }
}

extension SymbolicatedBacktrace {
    /// Patches `Symbol.name` for every frame whose `rawName` begins with `?`
    /// using the MSVC C++ demangler. The plain-text `BacktraceFormatter` reads
    /// `Symbol.name`, which is otherwise computed by Swift's runtime demangler
    /// and leaves MSVC-mangled C++ names untouched.
    func demangleMSVCSymbolNames() {
        for frame in frames {
            guard let symbol = frame.symbol,
                  symbol.rawName.hasPrefix("?") else { continue }
            let demangled = demangleMSVC(symbol.rawName)
            if demangled != symbol.rawName {
                symbol.name = demangled
            }
        }
    }
}

#endif
