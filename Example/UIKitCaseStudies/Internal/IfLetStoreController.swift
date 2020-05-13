//
//  IfLetStoreController.swift
//

import ComposableArchitectureX
import RxSwift
import UIKit

final class IfLetStoreController<State, Action>: UIViewController {
    let sotre: Store<State?, Action>
    let ifDestination: (Store<State, Action>) -> UIViewController
    let elseDestination: () -> UIViewController

    private let disposeBag = DisposeBag()

    private var viewController = UIViewController() {
        willSet {
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
            addChild(newValue)
            view.addSubview(newValue.view)
            newValue.didMove(toParent: self)
        }
    }

    init(
        store: Store<State?, Action>,
        then ifDestination: @escaping (Store<State, Action>) -> UIViewController,
        else elseDestination: @autoclosure @escaping () -> UIViewController
    ) {
        sotre = store
        self.ifDestination = ifDestination
        self.elseDestination = elseDestination
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        sotre.ifLet(then: { [weak self] store in
            guard let self = self else { return }
            self.viewController = self.ifDestination(store)
        }, else: { [weak self] in
            guard let self = self else { return }
            self.viewController = self.elseDestination()
        })
            .disposed(by: disposeBag)
    }
}
