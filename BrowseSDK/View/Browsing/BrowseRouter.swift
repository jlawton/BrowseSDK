//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

protocol BrowseRouter {
    func canBrowseTo(item: ItemViewModel) -> Bool
    func browseTo(item: ItemViewModel) -> SelectionBehavior
}

class DefaultBrowseRouter: BrowseRouter {
    let browseToFile: BrowseToFile
    weak var source: UIViewController?
    weak var navigationController: UINavigationController?

    init(source: UIViewController, navigationController: UINavigationController, browseToFile: BrowseToFile) {
        self.source = source
        self.navigationController = navigationController
        self.browseToFile = browseToFile
    }

    func canBrowseTo(item: ItemViewModel) -> Bool {
        if item.isFolder {
            return true
        }
        else if let file = item.fileModel {
            return browseToFile.canBrowseToFile(file)
        }
        else {
            return false
        }
    }

    func browseTo(item: ItemViewModel) -> SelectionBehavior {
        if let nav = navigationController, item.isFolder {
            let dest = BrowseViewController(nibName: nil, bundle: nil)
            dest.router = DefaultBrowseRouter(
                source: dest,
                navigationController: nav,
                browseToFile: browseToFile
            )
            dest.listingViewModel = item.listingViewModel()
            dest.searchViewModel = item.searchViewModel()
            nav.pushViewController(dest, animated: true)
            return .remainSelected
        }
        else if let source = source, let file = item.fileModel {
            return browseToFile.browseToFile(file, source)
        }
        return .deselect
    }
}
