//
//  Created on 7/27/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

class MoveOrCopyRouter: BrowseRouter {
    weak var source: UIViewController?
    weak var navigationController: UINavigationController?

    init(source: UIViewController, navigationController: UINavigationController) {
        self.source = source
        self.navigationController = navigationController
    }

    var folderActionCustomization: FolderActionCustomization {
        FolderActionCustomization()
    }

    func canBrowseTo(item _: ItemViewModel) -> Bool {
        return false
    }

    func browseTo(item _: ItemViewModel) -> SelectionBehavior {
        return .deselect
    }

    func canBrowseTo(listing _: ListingViewModel, search _: SearchViewModel?) -> Bool {
        return (navigationController != nil)
    }

    func browseTo(listing: ListingViewModel, search: SearchViewModel?) {
        if let nav = navigationController {
            let dest = BrowseViewController(nibName: nil, bundle: nil)
            dest.router = MoveOrCopyRouter(
                source: dest,
                navigationController: nav
            )
            dest.listingViewModel = listing
            dest.searchViewModel = search
            nav.pushViewController(dest, animated: true)
        }
    }

    func canPresent(folderCreation _: CreateFolderViewModel) -> Bool {
        return true
    }

    func present(folderCreation: CreateFolderViewModel) {
        let viewController = CreateFolderViewController.forModalPresentation(folderCreation) { _ in
            self.source?.dismiss(animated: true, completion: nil)
        }

        source?.present(viewController, animated: true, completion: nil)
    }

    func canPresent(moveOrCopy _: MoveOrCopyViewModel) -> Bool {
        return false
    }

    func present(moveOrCopy _: MoveOrCopyViewModel) {}
}
