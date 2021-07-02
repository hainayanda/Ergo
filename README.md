# Ergo

Ergo is a framework for concurrent programming based on promise pipelining. It could help to avoid callback hell in complex asynchronous task

[![codebeat badge](https://codebeat.co/badges/b3e8f99e-dc71-47cd-b35a-a1293375d598)](https://codebeat.co/projects/github-com-nayanda1-ergo-main)
![build](https://github.com/nayanda1/Ergo/workflows/build/badge.svg)
![test](https://github.com/nayanda1/Ergo/workflows/test/badge.svg)
[![SwiftPM Compatible](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen)](https://swift.org/package-manager/)
[![Version](https://img.shields.io/cocoapods/v/Ergo.svg?style=flat)](https://cocoapods.org/pods/Ergo)
[![License](https://img.shields.io/cocoapods/l/Ergo.svg?style=flat)](https://cocoapods.org/pods/Ergo)
[![Platform](https://img.shields.io/cocoapods/p/Ergo.svg?style=flat)](https://cocoapods.org/pods/Ergo)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- Swift 5.0 or higher (or 5.3 when using Swift Package Manager)
- iOS 10 or higher

### Only Swift Package Manager

- macOS 10.10 or higher
- tvOS 10 or higher

## Installation

### Cocoapods

Ergo is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'Ergo', '~> 1.0.2'
```

### Swift Package Manager from XCode

- Add it using XCode menu **File > Swift Package > Add Package Dependency**
- Add **https://github.com/nayanda1/Ergo.git** as Swift Package URL
- Set rules at **version**, with **Up to Next Major** option and put **1.0.2** as its version
- Click next and wait

### Swift Package Manager from Package.swift

Add as your target dependency in **Package.swift**

```swift
dependencies: [
  .package(url: "https://github.com/nayanda1/Ergo.git", .upToNextMajor(from: "1.0.2"))
]
```

Use it in your target as `Ergo`

```swift
 .target(
  name: "MyModule",
  dependencies: ["Ergo"]
)
```

## Author

Nayanda Haberty, nayanda1@outlook.com

## License

Impose is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Basic Usage

Ergo utilize the `Thenable` protocol which is implemented in the `Promise` class that acts as a proxy for the concurrent task. To create a concurrent task in Promise, just call the `runPromise` global method with any task you want to run:

```swift
runPromise {
  print("I'm running in the DispatchQueue.global(qos: .background)")
}
```

you can pass `DispatchQueue` to run on those queue:

```swift
runPromise(on: .main) {
  print("I'm running in the DispatchQueue.main")
}
```

### Chaining Promises

`Promise` designed to be chainable with other `Promise`. To chain it, simply call `then` after each `Promise`:

```swift
runPromise {
  print("I'm running in the DispatchQueue.global(qos: .background)")
}.then {
  print("I'm running on the same DispatchQueue as previous")
}.then(on: .main) {
  print("I'm running in the DispatchQueue.main")
}
```

You can chain it as much as you need. All of the chaining `Promise` will be released from the chain after it's finished doing its task.

You can also pass a value from one `Promise` to another so it could be used there:

```swift
runPromise {
  return "from first promise"
}.then { fromPrevious -> String in
  print(fromPrevious)
  return "from second promise"
}.then(on: .main) { fromPrevious in
  print(fromPrevious)
}
```

In the example above, the return value from the first `Promise` will be passed to the second `Promise`, and so on.

### Handling Error

`Promise` closure is throwable by default. You could always throw an error in the `Promise` closure to stop next `Thenable` to be executed

```swift
runPromise {
  print("no error here")
}.then {
  throw MyError()
}.then(on: .main) { 
  print("this line will not be executed because previous closure throw an error")
}
```

You can add error handler closure after then to catch the error and do something with it:

```swift
runPromise {
  print("no error here")
}.then {
  throw MyError()
}.handle {
  print($0)
  print("this line will executed with error throwed")
}.then(on: .main) { 
  print("this line will not be executed because previous closure throw an error")
}.handle {
  print($0)
  print("this line will executed with previous error throwed")
}
```

The error throws from `Promise` will always passed into all of its child `Promise`

### Finally Block

`Promise` have finally block which will always be executed regarding error or not the previous `Promise` is. It will produce another promise which will called after finally is executed:

```swift
runPromise {
  print("no error here")
}.then {
  throw MyError()
}.then(on: .main) { 
  print("this line will not be executed because previous closure throw an error")
}.finally { result, error in
  print("this line be executed. Result will be nil and error will be MyError")
}.then {
  print("this line will be executed after finally block finished")
}.finally { result, error in
  print("this line always be executed after all promise is done")
}
```

### Droping a promise

`Promise` can be dropped by calling the `drop` method. It will then emit an error and skip the current task if not finished yet. 
You can always pass custom errors when dropping so it will emit that error instead of the default one.

```swift
let promise = runPromise {
    print("will be dropped")
}

promise.drop()
```

Keep in mind that this will only drop the current `Promise`. `finally` block and `handle` block will still be called:

```swift
let promise = runPromise {
    print("will not be dropped")
}.then {
    print("will be dropped")
}.handle { error in
    print("will still be executed")
}.finally { result, error in
    print("will still be executed")
}

promise.drop()
```

### Combining Promises

You can combine up to 3 `Promise` to be a single `Promise` of `Tuple` as a Result:

```swift
let firstPromise = runPromise {
  return "from first Promise"
}
let secondPromise = runPromise {
  return "from second Promise"
}

waitPromises(from: firstPromise, secondPromise).then { result in
  // will print "from first Promise, from second Promise"
  print("\(result.1),\(result.2)")
}
```

Since `waitPromises` actually just return back a `Promise` of `Tuple`, you can always treat it as regular `Promise`

### Promise status

You can always check the `Promise` status using its object. its have some properties you can check:
- `result` which is the latest result from the task, will be nil if the task is not finished yet
- `error` which is the latest error from the task, will be nil if the task did not emit an error yet
- `currentQueue` which is the current DispatchQueue that run the task
- `isCompleted` will be true if the task is complete or emitting an error
- `isError` will be true the task emitting error

```swift
let promise = runPromise {
  print("I'm running in the DispatchQueue.global(qos: .background)")
}.then {
  print("I'm running on the same DispatchQueue as previous")
}

print(promise.isCompleted)
```

### Creating Promise with asynchronous task

Sometimes the task you want to convert to Promise is already an asynchronous task. In this case, you can use `asyncPromise` instead of `runPromise`:

```swift
asyncPromise(on: .main) { done in
  doSomethingAsync { result, error in
    done(result, error)
  }
}.then { result in
  print(result)
}.handle { error in
  print(error)
}
```

It will emit an error if `done` param is getting a nil result, or an error other than nil. If the result is not nil, it will run the next `Promise` task
The result of the `asyncPromise` is `Promise`, so you can always treat it as a regular `Promise`

## Chain Animation (iOS only)

You can run animation using `ChainAnimator` which can be chain like `Promise`:

```swift
UIView.chainAnimate(withDuration 0.2)
  .animation {
    view.alpha = 0.5
  }.chain(withDuration: 0.2) {
    view.alpha = 1
  }.animate()
```

It will run animation from the first one and proceed to the next one after the last one is finished. You can chain as much animation as you need.
The result of animate is `Promise` of `Bool`. the `Bool` result will be true if all of the animation is succeed:

```swift
UIView.chainAnimate(withDuration 0.2)
  .animation {
    view.alpha = 0.5
  }.chain(withDuration: 0.2) {
    view.alpha = 1
  }.animate()
  .then { succeed in
    print(succeed)
  }
```

Since the result is regular `Promise`, you can always treat it as regular `Promise`

## Contribute

You know how, just clone and do pull request
