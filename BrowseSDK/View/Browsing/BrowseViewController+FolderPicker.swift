//
//  Created on 8/18/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import UIKit

extension BrowseViewController {
    static func pickerNavigationController(
        path: [Folder],
        closeButton: UIBarButtonItem? = nil,
        createListing: (Folder) -> FolderListingViewModel,
        createSearch: (Folder) -> SearchViewModel?,
        createRouter: (UIViewController, UINavigationController) -> BrowseRouter
    ) -> UINavigationController {
        let nav = UINavigationController()
        pushBrowseControllers(
            path: path,
            onto: nav, animated: false,
            createListing: createListing,
            createSearch: createSearch,
            createRouter: createRouter
        )
        nav.setToolbarHidden(false, animated: false)
        if let closeButton = closeButton,
            let root = nav.viewControllers.first as? BrowseViewController
        {
            root.navigationItem.leftBarButtonItem = closeButton
        }
        return nav
    }

    static func pushBrowseControllers(
        path: [Folder],
        onto navigationController: UINavigationController,
        animated: Bool = true,
        createListing: (Folder) -> FolderListingViewModel,
        createSearch: (Folder) -> SearchViewModel?,
        createRouter: (UIViewController, UINavigationController) -> BrowseRouter
    ) {
        let controllers = path.map { folder -> UIViewController in
            let controller = Self()
            controller.listingViewModel = createListing(folder)
            controller.searchViewModel = createSearch(folder)
            controller.router = createRouter(controller, navigationController)
            return controller
        }

        navigationController.setViewControllers(
            navigationController.viewControllers + controllers,
            animated: animated
        )
    }
}
