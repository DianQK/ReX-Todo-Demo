//
//  HUD.swift
//  RxDataSourcesExample
//
//  Created by DianQK on 03/11/2016.
//  Copyright © 2016 T. All rights reserved.
//

import Foundation
import MBProgressHUD
import RxSwift
import RxCocoa

class HUD {

    private init() { }
    /**
     显示一个提示消息

     - parameter message: 显示内容
     */
    static func showMessage(_ message: String?, for view: UIView? = UIApplication.shared.keyWindow) {
        guard let message = message, let view = view else { return }
        let hud = MBProgressHUD.showAdded(to: view, animated: true)

        hud.mode = MBProgressHUDMode.text
        hud.label.text = message
        hud.margin = 10
        hud.offset.y = 150
        hud.removeFromSuperViewOnHide = true
        hud.isUserInteractionEnabled = false

        hud.hide(animated: true, afterDelay: 1.5)
    }

    static func showLoading(_ isLoading: Bool, for view: UIView) {
        let hudTag = 19786
        if isLoading {
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            hud.mode = .indeterminate
            hud.tag = hudTag
        } else {
            (view.viewWithTag(hudTag) as? MBProgressHUD)?.hide(animated: true)
        }
    }


}

enum RequestState {
    case isLoading
    case success(String?)
    case failure(String?)

    var isLoading: Bool {
        switch self {
        case .isLoading:
            return true
        case .success, .failure:
            return false
        }
    }

    var message: String? {
        switch self {
        case .isLoading:
            return nil
        case let .success(message), let .failure(message):
            return message
        }
    }

    var isSuccessful: Bool {
        switch self {
        case .isLoading, .failure:
            return false
        case .success:
            return true
        }
    }
}

extension Reactive where Base: UIView {

    var isShowLoading: UIBindingObserver<UIView, Bool> {
        return UIBindingObserver(UIElement: self.base) { view, isShowLoading in
            HUD.showLoading(isShowLoading, for: view)
        }
    }

    var requestState: UIBindingObserver<UIView, RequestState> {
        return UIBindingObserver(UIElement: self.base) { view, state in
            switch state {
            case .isLoading:
                HUD.showLoading(true, for: view)
            case let .success(message), let .failure(message):
                HUD.showLoading(false, for: view)
                HUD.showMessage(message)//, for: view)
            }
        }
    }

    var showMessage: UIBindingObserver<UIView, String?> {
        return UIBindingObserver(UIElement: self.base) { view, message in
            HUD.showMessage(message, for: view)
        }
    }

}
