//
//  Created on 7/22/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import UIKit

public enum DefaultFolderActionIdentifier: String {
    case createFolder = "BrowseSDK.createFolder"
    case importPhoto = "BrowseSDK.importPhoto"
}

public struct FolderActionCustomization {
    public typealias CustomizeActionBarItems = (_ folder: Folder, _ suggested: [UIBarButtonItem]) -> [UIBarButtonItem]
    public typealias CustomizeAddMenu = (_ folder: Folder, _ suggested: UIMenu?) -> UIMenu?

    private var _customizeActionBarItems: CustomizeActionBarItems = { $1 }
    private var _customizeAddMenu: CustomizeAddMenu = { $1 }

    public init() {}

    func customizeActionBarItems(for folder: Folder, suggested: [UIBarButtonItem]) -> [UIBarButtonItem] {
        return _customizeActionBarItems(folder, suggested)
    }

    func customizeAddMenu(for folder: Folder, suggested: UIMenu?) -> UIMenu? {
        if let menu = _customizeAddMenu(folder, suggested), !menu.children.isEmpty {
            return menu
        }
        return nil
    }
}

public extension FolderActionCustomization {
    mutating func disallow(_ disallowed: Set<DefaultFolderActionIdentifier>) {
        modifyAddMenuElements { elements in
            elements.filter { elem in
                if let action = elem as? UIAction,
                    let id = DefaultFolderActionIdentifier(rawValue: action.identifier.rawValue)
                {
                    return !disallowed.contains(id)
                }
                return true
            }
        }
    }

    mutating func modifyAddMenuElements(
        _ modifyElements: @escaping ([UIMenuElement]) -> [UIMenuElement]
    ) {
        let applyExistingCustomizations = _customizeAddMenu
        _customizeAddMenu = { file, suggested in
            if let menu = applyExistingCustomizations(file, suggested) {
                return suggested?.replacingChildren(
                    modifyElements(menu.children)
                )
            }
            else {
                return nil
            }
        }
    }
}

public extension FolderActionCustomization {
    mutating func insertMenu(
        requiredPermissions: FolderPermissions = [],
        systemItem: UIBarButtonItem.SystemItem,
        menu createMenu: @escaping (Folder) -> UIMenu?
    ) {
        let applyExistingCustomizations = _customizeActionBarItems
        _customizeActionBarItems = { folder, suggested in
            let item: [UIBarButtonItem]
            if requiredPermissions.matches(folder),
                let menu = createMenu(folder), !menu.children.isEmpty
            {
                item = [MenuButton(systemItem: systemItem, menu: menu).barButtonItem()]
            }
            else {
                item = []
            }
            return applyExistingCustomizations(folder, suggested) + item
        }
    }
}
