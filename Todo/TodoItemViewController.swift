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
    @IBOutlet private weak var isCompletedSwitch: UISwitch!
    @IBOutlet private weak var deleteButton: UIButton!
    @IBOutlet weak var isCompletedSectionView: UIStackView!
    
    @IBOutlet weak var containerScrollView: UIScrollView!

    var store: TodoStore!

    enum EditType {
        case new
        case edit(TodoItemModel)
    }

    var editType: EditType = .new

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        let requestState: Observable<RequestState>

        switch editType {
        case .new:
            self.title = "创建新的待办事项"
            self.deleteButton.isHidden = true
            self.isCompletedSectionView.isHidden = true

            requestState = saveBarButtonItem.rx.tap.asObservable()
                .withLatestFrom(Observable.combineLatest(nameTextField.rx.text.orEmpty, noteTextView.rx.text, resultSelector: { (name: $0, note: $1) }))
                .flatMap(store.dispatch.addItem())
                .shareReplay(1)
        case let .edit(item):
            self.title = item.name
            self.nameTextField.text = item.name
            self.noteTextView.text = item.content
            self.isCompletedSwitch.isOn = item.isCompleted

            self.deleteButton.isHidden = false
            self.isCompletedSwitch.isHidden = false

            let deleteState = deleteButton.rx.tap.asObservable()
                .map { item }
                .flatMap(store.dispatch.deleteItem())
                .shareReplay(1)

            let saveState = saveBarButtonItem.rx.tap.asObservable()
                .withLatestFrom(Observable.combineLatest(
                    nameTextField.rx.text.orEmpty.startWith(item.name),
                    noteTextView.rx.text.startWith(item.content).debug("note"),
                    isCompletedSwitch.rx.value,
                    resultSelector: { name, note, isCompleted in
                        var item = item
                        item.name = name
                        item.content = note
                        item.isCompleted = isCompleted
                        return item
                }))
                .flatMap(store.dispatch.editItem())
                .shareReplay(1)

            requestState = Observable.from([deleteState, saveState]).merge()
        }

        requestState
            .bindTo(view.rx.requestState)
            .addDisposableTo(disposeBag)

        requestState.map { $0.isSuccessful }.filter { $0 }
            .subscribe(onNext: { [unowned self] _ in
                _ = self.navigationController?.popViewController(animated: true)
            })
            .addDisposableTo(disposeBag)

        nameTextField.rx.text.orEmpty
            .map { !$0.isEmpty }
            .bindTo(saveBarButtonItem.rx.isEnabled)
            .addDisposableTo(disposeBag)
        
        RxKeyboard.shared.visibleHeight
            .map { UIEdgeInsets(top: 64, left: 0, bottom: $0, right: 0) }.asObservable()
            .subscribe(onNext: { [unowned self] inset in
                self.containerScrollView.contentInset = inset
                self.containerScrollView.scrollIndicatorInsets = inset
            })
            .addDisposableTo(disposeBag)

    }

}
