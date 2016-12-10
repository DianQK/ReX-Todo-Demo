//
//  TodoItemViewController.swift
//  Todo
//
//  Created by qing on 2016/12/10.
//  Copyright © 2016年 qing. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TodoItemViewController: UIViewController {

    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var noteTextView: UITextView!
    @IBOutlet private weak var saveBarButtonItem: UIBarButtonItem!

    var store: TodoStore!

    enum `Type` {
        case new
        case edit(TodoItemModel)
    }

    var type: Type = .new

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        nameTextField.rx.text.orEmpty.map { !$0.isEmpty }
            .bindTo(saveBarButtonItem.rx.isEnabled)
            .addDisposableTo(disposeBag)

        let requestState: Observable<RequestState>

        switch type {
        case .new:
            self.title = "创建新的待办事项"
            requestState = saveBarButtonItem.rx.tap.asObservable()
                .withLatestFrom(Observable.combineLatest(nameTextField.rx.text.orEmpty, noteTextView.rx.text.orEmpty, resultSelector: { (name: $0, note: $1) }))
                .flatMap(store.dispatch.addItem())
                .shareReplay(1)
        case let .edit(item):
            self.title = item.name
            self.nameTextField.text = item.name
            self.noteTextView.text = item.content
            requestState = saveBarButtonItem.rx.tap.asObservable()
                .withLatestFrom(Observable.combineLatest(nameTextField.rx.text.orEmpty, noteTextView.rx.text.orEmpty, resultSelector: { name, note in
                    var item = item
                    item.name = name
                    item.content = note
                    return item
                }))
                .flatMap(store.dispatch.editItem())
                .shareReplay(1)
        }

        requestState
            .bindTo(view.rx.requestState)
            .addDisposableTo(disposeBag)

        requestState.map { $0.isSuccessful }.filter { $0 }
            .subscribe(onNext: { [unowned self] _ in
                _ = self.navigationController?.popViewController(animated: true)
            })
            .addDisposableTo(disposeBag)

    }

}
