//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

protocol BrowseRouter {
    func canBrowseTo(listing: ListingViewModel, search: SearchViewModel?) -> Bool
    func browseTo(listing: ListingViewModel, search: SearchViewModel?)
    func canSelect(item: ItemViewModel) -> Bool
    func handleSelected(items: [ItemViewModel])
}

class DefaultBrowseRouter: BrowseRouter {
    weak var source: UIViewController?
    weak var navigationController: UINavigationController?
    let selectionHandler: SelectionHandler

    init(source: UIViewController, navigationController: UINavigationController, selectionHandler: SelectionHandler) {
        self.source = source
        self.navigationController = navigationController
        self.selectionHandler = selectionHandler
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
                selectionHandler: selectionHandler
            )
            dest.listingViewModel = listing
            dest.searchViewModel = search
            nav.pushViewController(dest, animated: true)
        }
    }

    func canSelect(item: ItemViewModel) -> Bool {
        selectionHandler.canSelect(item: item)
    }

    func handleSelected(items: [ItemViewModel]) {
        selectionHandler.handleSelected(items: items)
    }
}
