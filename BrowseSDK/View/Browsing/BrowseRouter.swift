//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

/// Manages transitions between view controllers while browsing Box. Also
/// makes exposes the selection confirmation action from anywhere in the
/// browsing hierarchy.
protocol BrowseRouter {
    func canBrowseTo(item: ItemViewModel) -> Bool
    func browseTo(item: ItemViewModel)

    var supportsSelection: Bool { get }
    func canSelect(item: ItemViewModel) -> Bool
    func handleSelected(items: [ItemViewModel])
}

class DefaultBrowseRouter: BrowseRouter {
    weak var navigationController: UINavigationController?
    let selectionHandler: SelectionHandler?

    init(navigationController: UINavigationController, selectionHandler: SelectionHandler?) {
        self.navigationController = navigationController
        self.selectionHandler = selectionHandler
    }

    func canBrowseTo(item: ItemViewModel) -> Bool {
        if let listing = item.listingViewModel() {
            return canBrowseTo(listing: listing, search: item.searchViewModel())
        }
        return false
    }

    func browseTo(item: ItemViewModel) {
        if let listing = item.listingViewModel() {
            return browseTo(listing: listing, search: item.searchViewModel())
        }
    }

    func canBrowseTo(listing _: ListingViewModel, search _: SearchViewModel?) -> Bool {
        return (navigationController != nil)
    }

    func browseTo(listing: ListingViewModel, search: SearchViewModel?) {
        if let nav = navigationController {
            let dest = BrowseViewController(nibName: nil, bundle: nil)
            dest.router = self
            dest.listingViewModel = listing
            dest.searchViewModel = search
            nav.pushViewController(dest, animated: true)
        }
    }

    var supportsSelection: Bool {
        selectionHandler != nil
    }

    func canSelect(item: ItemViewModel) -> Bool {
        selectionHandler?.canSelect(item: item) ?? false
    }

    func handleSelected(items: [ItemViewModel]) {
        selectionHandler?.handleSelected(items: items)
    }
}
