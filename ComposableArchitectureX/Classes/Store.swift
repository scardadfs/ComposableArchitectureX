//
//  Store.swift
//

import Foundation
import RxSwift

public final class Store<State, Action> {
    let state: BehaviorSubject<State>
    private let reducer: (inout State, Action) -> Effect<Action>
    private var parentDisposable: Disposable?
    private var isSending = false
    private var synchronousActionsToSend: [Action] = []
    var effectDisposables: [UUID: Disposable] = [:]

    private init(
        initialState: State,
        reducer: @escaping (inout State, Action) -> Effect<Action>
    ) {
        state = BehaviorSubject(value: initialState)
        self.reducer = reducer
    }

    public convenience init<Environment>(
        initialState: State,
        reducer: Reducer<State, Action, Environment>,
        environment: Environment
    ) {
        self.init(
            initialState: initialState,
            reducer: { reducer.callAsFunction(&$0, $1, environment) }
        )
    }

    public func scope<LocalState, LocalAction>(
        state toLocalState: @escaping (State) -> LocalState,
        action fromLocalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalState, LocalAction> {
        let localStore = Store<LocalState, LocalAction>(
            initialState: toLocalState(try! state.value()),
            reducer: { localState, localAction in
                self.send(fromLocalAction(localAction))
                localState = toLocalState(try! self.state.value())
                return .none
            }
        )

        localStore.parentDisposable = state
            .skip(1)
            .subscribe(onNext: { state in
                localStore.state.onNext(toLocalState(state))
            })
        return localStore
    }

    public func scope<LocalState>(
        state toLocalState: @escaping (State) -> LocalState
    ) -> Store<LocalState, Action> {
        scope(state: toLocalState, action: { $0 })
    }

    public func scope<O: ObservableType, LocalState, LocalAction>(
        state toLocalState: @escaping (Observable<State>) -> O,
        action fromLocalAction: @escaping (LocalAction) -> Action
    ) -> Observable<Store<LocalState, LocalAction>> where O.Element == LocalState {
        func extractLocalState(_ state: State) -> LocalState? {
            var localState: LocalState?
            _ = toLocalState(Observable.just(state))
                .subscribe(onNext: {
                    localState = $0
                })
            return localState
        }

        return toLocalState(state.asObservable())
            .map { localState in
                let localStore = Store<LocalState, LocalAction>(
                    initialState: localState,
                    reducer: { localState, localAction in
                        self.send(fromLocalAction(localAction))
                        localState = extractLocalState(try! self.state.value()) ?? localState
                        return .none
                    }
                )

                localStore.parentDisposable = self.state
                    .skip(1)
                    .subscribe(onNext: { [weak localStore] state in
                        guard let localStore = localStore else { return }
                        localStore.state.onNext(extractLocalState(state) ?? (try! localStore.state.value()))
                    })
                return localStore
            }
    }

    public func scope<O: ObservableType, LocalState>(
        state toLocalState: @escaping (Observable<State>) -> O
    ) -> Observable<Store<LocalState, Action>> where O.Element == LocalState {
        scope(state: toLocalState, action: { $0 })
    }

    func send(_ action: Action) {
        if isSending {
            assertionFailure(
                """
                The store was sent an action recursively. This can occur when you run an effect directly \
                in the reducer, rather than returning it from the reducer. Check the stack (⌘7) to find \
                frames corresponding to one of your reducers. That code should be refactored to not invoke \
                the effect directly.
                """
            )
        }

        isSending = true
        var state = try! self.state.value()
        let effect = reducer(&state, action)
        self.state.onNext(state)

        isSending = false

        var didComplete = false
        let uuid = UUID()

        var isProcessingEffects = true

        let onDisposed = { [weak self] in
            didComplete = true
            self?.effectDisposables[uuid] = nil
        }
        let effectDisposable = effect.subscribe(onNext: { [weak self] action in
            if isProcessingEffects {
                self?.synchronousActionsToSend.append(action)
            } else {
                self?.send(action)
            }
        }, onDisposed: onDisposed)

        isProcessingEffects = false

        if !didComplete {
            effectDisposables[uuid] = effectDisposable
        }

        while !synchronousActionsToSend.isEmpty {
            let action = synchronousActionsToSend.removeFirst()
            send(action)
        }
    }
}

@dynamicMemberLookup
public struct StoreObservable<State>: ObservableType {
    public typealias Element = State

    public let soucre: Observable<State>

    init<O>(_ source: O) where O: ObservableType, Element == O.Element {
        soucre = source.asObservable()
    }

    public func subscribe<Observer>(
        _ observer: Observer
    ) -> Disposable where Observer: ObserverType, Element == Observer.Element {
        soucre.subscribe(observer)
    }

    public subscript<LocalState>(
        dynamicMember keyPath: KeyPath<State, LocalState>
    ) -> StoreObservable<LocalState> where LocalState: Equatable {
        .init(soucre.map { $0[keyPath: keyPath] }.distinctUntilChanged())
    }
}

public final class ViewStore<State, Action> {
    public let observable: StoreObservable<State>
    private var disposable: Disposable?
    let state: BehaviorSubject<State>
    let _send: (Action) -> Void
    public init(
        _ store: Store<State, Action>,
        distinctUntilChanged comparer: @escaping (State, State) -> Bool
    ) {
        let observable = store.state.distinctUntilChanged(comparer)
        self.observable = StoreObservable(observable)
        state = BehaviorSubject(value: try! store.state.value())
        _send = store.send

        disposable = observable
            .subscribe(onNext: { [weak state] in
                state?.onNext($0)
            })
    }

    public func send(_ action: Action) {
        _send(action)
    }
}

extension ViewStore where State: Equatable {
    public convenience init(_ store: Store<State, Action>) {
        self.init(store, distinctUntilChanged: ==)
    }
}
