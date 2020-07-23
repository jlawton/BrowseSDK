//
//  Created on 7/19/20.
//  Copyright © 2020 Box. All rights reserved.
//

import Foundation
import UIKit

protocol ListingViewModelDelegate: AnyObject {
    func listingItemsChanged(_ viewModel: ListingViewModel)
    func listingTitleChanged(_ viewModel: ListingViewModel)
}

protocol NeedsListingViewModel: AnyObject {
    var listingViewModel: ListingViewModel? { get set }
}

class ListingViewModel {

    weak var delegate: ListingViewModelDelegate?

    private var itemViewModels: [ItemViewModel] = []
    let provider: BoxFolderProvider
    private let createEnumerator: () -> BoxEnumerator
    private var enumerator: BoxEnumerator?

    init(title: String, provider: BoxFolderProvider, createEnumerator: @escaping () -> BoxEnumerator) {
        self.title = title
        self.provider = provider
        self.createEnumerator = createEnumerator
    }

    // MARK: - Data Source

    var title: String {
        didSet {
            if title != oldValue {
                delegate?.listingTitleChanged(self)
            }
        }
    }

    private(set) var isFinishedPaging: Bool = false

    func item(at indexPath: IndexPath) -> ItemViewModel? {
        return itemViewModels[indexPath.row]
    }

    var itemCount: Int {
        return itemViewModels.count
    }

    // MARK: - Capabilities provided by subclasses

    func folderCreationViewModel() -> CreateFolderViewModel? {
        return nil
    }

    // MARK: - Actions

    private var pageLoadProgress: Progress?

    func reloadFirstPage() {
        pageLoadProgress?.cancel()
        pageLoadProgress = nil
        enumerator = nil
        isFinishedPaging = false
        loadNextPage()
    }

    func loadNextPage() {
        guard pageLoadProgress == nil else {
            return
        }
        if isFinishedPaging {
            return
        }

        let firstPage = (enumerator == nil)
        if firstPage {
            enumerator = createEnumerator()
        }

        let progress = Progress.discreteProgress(totalUnitCount: 1)
        pageLoadProgress = progress

        enumerator?.getNextPage { result in
            let resultVM = result.flatMap { page -> Result<[ItemViewModel], Error> in
                .success(page.map { item in
                    ItemViewModel(item: item, provider: self.provider)
                })
            }

            guard !progress.isCancelled else {
                return
            }
            progress.completedUnitCount = 1
            switch resultVM {
            case let .success(page):
                if firstPage {
                    self.itemViewModels = page
                }
                else {
                    self.itemViewModels += page
                }
                if page.isEmpty {
                    self.isFinishedPaging = true
                }
            case .failure:
                self.isFinishedPaging = true
            }
            self.pageLoadProgress = nil
            self.delegate?.listingItemsChanged(self)
        }
    }
}

extension ListingViewModelDelegate {
    func listingTitleChanged(_: ListingViewModel) {}
}
