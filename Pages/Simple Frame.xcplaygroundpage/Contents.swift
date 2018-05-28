//: [Previous](@previous)

import Foundation

enum NodeResult {
    case success, failure
}

typealias Node = () -> NodeResult

class Frame {
    var currentHour: Int?
    var output: (String) -> () = { print($0)}
    init() {}
}

func computeHour(frame: Frame) -> Node {
    return {
        frame.currentHour = Calendar.current.component(.hour, from: Date())
        return .success
    }
}

func sayGoodMorning(frame: Frame) -> Node {
    return {
        guard let hour = frame.currentHour else { return .failure }
        switch hour {
        case 6...11:
            frame.output("Good Morning")
            return .success
        default:
            return .failure
        }
    }
}

func sayGoodDay(frame: Frame) -> Node {
    return {
        guard let hour = frame.currentHour else { return .failure }
        switch hour {
        case 12...17:
            frame.output("Good Day")
            return .success
        default:
            return .failure
        }
    }
}

func sayGoodEvening(frame: Frame) -> Node {
    return {
        guard let hour = frame.currentHour else { return .failure }
        switch hour {
        case 18...20:
            frame.output("Good Evening")
            return .success
        default:
            return .failure
        }
    }
}

func sayGoodNight(frame: Frame) -> Node {
    return {
        guard let hour = frame.currentHour else { return .failure }
        switch hour {
        case 21...23:
            frame.output("Good Night")
            return .success
        default:
            return .failure
        }
    }

}

func sayWhatAreYouDoingUp(frame: Frame) -> Node {
    return {
        guard let hour = frame.currentHour else { return .failure }
        switch hour {
        case 6...23:
            return .failure
        default:
            frame.output("What are you doing up?")
            return .success
        }
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
    sayWhatAreYouDoingUp(frame: frame),
    sayGoodMorning(frame: frame),
    sayGoodDay(frame: frame),
    sayGoodEvening(frame: frame),
    sayGoodNight(frame: frame)
])

let root = sequence(nodes: [
    computeHour(frame: frame),
    greetings
])

root()

frame.currentHour = 13

greetings()

//: [Next](@next)
