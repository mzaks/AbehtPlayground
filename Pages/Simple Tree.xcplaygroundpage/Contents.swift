//: Playground - noun: a place where people can play

import Foundation

enum NodeResult {
    case success, failure
}

typealias Node = () -> NodeResult

func greetings() -> NodeResult {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 6...11:
        print("Good Morning")
        return .success
    case 12...17:
        print("Good Day")
        return .success
    case 18...20:
        print("Good Evening")
        return .success
    case 21...23:
        print("Good Night")
        return .success
    default:
        print("What are you doing up?")
        return .success
    }
}

func sayGoodMorning() -> NodeResult {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 6...11:
        print("Good Morning")
        return .success
    default:
        return .failure
    }
}

func sayGoodDay() -> NodeResult {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 12...17:
        print("Good Day")
        return .success
    default:
        return .failure
    }
}

func sayGoodEvening() -> NodeResult {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 18...20:
        print("Good Evening")
        return .success
    default:
        return .failure
    }
}

func sayGoodNight() -> NodeResult {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 21...23:
        print("Good Night")
        return .success
    default:
        return .failure
    }
}

func sayWhatAreYouDoingUp() -> NodeResult {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 6...23:
        return .failure
    default:
        print("What are you doing up?")
        return .success
    }
}

func selector(nodes: [Node]) -> Node {
    return {
        for node in nodes {
            let result = node()
            if result == .success {
                return result
            }
        }
        return .failure
    }
}

let root = selector(nodes: [
    sayWhatAreYouDoingUp,
    sayGoodMorning,
    sayGoodDay,
    sayGoodNight,
    sayGoodEvening
])

root()

greetings()
