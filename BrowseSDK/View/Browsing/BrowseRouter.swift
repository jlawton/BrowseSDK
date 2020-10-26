//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

protocol BrowseRouter {
    func canBrowseTo(listing: ListingViewModel, search: SearchViewModel?) -> Bool
    func browseTo(listing: ListingViewModel, search: SearchViewModel?)
}

class DefaultBrowseRouter: BrowseRouter {
    let configuration: BrowseConfiguration
    weak var source: UIViewController?
    weak var navigationController: UINavigationController?

    init(source: UIViewController, navigationController: UINavigationController, configuration: BrowseConfiguration) {
        self.source = source
        self.navigationController = navigationController
        self.configuration = configuration
    }

    func canBrowseTo(listing _: ListingViewModel, search _: SearchViewModel?) -> Bool {
        return (navigationController != nil)
    }

    func browseTo(listing: ListingViewModel, search: SearchViewModel?) {
        if let nav = navigationController {
            let dest = BrowseViewController(nibName: nil, bundle: nil)
            dest.router = DefaultBrowseRouter(
                source: dest,
                navigationController: nav,
                configuration: configuration
            )
            dest.listingViewModel = listing
            dest.searchViewModel = search
            nav.pushViewController(dest, animated: true)
        }
    }
}
