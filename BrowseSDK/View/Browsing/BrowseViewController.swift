//
//  Created on 7/18/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

/// Lists the contents of a Box folder.
///
/// * General listing logic in base class.
///
/// With the help of FolderListingViewModel:
/// * Search for descendants of the folder.
/// * Refresh details about the folder (eg name, permissions) when presented.
public class BrowseViewController: AbstractListingViewController, FolderListingViewModelDelegate {

    // MARK: - Data

    var isEditingSearchResults: Bool = false

    override func didSetRouter() {
        super.didSetRouter()
        if let searchController = navigationItem.searchController,
           let searchResults = searchController.searchResultsController as? SearchResultsViewController
        {
            searchResults.router = router

            if router?.supportsSelection ?? false {
                // FIXME: Doesn't handle safe area when keyboard is hidden
                let toolbar = UIToolbar()
                toolbar.items = [
                    UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                    UIBarButtonItem(
                        title: NSLocalizedString(
                            "Select",
                            comment: "Enter selection mode for files and folders."
                        ),
                        style: .plain,
                        target: searchResults, action: #selector(SearchResultsViewController.toggleEditing)
                    )
                ]
                toolbar.sizeToFit()
                searchController.searchBar.searchTextField.inputAccessoryView = toolbar
            }
            else {
                searchController.searchBar.searchTextField.inputAccessoryView = nil
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
            searchResultsController.didSetEditing = { [weak self] editing in
                if let self = self {
                    if editing {
                        self.navigationItem.searchController?.searchBar.endEditing(true)
                    }
                    self.isEditingSearchResults = editing
                    self.selectionUpdated(animated: true)
                }
            }
            searchResultsController.didUpdateSelection = { [weak self] in
                self?.selectionUpdated()
            }

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
           let results = resultsVC.tableView,
           let selectedIndexPaths = results.indexPathsForSelectedRows
        {
            for indexPath in selectedIndexPaths {
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

    // MARK: - Selection

    override func selectedItems() -> [ItemViewModel] {
        if isEditingSearchResults {
            if let results = navigationItem.searchController?.searchResultsController as? SearchResultsViewController {
                return results.selectedItems()
            }
        }
        return super.selectedItems()
    }

    override var isSelecting: Bool {
        super.isSelecting || isEditingSearchResults
    }
}

// MARK: - Search

extension BrowseViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        searchViewModel?.update(query: searchController.searchBar.text ?? "")
        if let results = searchController.searchResultsController, results.isEditing {
            results.setEditing(false, animated: true)
        }
    }
}
