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
            configureLoadingFooter()
        }
    }

    var isMultiselecting: Bool = false {
        didSet {
            if !isMultiselecting {
                listingViewModel?.resetSelection()
            }
            tableView.reloadData()

            navigationItem.rightBarButtonItems = rightNagivationItems(multiselecting: isMultiselecting)
            toolbarItems = selectionToolbarItems()
        }
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        isMultiselecting = false

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)

        navigationItem.rightBarButtonItems = rightNagivationItems(multiselecting: isMultiselecting)
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
        return false
    }

    func browseTo(item: ItemViewModel) -> Bool {
        if let router = router, let listing = item.listingViewModel() {
            router.browseTo(listing: listing, search: item.searchViewModel())
            return true
        }
        return false
    }

    func canMultiselect(item: ItemViewModel) -> Bool {
        if let router = router {
            return router.canSelect(item: item)
        }
        return false
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
            cell.showDisabled = !canBrowseTo(item: viewModel) && !canMultiselect(item: viewModel)
            cell.itemViewModel = viewModel
            cell.isMultiselecting = isMultiselecting
        }
    }

    // MARK: - UITableViewDelegate

    override public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel = listingViewModel?.item(at: indexPath) else {
            return
        }

        if !isMultiselecting {
            if browseTo(item: viewModel) {
                return
            }
            if canMultiselect(item: viewModel) {
                isMultiselecting = true
            }
            else {
                return
            }
        }

        // Multiselecting
        viewModel.selected.toggle()
        if let cell = tableView.cellForRow(at: indexPath) as? ListingItemCell {
            UIView.animate(withDuration: 0.2) {
                cell.itemViewModel = viewModel
            }
            toolbarItems = selectionToolbarItems()
        }
    }

    override public func tableView(_: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let viewModel = listingViewModel?.item(at: indexPath) else {
            return nil
        }
        return canBrowseTo(item: viewModel) || canMultiselect(item: viewModel) ? indexPath : nil
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

    // MARK: - Selecting

    private func rightNagivationItems(multiselecting: Bool) -> [UIBarButtonItem] {
        if multiselecting {
            return [
                UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(toggleMultiselect))
            ]
        }
        else {
            return [
                UIBarButtonItem(
                    title: NSLocalizedString("Select", comment: "Enter selection mode for files and filders."),
                    style: .plain,
                    target: self, action: #selector(toggleMultiselect)
                )
            ]
        }
    }

    @objc private func toggleMultiselect() {
        isMultiselecting.toggle()
    }

    //

    func selectionToolbarItems() -> [UIBarButtonItem] {
        let selectedItemCount = listingViewModel?.selectedItems().count ?? 0
        let confirmationTitle = NSString.localizedStringWithFormat(
            NSLocalizedString("Select %d items", comment: "Confirm the selected files, folders and weblinks") as NSString,
            selectedItemCount
        )

        let confirmButton = UIBarButtonItem(
            title: confirmationTitle as String?,
            style: .plain,
            target: self, action: #selector(confirmTapped)
        )
        confirmButton.isEnabled = (selectedItemCount > 0)

        return [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            confirmButton
        ]
    }

    @objc private func confirmTapped() {
        print("Confirm from \(String(describing: self))")
    }
}
