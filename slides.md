# iOS Crash Course
## Swift Swiftly



## Topics
* Swift 101
* iOS components (Frameworks, TableViews, WebViews, etc...)
* Package Management
* Testing
* Tools - XCode
* Provisioning and Deployment
* Crash reporting and analytics



# Swift 101


## Swift is STATIC
Types must be inferable at compile time.

Doesn't compile:
```swift
var a

a = 5.0
```

Will compile:
```swift
var a : Double

a = 5.0
```


JSON deserialisation must be statically declared

(ugh. but also, yay! type safety)

```swift
import SwiftyJSON

class User {
  let name : String

  init(json: JSON) {
    name = json["name"].stringValue
  }
}
```


## Optionals
In swift, normal variables cannot be nil.
```swift
class Car {
  var make : String
  var model : String

  init() {
    make = "Honda"
  }
}
// Compiler error: model is not initialised by init()
```


But, optionals can be.
```swift
class Car {
  var make : String
  var model : String?

  init() {
    make = "Honda"
  }
}
// Works
```
This makes swift REALLY safe. You have to explicitly handle when a variable can be nil.


### What is an optional?
An optional is a type that can be nil or something else. We use `!` or `?` after the type as short hand for specifying an optional type:
```swift
let string : String? = "Hi"
print(string) // Optional("Hi")

if let string = string {
    print(string) // "Hi"
}
let a : Int? = nil
print(a) // "nil"

if let a = a {
    print(a)
} else {
    print("a is nil") // "a is nil"
}
```
`if let` clause lets us unwrap optionals in a nice way.


### Use Optionals as a tool to guide you
Handle optionality as early as possible.

Someone lazy might do this:

```swift
class Car {
  var make : String?

  init(json: String) {
    make = json["make"].string
  }
}
```
But, then we might have cars driving around in our code without a make. Could get ugly when we need to display the car (the user may see "nil").


If a car doesn't make sense without a make, then fail on initialisation:
```swift
class Car {
  var make : String

  init?(json: JSON) {
    guard let make = json["make"].string else {
      return nil
    }

    self.make = make
  }
}
```
Then, later on we don't have to worry that the car might not have a make. We know if we have a car, it has a make.


### Only EXTREMELY rarely should you need to force unwrap an optional
Really bad:
```swift
class UserView {
  let addressLabel : UILabel

  init(user: User) {
    addressLabel.text = "Address: " + user.address!
  }
}
```
This will work when you have an address, but it makes your code really brittle: there ever isn't an address, this will crash.


Better:
```swift
class UserView {
  let addressLabel: UILabel

  init(user: User) {
    if let address = user.address {
      addressLabel.text = "Address: " + address
    } else {
      addressLabel.hidden = true
    }
  }
}
```
Handle the optionality explicitly.


## Functions and Closures
Swift function:
```swift
func add(a: Int, b: Int) -> Int {
  return a + b
}
print(add(1,b: 2)) // 3
```

Swift closure, most verbose:
```swift
let add : ((Int,Int)->Int) = { (a:Int, b:Int)->Int in
  return a + b
}
print(add(1,2)) // 3
```

Swift closure, least verbose:
```swift
let add = { (a:Int,b:Int) in a+b }
```


### Higher order Functions
As with other languages, we can pass functions as arguments.
```swift
func doTwice(something: ()->()) {
  something()
  something()
}

doTwice({
  print("Hi")
})

// Hi
// Hi
```

In Swift, if a function is the last argument in a function signature, we can pull it out of the parentheses:
```swift
doTwice { print("Hi") }
```


## Memory Model
Swift is a reference counted language (as opposed to garbage collected). This means that as soon as a variable is no longer referenced, it is deallocated.

```swift
class Item {
  init() { print("init") }
  deinit { print("deinit") }
}
func f() {
  let _ = Item()
}

print(start)
f()
print(done)

// start
// init
// deinit
// done
```


### Reference Cycle
Since variables are not freed until they are not referenced, we must be careful not to retain extra references that could cause memory leaks.
```swift
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
```
But what happens if we need to reference a parent object from within a child?


### Unowned and Weak References
We can resolve by using a weak or unowned reference:
```swift
class Child {
  weak var parent : Parent?
}
```
or
```swift
class Child {
  unowned var parent : Parent
}
```
Now, Child will not increase reference count of parent, so parent can be deallocated when all references to it are gone.

You should pretty much always use weak references - they are safer.


### Reference cycles with Closures
This problem also arises when dealing with asynchronous behaviour.

```swift
import Foundation

class Example {
  func doSomething() { print("Hi") }

  func start() {
    // imagine we have func wait(seconds: Int, callback: ()->())
    // like setTimeout() in Javascript (iOS is a bit more annoying)
    wait(10) {
      self.doSomething()
    }
  }
}
```
`self` is explicitly captured by the closure (removing `self` from `self.doSomething()` will cause a compile error).


Do we want an Example object to still be in memory even if no external object is referencing it? If not -
```
class Example {
  ...
  func start() {
    wait(10) { [weak self] in
      if let `self` = self {
        self.doSomething()
      }
    }
  }
}
```
`[weak self]` is capture expression. `self` is made weak for the closure.

Also, swift magic: we can reassign `self` with back ticks.


## Protocols
More powerful than inheritance.


Say we want to reuse code between two classes:
```swift
class Human {
  let weightInKg : Double

  // initializers

  func dailyCaloricEstimate() -> Double {
    return weightInKg * 25.0
  }
}
```
```swift
class Dog {
  let weightInKg : Double

  // initializers

  func dailyCaloricEstimate() -> Double {
    return weightInKg * 25.0
  }
}
```


Traditionally we may use inheritance:
```swift
class Animal {
  let weightInKg : Double

  // initializers

  func dailyCaloricEstimate() -> Double {
    return weightInKg * 25.0
  }
}

class Human : Animal {}
class Dog : Animal {}
```
But and inheritance hierarchy is very difficult to get right the first time, and can get complicated quickly.


or better, we can use composition:
```swift
func dailyCaloricEstimateByWeight(weightInKg: Double) -> Double {
  return weightInKg * 25.0
}

class Human {
  let weightInKg : Double

  // initializers

  func dailyCaloricEstimate() -> Double {
    return dailyCaloricEstimateByWeight(weightInKg)
  }
}
...
```
But, number of parameters in free functions (or classes) can become large, and we have a lot of boilerplate code.


### Swift has a nicer choice
Use a protocol default implementation to share code.

```swift
protocol CalorieConsumer {
  var weightInKg : Double { get }
}

extension CalorieConsumer {
  func dailyCaloricEstimate() -> Double {
    return weightInKg * 25.0
  }
}

class Human : CalorieConsumer {
  let weightInKg : Double

  // initializers
}

class Dog : CalorieConsumer {
  let weightInKg : Double

  // initializers
}
```
All implementers of `CalorieConsumer` get `dailyCaloricEstimate()` for free.



## iOS components


* The View Hierarchy
* The delegate pattern
* UITableView
* UIStackView
* UIWebView
* AutoLayout


## The View Hierarchy

![](/images/ios-view-hierarchy.svg)


Each view can have zero or more subviews.

A ViewController has a view but is not part of the view hierarchy. It is responsible for controlling that view.


## The Delegate Pattern
Most of the iOS components use the delegate pattern to pass control from a view back to the view controller.

![](/images/ios-delegate-pattern.svg)


A view may use the delegate pattern to obtain more information from it's controller or notify the controller of events.


## UITableView
UIVableView is just a vertically scrollable stack of cells.

![](/images/tableview.svg)


The UITableView is at the core of most native iOS apps. It's highly performant - but that performance comes at a cost - its a bit difficult to use.

The UITableView decides when to load and what data to load - your code just provides the cells and meta data for the table.

As the user scrolls, UITableView determines which cells will be visible and then loads them on demand.


UITableView pulls cells from a UITableViewDataSource.

The core protocol:
```swift
protocol UITableViewDataSource {
  func numberOfSectionsInTableView(
    _ tableView: UITableView) -> Int

  func tableView(
    _ tableView: UITableVIew,
    numberOfRowsInSection section: Int) -> Int

  func tableView(
    _ tableView: UITableView,
    cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
}
```


### A Simple Example
```swift
class MyController : UIViewController, UITableViewDataSource {
  let coffees = ["Flat White", "Cappuccino", "Americano"]

  override func loadView() {
    super.loadView()
    let tableView = UITableView()
    tableView.dataSource = self
    tableView.registerClass(UITableViewCell.self,
      forCellReuseIdentifier: "Cell")
    // visual layout and other setup
  }
```
```swift
  func tableView(_ tableView: UITableView,
    numberOfRowsInSection section: Int) -> Int {
    return coffees.count
  }

  func tableView(_ tableView: UITableView,
    cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
    cell.textLabel?.text = coffees[indexPath.row]
    return cell
  }
}
```


## UIStackView
Stack View is way simpler to use, and more useful for static data. It represents a vertical or horizontal stack of views.

```swift
class MyController : UIViewController {
  let coffees = ["Flat White", "Cappuccino", "Americano"]

  func loadView() {
    super.loadView()
    let coffeeViews = coffees.map { coffee->UIView in
        let label = UILabel()
        label.text = coffee
        return label
    }

    let stackView = UIStackView(arrangedSubviews: coffeeViews)
    stackView.axis = .Vertical
    // visual layout and other setup
  }
}
```


## UINavigationController

![](/images/navigation-controller.png)


### For Example
```swift
let viewController = UIViewController()
let navigationController = UINavigationController(rootViewController: viewController)
// after rendering, viewController will be shown inside navigationController

let secondViewController = UIViewController()
navigationController
  .pushViewController(secondViewController, animated: true)
// now, after rendering secondViewController will be displayed

navigationController.popViewController(true)
// now viewController is displayed again
```


## AutoLayout


### Prior to AutoLayout
Autolayout was introduced in iOS 6

Prior to Autolayout, all views needed to be manually laid out by specifying their position and size within their parent.

```swift
let child = View(frame: CGRectMake(25.0, 25.0, 50.0, 100.0))
view.addSubview(child)
```
This creates a view located at (25,25) that is 50 pixels wide and 100 pixels high.

This is fine as long as everything is simple (like, one screen size, one orientation). But when you have multiple views, multiple screen sizes and multiple orientation, it gets more complex.


### Enter AutoLayout
AutoLayout is essentially a relational position engine. You specify relationships between views, and AutoLayout calculates the resulting positions of the views.

This happens as part of a layout step after the views are created and added to the view hierarchy.

AutoLayout is really powerful and you should definitely use it.

How?


### How to AutoLayout

I could describe the AutoLayout API to you if you want to do things like this:
```swift
addConstraint(NSLayoutConstraint(
    item: button1,
    attribute: .Right,
    relatedBy: .Equal,
    toItem: button2,
    attribute: .Left,
    multiplier: 1.0,
    constant: -12.0
))
```
But the API sucks as you can see, so we should use a library to abstract that away.


### Cartography

Cartography is my go-to choice for autolayout, but there are many many choices.

Cartography is on github at `robb/Cartography`.


### For Example

```swift
let child = View(frame: CGRectZero)
view.addSubview(child)
constrain(child) { view in
  view.edges == view.superview!.edges
}
```
Now, the child will have the same edges as the parent
1. we no longer care about the initial frame (so we set it to zero), because it gets set by AutoLayout later
2. add the subview before creating constraints (or the `superview!` expression will fail)
3. set up constraints in the `loadView()` method of your ViewControllers or in the `init()` method of your views.



## Package Management
Cocoapods v Carthage


### Cocoapods
* Works with all versions of iOS
* Written in Ruby
* Integrates tightly with XCode - (it creates a workspace for you)
* Centralized package index at cocoapods.org


### Carthage
* Works with iOS 8.0 and above
* Written in Swift
* Not tightly coupled to XCode
* Distributed package manager - typically download directly from github


Carthage is probably the way of the future, but I've used cocoapods most, and it seems to be more of the industry standard at this point.


### List of great libraries
* PromiseKit
* Quick / Nimble (test and BDD expectations framework)
* ReactiveKit
* Cartography (autolayout library)
* SwiftyJSON
* OAStackView (as a backfill for UIStackView)
* AlamoFire (networking library)
* OHHTTPStubs (stubbing for HTTP requests for testing)



# Testing


## Unit Tests
Quick and Nimble sit on top of XCTest which is XCode's test framework, which isn't great.

I like to split my code into tested code in an "AppKit" that is decoupled from iOS core libraries, and an "App" that is the view code and all the iOS dependent stuff that is harder to test.


### Stubbing
Since Swift is static, and has no reflection, it is not possible (without hacking) to dynamically create stub objects.

Therefore, we are forced to create our own stubs.


For example:

Say we have a CoffeeListViewModel which gets a list of coffees from a CoffeeService and then sorts them for presentation:
```swift
class CoffeeListViewModel {
  let coffeeService : CoffeeService

  init(coffeeService: CoffeeService) {
    self.coffeeService = coffeeService
  }

  func sortedCoffees(callback: ([Coffee])->()) {
    coffeeService.get { coffees in
      callback(coffees.sort())
    }
  }
}
```


We need to manually stub the CoffeeService:
```swift
class StubCoffeeService : CoffeeService {
  var getCallCount = 0

  func get(callback: ([Coffee])->()) {
    getCallCount += 1
    callback([Coffee()])
  }
}
```


## Application Structure for Testability


![](/images/ios-mvvm.svg)


## Continuous Integration
Setting up CI for mobile devices is not that easy. The main problem is Apple itself, who continually change their APIs seemingly without warning - to disastrous effect. It's hard to keep up with the pace of change. So, new xcode releases will break things, and updates to iTunes Connect will break things. Just get ready for that. But there are lots of tools to help.


### Problems you will want to solve
* Report unit tests and UI tests success and failure for latest builds
* Run integration and contract tests for latest builds against the rest of your APIs
* Distribute your application to testers
* Upload builds to the app store


### Run your unit and integration tests
* Run your own server (not recommended) or
* Pick any third party CI service (circleci, greenhouse, travis.ci, bitrise, buddybuild, etc...)
* Have your CI connect to your APIs to run integration tests.


### Distribute your application to testers
Options:
* Apple TestFlight (recommended)
* Use Ad-hoc or developer certificate and manually install on devices
* HockeyApp or other third party tool

I recommend using fastlane to upload builds to testflight after successful builds.


### Upload builds to app store
You'll need to take screenshots of your app



# XCode


XCode is a mixed bag - some people choose not to use it except where completely necessary. I'll take you through the basics in a demo.


## Storyboards


### Storyboards give you:
* Quick, visual layout
* Some limited transitions
* A toolbox of available components
* Autolayout for creating constraints between visual items
* Not much else.


### Storyboard issues:
* Merge conflicts when collaborating (storyboard is a giant, hard to read XML file)
* Lack of a consistent way to apply styling
* Large storyboards load really slowly


### My Advice: Avoid Storyboards for big projects

Build everything programmtically.  

It may seem painful at first, but you get:
* Components and styles that can be used app wide
* Consistency - everything is in code
* No merge conflicts - keep everything in small, single responsibility files
* Less reliance on xcode user-interface (you will learn this is good)



# Provisioning and Deployment


![](/images/signing-process.svg)


## There are tools to help you automate the signing and deployment process

Xcode can handle your distribution and deployment but it can be cumbersome for a team and a very manual process.
Fastlane is probably the best and most widely used tool - it can handle most aspects of your build and distribution.



# Crash reporting and analytics
You will want to know how much your app is crashing in the wild.


## How crash reporting works


![](/images/ios-crash-reporting.svg)


When an app crashes, iOS deposits a crash log (including a binary __stack trace__) on the device.

Next time the app starts a crash reporting tool can extract that crash log and report back to a central server.

There, the binary stack trace is matched with the source code (via a process called __symbolication__) where you can view a nice stack trace of all the crashes, and see where your app sucks the most.


Apple provides some built in functionality, but I have not used it, so I don't know how good it is.

Other tools include  Crashlytics, Splunk, and many others. Crashlytics is probably the most widely used (it's from Twitter)



# Thanks

**Will James**

**wjames@thoughtworks.com**
