//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK

struct Breadcrumbs {
    private let item: FolderItem
    init(item: FolderItem) {
        self.item = item
    }

    var abbreviatedString: String? {
        return abbreviatedNames?.joined(separator: " ≫ ")
    }

    private var abbreviatedNames: [String]? {
        guard var names = folderNames else {
            return nil
        }
        if names.count > 3 {
            names.replaceSubrange(2 ..< names.count - 1, with: ["⋯"])
        }
        return names
    }

    private var folderNames: [String]? {
        guard var folders = pathCollection, !folders.isEmpty else {
            return nil
        }
        if folders.count > 1, folders[0].id == BoxFolderProvider.root {
            folders.removeFirst()
        }
        return folders.compactMap { folder in
            folder.name
        }
    }

    private var pathCollection: [Folder]? {
        let pathCollection: [Folder]?
        switch item {
        case let .folder(folder):
            pathCollection = folder.pathCollection?.entries
        case let .file(file):
            pathCollection = file.pathCollection?.entries
        case let .webLink(link):
            pathCollection = link.pathCollection?.entries
        }
        return pathCollection
    }
}
