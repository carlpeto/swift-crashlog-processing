#if os(macOS)
internal import Darwin
#elseif os(Windows)
internal import ucrt
#elseif canImport(Glibc)
internal import Glibc
#elseif canImport(Musl)
internal import Musl
#endif

func level1() {
  level2()
}

func level2() {
  level3()
}

func level3() {
  level4()
}

func level4() {
  print("About to crash: [\(getpid())]")
  let ptr = UnsafeMutablePointer<Int>(bitPattern: 6)!
  ptr.pointee = 42
}

@main
struct Crash {
  static func main() {
    let fd1 = creat("tmp1.txt", 0o644)
    guard fd1 > 0 else {
      perror("failed to open fd1")
      exit(-1)
    }

    let fd2 = creat("tmp2.txt", 0o644)
    guard fd1 > 0 else {
      perror("failed to open fd2")
      exit(-1)
    }

    defer {
        close(fd1)
        close(fd2)

        unlink("tmp1.txt")
        unlink("tmp2.txt")
    }

    print("created and opened: [\(fd1), \(fd2)]")

    level1()
  }
}
