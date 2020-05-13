//
//  Reducer.swift
//

import Foundation

public struct Reducer<State, Action, Environment> {
    private let reducer: (inout State, Action, Environment) -> Effect<Action>

    public init(
        _ reducer: @escaping (inout State, Action, Environment) -> Effect<Action>) {
        self.reducer = reducer
    }

    public static var empty: Reducer {
        Self { _, _, _ in .none }
    }

    public static func combine(_ reducers: [Reducer]) -> Reducer {
        Self { value, action, environment in
            .merge(reducers.map { $0.reducer(&value, action, environment) })
        }
    }

    public static func combine(_ reducers: Reducer...) -> Reducer {
        .combine(reducers)
    }

    public func pullpack<GlobalState, GlobalAction, GlobalEnviroment>(
        state toLocalState: WritableKeyPath<GlobalState, State>,
        action toLocalAction: CasePath<GlobalAction, Action>,
        environment toLocalEnvironment: @escaping (GlobalEnviroment) -> Environment
    ) -> Reducer<GlobalState, GlobalAction, GlobalEnviroment> {
        .init { globalState, globalAction, globalEnviroment in
            guard let localAction = toLocalAction.extract(from: globalAction) else { return .none }
            return self.reducer(
                &globalState[keyPath: toLocalState],
                localAction,
                toLocalEnvironment(globalEnviroment)
            )
            .map(toLocalAction.embed)
        }
    }

    public func forEach<GlobalState, GlobalAction, GlobalEnvironment>(
        state toLocalState: WritableKeyPath<GlobalState, [State]>,
        action toLocalAction: CasePath<GlobalAction, (Int, Action)>,
        environment toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment
    ) -> Reducer<GlobalState, GlobalAction, GlobalEnvironment> {
        .init { globalState, globalAction, globalEnvironment in
            guard let (index, localAction) = toLocalAction.extract(from: globalAction) else {
                return .none
            }
            return self.reducer(
                &globalState[keyPath: toLocalState][index],
                localAction,
                toLocalEnvironment(globalEnvironment)
            )
            .map { toLocalAction.embed((index, $0)) }
        }
    }

    public func forEach<GlobalState, GlobalAction, GlobalEnvironment, Key>(
        state toLocalState: WritableKeyPath<GlobalState, [Key: State]>,
        action toLocalAction: CasePath<GlobalAction, (Key, Action)>,
        environment toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment
    ) -> Reducer<GlobalState, GlobalAction, GlobalEnvironment> {
        .init { globalState, globalAction, globalEnvironment in
            guard let (key, localAction) = toLocalAction.extract(from: globalAction) else {
                return .none
            }
            return self.optional
                .reducer(
                    &globalState[keyPath: toLocalState][key],
                    localAction,
                    toLocalEnvironment(globalEnvironment)
                )
                .map { toLocalAction.embed((key, $0)) }
        }
    }

    public func callAsFunction(
        _ state: inout State,
        _ action: Action,
        _ environment: Environment
    ) -> Effect<Action> {
        reducer(&state, action, environment)
    }

    public var optional: Reducer<State?, Action, Environment> {
        .init { state, action, environment in
            guard state != nil else { return .none }
            return self.callAsFunction(&state!, action, environment)
        }
    }
}

extension Reducer where Environment == Void {
    public func callAsFunction(
        _ state: inout State,
        _ action: Action
    ) -> Effect<Action> {
        reducer(&state, action, ())
    }
}
