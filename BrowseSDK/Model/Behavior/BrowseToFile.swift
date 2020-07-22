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
    let canBrowseToFile: (_ file: File) -> Bool
    let browseToFile: (_ file: File, _ fromVC: UIViewController) -> SelectionBehavior

    public init(
        canBrowseToFile: @escaping (File) -> Bool,
        browseToFile: @escaping (File, UIViewController) -> SelectionBehavior
    ) {
        self.canBrowseToFile = canBrowseToFile
        self.browseToFile = browseToFile
    }
}

public extension BrowseToFile {
    static let noFileAction = BrowseToFile(
        canBrowseToFile: { _ in false },
        browseToFile: { _, _ in .deselect }
    )
}
