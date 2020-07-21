//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import UIKit

public extension BrowseViewController {
    typealias BrowseToFile = (_ identifier: String, _ from: UIViewController) -> Bool

    static func browseNavigationController(
        client: BoxClient,
        browseToFile: @escaping BrowseToFile = { _, _ in false }
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
        browseToFile: @escaping BrowseToFile = { _, _ in false }
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
        browseToFile: @escaping BrowseToFile
    ) {
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
            browseToFile: browseToFile
        )
    }
}
