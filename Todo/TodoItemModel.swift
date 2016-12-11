//
//  TodoItemModel.swift
//  Todo
//
//  Created by qing on 2016/12/10.
//  Copyright © 2016年 qing. All rights reserved.
//

import Foundation
import APIKit
import RxDataSources

struct TodoItemModel {

    let id: Int64
    var name: String
    var content: String?
    var isCompleted: Bool

    init(object: Any) throws {
        guard let dictionary = object as? [String: Any],
            let id = dictionary["id"] as? Int64,
            let name = dictionary["name"] as? String,
            let isCompleted = dictionary["isCompleted"] as? Bool else {
                throw ResponseError.unexpectedObject(object)
        }

        self.id = id
        self.name = name
        self.content = dictionary["content"] as? String
        self.isCompleted = isCompleted
    }

}

extension TodoItemModel: Hashable, IdentifiableType {

    static func ==(lhs: TodoItemModel, rhs: TodoItemModel) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.isCompleted == rhs.isCompleted && lhs.content == rhs.content
    }

    var hashValue: Int {
        return id.hashValue
    }

    var identity: Int64 {
        return id
    }

}
