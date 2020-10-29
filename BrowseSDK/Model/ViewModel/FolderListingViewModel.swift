//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import Foundation
import UIKit

protocol FolderListingViewModelDelegate: ListingViewModelDelegate {
    func folderInfoChanged(_ viewModel: FolderListingViewModel)
    func folderInfoFailed(_ viewModel: FolderListingViewModel, error: BoxSDKError)
}

/// A refinement of ListingViewModel for folder listing.
///
/// Main features:
/// * Title is set from folder name.
/// * Exposes a folder object.
/// * Folder info can be refreshed. Even when folders aren't being changed often,
///   This is useful to allow providing a partial folder object and fetching one
///   with complete permission info. The common case would be fetching the root
///   folder starting with the equivalent of Folder(id: 0, name: "All Files").
class FolderListingViewModel: ListingViewModel {
    private(set) var folder: Folder {
        didSet {
            title = folder.name ?? ""
            folderListingDelegate?.folderInfoChanged(self)
        }
    }

    init(folder: Folder, provider: BoxFolderProvider, createEnumerator: @escaping () -> BoxEnumerator) {
        self.folder = folder
        super.init(
            title: folder.name ?? "",
            provider: provider,
            createEnumerator: createEnumerator
        )
    }

    func refreshFolderInfo() {
        provider.folderInfo(for: folder.id) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                switch result {
                case let .success(folder):
                    self.folder = folder
                case let .failure(error):
                    self.folderListingDelegate?.folderInfoFailed(self, error: error)
                }
            }
        }
    }

    private var folderListingDelegate: FolderListingViewModelDelegate? {
        delegate as? FolderListingViewModelDelegate
    }
}

extension FolderListingViewModelDelegate {
    func folderInfoChanged(_: FolderListingViewModel) {}
    func folderInfoFailed(_: FolderListingViewModel, error _: BoxSDKError) {}
}
