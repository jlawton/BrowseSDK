//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import UIKit

struct FolderActions {
    let listingViewModel: FolderListingViewModel
    let router: BrowseRouter?
    let customizations: FolderActionCustomization
}

extension FolderActions {
    static func actionButtons(
        listingViewModel: FolderListingViewModel,
        router: BrowseRouter?,
        customizations _: FolderActionCustomization?
    ) -> [UIBarButtonItem] {
        FolderActions(
            listingViewModel: listingViewModel,
            router: router,
            customizations: router?.folderActionCustomization ?? FolderActionCustomization()
        ).actionButtons()
    }
}

extension FolderActions {
    private func actionID(_ id: DefaultFolderActionIdentifier) -> UIAction.Identifier {
        UIAction.Identifier(id.rawValue)
    }

    func actionButtons() -> [UIBarButtonItem] {
        return customizations.customizeActionBarItems(
            for: listingViewModel.folder,
            suggested: [
                addToFolderMenuButton()
            ].compactMap { $0 }
        )
    }

    func addToFolderMenuButton() -> UIBarButtonItem? {
        // Get default menu
        var menu: UIMenu? = addToFolderMenu()
        // Allow customization
        menu = customizations.customizeAddMenu(
            for: listingViewModel.folder, suggested: menu
        )
        // Stick it in a button
        if let menu = menu {
            return MenuButton(systemItem: .add, menu: menu).barButtonItem()
        }
        return nil
    }

    func addToFolderMenu() -> UIMenu {
        let children: [UIMenuElement] = [
            createFolderAction()
//            importMedia()
        ].compactMap { $0 }

        return UIMenu(
            title: "",
            children: children
        )
    }

    func createFolderAction() -> UIAction? {
        guard let viewModel = listingViewModel.folderCreationViewModel(),
            let router = router, router.canPresent(folderCreation: viewModel)
        else {
            return nil
        }
        return UIAction(
            title: "Create folder",
            image: UIImage(systemName: "folder.badge.plus"),
            identifier: actionID(.createFolder),
            handler: { _ in
                router.present(folderCreation: viewModel)
            }
        )
    }

    func importMedia() -> UIAction? {
        return UIAction(
            title: "Import Photo",
            image: UIImage(systemName: "photo.on.rectangle"),
            identifier: actionID(.importPhoto),
            handler: { _ in /* TODO: */ }
        )
    }
}
