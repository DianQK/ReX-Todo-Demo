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

class TodoStore: ReX.StoreType {
    
    class State {
        let list = Variable<[TodoItemModel]>([])
    }
    
    let state = State()

}

extension ReX.Getter where Store: TodoStore {
    
    var list: Observable<[TodoItemModel]> {
        return store.state.list.asObservable().skip(1)
    }

    var completedList: Observable<[TodoItemModel]> {
        return list.map { $0.filter { $0.isCompleted } }
    }

    var uncompletedList: Observable<[TodoItemModel]> {
        return list.map { $0.filter { !$0.isCompleted } }
    }

    var sectionList: Observable<[TodoSectionModel]> {
        return list.map { list in
            return [
                TodoSectionModel(model: "未完成", items: list.filter { !$0.isCompleted }),
                TodoSectionModel(model: "已完成", items: list.filter { $0.isCompleted })
            ]
        }
    }

}

extension ReX.Mutation where Store: TodoStore {

    var updateList: ([TodoItemModel]) -> Void {
        return { [unowned store = self.store] list in
            store.state.list.value = list
        }
    }

    var deleteItem: (TodoItemModel) -> Void {
        return { [unowned store = self.store] item in
            if let index = store.state.list.value.index(where: { $0.id == item.id }) {
                store.state.list.value.remove(at: index)
            }
        }
    }

    var addItem: (TodoItemModel) -> Void {
        return { [unowned store = self.store] item in
            store.state.list.value.append(item)
        }
    }

    var editItem: (TodoItemModel) -> Void {
        return { [unowned store = self.store] updatedItem in
            store.state.list.value = store.state.list.value.map { item in
                if updatedItem.id == item.id {
                    return updatedItem
                } else {
                    return item
                }
            }
        }
    }

}

extension ReX.Action where Store: TodoStore {

    var updateList: () -> Observable<RequestState> {
        return { [unowned store = self.store] in
            Session.rx.send(TodoRequest.List())
                .do(onNext: store.commit.updateList)
                .map { _ in RequestState.success("更新成功") }
                .startWith(RequestState.isLoading)
                .catchErrorJustReturn(RequestState.failure("更新失败"))
        }
    }

    var deleteItem: (TodoItemModel) -> Observable<RequestState> {
        return { [unowned store = self.store]  item in
            showEnsure("确定删除\(item.name)吗？")
                .flatMap {
                    Session.rx.send(TodoRequest.DeleteItem(id: item.id))
                        .do(onNext: store.commit.deleteItem)
                        .map { _ in RequestState.success("删除成功") }
                        .startWith(RequestState.isLoading)
                        .catchErrorJustReturn(RequestState.failure("删除失败"))
            }
        }
    }

    var addItem: (_ name: String, _ note: String?) -> Observable<RequestState> {
        return { [unowned store = self.store] name, note in
            Session.rx.send(TodoRequest.CreateItem(name: name, content: note))
                .do(onNext: store.commit.addItem)
                .map { _ in RequestState.success("添加成功") }
                .startWith(RequestState.isLoading)
                .catchErrorJustReturn(RequestState.failure("添加失败"))
        }
    }

    var editItem: (TodoItemModel) -> Observable<RequestState> {
        return { [unowned store = self.store] item in
            Session.rx.send(TodoRequest.EditItem(id: item.id, name: item.name, content: item.content, isCompleted: item.isCompleted))
                .do(onNext: store.commit.editItem)
                .map { _ in RequestState.success("保存成功") }
                .startWith(RequestState.isLoading)
                .catchErrorJustReturn(RequestState.failure("保存失败"))
        }
    }

    var completedItem: (TodoItemModel) -> Observable<RequestState> {
        return { [unowned store = self.store] item in
            Session.rx.send(TodoRequest.EditItem(id: item.id, name: item.name, content: item.content, isCompleted: true))
                .do(onNext: store.commit.editItem)
                .map { _ in RequestState.success("已完成") }
                .startWith(RequestState.isLoading)
                .catchErrorJustReturn(RequestState.failure("请求失败"))
        }
    }

}
