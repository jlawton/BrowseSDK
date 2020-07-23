//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK

class FolderListingViewModel: ListingViewModel {
    let folder: Folder

    init(folder: Folder, provider: BoxFolderProvider, createEnumerator: @escaping () -> BoxEnumerator) {
        self.folder = folder
        super.init(
            title: folder.name ?? "",
            provider: provider,
            createEnumerator: createEnumerator
        )
    }

    override func folderCreationViewModel() -> CreateFolderViewModel? {
        CreateFolderViewModel(folder: folder, provider: provider)
    }
}
