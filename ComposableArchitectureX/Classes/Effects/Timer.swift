//
//  Timer.swift
//  ComposableArchitectureX

import Foundation
import RxSwift

extension Effect {
    public static func timer(
        id: AnyHashable,
        every interval: RxTimeInterval,
        on scheduler: SchedulerType
    ) -> Effect<RxTime> {
        Observable<RxTime>.deferred {
            let subject = PublishSubject<RxTime>()
            let cancellable = scheduler.schedulePeriodic(
                scheduler.now,
                startAfter: interval,
                period: interval
            ) { _ in
                subject.onNext(scheduler.now)
                return scheduler.now
            }
            return subject.do(onDispose: cancellable.dispose)
        }
        .eraseToEffect()
        .cancellable(id: id)
    }
}
