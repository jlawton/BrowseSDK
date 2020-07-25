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
    typealias BTF = Predicated<File, (File, UIViewController), SelectionBehavior>
    var btf = BTF()

    public init(
        canBrowseToFile: @escaping (File) -> Bool,
        browseToFile: @escaping (File, UIViewController) -> SelectionBehavior
    ) {
        btf = .init(predicate: canBrowseToFile, action: browseToFile)
    }

    public init() {
        btf = .init()
    }

    func canBrowseToFile(_ file: File) -> Bool {
        return btf.canAct(file)
    }

    func browseToFile(_ file: File, _ source: UIViewController) -> SelectionBehavior {
        return btf.act(file, source) ?? .deselect
    }
}

public extension BrowseToFile {
    enum ViewControllerPresentation {
        case push((File) -> UIViewController?)
        case present((File) -> UIViewController?)
    }

    mutating func forFiles(
        withExtension ext: String,
        permissions: FilePermissions = [],
        _ presentation: ViewControllerPresentation
    ) {
        forFiles(
            where: Predicate(fileExtension: ext) && Predicate(permissions),
            browse: presentation.presentFile(_:from:)
        )
    }

    mutating func forFiles(
        withExtensionIn extensions: [String],
        permissions: FilePermissions = [],
        _ presentation: ViewControllerPresentation
    ) {
        forFiles(
            where: Predicate(permissions) && Predicate(fileExtensionIn: extensions),
            browse: presentation.presentFile(_:from:)
        )
    }

    mutating func forFiles(
        where match: @escaping (File) -> Bool,
        browse: @escaping (File, UIViewController) -> SelectionBehavior
    ) {
        forFiles(where: Predicate(match), browse: browse)
    }

    internal mutating func forFiles(
        where match: Predicate<File>,
        browse: @escaping (File, UIViewController) -> SelectionBehavior
    ) {
        btf.fallbackTo(BTF(
            predicate: match,
            action: browse
        ))
    }
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
