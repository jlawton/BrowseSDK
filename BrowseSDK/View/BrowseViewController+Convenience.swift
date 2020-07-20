//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import UIKit

public extension BrowseViewController {
    static func browseNavigationController(client: BoxClient) -> UINavigationController {
        let controller = BrowseViewController(nibName: nil, bundle: nil)
        let nav = UINavigationController(rootViewController: controller)
        controller.configure(client: client, navigationController: nav)
        return nav
    }

    static func pushBrowseController(client: BoxClient, onto navigationController: UINavigationController, animated: Bool = true) {
        let controller = BrowseViewController(nibName: nil, bundle: nil)
        controller.configure(client: client, navigationController: navigationController)
        navigationController.pushViewController(controller, animated: animated)
    }
}

private extension BrowseViewController {
    func configure(client: BoxClient, navigationController: UINavigationController) {
        let provider = BoxFolderProvider(client: client)
        listingViewModel = ListingViewModel(
            title: "All Files",
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
            browseToFile: { _, _ in false }
        )
    }
}
