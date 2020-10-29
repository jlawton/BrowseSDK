//
//  Created on 7/18/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

public class BrowseViewController: AbstractListingViewController, FolderListingViewModelDelegate {

    // MARK: - Data

    override func didSetRouter() {
        super.didSetRouter()
        if let searchResults = navigationItem.searchController?.searchResultsController as? SearchResultsViewController {
            searchResults.router = router
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
//            searchController.searchBar.searchTextField.inputAccessoryView = UIToolbar(frame: CGRect(x: 0, y: 0, width: 200, height: 64))
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
            folderInfoChanged(viewModel)
            viewModel.refreshFolderInfo()
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // HACK: UISearchController has lifecycle bugs
        if let search = navigationItem.searchController,
            search.isActive,
            let resultsVC = search.searchResultsController as? UITableViewController,
            let results = resultsVC.tableView
        {
            for indexPath in results.indexPathsForSelectedRows ?? [] {
                results.deselectRow(at: indexPath, animated: true)
            }
        }
    }

    override public func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        // Disable search while editing
        if let searchBar = navigationItem.searchController?.searchBar {
            searchBar.searchTextField.isEnabled = !editing
        }
    }
}

// MARK: - Search

extension BrowseViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        searchViewModel?.update(query: searchController.searchBar.text ?? "")
    }
}
