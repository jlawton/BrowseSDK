//
//  Created on 7/24/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK

extension Predicate where Input == Folder {
    init(_ perms: FolderPermissions) {
        self.init(perms.matches(_:))
    }
}

extension Predicate where Input == File {
    init(_ perms: FilePermissions) {
        self.init(perms.matches(_:))
    }
}

extension Predicate where Input == File {
    init(fileExtension: String) {
        self.init { extensionFrom($0) == fileExtension }
    }

    init(fileExtensionIn extensions: [String]) {
        let exts = Set(extensions.map { $0.lowercased() })
        self.init { exts.contains(extensionFrom($0)) }
    }
}

private func extensionFrom(_ file: File) -> String {
    if let ext = file.extension {
        return ext.lowercased()
    }
    if let name = file.name, let extStart = name.lastIndex(of: "."),
        extStart != name.startIndex {
        return name[extStart...].lowercased()
    }
    return ""
}
