//
//  TodoViewController.swift
//  Todo
//
//  Created by qing on 2016/12/9.
//  Copyright © 2016年 qing. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources



class TodoViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var createTodoBarButtonItem: UIBarButtonItem!

    private let store = TodoStore()
    fileprivate let dataSource = RxTableViewSectionedAnimatedDataSource<TodoSectionModel>()

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

//        store.plugin.use(state: { state in
//            _ = state.list.asObservable()
//                .subscribe(onNext: { items in
//                    print(items)
//            })
//        }, getter: { getter in
//            _ = getter.sectionList.asObservable()
//                .subscribe(onNext: { items in
//                    print(items)
//                })
//        }, mutation: { mutation in
//
//        }, action: { action in
//
//        })

        dataSource.configureCell = { dataSource, tableView, indexPath, element in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = element.name
            return cell
        }

        dataSource.canEditRowAtIndexPath = { _ in true }

        dataSource.titleForHeaderInSection = { dataSource, section in
            return dataSource.sectionModels[section].model
        }

        dataSource.animationConfiguration = AnimationConfiguration(insertAnimation: .automatic, reloadAnimation: .automatic, deleteAnimation: .automatic)

        do {
            let refresh = UIRefreshControl()
            tableView.refreshControl = refresh
            let updateList = refresh.rx.controlEvent(.valueChanged)
                .startWith(())
                .flatMap(store.dispatch.updateList())
                .shareReplay(1)

            updateList.map { $0.isLoading }
                .bindTo(refresh.rx.refreshing)
                .addDisposableTo(disposeBag)

            updateList.map { $0.message }
                .bindTo(view.rx.showMessage)
                .addDisposableTo(disposeBag)

        }

        do {
            createTodoBarButtonItem.rx.tap.asObservable()
                .subscribe(onNext: { [unowned self] in
                    let todoItemViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TodoItemViewController") as! TodoItemViewController
                    todoItemViewController.store = self.store
                    todoItemViewController.type = .new
                    self.show(todoItemViewController, sender: nil)
                })
                .addDisposableTo(disposeBag)
        }

        store.getter.sectionList
            .observeOn(MainScheduler.asyncInstance)
            .bindTo(tableView.rx.items(dataSource: dataSource))
            .addDisposableTo(disposeBag)

        tableView.rx.setDelegate(self).addDisposableTo(disposeBag)
        tableView.rx.enableAutoDeselect().addDisposableTo(disposeBag)

        tableView.rx.modelSelected(TodoItemModel.self)
            .subscribe(onNext: { [unowned self] item in
                let todoItemViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TodoItemViewController") as! TodoItemViewController
                todoItemViewController.store = self.store
                todoItemViewController.type = .edit(item)
                self.show(todoItemViewController, sender: nil)
            })
            .addDisposableTo(disposeBag)


        let item = tableView.rx.itemDeleted
            .map { [unowned self] in self.dataSource[$0] }
            .shareReplay(1)

        item.filter { $0.isCompleted }
            .flatMap(store.dispatch.deleteItem())
            .bindTo(view.rx.requestState)
            .addDisposableTo(disposeBag)

        item.filter { !$0.isCompleted }
            .flatMap(store.dispatch.completedItem())
            .bindTo(view.rx.requestState)
            .addDisposableTo(disposeBag)

    }

}

extension TodoViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        if dataSource[indexPath].isCompleted {
            return "删除"
        } else {
            return "完成"
        }
    }
    
}
