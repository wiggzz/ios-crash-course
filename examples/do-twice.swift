func doTwice(something: ()->()) {
  something()
  something()
}

doTwice({
  print("Hi")
})
