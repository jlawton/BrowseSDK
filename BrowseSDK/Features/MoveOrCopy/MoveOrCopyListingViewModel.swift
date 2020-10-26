//
//  Created on 8/17/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import Foundation
import UIKit

class MoveOrCopyToFolderListingViewModel: FolderListingViewModel {
    let actionViewModel: MoveOrCopyViewModel

    init(actionViewModel: MoveOrCopyViewModel, folder: Folder, provider: BoxFolderProvider, createEnumerator: @escaping () -> BoxEnumerator) {
        self.actionViewModel = actionViewModel
        super.init(
            folder: folder,
            provider: provider,
            createEnumerator: createEnumerator
        )
    }

    override func itemViewModel(for item: FolderItem) -> ItemViewModel {
        MoveOrCopyItemViewModel(actionViewModel: actionViewModel, item: item, provider: provider)
    }

    override var prompt: String? {
        "Select destination folder"
    }

    override func rightBarButtonItems(router _: BrowseRouter?) -> [UIBarButtonItem] {
        []
    }

    override func toolbarItems() -> [UIBarButtonItem] {
        let actions = actionViewModel.possibleActions(to: folder)

        let copyButton = UIBarButtonItem(
            title: "Copy Here",
            style: .plain,
            target: self, action: #selector(copyTapped)
        )
        copyButton.isEnabled = actions.contains(.copy)

        let moveButton = UIBarButtonItem(
            title: "Move Here",
            style: .plain,
            target: self, action: #selector(moveTapped)
        )
        moveButton.isEnabled = actions.contains(.move)

        return [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            copyButton,
            moveButton
        ]
    }

    @objc private func copyTapped() {
        actionViewModel.copy(to: folder.id) { _ in
        }
    }

    @objc private func moveTapped() {
        actionViewModel.move(to: folder.id) { _ in
        }
    }
}
