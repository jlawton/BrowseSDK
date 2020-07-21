//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

struct FolderActionHandlers {
    var createFolder: (() -> Void)?
    var importMedia: (() -> Void)?
}

class FolderActions {
    let handlers: FolderActionHandlers

    init(_ handlers: FolderActionHandlers) {
        self.handlers = handlers
    }

    // Jumping through some hoops for iOS 13 compatibility
    private lazy var addToFolderMenuButtonShim = addToFolderMenu.map {
        MenuButton(systemItem: .add, menu: $0)
    }
}

extension FolderActions {
    var addToFolderMenuButton: UIBarButtonItem? {
        addToFolderMenuButtonShim?.barButtonItem
    }

    var addToFolderMenu: UIMenu? {
        let children = [
            createFolder(handlers.createFolder),
            importMedia(handlers.importMedia)
        ].compactMap { $0 }

        return children.isEmpty ? nil : UIMenu(
            title: "Add to folder",
            children: children
        )
    }

    func createFolder(_ handler: (() -> Void)?) -> UIAction? {
        guard let handler = handler else {
            return nil
        }
        return UIAction(
            title: "Create folder",
            image: UIImage(systemName: "folder.badge.plus"),
            handler: { _ in handler() }
        )
    }

    func importMedia(_ handler: (() -> Void)?) -> UIAction? {
        guard let handler = handler else {
            return nil
        }
        return UIAction(
            title: "Import Photo",
            image: UIImage(systemName: "photo.on.rectangle"),
            handler: { _ in handler() }
        )
    }
}
