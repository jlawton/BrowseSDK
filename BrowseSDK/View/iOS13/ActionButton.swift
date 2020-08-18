//
//  Created on 8/17/20.
//  Copyright © 2020 Box. All rights reserved.
//

import ObjectiveC
import UIKit

extension UIBarButtonItem {
    // Just a mutable thing to which we can get a pointer that will be unique
    // wrt objc_setAssociatedObject
    private static var ActionButtonKey: UInt8 = 0

    convenience init(action: UIAction) {
        if #available(iOS 14, *) {
            self.init(image: action.image, primaryAction: action)
        }
        else {
            self.init(image: action.image, style: .plain, target: action, action: #selector(action.runHandler))
            objc_setAssociatedObject(
                action, &Self.ActionButtonKey,
                self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
        accessibilityLabel = action.title
    }
}

@available(iOS, deprecated: 14.0)
private extension UIAction {
    typealias ActionHandler = @convention(block) (UIAction) -> Void

    @objc func runHandler() {
        let rawHandler = value(forKey: "handler") as AnyObject
        let handler = unsafeBitCast(rawHandler, to: ActionHandler.self)
        handler(self)
    }
}
