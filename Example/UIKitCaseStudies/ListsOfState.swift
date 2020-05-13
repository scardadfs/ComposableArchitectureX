import ComposableArchitectureX
import RxCocoa
import RxSwift
import UIKit

struct CounterListState: Equatable {
    var counters: [CounterState] = []
}

enum CounterListAction: Equatable {
    case counter(index: Int, action: CounterAction)
}

struct CounterListEnvironment {}

let counterListReducer: Reducer<CounterListState, CounterListAction, CounterListEnvironment> =
    counterReducer.forEach(
        state: \CounterListState.counters,
        action: /CounterListAction.counter(index:action:),
        environment: { _ in CounterEnvironment() }
    )

let cellIdentifier = "Cell"

final class CountersTableViewController: UITableViewController {
    let store: Store<CounterListState, CounterListAction>
    let viewStore: ViewStore<CounterListState, CounterListAction>
    let disposeBag = DisposeBag()

    var dataSource: [CounterState] = [] {
        didSet { tableView.reloadData() }
    }

    init(store: Store<CounterListState, CounterListAction>) {
        self.store = store
        viewStore = ViewStore(store)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Lists"

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        viewStore.observable.counters
            .subscribe(onNext: { [weak self] in self?.dataSource = $0 })
            .disposed(by: disposeBag)
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = "\(dataSource[indexPath.row].count)"
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(
            CounterViewController(
                store: store.scope(
                    state: \.counters[indexPath.row],
                    action: { .counter(index: indexPath.row, action: $0) }
                )
            ),
            animated: true
        )
    }
}
