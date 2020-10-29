//
//  Created on 7/19/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import Foundation
import UIKit

protocol ListingViewModelDelegate: AnyObject {
    func listingItemsChanged(_ viewModel: ListingViewModel, appendingOnly: Bool)
    func listingTitleChanged(_ viewModel: ListingViewModel)
}

protocol NeedsListingViewModel: AnyObject {
    var listingViewModel: ListingViewModel? { get set }
}

/// Represents a list of Box items, backed by a BoxEnumerator (usually a folder
/// listing or search on the Box API).
///
/// Main features:
/// * Cache the pages of items that come back from the enumerator, and serve them
///   as a simple interface suatable to back a UITableView.
/// * Notify a delegate when the cached items change.
/// * Implement list refresh by creating a new enumerator and replacing the cached
///   items once the first page comes back, which is reasonable semantics for pull
///   to refresh in the view, and for handling search query updates.
/// * Title and prompt complete the information for a bare-bones list view.
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

    var prompt: String? { nil }

    func itemViewModel(for item: FolderItem) -> ItemViewModel {
        ItemViewModel(item: item, provider: provider)
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
                .success(page.map(self.itemViewModel(for:)))
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
            self.delegate?.listingItemsChanged(self, appendingOnly: !firstPage)
        }
    }
}

extension ListingViewModelDelegate {
    func listingTitleChanged(_: ListingViewModel) {}
}
