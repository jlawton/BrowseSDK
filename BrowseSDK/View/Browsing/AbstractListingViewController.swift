//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

protocol CanShowDisabled: AnyObject {
    var showDisabled: Bool { get set }
}

protocol MultiSelectItem: AnyObject {
    var isMultiselecting: Bool { get set }
}

typealias ListingItemCell = UITableViewCell & NeedsItemViewModel & CanShowDisabled & MultiSelectItem

public class AbstractListingViewController: UITableViewController,
    NeedsListingViewModel, ListingViewModelDelegate
{

    let reuseIdentifier = "ListingItemCell"

    // MARK: - Data

    var listingViewModel: ListingViewModel? {
        didSet {
            oldValue?.delegate = nil

            title = listingViewModel?.title
            navigationItem.prompt = listingViewModel?.prompt
            listingViewModel?.delegate = self
            isMultiselecting = listingViewModel?.isMultiselecting ?? false
            configureLoadingFooter()
        }
    }

    var isMultiselecting: Bool = true {
        didSet {
            if !isMultiselecting {
                listingViewModel?.resetSelection()
            }
            tableView.reloadData()
        }
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)

        configureLoadingFooter()

        // Subclasses need to register cells for `reuseIdentifier`
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listingViewModel?.loadNextPage()
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

    // MARK: - Routing

    var router: BrowseRouter? {
        didSet {
            didSetRouter()
        }
    }

    func didSetRouter() {}

    func canBrowseTo(item: ItemViewModel) -> Bool {
        if let listing = item.listingViewModel() {
            return router?.canBrowseTo(listing: listing, search: item.searchViewModel()) ?? false
        }
        return router?.canBrowseTo(item: item) ?? false
    }

    func browseTo(item: ItemViewModel) {
        if let router = router, let listing = item.listingViewModel() {
            router.browseTo(listing: listing, search: item.searchViewModel())
            return
        }

        let behavior = router?.browseTo(item: item) ?? .deselect
        if behavior == .deselect {
            for row in tableView.indexPathsForSelectedRows ?? [] {
                tableView.deselectRow(at: row, animated: true)
            }
        }
    }

    // MARK: - UITableViewDataSource

    override public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return listingViewModel?.itemCount ?? 0
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ListingItemCell
        configure(cell, at: indexPath)
        return cell
    }

    func configure(_ cell: ListingItemCell, at indexPath: IndexPath) {
        if let viewModel = listingViewModel?.item(at: indexPath) {
            cell.showDisabled = !canBrowseTo(item: viewModel)
            cell.itemViewModel = viewModel
            cell.isMultiselecting = isMultiselecting
        }
    }

    // MARK: - UITableViewDelegate

    override public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel = listingViewModel?.item(at: indexPath) else {
            return
        }
        if isMultiselecting {
            viewModel.selected.toggle()
            if let cell = tableView.cellForRow(at: indexPath) as? ListingItemCell {
                UIView.animate(withDuration: 0.2) {
                    cell.itemViewModel = viewModel
                }
            }
            return
        }
        browseTo(item: viewModel)
    }

    override public func tableView(_: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let viewModel = listingViewModel?.item(at: indexPath) else {
            return nil
        }
        return canBrowseTo(item: viewModel) ? indexPath : nil
    }

    // MARK: - Paging

    override public func tableView(_: UITableView, willDisplay _: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let count = listingViewModel?.itemCount else {
            return
        }
        if indexPath.row >= count - 3 {
            listingViewModel?.loadNextPage()
        }
    }

    // MARK: - Refreshing

    @IBAction private func refresh(_: UIRefreshControl) {
        listingViewModel?.reloadFirstPage()
    }

    // MARK: - ListingViewModelDelegate

    func listingItemsChanged(_ viewModel: ListingViewModel) {
        assert(viewModel === listingViewModel)
        tableView?.reloadData()
        refreshControl?.endRefreshing()
        configureLoadingFooter()
    }

    func listingTitleChanged(_ viewModel: ListingViewModel) {
        title = viewModel.title
    }

    func isMultiselectingChanged(_ viewModel: ListingViewModel) {
        isMultiselecting = viewModel.isMultiselecting
    }

    // MARK: - Footer

    func configureLoadingFooter() {
        if !isViewLoaded {
            return
        }
        if let tableView = tableView {
            tableView.tableFooterView = createLoadingFooter(tableView)
        }
    }

    func createLoadingFooter(_ tableView: UITableView) -> UIView? {
        if listingViewModel?.isFinishedPaging ?? true {
            return nil
        }

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
        spinner.startAnimating()
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            spinner.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12)
        ])
        return view
    }
}
