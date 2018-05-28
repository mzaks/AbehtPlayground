//: [Previous](@previous)

import Foundation

enum NodeResult {
    case success, failure
}

typealias Node = (@escaping (NodeResult) -> ()) -> ()

class Frame {
    var currentHour: Int?
    var output: (String) -> () = { print($0) }
    init() {}
}

func computeHour(frame: Frame) -> Node {
    return { callback in
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            frame.currentHour = Calendar.current.component(.hour, from: Date())
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                callback(.success)
            }
        }
    }
}

func say(message: String, frame: Frame) -> Node {
    return { callback in
        frame.output(message)
        callback(.success)
    }
}

func condition(_ predicat: @escaping @autoclosure () -> Bool) -> Node {
    return { callback in
        return predicat() ? callback(.success) : callback(.failure)
    }
}

func selector(nodes: [Node]) -> Node {
    return  { callback in
        var index = 0
        func callNext () {
            guard index < nodes.count else {
                callback(.failure)
                return
            }
            let node = nodes[index]
            node() {
                if $0 == .success {
                    callback($0)
                } else {
                    index += 1
                    callNext()
                }
            }
        }

        return callNext()
    }
}

func sequence(nodes: [Node]) -> Node {
    return { callback in
        var index = 0
        func callNext () {
            guard index < nodes.count else {
                callback(index > 0 ? .success : .failure)
                return
            }
            let node = nodes[index]
            node() {
                if $0 == .failure {
                    callback($0)
                } else {
                    index += 1
                    callNext()
                }
            }
        }

        return callNext()
    }
}

let frame = Frame()

let greetings = selector(nodes: [
    sequence(nodes: [
        condition(frame.currentHour != nil && (frame.currentHour! < 6 || frame.currentHour! == 24)),
        say(message: "What are you doing up?", frame: frame)
    ]),
    sequence(nodes: [
        condition(frame.currentHour != nil && frame.currentHour! >= 6 && frame.currentHour! <= 11),
        say(message: "Good morning", frame: frame)
    ]),
    sequence(nodes: [
        condition(frame.currentHour != nil && frame.currentHour! >= 12 && frame.currentHour! <= 17),
        say(message: "Good Day", frame: frame)
    ]),
    sequence(nodes: [
        condition( frame.currentHour != nil && frame.currentHour! >= 18 && frame.currentHour! <= 20),
        say(message: "Good Evening", frame: frame)
    ]),
    sequence(nodes: [
        condition( frame.currentHour != nil && frame.currentHour! >= 21 && frame.currentHour! <= 23),
        say(message: "Good Night", frame: frame)
    ])
])

let root = sequence(nodes: [
    computeHour(frame: frame),
    greetings
])

import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

root(){
    print($0)
    PlaygroundPage.current.finishExecution()
}

frame.currentHour = 24
greetings() {
    print($0)
}

//: [Next](@next)
