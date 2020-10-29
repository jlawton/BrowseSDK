//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import Foundation

/// Generates a string representing the path to a given Box item.
///
/// This may not be very localization-friendly, as we're doing a bunch of string
/// concatenation.
struct Breadcrumbs {
    private let pathCollection: [Folder]?

    init(item: FolderItem) {
        pathCollection = Self.path(containing: item)
    }

    init(folder: Folder) {
        pathCollection = Self.path(including: folder)
    }

    var abbreviatedString: String? {
        let sep = NSLocalizedString(" ≫ ", comment: "Separator between path components rendered in the Box search UI")
        return abbreviatedNames?.joined(separator: sep)
    }

    private var abbreviatedNames: [String]? {
        guard var names = folderNames else {
            return nil
        }
        if names.count > 3 {
            let trunc = NSLocalizedString("⋯", comment: "Indicator that one or more path components have been elided for space reasons, in the Box search UI")
            names.replaceSubrange(2 ..< names.count - 1, with: [trunc])
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

    private static func path(containing item: FolderItem) -> [Folder]? {
        let path: [Folder]?
        switch item {
        case let .folder(folder):
            path = folder.pathCollection?.entries
        case let .file(file):
            path = file.pathCollection?.entries
        case let .webLink(link):
            path = link.pathCollection?.entries
        }
        return path
    }

    private static func path(including folder: Folder) -> [Folder]? {
        if let path = folder.pathCollection?.entries {
            return path + [folder]
        }
        return nil
    }
}
