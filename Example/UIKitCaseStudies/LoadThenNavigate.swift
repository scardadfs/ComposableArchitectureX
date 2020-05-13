//
//  LoadThenNavigate.swift
//

import ComposableArchitectureX
import RxCocoa
import RxSwift

struct LazyNavigationState: Equatable {
    var optionalCounter: CounterState?
    var isActivityIndicatorHidden = true
}

enum LazyNavigationAction: Equatable {
    case optionalCounter(CounterAction)
    case setNavigation(isActive: Bool)
    case setNavigationIsActiveDelayCompleted
}

struct LazyNavigationEnvironment {
    var mainQueue: SchedulerType
}

let lazyNavigationReducer = Reducer<
    LazyNavigationState, LazyNavigationAction, LazyNavigationEnvironment
>.combine(
    Reducer { state, action, environment in
        switch action {
        case .setNavigation(isActive: true):
            state.isActivityIndicatorHidden = false
            return Effect(value: .setNavigationIsActiveDelayCompleted)
                .delay(.seconds(1), scheduler: environment.mainQueue)
                .eraseToEffect()
        case .setNavigation(isActive: false):
            state.optionalCounter = nil
            return .none
        case .setNavigationIsActiveDelayCompleted:
            state.isActivityIndicatorHidden = true
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
            action: /LazyNavigationAction.optionalCounter,
            environment: { _ in CounterEnvironment() }
        )
)

class LazyNavigationViewController: UIViewController {
    let disposeBag = DisposeBag()
    let store: Store<LazyNavigationState, LazyNavigationAction>
    let viewStore: ViewStore<LazyNavigationState, LazyNavigationAction>

    init(store: Store<LazyNavigationState, LazyNavigationAction>) {
        self.store = store
        viewStore = ViewStore(store)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Load then navigate"

        view.backgroundColor = .white

        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(loadOptionalCounterTapped), for: .touchUpInside)
        button.setTitle("Load optional counter", for: .normal)

        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.startAnimating()

        let rootStackView = UIStackView(arrangedSubviews: [
            button,
            activityIndicator,
        ])
        rootStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStackView)

        NSLayoutConstraint.activate([
            rootStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            rootStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        viewStore.observable
            .isActivityIndicatorHidden
            .bind(to: activityIndicator.rx.isHidden)
            .disposed(by: disposeBag)

        store.scope(
            state: \.optionalCounter,
            action: LazyNavigationAction.optionalCounter
        )
        .ifLet(
            then: { [weak self] store in
                self?.navigationController?.pushViewController(
                    CounterViewController(store: store),
                    animated: true
                )
            },
            else: { [weak self] in
                guard let self = self else { return }
                self.navigationController?.popToViewController(self, animated: true)
            }
        )
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
