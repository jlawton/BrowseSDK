//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

protocol BrowseRouter {
    func canBrowseTo(item: ItemViewModel) -> Bool
    func browseTo(item: ItemViewModel) -> SelectionBehavior
    func canPresent(folderCreation: CreateFolderViewModel) -> Bool
    func present(folderCreation: CreateFolderViewModel)
    var folderActionCustomization: FolderActionCustomization { get }
}

class DefaultBrowseRouter: BrowseRouter {
    let configuration: BrowseConfiguration
    weak var source: UIViewController?
    weak var navigationController: UINavigationController?

    init(source: UIViewController, navigationController: UINavigationController, configuration: BrowseConfiguration) {
        self.source = source
        self.navigationController = navigationController
        self.configuration = configuration
    }

    var folderActionCustomization: FolderActionCustomization {
        configuration.folderActions
    }

    func canBrowseTo(item: ItemViewModel) -> Bool {
        if item.isFolder {
            return true
        }
        else if let file = item.fileModel {
            return configuration.browseToFile.canBrowseToFile(file)
        }
        else {
            return false
        }
    }

    func browseTo(item: ItemViewModel) -> SelectionBehavior {
        if let nav = navigationController, item.isFolder {
            let dest = BrowseViewController(nibName: nil, bundle: nil)
            dest.router = DefaultBrowseRouter(
                source: dest,
                navigationController: nav,
                configuration: configuration
            )
            dest.listingViewModel = item.listingViewModel()
            dest.searchViewModel = item.searchViewModel()
            nav.pushViewController(dest, animated: true)
            return .remainSelected
        }
        else if let source = source, let file = item.fileModel {
            return configuration.browseToFile.browseToFile(file, source)
        }
        return .deselect
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
}
