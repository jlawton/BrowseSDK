//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import ObjectiveC
import UIKit

class MenuButton: NSObject, UIContextMenuInteractionDelegate {
    enum Style {
        case systemItem(UIBarButtonItem.SystemItem)
        case image(UIImage, alt: String)
    }

    let style: Style
    let menu: UIMenu

    init(systemItem: UIBarButtonItem.SystemItem, menu: UIMenu) {
        style = .systemItem(systemItem)
        self.menu = menu
    }

    init(image: UIImage, alt: String, menu: UIMenu) {
        style = .image(image, alt: alt)
        self.menu = menu
    }

    // Just a mutable thing to which we can get a pointer that will be unique
    // wrt objc_setAssociatedObject
    private static var MenuButtonKey: UInt8 = 0

    func barButtonItem() -> UIBarButtonItem {
        if #available(iOSApplicationExtension 14.0, *) {
            return createBarButtonItem14()
        }
        let item = createBarButtonItem13()
        objc_setAssociatedObject(
            item, &Self.MenuButtonKey,
            self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return item
    }

    func button() -> UIButton {
        if #available(iOSApplicationExtension 14.0, *) {
            return createButton14()
        }
        let button = createButton13()
        objc_setAssociatedObject(
            button, &Self.MenuButtonKey,
            self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return button
    }

    @available(iOS 14.0, *)
    private func createBarButtonItem14() -> UIBarButtonItem {
        switch style {
        case let .systemItem(systemItem):
            return UIBarButtonItem(systemItem: systemItem, menu: menu)
        case let .image(image, alt: alt):
            let button = UIBarButtonItem(image: image, menu: menu)
            button.accessibilityLabel = alt
            return button
        }
    }

    @available(iOS 14.0, *)
    private func createButton14() -> UIButton {
        let image = style.asImage
        let button = UIButton.systemButton(
            with: image.image,
            target: nil, action: nil
        )
        button.accessibilityLabel = image.alt
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
        return button
    }

    @available(iOS, deprecated: 14.0)
    private func createBarButtonItem13() -> UIBarButtonItem {
        // Use a custom view for the button so we can add a context menu
        // interaction triggered by long-press on iOS 13. A tap will instead
        // trigger the selector.
        let button = createButton13()
        return UIBarButtonItem(customView: button)
    }

    @available(iOS, deprecated: 14.0)
    private func createButton13() -> UIButton {
        let image = style.asImage
        let button = UIButton.systemButton(
            with: image.image,
            target: self, action: #selector(buttonTapped(_:))
        )
        button.accessibilityLabel = image.alt
        button.addInteraction(UIContextMenuInteraction(delegate: self))
        return button
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
        var responder: UIResponder? = sender
        while responder != nil, !(responder is UIViewController) {
            responder = responder?.next
        }
        if let controller = responder as? UIViewController {
            controller.present(alert, animated: true, completion: nil)
        }
    }
}

extension MenuButton.Style {
    var asImage: (image: UIImage, alt: String) {
        switch self {
        case let .systemItem(systemItem):
            return imageForSystemItem(systemItem)
        case let .image(image, alt):
            return (image, alt)
        }
    }

    func imageForSystemItem(_ systemItem: UIBarButtonItem.SystemItem) -> (image: UIImage, alt: String) {
        // swiftlint:disable force_unwrapping
        switch systemItem {
        case .add:
            return (UIImage(systemName: "plus")!, "Add")
        case .action:
            return (UIImage(systemName: "square.and.arrow.up")!, "Share")
        default:
            preconditionFailure("Unsupported button type")
        }
        // swiftlint:enable force_unwrapping
    }
}
