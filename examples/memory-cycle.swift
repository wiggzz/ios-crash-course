class Child {
  var parent: Parent?
}

class Parent {
  var child : Child

  init() {
    child = Child()
    child.parent = self
  }
}
