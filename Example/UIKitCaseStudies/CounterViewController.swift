import ComposableArchitectureX
import RxCocoa
import RxSwift
import UIKit

struct CounterState: Equatable {
    var count = 0
}

enum CounterAction: Equatable {
    case decrementButtonTapped
    case incrementButtonTapped
}

struct CounterEnvironment {}

let counterReducer = Reducer<CounterState, CounterAction, CounterEnvironment> { state, action, _ in
    switch action {
    case .decrementButtonTapped:
        state.count -= 1
    case .incrementButtonTapped:
        state.count += 1
    }
    return .none
}

class CounterViewController: UIViewController {
    let viewStore: ViewStore<CounterState, CounterAction>
    let disposeBag = DisposeBag()

    init(store: Store<CounterState, CounterAction>) {
        viewStore = ViewStore(store)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let decrementButton = UIButton(type: .system)
        decrementButton.addTarget(self, action: #selector(decrementButtonTapped), for: .touchUpInside)
        decrementButton.setTitle("−", for: .normal)

        let countLabel = UILabel()
        countLabel.font = .monospacedDigitSystemFont(ofSize: 17, weight: .regular)

        let incrementButton = UIButton(type: .system)
        incrementButton.addTarget(self, action: #selector(incrementButtonTapped), for: .touchUpInside)
        incrementButton.setTitle("+", for: .normal)

        let rootStackView = UIStackView(arrangedSubviews: [
            decrementButton,
            countLabel,
            incrementButton,
        ])
        rootStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStackView)

        NSLayoutConstraint.activate([
            rootStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            rootStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        viewStore
            .observable
            .map { "\($0.count)" }
            .subscribe(countLabel.rx.text)
            .disposed(by: disposeBag)
    }

    @objc func decrementButtonTapped() {
        viewStore.send(.decrementButtonTapped)
    }

    @objc func incrementButtonTapped() {
        viewStore.send(.incrementButtonTapped)
    }
}
