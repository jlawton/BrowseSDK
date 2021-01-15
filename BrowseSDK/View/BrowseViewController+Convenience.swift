//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import UIKit

extension BrowseViewController {
    static var requiredFields: [String] {
        BoxFolderProvider.requiredFields
    }
}

extension BrowseViewController {
    static func pushBrowseController(
        provider: BoxFolderProvider,
        router: BrowseRouter,
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

        let controllers = folders.map { folder -> UIViewController in
            let controller = BrowseViewController()
            controller.router = router
            controller.configure(provider: provider, folder: folder)
            return controller
        }

        navigationController.setViewControllers(
            navigationController.viewControllers + controllers,
            animated: animated
        )
    }

    private func configure(
        provider: BoxFolderProvider,
        folder: Folder
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
    }
}
