//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import UIKit

public extension BrowseViewController {
    static func browseNavigationController(
        client: BoxClient,
        folder: Folder,
        withAncestors: Bool = false,
        browseToFile: BrowseToFile = .noFileAction,
        withCloseButton: Bool = false
    ) -> UINavigationController {
        let nav = UINavigationController()
        pushBrowseController(
            client: client,
            folder: folder, withAncestors: withAncestors,
            onto: nav, animated: false, browseToFile: browseToFile
        )
        if withCloseButton,
            let root = nav.viewControllers.first as? BrowseViewController {
            root.navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: root, action: #selector(closeButtonPressed(_:))
            )
        }
        return nav
    }

    static func pushBrowseController(
        client: BoxClient,
        folder: Folder,
        withAncestors: Bool = false,
        onto navigationController: UINavigationController,
        animated: Bool = true,
        browseToFile: BrowseToFile = .noFileAction
    ) {
        let folders: [Folder]
        if withAncestors {
            folders = (folder.pathCollection?.entries ?? []) + [folder]
        }
        else {
            folders = [folder]
        }

        let controllers = folders.map { folder -> UIViewController in
            let controller = BrowseViewController(nibName: nil, bundle: nil)
            controller.configure(
                client: client, folder: folder,
                navigationController: navigationController, browseToFile: browseToFile
            )
            return controller
        }

        navigationController.setViewControllers(
            navigationController.viewControllers + controllers,
            animated: animated
        )
    }
}

private extension BrowseViewController {
    func configure(
        client: BoxClient,
        folder: Folder,
        navigationController: UINavigationController,
        browseToFile: BrowseToFile
    ) {
        let provider = BoxFolderProvider(client: client)
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
            source: self,
            navigationController: navigationController,
            browseToFile: browseToFile
        )
    }

    @objc
    private func closeButtonPressed(_: AnyObject?) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
