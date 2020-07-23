//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

// Kill all of this when iOS 13 goes away.
extension UIAlertController {
    @available(iOS, deprecated: 14.0)
    convenience init(menu: UIMenu, preferredStyle: Style = .actionSheet) {
        let title: String? = menu.title.isEmpty ? nil : menu.title
        self.init(title: title, message: nil, preferredStyle: preferredStyle)

        for element in menu.children {
            guard let menuAction = element as? UIAction else {
                continue
            }
            if let action = alertAction(from: menuAction) {
                addAction(action)
            }
        }

        addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
    }

    @available(iOS, deprecated: 14.0)
    private typealias ActionHandler = @convention(block) (UIAction) -> Void

    @available(iOS, deprecated: 14.0)
    private func alertAction(from menuAction: UIAction) -> UIAlertAction? {
        guard !menuAction.attributes.contains(.hidden) else {
            return nil
        }
        let style: UIAlertAction.Style = menuAction.attributes.contains(.destructive)
            ? .destructive : .default
        let enabled: Bool = !menuAction.attributes.contains(.disabled)

        let rawHandler = menuAction.value(forKey: "handler") as AnyObject
        let handler = unsafeBitCast(rawHandler, to: ActionHandler.self)

        let action = UIAlertAction(
            title: menuAction.title,
            style: style,
            handler: { _ in handler(menuAction) }
        )

        if let image = menuAction.image {
            action.setValue(image, forKey: "image")
        }

        action.isEnabled = enabled
        return action
    }
}
