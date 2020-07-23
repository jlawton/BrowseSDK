//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import UIKit

public enum SelectionBehavior {
    case deselect
    case remainSelected
}

public struct BrowseToFile {
    var canBrowseToFile: (_ file: File) -> Bool
    var browseToFile: (_ file: File, _ fromVC: UIViewController) -> SelectionBehavior

    public init(
        canBrowseToFile: @escaping (File) -> Bool,
        browseToFile: @escaping (File, UIViewController) -> SelectionBehavior
    ) {
        self.canBrowseToFile = canBrowseToFile
        self.browseToFile = browseToFile
    }
}

public extension BrowseToFile {
    init() {
        self.init(
            canBrowseToFile: { _ in false },
            browseToFile: { _, _ in .deselect }
        )
    }
}

public extension BrowseToFile {
    enum ViewControllerPresentation {
        case push((File) -> UIViewController?)
        case present((File) -> UIViewController?)
    }

    mutating func forFiles(
        withExtension: String,
        permissions: FilePermissions = [],
        _ presentation: ViewControllerPresentation
    ) {
        let ext = withExtension.lowercased()
        forFiles(
            where: { file in
                permissions.matches(file)
                    && (extensionFrom(file) == ext)
            },
            browse: presentation.presentFile(_:from:)
        )
    }

    mutating func forFiles(
        withExtensionIn: [String],
        permissions: FilePermissions = [],
        _ presentation: ViewControllerPresentation
    ) {
        let ext = Set(withExtensionIn.map { $0.lowercased() })
        forFiles(
            where: { file in
                permissions.matches(file)
                    && (extensionFrom(file).map(ext.contains) ?? false)
            },
            browse: presentation.presentFile(_:from:)
        )
    }

    mutating func forFiles(
        where match: @escaping (File) -> Bool,
        browse: @escaping (File, UIViewController) -> SelectionBehavior
    ) {
        let existing = self
        canBrowseToFile = { file in
            match(file) || existing.canBrowseToFile(file)
        }
        browseToFile = { file, src in
            if match(file) {
                return browse(file, src)
            }
            else {
                return existing.browseToFile(file, src)
            }
        }
    }
}

private func extensionFrom(_ file: File) -> String? {
    if let ext = file.extension {
        return ext.lowercased()
    }
    if let name = file.name, let extStart = name.lastIndex(of: "."),
        extStart != name.startIndex {
        return name[extStart...].lowercased()
    }
    return nil
}

extension BrowseToFile.ViewControllerPresentation {
    func presentFile(_ file: File, from src: UIViewController) -> SelectionBehavior {
        switch self {
        case let .push(makeVC):
            if let src = src as? UINavigationController, let dest = makeVC(file) {
                src.pushViewController(dest, animated: true)
                return .remainSelected
            }
        case let .present(makeVC):
            if let dest = makeVC(file) {
                src.present(dest, animated: true, completion: nil)
                return .deselect
            }
        }
        return .deselect
    }
}
