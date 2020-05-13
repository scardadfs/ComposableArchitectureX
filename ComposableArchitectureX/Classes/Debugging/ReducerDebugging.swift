//
//  ReducerDebugging.swift
//

import Dispatch

extension Reducer {
    public func debug(
        prefix: String = "",
        environment toDebugEnvironment: @escaping (Environment) -> DebugEnvironment = { _ in DebugEnvironment() }
    ) -> Reducer {
        debug(prefix: prefix, state: { $0 }, action: .self, environment: toDebugEnvironment)
    }

    public func debugActions(
        prefix: String = "",
        environment toDebugEnvironment: @escaping (Environment) -> DebugEnvironment = { _ in DebugEnvironment() }
    ) -> Reducer {
        debug(
            prefix: prefix,
            state: { _ in () },
            action: .self, environment: toDebugEnvironment
        )
    }

    public func debug<LocalState, LocalAction>(
        prefix: String = "",
        state toLocalState: @escaping (State) -> LocalState,
        action toLocalAction: CasePath<Action, LocalAction>,
        environment toDebugEnvironment: @escaping (Environment) -> DebugEnvironment = { _ in DebugEnvironment() }
    ) -> Reducer {
        #if DEBUG
            return .init { state, action, environment in
                let previousState = toLocalState(state)
                let effects = self.callAsFunction(&state, action, environment)
                guard let localAction = toLocalAction.extract(from: action) else { return effects }
                let nextState = toLocalState(state)
                let debugEnvironment = toDebugEnvironment(environment)
                return .concatenate(
                    .fireAndForget {
                        debugEnvironment.queue.async {
                            let actionOutput = debugOutput(localAction).indent(by: 2)
                            let stateOutput = debugDiff(previousState, nextState).map { "\($0)\n" } ?? "  (No state changes)"
                            debugEnvironment.printer(
                                """
                                \(prefix.isEmpty ? "" : "\(prefix): ")received action:
                                \(actionOutput)
                                \(stateOutput)
                                """
                            )
                        }
                    },
                    effects
                )
            }
        #else
            return .empty
        #endif
    }
}

public struct DebugEnvironment {
    public var printer: (String) -> Void
    public var queue: DispatchQueue

    public init(
        printer: @escaping (String) -> Void = { print($0) },
        queue: DispatchQueue
    ) {
        self.printer = printer
        self.queue = queue
    }

    public init(
        printer: @escaping (String) -> Void = { print($0) }
    ) {
        self.init(printer: printer, queue: _queue)
    }
}

private let _queue = DispatchQueue(
    label: "com.queue.ComposableArchitectureX",
    qos: .background
)
