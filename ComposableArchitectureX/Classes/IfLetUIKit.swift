//
//  IfLetUIKit.swift
//

import RxSwift

extension Store {
    public func ifLet<Wrapped>(
        then unwrap: @escaping (Store<Wrapped, Action>) -> Void,
        else: @escaping () -> Void
    ) -> Disposable where State == Wrapped? {
        scope(
            state: { state in
                state
                    .distinctUntilChanged { ($0 != nil) == ($1 != nil) }
                    .do(onNext: { if $0 == nil { `else`() } })
                    .compactMap { $0 }
            },
            action: { $0 }
        )
        .subscribe(onNext: unwrap)
    }
}
