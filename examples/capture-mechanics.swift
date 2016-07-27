class A {
  func foo() {
    print("foo")
  }
}

let a = A()

let f = { [weak a] in
  a?.foo()
}
