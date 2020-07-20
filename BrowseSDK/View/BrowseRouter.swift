//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

protocol BrowseRouter {
    func browseTo(item: ItemViewModel)
}

class DefaultBrowseRouter: BrowseRouter {
    typealias BrowseToFile = (_ identifier: String, _ from: UIViewController) -> Void
    let browseToFile: BrowseToFile
    weak var source: UIViewController?
    weak var navigationController: UINavigationController?

    init(source: UIViewController, navigationController: UINavigationController, browseToFile: @escaping BrowseToFile) {
        self.source = source
        self.navigationController = navigationController
        self.browseToFile = browseToFile
    }

    func browseTo(item: ItemViewModel) {
        if let nav = navigationController, item.isFolder {
            let dest = BrowseViewController(nibName: nil, bundle: nil)
            dest.router = DefaultBrowseRouter(
                source: dest,
                navigationController: nav,
                browseToFile: browseToFile
            )
            dest.listingViewModel = item.listingViewModel()
            nav.pushViewController(dest, animated: true)
        }
        else if let source = source {
            browseToFile(item.identifier, source)
        }
    }
}
