//
//  TodoStore.swift
//  Todo
//
//  Created by qing on 2016/12/10.
//  Copyright (c) 2016年 qing. All rights reserved.
//

import ReX
import RxSwift
import APIKit
import RxDataSources

typealias TodoSectionModel = AnimatableSectionModel<String, TodoItemModel>

class TodoStore: ReX.Store {

    fileprivate let list = Variable<[TodoItemModel]>([])

}

extension ReX.State where Base: TodoStore {

    var list: GetVariable<[TodoItemModel]> {
        return base.list.asGetVariable()
    }
}

extension ReX.Getter where Base: TodoStore {

    var completedList: Observable<[TodoItemModel]> {
        return base.list.asObservable().skip(1)
            .map { $0.filter { $0.isCompleted } }
    }

    var uncompletedList: Observable<[TodoItemModel]> {
        return base.list.asObservable().skip(1)
            .map { $0.filter { !$0.isCompleted } }
    }

    var sectionList: Observable<[TodoSectionModel]> {
        return base.list.asObservable().skip(1)
            .map { list in
                return [
                    TodoSectionModel(model: "未完成", items: list.filter { !$0.isCompleted }),
                    TodoSectionModel(model: "已完成", items: list.filter { $0.isCompleted })
                ]
        }
    }

}

extension ReX.Mutation where Base: TodoStore {

    func updateList() -> (([TodoItemModel]) -> Void) {
        return { [unowned store = self.base as TodoStore] list in
            store.list.value = list
        }
    }

    func deleteItem() -> ((TodoItemModel) -> Void) {
        return { [unowned store = self.base as TodoStore] item in
            if let index = store.list.value.index(where: { $0.id == item.id }) {
                store.list.value.remove(at: index)
            }
        }
    }

    func addItem() -> ((TodoItemModel) -> Void) {
        return { [unowned store = self.base as TodoStore] item in
            store.list.value.append(item)
        }
    }

    func editItem() -> ((TodoItemModel) -> Void) {
        return { [unowned store = self.base as TodoStore] updatedItem in
            store.list.value = store.list.value.map { item in
                if updatedItem.id == item.id {
                    return updatedItem
                } else {
                    return item
                }
            }
        }
    }

}

extension ReX.Action where Base: TodoStore {

    func updateList() -> (() -> Observable<RequestState>) {
        return { [unowned store = self.base as TodoStore] in
            Session.rx.send(TodoRequest.List())
                .do(onNext: store.commit.updateList())
                .map { _ in RequestState.success("更新成功") }
                .startWith(RequestState.isLoading)
                .catchErrorJustReturn(RequestState.failure("更新失败"))
        }
    }

    func deleteItem() -> ((TodoItemModel) -> Observable<RequestState>) {
        return { [unowned store = self.base as TodoStore]  item in
            showEnsure("确定删除\(item.name)吗？")
                .flatMap {
                    Session.rx.send(TodoRequest.DeleteItem(id: item.id))
                        .do(onNext: store.commit.deleteItem())
                        .map { _ in RequestState.success("删除成功") }
                        .startWith(RequestState.isLoading)
                        .catchErrorJustReturn(RequestState.failure("删除失败"))
            }
        }
    }

    func addItem() -> ((_ name: String, _ note: String?) -> Observable<RequestState>) {
        return { [unowned store = self.base as TodoStore] name, note in
            Session.rx.send(TodoRequest.CreateItem(name: name, content: note))
                .do(onNext: store.commit.addItem())
                .map { _ in RequestState.success("添加成功") }
                .startWith(RequestState.isLoading)
                .catchErrorJustReturn(RequestState.failure("添加失败"))
        }
    }

    func editItem() -> ((TodoItemModel) -> Observable<RequestState>) {
        return { [unowned store = self.base as TodoStore] item in
            Session.rx.send(TodoRequest.EditItem(id: item.id, name: item.name, content: item.content, isCompleted: item.isCompleted))
                .do(onNext: store.commit.editItem())
                .map { _ in RequestState.success("保存成功") }
                .startWith(RequestState.isLoading)
                .catchErrorJustReturn(RequestState.failure("保存失败"))
        }
    }

    func completedItem() -> ((TodoItemModel) -> Observable<RequestState>) {
        return { [unowned store = self.base as TodoStore] item in
            Session.rx.send(TodoRequest.EditItem(id: item.id, name: item.name, content: item.content, isCompleted: true))
                .do(onNext: store.commit.editItem())
                .map { _ in RequestState.success("已完成") }
                .startWith(RequestState.isLoading)
                .catchErrorJustReturn(RequestState.failure("请求失败"))
        }
    }

}
