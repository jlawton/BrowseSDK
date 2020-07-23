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
    public typealias CustomizeActionItems = (_ folder: Folder, _ suggested: [UIBarButtonItem]) -> [UIBarButtonItem]
    public typealias CustomizeAddMenu = (_ folder: Folder, _ suggested: UIMenu?) -> UIMenu?

    private var _customizeActionItems: CustomizeActionItems = { $1 }
    private var _customizeAddMenu: CustomizeAddMenu = { $1 }

    func customizeActionItems(for folder: Folder, suggested: [UIBarButtonItem]) -> [UIBarButtonItem] {
        return _customizeActionItems(folder, suggested)
    }

    func customizeAddMenu(for folder: Folder, suggested: UIMenu?) -> UIMenu? {
        return _customizeAddMenu(folder, suggested)
    }
}
