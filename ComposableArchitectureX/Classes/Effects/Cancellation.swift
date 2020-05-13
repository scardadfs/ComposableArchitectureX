//
//  Cancellation.swift
//  ComposableArchitectureX

import Foundation
import RxSwift

extension Effect {
    public func cancellable(
        id: AnyHashable,
        cancelInFlight: Bool = false
    ) -> Effect {
        return Observable.deferred {
            let subject = PublishSubject<Element>()
            let uuid = UUID()
            var isCleaningUp = false

            cancellablesLock.sync {
                if cancelInFlight {
                    cancellationCancellables[id]?.forEach { _, cancellable in cancellable.dispose() }
                    cancellationCancellables[id] = nil
                }

                let cancellable = self.subscribe(subject)

                cancellationCancellables[id] = cancellationCancellables[id] ?? [:]
                cancellationCancellables[id]?[uuid] = Disposables.create {
                    cancellable.dispose()
                    if !isCleaningUp {
                        subject.onCompleted()
                    }
                }
            }

            func cleanup() {
                isCleaningUp = true
                cancellablesLock.sync {
                    cancellationCancellables[id]?[uuid] = nil
                    if cancellationCancellables[id]?.isEmpty == true {
                        cancellationCancellables[id] = nil
                    }
                }
            }

            return subject.do(onDispose: cleanup)
        }
        .eraseToEffect()
    }
}

var cancellationCancellables: [AnyHashable: [UUID: Disposable]] = [:]
let cancellablesLock = NSRecursiveLock()
