//
//  Effect.swift
//

import Foundation
import RxSwift

public struct Effect<Element>: ObservableType {
    let _source: Observable<Element>

    public init(_ source: Observable<Element>) {
        _source = source
    }

    public init(value: Element) {
        self.init(.just(value))
    }

    public func subscribe<Observer>(
        _ observer: Observer
    ) -> Disposable where Observer: ObserverType, Element == Observer.Element {
        _source.subscribe(observer)
    }

    public static var none: Effect {
        Observable.empty().eraseToEffect()
    }

    public static func merge<S: Sequence>(_ effects: S) -> Effect where S.Element == Effect {
        Observable.merge(effects.map { $0.asObservable() }).eraseToEffect()
    }

    public func map<T>(_ transform: @escaping (Element) -> T) -> Effect<T> {
        .init(map(transform))
    }

    public static func future(
        work: @escaping (@escaping (Result<Element, Error>) -> Void) -> Void
    ) -> Effect {
        Observable.deferred {
            Observable.create { observer -> Disposable in
                work { result in
                    do {
                        let element = try result.get()
                        observer.onNext(element)
                        observer.onCompleted()
                    } catch {
                        observer.onError(error)
                    }
                }
                return Disposables.create()
            }
        }
        .eraseToEffect()
    }

    public func result(_ work: @escaping () -> Result<Element, Error>) -> Self {
        Observable.deferred {
            Observable.create { (observer: AnyObserver<Element>) -> Disposable in
                let result = work()
                do {
                    let element = try result.get()
                    observer.onNext(element)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
                return Disposables.create()
            }
        }
        .eraseToEffect()
    }

    public static func async(
        _ run: @escaping (Effect.Observer<Element>) -> Disposable
    ) -> Self {
        Observable.createWithEffectObserverCallback(run).eraseToEffect()
    }

    public static func concatenate(_ effects: Effect...) -> Effect {
        .concatenate(effects)
    }

    public static func concatenate<C: Collection>(
        _ effects: C
    ) -> Effect where C.Element == Effect {
        guard let first = effects.first else { return .none }
        return effects
            .suffix(effects.count - 1)
            .reduce(into: first) { effects, effect in
                effects = effects.concat(effect).eraseToEffect()
            }
    }

    public static func fireAndForget(work: @escaping () -> Void) -> Effect {
        Observable.deferred {
            work()
            return Observable.empty()
        }
        .eraseToEffect()
    }

    public static func sync(_ work: @escaping () throws -> Element) -> Self {
        .future { $0(Result { try work() }) }
    }
}

extension Effect where Element == Never {
    public func fireAndForget<T>() -> Effect<T> {
        func absurd<A>(_: Never) -> A {}
        return map(absurd)
    }
}

extension Observable {
    static func createWithEffectObserverCallback(
        _ factory: @escaping (Effect<Element>.Observer<Element>) -> Disposable
    ) -> Observable<Element> {
        Observable.create { (observer: AnyObserver<Element>) in
            let effect = Effect<Element>.Observer<Element>(
                send: { element in
                    observer.onNext(element)
                },
                complete: {
                    observer.onCompleted()
                },
                error: { error in
                    observer.onError(error)
                }
            )

            return factory(effect)
        }
    }
}

extension Effect {
    public struct Observer<Element> {
        private let _send: (Element) -> Void
        private let _complete: () -> Void
        private let _error: (Error) -> Void

        init(
            send: @escaping (Element) -> Void,
            complete: @escaping () -> Void,
            error: @escaping (Error) -> Void
        ) {
            _send = send
            _complete = complete
            _error = error
        }

        public func send(_ input: Element) {
            _send(input)
        }

        public func sendCompleted() {
            _complete()
        }

        public func sendError(_ input: Error) {
            _error(input)
        }
    }
}

extension ObservableType {
    public func eraseToEffect() -> Effect<Element> {
        return Effect(asObservable())
    }

    public func catchToEffect() -> Effect<Result<Element, Error>> {
        map(Result.success)
            .catchError { .just(.failure($0)) }
            .eraseToEffect()
    }
}
