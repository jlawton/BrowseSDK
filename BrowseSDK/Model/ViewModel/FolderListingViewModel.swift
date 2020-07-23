//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import Foundation

protocol FolderListingViewModelDelegate: ListingViewModelDelegate {
    func folderInfoChanged(_ viewModel: FolderListingViewModel)
    func folderInfoFailed(_ viewModel: FolderListingViewModel, error: BoxSDKError)
}

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

    override func folderCreationViewModel() -> CreateFolderViewModel? {
        if folder.permissions?.canUpload ?? false {
            return CreateFolderViewModel(folder: folder, provider: provider)
        }
        return nil
    }

    private var folderListingDelegate: FolderListingViewModelDelegate? {
        delegate as? FolderListingViewModelDelegate
    }
}

extension FolderListingViewModelDelegate {
    func folderInfoChanged(_: FolderListingViewModel) {}
    func folderInfoFailed(_: FolderListingViewModel, error _: BoxSDKError) {}
}
