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
  print("About to crash")
  let ptr = UnsafeMutablePointer<Int>(bitPattern: 6)!
  ptr.pointee = 42
}

@main
struct Crash {
  static func main() {
    level1()
  }
}