//: [Previous](@previous)

import Foundation

enum NodeResult {
    case success, failure, panic(Error)
}

enum NodeState {
    case idle, running, succeeded, failed, panicked, canceled
}

protocol Node: class {
    var state: NodeState {get set}
    var label: String { get }
    func execute(callback: @escaping (NodeResult) -> ())
    func cancel()
    func accept(visitor: NodeVisitor)
}

extension Node {
    var label: String {
        return "\(type(of: self))"
    }
    func cancel() {
        state = .canceled
    }
    func accept(visitor: NodeVisitor) {
        visitor.visit(node: self, children: [])
    }
}

protocol NodeVisitor: class {
    func visit(node: Node, children: [Node])
}

class AsciiExporter: NodeVisitor {
    public static func asciiString(root: Node, runningPathOnly: Bool = false) -> String {
        let exporter = AsciiExporter()
        exporter.runningPathOnly = runningPathOnly

        root.accept(visitor: exporter)

        return exporter.asciiString()
    }

    private var lines: [String] = []
    private var indent = 0
    public var runningPathOnly: Bool = false

    public init() {}

    public func visit(node: Node, children: [Node]) {
        addLine(string: "\(node.label) \(stateIcon(node))")

        guard runningPathOnly == false || node.state == .running else { return }

        indent += 1
        for child in children {
            child.accept(visitor: self)
        }

        indent -= 1
    }

    private func addLine(string: String) {
        var indentString = ""
        for _ in 0..<indent {
            indentString.append("  ")
        }

        if indent > 0 {
            indentString.append("➥")
        }

        lines.append("\(indentString)\(string)")
    }

    private func stateIcon(_ node: Node) -> String {
        switch node.state {
        case .idle:
            return "⚫️"

        case .running:
            return "🔵"

        case .succeeded:
            return "✅"

        case .failed:
            return "🔴"

        case .panicked:
            return "💩"

        case .canceled:
            return "🔶"
        }
    }

    public func asciiString() -> String {
        return lines.joined(separator: "\n")
    }
}



class Frame {
    var currentHour: Int?
    var output: (String) -> () = { print($0) }
    init() {}
}

enum MyError: Error {
    case currentHourIsNotSet
    case unexpectedValueAsCurrentHour
}

class ComputeHourAction: Node {
    let frame: Frame
    var state: NodeState = .idle
    init(frame: Frame) {
        self.frame = frame
    }
    func execute(callback: @escaping (NodeResult) -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
            self?.frame.currentHour = Calendar.current.component(.hour, from: Date())
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                callback(.success)
            }
        }
    }
}

class CheckHourAction: Node {
    let frame: Frame
    var state: NodeState = .idle
    init(frame: Frame) {
        self.frame = frame
    }
    func execute(callback: @escaping (NodeResult) -> ()) {
        guard let hour = frame.currentHour else {
            callback(.panic(MyError.currentHourIsNotSet))
            return
        }
        if hour < 0 || hour > 24 {
            callback(.panic(MyError.unexpectedValueAsCurrentHour))
            return
        }
        callback(.success)
    }
}

class SayAction: Node {
    let frame: Frame
    let message: String
    var state: NodeState = .idle
    init(message: String, frame: Frame) {
        self.frame = frame
        self.message = message
    }
    func execute(callback: @escaping (NodeResult) -> ()) {
        frame.output(message)
        callback(.success)
    }
    var label: String {
        return "Say: \(message)"
    }
}

class Condition: Node {
    let predicate: () -> Bool
    var state: NodeState = .idle
    init(_ predicate: @escaping @autoclosure () -> Bool) {
        self.predicate = predicate
    }
    func cancel() {
        state = .canceled
    }
    func execute(callback: @escaping (NodeResult) -> ()) {
        predicate() ? callback(.success) : callback(.failure)
    }
}

class SelectorNode: Node {
    let nodes: [Node]
    var state: NodeState = .idle
    init(nodes: [Node]) {
        self.nodes = nodes
    }
    func cancel() {
        state = .canceled
        for node in nodes where node.state == .idle {
            node.cancel()
        }
    }
    func execute(callback: @escaping (NodeResult) -> ()) {
        var index = 0
        func callNext () {
            func cancelNotExecuted() {
                guard (index + 1) < nodes.count else { return }
                for i in (index + 1)..<nodes.count {
                    nodes[i].cancel()
                }
            }
            guard state != .canceled else {
                cancelNotExecuted()
                return
            }
            guard index < nodes.count else {
                cancelNotExecuted()
                callback(.failure)
                return
            }
            let node = nodes[index]
            node.state = .running
            node.execute {
                switch $0 {
                case .success:
                    node.state = .succeeded
                    cancelNotExecuted()
                    callback($0)
                case .panic:
                    node.state = .panicked
                    cancelNotExecuted()
                    callback($0)
                case .failure:
                    node.state = .failed
                    index += 1
                    callNext()
                }
            }
        }

        return callNext()
    }
    func accept(visitor: NodeVisitor) {
        visitor.visit(node: self, children: nodes)
    }
}

class SequenceNode: Node {
    let nodes: [Node]
    var state: NodeState = .idle
    init(nodes: [Node]) {
        self.nodes = nodes
    }
    func cancel() {
        state = .canceled
        for node in nodes where node.state == .idle {
            node.cancel()
        }
    }
    func execute(callback: @escaping (NodeResult) -> ()) {
        var index = 0
        func callNext () {
            func cancelNotExecuted() {
                guard (index + 1) < nodes.count else { return }
                for i in (index + 1)..<nodes.count {
                    nodes[i].cancel()
                }
            }
            guard index < nodes.count else {
                cancelNotExecuted()
                callback(index > 0 ? .success : .failure)
                return
            }
            let node = nodes[index]
            node.state = .running
            node.execute {
                switch $0 {
                case .failure:
                    node.state = .failed
                    cancelNotExecuted()
                    callback($0)
                case .panic:
                    node.state = .panicked
                    cancelNotExecuted()
                    callback($0)
                case .success:
                    node.state = .succeeded
                    index += 1
                    callNext()
                }
            }
        }

        return callNext()
    }
    func accept(visitor: NodeVisitor) {
        visitor.visit(node: self, children: nodes)
    }
}

let frame = Frame()

let greetings = SelectorNode(nodes: [
    SequenceNode(nodes: [
        Condition(frame.currentHour != nil && (frame.currentHour! < 6 || frame.currentHour! == 24)),
        SayAction(message: "What are you doing up?", frame: frame)
    ]),
    SequenceNode(nodes: [
        Condition(frame.currentHour != nil && frame.currentHour! >= 6 && frame.currentHour! <= 11),
        SayAction(message: "Good morning", frame: frame)
    ]),
    SequenceNode(nodes: [
        Condition(frame.currentHour != nil && frame.currentHour! >= 12 && frame.currentHour! <= 17),
        SayAction(message: "Good Day", frame: frame)
    ]),
    SequenceNode(nodes: [
        Condition( frame.currentHour != nil && frame.currentHour! >= 18 && frame.currentHour! <= 20),
        SayAction(message: "Good Evening", frame: frame)
    ]),
    SequenceNode(nodes: [
        Condition( frame.currentHour != nil && frame.currentHour! >= 21 && frame.currentHour! <= 23),
        SayAction(message: "Good Night", frame: frame)
    ])
])

let root = SequenceNode(nodes: [
    ComputeHourAction(frame: frame),
    CheckHourAction(frame: frame),
    greetings
])

import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

root.state = .running
root.execute {
    switch $0 {
    case .success:
        root.state = .succeeded
    case .failure:
        root.state = .failed
    case .panic:
        root.state = .panicked
    }
    print(AsciiExporter.asciiString(root: root))
    print("------------")
    print(AsciiExporter.asciiString(root: root, runningPathOnly: true))
    PlaygroundPage.current.finishExecution()
}

frame.currentHour = 24
greetings.execute {
    print($0)
}

frame.currentHour = -1

CheckHourAction(frame: frame).execute {
    print($0)
}

frame.currentHour = nil

CheckHourAction(frame: frame).execute {
    print($0)
}

//: [Next](@next)
