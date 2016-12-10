//
//  Session+Rx.swift
//  Todo
//
//  Created by qing on 2016/12/10.
//  Copyright © 2016年 qing. All rights reserved.
//

import RxSwift
import APIKit

extension Reactive where Base: Session {

    static func send<R: Request>(_ request: R) -> Observable<R.Response> {
        return Observable.create { observer in
            let task = Session.send(request) { result in
                switch result {
                case let .success(response):
                    observer.onNext(response)
                    observer.onCompleted()
                case let .failure(error):
                    observer.onError(error)
                }
            }
            return Disposables.create {
                task?.cancel()
            }
        }
    }

}

extension Session: ReactiveCompatible {

}
