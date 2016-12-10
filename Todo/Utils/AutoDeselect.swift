//
//  AutoDeselect.swift
//  SelectCell
//
//  Created by DianQK on 20/10/2016.
//  Copyright © 2016 T. All rights reserved.
//

import UIKit
import RxSwift

//public protocol AssemblyView {
//    func deselectItem(at indexPath: IndexPath, animated: Bool)
//}
//
//extension UITableView: AssemblyView {
//    public func deselectItem(at indexPath: IndexPath, animated: Bool) {
//        deselectRow(at: indexPath, animated: animated)
//    }
//}
//
//extension UICollectionView: AssemblyView { }

extension Reactive where Base: UITableView {
    public func enableAutoDeselect() -> Disposable {
        return itemSelected
            .map { (at: $0, animated: true) }
            .subscribe(onNext: base.deselectRow)
    }
}

extension Reactive where Base: UICollectionView {
    public func enableAutoDeselect() -> Disposable {
        return itemSelected
            .map { (at: $0, animated: true) }
            .subscribe(onNext: base.deselectItem)
    }
}
