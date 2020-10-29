//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import UIKit

public extension BrowseViewController {
    static var requiredFields: [String] {
        BoxFolderProvider.requiredFields
    }

    static func browseNavigationController(
        client: BoxClient,
        folder: Folder,
        withCloseButton: Bool = true
    ) -> UINavigationController {
        let nav = UINavigationController()
        pushBrowseController(
            client: client,
            folder: folder, withAncestors: true,
            onto: nav, animated: false
        )
        nav.setToolbarHidden(false, animated: false)
        if withCloseButton,
            let root = nav.viewControllers.first as? BrowseViewController
        {
            root.navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: root, action: #selector(closeButtonPressed(_:))
            )
        }
        return nav
    }
}

private extension BrowseViewController {
    static func pushBrowseController(
        client: BoxClient,
        folder: Folder,
        withAncestors: Bool = false,
        onto navigationController: UINavigationController,
        animated: Bool = true
    ) {
        let folders: [Folder]
        if withAncestors {
            folders = (folder.pathCollection?.entries ?? []) + [folder]
        }
        else {
            folders = [folder]
        }

        let provider = BoxFolderProvider(
            client: client,
            additionalFields: SharedLinkSelectionHandler.requiredFields
        )
        let selectionHandler = SharedLinkSelectionHandler(provider: provider)

        let controllers = folders.map { folder -> UIViewController in
            let controller = BrowseViewController()
            controller.configure(
                provider: provider, folder: folder,
                navigationController: navigationController, selectionHandler: selectionHandler
            )
            return controller
        }

        navigationController.setViewControllers(
            navigationController.viewControllers + controllers,
            animated: animated
        )
    }

    func configure(
        provider: BoxFolderProvider,
        folder: Folder,
        navigationController: UINavigationController,
        selectionHandler: SelectionHandler
    ) {
        let folderID = folder.id

        listingViewModel = FolderListingViewModel(
            folder: folder,
            provider: provider,
            createEnumerator: { provider.enumerator(for: folderID) }
        )

        searchViewModel = SearchViewModel(
            provider: provider,
            folderID: folder.id
        )

        router = DefaultBrowseRouter(
            navigationController: navigationController,
            selectionHandler: selectionHandler
        )
    }

    @objc
    private func closeButtonPressed(_: AnyObject?) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
