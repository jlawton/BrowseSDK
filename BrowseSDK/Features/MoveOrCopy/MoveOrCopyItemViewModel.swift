//
//  Created on 8/19/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK

class MoveOrCopyItemViewModel: ItemViewModel {
    let actionViewModel: MoveOrCopyViewModel

    init(actionViewModel: MoveOrCopyViewModel, item: FolderItem, provider: BoxFolderProvider) {
        self.actionViewModel = actionViewModel
        super.init(item: item, provider: provider)
    }

    override func listingViewModel() -> ListingViewModel? {
        guard case let .folder(folder) = item, actionViewModel.canMoveOrCopy(to: folder) else {
            return nil
        }
        let provider = self.provider
        let identifier = self.identifier
        return MoveOrCopyToFolderListingViewModel(
            actionViewModel: actionViewModel,
            folder: folder,
            provider: provider,
            createEnumerator: { provider.enumerator(for: identifier) }
        )
    }

    override func searchViewModel() -> SearchViewModel? {
        nil
    }
}
