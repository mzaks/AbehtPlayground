//: [Previous](@previous)

import Foundation

enum NodeResult {
    case success, failure
}

typealias Node = () -> NodeResult

class Frame {
    var currentHour: Int?
    var output: (String) -> () = { print($0) }
    init() {}
}

func computeHour(frame: Frame) -> Node {
    return {
        frame.currentHour = Calendar.current.component(.hour, from: Date())
        return .success
    }
}

func say(message: String, frame: Frame) -> Node {
    return {
        frame.output(message)
        return .success
    }
}

func condition(_ predicat: @escaping @autoclosure () -> Bool) -> Node {
    return {
        return predicat() ? .success : .failure
    }
}

func selector(nodes: [Node]) -> Node {
    return  {
        for node in nodes {
            let result = node()
            if result == .success {
                return result
            }
        }
        return .failure
    }
}

func sequence(nodes: [Node]) -> Node {
    return {
        guard nodes.isEmpty == false else { return .failure }
        for node in nodes {
            let result = node()
            if result == .failure {
                return result
            }
        }
        return .success
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

root()

frame.currentHour = 24
greetings()

//: [Next](@next)
