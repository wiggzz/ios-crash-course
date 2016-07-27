import Foundation

class Counter {
  var state = 0

  func count() { state+=1 }

  func start() {
    // iOS syntax for setTimeout()...
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1*NSEC_PER_SEC)), dispatch_get_main_queue()) { [weak self] in
      if let `self` = self {
        print("counter: \(self.state)")
        self.count()
        self.start()
      }
    }
  }
}

func f() {
  let counter = Counter()
  counter.start()
}

f()

dispatch_main()
