//
//  Created on 7/18/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

public class BrowseViewController: AbstractListingViewController {

    lazy var actions = FolderActions(FolderActionHandlers(
        createFolder: { [weak self] in
            guard let viewModel = self?.listingViewModel?.folderCreationViewModel() else {
                return
            }
            let viewController = CreateFolderViewController.forModalPresentation(viewModel)
            self?.present(viewController, animated: true, completion: nil)
        },
        importMedia: { print("IMPORT MEDIA") }
    ))

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

        navigationItem.rightBarButtonItem = actions.addToFolderMenuButton

        // Context for search presentation
        definesPresentationContext = true
    }

    override public func viewWillAppear(_ animated: Bool) {
        assert(listingViewModel != nil)
        super.viewWillAppear(animated)
    }
}

// MARK: - Search

extension BrowseViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        searchViewModel?.update(query: searchController.searchBar.text ?? "")
    }
}
