//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

typealias ListingItemCell = UITableViewCell & NeedsItemViewModel

public class AbstractListingViewController: UITableViewController,
    NeedsListingViewModel, ListingViewModelDelegate {

    let reuseIdentifier = "ListingItemCell"

    // MARK: - Data

    var listingViewModel: ListingViewModel? {
        didSet {
            oldValue?.delegate = nil

            title = listingViewModel?.title
            listingViewModel?.delegate = self
            tableView?.reloadData()
        }
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)

        // Subclasses need to register cells for `reuseIdentifier`
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listingViewModel?.loadNextPage()
    }

    // MARK: - Routing

    var router: BrowseRouter?

    func browseTo(item: ItemViewModel) {
        let success = router?.browseTo(item: item) ?? false
        if !success {
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
        cell.itemViewModel = listingViewModel?.item(at: indexPath)
    }

    // MARK: - UITableViewDelegate

    override public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel = listingViewModel?.item(at: indexPath) else {
            return
        }
        browseTo(item: viewModel)
    }

    override public func tableView(_: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let viewModel = listingViewModel?.item(at: indexPath) else {
            return nil
        }
        return (viewModel.allowsReading) ? indexPath : nil
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
    }
}
