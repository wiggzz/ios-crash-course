class Item {
  init() { print("init") }
  deinit { print("deinit") }
}
func f() {
  let _ = Item()
}

print("start")
f()
print("done")
