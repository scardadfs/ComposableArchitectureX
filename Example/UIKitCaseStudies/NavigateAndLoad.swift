import ComposableArchitectureX
import RxSwift
import UIKit

struct EagerNavigationState: Equatable {
    var isNavigationActive = false
    var optionalCounter: CounterState?
}

enum EagerNavigationAction: Equatable {
    case optionalCounter(CounterAction)
    case setNavigation(isActive: Bool)
    case setNavigationIsActiveDelayCompleted
}

struct EagerNavigationEnvironment {
    var mainQueue: SchedulerType
}

let eagerNavigationReducer = Reducer<
    EagerNavigationState, EagerNavigationAction, EagerNavigationEnvironment
>.combine(
    Reducer { state, action, environment in
        switch action {
        case .setNavigation(isActive: true):
            state.isNavigationActive = true
            return Effect(value: .setNavigationIsActiveDelayCompleted)
                .delay(.seconds(1), scheduler: environment.mainQueue)
                .eraseToEffect()
        case .setNavigation(isActive: false):
            state.isNavigationActive = false
            state.optionalCounter = nil
            return .none
        case .setNavigationIsActiveDelayCompleted:
            state.optionalCounter = CounterState()
            return .none
        case .optionalCounter:
            return .none
        }
    },
    counterReducer
        .optional
        .pullpack(
            state: \.optionalCounter,
            action: /EagerNavigationAction.optionalCounter,
            environment: { _ in CounterEnvironment() }
        )
)

class EagerNavigationViewController: UIViewController {
    let disposeBag = DisposeBag()
    let store: Store<EagerNavigationState, EagerNavigationAction>
    let viewStore: ViewStore<EagerNavigationState, EagerNavigationAction>

    init(store: Store<EagerNavigationState, EagerNavigationAction>) {
        self.store = store
        viewStore = ViewStore(store)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Navigate and load"

        view.backgroundColor = .white

        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(loadOptionalCounterTapped), for: .touchUpInside)
        button.setTitle("Load optional counter", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        viewStore.observable.isNavigationActive.subscribe(onNext: { [weak self] isNavigationActive in
            guard let self = self else { return }
            if isNavigationActive {
                self.navigationController?.pushViewController(
                    IfLetStoreController(
                        store: self.store.scope(
                            state: \.optionalCounter, action: EagerNavigationAction.optionalCounter
                        ),
                        then: CounterViewController.init(store:),
                        else: ActivityIndicatorViewController()
                    ),
                    animated: true
                )
            } else {
                self.navigationController?.popToViewController(self, animated: true)
            }
    })
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !isMovingToParent {
            viewStore.send(.setNavigation(isActive: false))
        }
    }

    @objc private func loadOptionalCounterTapped() {
        viewStore.send(.setNavigation(isActive: true))
    }
}
