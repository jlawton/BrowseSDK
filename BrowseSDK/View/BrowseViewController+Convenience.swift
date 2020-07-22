//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import UIKit

public extension BrowseViewController {
    static func browseNavigationController(
        client: BoxClient,
        browseToFile: BrowseToFile = .noFileAction
    ) -> UINavigationController {
        let controller = BrowseViewController(nibName: nil, bundle: nil)
        let nav = UINavigationController(rootViewController: controller)
        controller.configure(client: client, navigationController: nav, browseToFile: browseToFile)
        return nav
    }

    static func pushBrowseController(
        client: BoxClient,
        onto navigationController: UINavigationController,
        animated: Bool = true,
        browseToFile: BrowseToFile = .noFileAction
    ) {
        let controller = BrowseViewController(nibName: nil, bundle: nil)
        controller.configure(client: client, navigationController: navigationController, browseToFile: browseToFile)
        navigationController.pushViewController(controller, animated: animated)
    }
}

private extension BrowseViewController {
    func configure(
        client: BoxClient,
        navigationController: UINavigationController,
        browseToFile: BrowseToFile
    ) {
        let provider = BoxFolderProvider(client: client)
        listingViewModel = FolderListingViewModel(
            folder: provider.rootFolder,
            provider: provider,
            createEnumerator: { provider.rootEnumerator() }
        )

        searchViewModel = SearchViewModel(
            provider: provider,
            folderID: BoxFolderProvider.root
        )

        router = DefaultBrowseRouter(
            source: self,
            navigationController: navigationController,
            browseToFile: browseToFile
        )
    }
}
