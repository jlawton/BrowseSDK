//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

class MenuButton: NSObject, UIContextMenuInteractionDelegate {
    let systemItem: UIBarButtonItem.SystemItem
    let menu: UIMenu

    init(systemItem: UIBarButtonItem.SystemItem, menu: UIMenu) {
        self.systemItem = systemItem
        self.menu = menu
    }

    lazy var barButtonItem: UIBarButtonItem = {
        if #available(iOSApplicationExtension 14.0, *) {
            return createButton14()
        }
        else {
            return createButton13()
        }
    }()

    @available(iOS 14.0, *)
    private func createButton14() -> UIBarButtonItem {
        UIBarButtonItem(systemItem: systemItem, menu: menu)
    }

    @available(iOS, deprecated: 14.0)
    private func createButton13() -> UIBarButtonItem {
        // Use a custom view for the button so we can add a context menu
        // interaction triggered by long-press on iOS 13. A tap will instead
        // trigger the selector.
        let button: UIButton
        // swiftlint:disable force_unwrapping
        switch systemItem {
        case .add:
            button = UIButton.systemButton(
                with: UIImage(systemName: "plus")!,
                target: self,
                action: #selector(buttonTapped(_:))
            )
            button.accessibilityLabel = "Add"
        default:
            preconditionFailure("Unsupported button type")
        }
        // swiftlint:enable force_unwrapping

        button.addInteraction(UIContextMenuInteraction(delegate: self))
        return UIBarButtonItem(customView: button)
    }

    // Used to render the menu from the add button's context menu interaction
    // on iOS 13.
    @available(iOS, deprecated: 14.0)
    public func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            self.menu
        }
    }

    // Used when the add button is tapped on iOS 13.
    @available(iOS, deprecated: 14.0)
    @objc private func buttonTapped(_ sender: UIButton) {
        let alert = UIAlertController(menu: menu)
        alert.popoverPresentationController?.sourceView = sender
        // Living with this grossness because it goes away with iOS 13
        sender.window?.rootViewController?
            .present(alert, animated: true, completion: nil)
    }
}
