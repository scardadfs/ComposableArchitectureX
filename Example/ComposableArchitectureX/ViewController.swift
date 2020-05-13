//
//  ViewController.swift
//  ComposableArchitectureX
//
//  Created by sylvanasx on 05/06/2020.
//  Copyright (c) 2020 sylvanasx. All rights reserved.
//

import ComposableArchitectureX
import RxSwift
import UIKit

struct CaseStudy {
    let title: String
    let viewController: () -> UIViewController

    init(title: String, viewController: @autoclosure @escaping () -> UIViewController) {
        self.title = title
        self.viewController = viewController
    }
}

let dataSource: [CaseStudy] = [
    CaseStudy(
        title: "Basics",
        viewController: CounterViewController(
            store: Store(
                initialState: CounterState(),
                reducer: counterReducer,
                environment: CounterEnvironment()
            )
        )
    ),

    CaseStudy(
        title: "Lists",
        viewController: CountersTableViewController(
            store: Store(
                initialState: CounterListState(
                    counters: [
                        CounterState(),
                        CounterState(),
                        CounterState(),
                    ]
                ),
                reducer: counterListReducer,
                environment: CounterListEnvironment()
            )
        )
    ),
    CaseStudy(
        title: "Navigate and load",
        viewController: EagerNavigationViewController(
            store: Store(
                initialState: EagerNavigationState(),
                reducer: eagerNavigationReducer,
                environment: EagerNavigationEnvironment(
                    mainQueue: MainScheduler.instance
                )
            )
        )
    ),
    CaseStudy(
        title: "Load then navigate",
        viewController: LazyNavigationViewController(
            store: Store(
                initialState: LazyNavigationState(),
                reducer: lazyNavigationReducer,
                environment: LazyNavigationEnvironment(
                    mainQueue: MainScheduler.instance
                )
            )
        )
    ),
]

class ViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Case Studies"
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        dataSource.count
    }

    override func tableView(_: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
        let caseStudy = dataSource[indexPath.row]
        let cell = UITableViewCell()
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = caseStudy.title
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let caseStudy = dataSource[indexPath.row]
        navigationController?.pushViewController(caseStudy.viewController(), animated: true)
    }
}
