//
//  TodoRequest.swift
//  Todo
//
//  Created by qing on 2016/12/10.
//  Copyright © 2016年 qing. All rights reserved.
//

import Foundation
import APIKit

extension Request {
    var baseURL: URL {
//        return URL(string: "http://localhost:3000")!
        return URL(string: "https://todo666666.herokuapp.com")!
    }
}

struct TodoRequest {

    struct List: Request {

        typealias Response = [TodoItemModel]

        var path: String {
            return "/todos.json"
        }

        var method: HTTPMethod {
            return .get
        }

        func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Array<TodoItemModel> {
            guard let array = object as? [Any] else {
                throw ResponseError.unexpectedObject(object)
            }
            return try array.map { try TodoItemModel(object: $0) }
        }

    }

    struct Item: Request {

        typealias Response = TodoItemModel

        var path: String {
            return "/todos/\(id).json"
        }

        var method: HTTPMethod {
            return .get
        }

        let id: Int64

        func response(from object: Any, urlResponse: HTTPURLResponse) throws -> TodoItemModel {
            return try TodoItemModel(object: object)
        }

    }

    struct CreateItem: Request {

        typealias Response = TodoItemModel

        var path: String {
            return "/todos.json"
        }

        var method: HTTPMethod {
            return .post
        }

        var parameters: Any? {
            var parameters: [String: Any] = [:]
            if let name = name {
                parameters["name"] = name
            }
            if let content = content {
                parameters["content"] = content
            }
//            if let isCompleted = isCompleted {
//                parameters["isCompleted"] = isCompleted
//            }
            return parameters
        }

        let name: String?
        let content: String?
//        let isCompleted: Bool?

        func response(from object: Any, urlResponse: HTTPURLResponse) throws -> TodoItemModel {
            return try TodoItemModel(object: object)
        }
        
    }

    struct EditItem: Request {

        typealias Response = TodoItemModel

        var path: String {
            return "/todos/\(id).json"
        }

        var method: HTTPMethod {
            return .patch
        }

        var parameters: Any? {
            var parameters: [String: Any] = [:]
            if let name = name {
                parameters["name"] = name
            }
            if let content = content {
                parameters["content"] = content
            }
            if let isCompleted = isCompleted {
                parameters["isCompleted"] = isCompleted
            }
            return parameters
        }

        let id: Int64
        let name: String?
        let content: String?
        let isCompleted: Bool?

        func response(from object: Any, urlResponse: HTTPURLResponse) throws -> TodoItemModel {
            return try TodoItemModel(object: object)
        }

    }

    struct DeleteItem: Request {

        typealias Response = TodoItemModel

        var path: String {
            return "/todos/\(id).json"
        }

        var method: HTTPMethod {
            return .delete
        }

        let id: Int64

        func response(from object: Any, urlResponse: HTTPURLResponse) throws -> TodoItemModel {
            return try TodoItemModel(object: object)
        }
        
    }
}
