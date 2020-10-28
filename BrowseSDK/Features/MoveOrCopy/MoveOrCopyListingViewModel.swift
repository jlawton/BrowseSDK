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

    @objc private func copyTapped() {
        actionViewModel.copy(to: folder.id) { _ in
        }
    }

    @objc private func moveTapped() {
        actionViewModel.move(to: folder.id) { _ in
        }
    }
}
