//
//  Created on 7/18/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

public class BrowseViewController: AbstractListingViewController {

    // MARK: - Data

    override var router: BrowseRouter? {
        get { super.router }
        set {
            super.router = newValue
            if let searchResults = navigationItem.searchController?.searchResultsController as? SearchResultsViewController {
                searchResults.router = newValue
            }
        }
    }

    var searchViewModel: SearchViewModel? {
        didSet {
            guard let searchVM = searchViewModel else {
                navigationItem.searchController = nil
                return
            }

            let searchResultsController = SearchResultsViewController(nibName: nil, bundle: nil)
            searchResultsController.listingViewModel = searchVM.listingViewModel
            searchResultsController.router = router

            let searchController = UISearchController(searchResultsController: searchResultsController)
            navigationItem.searchController = searchController
            searchController.searchResultsUpdater = self
        }
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(BrowseItemCell.self, forCellReuseIdentifier: reuseIdentifier)

        // Context for search presentation
        definesPresentationContext = true
    }

    override public func viewWillAppear(_ animated: Bool) {
        assert(listingViewModel != nil)
        super.viewWillAppear(animated)

        if let viewModel = listingViewModel as? FolderListingViewModel {
            navigationItem.rightBarButtonItems = FolderActions.actionButtons(
                listingViewModel: viewModel,
                router: router,
                customizations: nil
            )
        }
    }
}

// MARK: - Search

extension BrowseViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        searchViewModel?.update(query: searchController.searchBar.text ?? "")
    }
}
