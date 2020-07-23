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
        withAncestors: Bool = false,
        configuration: BrowseConfiguration = BrowseConfiguration(),
        withCloseButton: Bool = false
    ) -> UINavigationController {
        let nav = UINavigationController()
        pushBrowseController(
            client: client,
            folder: folder, withAncestors: withAncestors,
            onto: nav, animated: false, configuration: configuration
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
        configuration: BrowseConfiguration = BrowseConfiguration()
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
            additionalFields: configuration.additionalFields
        )
        let controllers = folders.map { folder -> UIViewController in
            let controller = BrowseViewController()
            controller.configure(
                provider: provider, folder: folder,
                navigationController: navigationController, configuration: configuration
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
        provider: BoxFolderProvider,
        folder: Folder,
        navigationController: UINavigationController,
        configuration: BrowseConfiguration
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
            source: self,
            navigationController: navigationController,
            configuration: configuration
        )
    }

    @objc
    private func closeButtonPressed(_: AnyObject?) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
