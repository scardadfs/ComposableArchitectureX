//
//  Throttling.swift
//  ComposableArchitectureX

import Foundation
import RxSwift

extension Effect {
    func throttle(
        id: AnyHashable,
        for interval: RxTimeInterval,
        scheduler: SchedulerType,
        latest: Bool
    ) -> Effect {
        flatMap { value -> Observable<Element> in
            guard let throttleTime = throttleTimes[id] as! RxTime? else {
                throttleTimes[id] = scheduler.now
                throttleValues[id] = nil
                return .just(value)
            }

            let distance = throttleTime.timeIntervalSince1970 - scheduler.now.timeIntervalSince1970
            guard distance < (interval.toDouble() ?? 0.0) else {
                throttleTimes[id] = scheduler.now
                throttleValues[id] = nil
                return .just(value)
            }

            let value = latest ? value : (throttleValues[id] as! Element? ?? value)

            let dueTime = scheduler.now.timeIntervalSince1970 - (throttleTime.timeIntervalSince1970 + (interval.toDouble() ?? 0))
            return Observable
                .just(value)
                .delay(.seconds(Int(dueTime)), scheduler: scheduler)
        }
        .eraseToEffect()
        .cancellable(id: id, cancelInFlight: true)
    }
}

var throttleTimes: [AnyHashable: Any] = [:]
var throttleValues: [AnyHashable: Any] = [:]

extension DispatchTimeInterval {
    func toDouble() -> Double? {
        var result: Double? = 0

        switch self {
        case let .seconds(value):
            result = Double(value)
        case let .milliseconds(value):
            result = Double(value) * 0.001
        case let .microseconds(value):
            result = Double(value) * 0.000001
        case let .nanoseconds(value):
            result = Double(value) * 0.000000001

        case .never:
            result = nil
        @unknown default:
            result = nil
        }

        return result
    }
}
