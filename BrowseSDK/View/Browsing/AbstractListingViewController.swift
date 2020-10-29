//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

protocol CanShowDisabled: AnyObject {
    var showDisabledWhileNotEditing: Bool { get set }
    var showDisabledDuringEditing: Bool { get set }
}

typealias ListingItemCell = UITableViewCell & NeedsItemViewModel & CanShowDisabled

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

    override public func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        toolbarItems = selectionToolbarItems()
        navigationController?.setToolbarHidden(!editing, animated: animated)
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)

        navigationItem.rightBarButtonItems = [editButtonItem]
        configureLoadingFooter()

        tableView.allowsMultipleSelectionDuringEditing = true

        // Subclasses need to register cells for `reuseIdentifier`
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listingViewModel?.loadNextPage()
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
            let canSelect = canMultiselect(item: viewModel)
            let canBrowse = canBrowseTo(item: viewModel)
            cell.showDisabledWhileNotEditing = !canBrowse && !canSelect
            cell.showDisabledDuringEditing = !canSelect
            cell.itemViewModel = viewModel
        }
    }

    // MARK: - UITableViewDelegate

    override public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel = listingViewModel?.item(at: indexPath) else {
            return
        }

        if !isEditing {
            if !browseTo(item: viewModel) {
                // This is unexpected
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
        else {
            toolbarItems = selectionToolbarItems()
        }
    }

    override public func tableView(_: UITableView, didDeselectRowAt _: IndexPath) {
        toolbarItems = selectionToolbarItems()
    }

    override public func tableView(_: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let viewModel = listingViewModel?.item(at: indexPath) else {
            return nil
        }
        if !isEditing, canBrowseTo(item: viewModel) {
            return indexPath
        }
        if canMultiselect(item: viewModel) {
            if !isEditing {
                setEditing(true, animated: true)
            }
            return indexPath
        }
        return nil
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

    func listingItemsChanged(_ viewModel: ListingViewModel, appendingOnly: Bool) {
        assert(viewModel === listingViewModel)
        let selection = tableView.indexPathsForSelectedRows
        tableView?.reloadData()
        refreshControl?.endRefreshing()
        configureLoadingFooter()

        // If we only appended, we can simply keep the existing selected rows
        // Otherwise, we just let it get reset
        // TODO: Use Identifiable item view models to reconstruct the selection.
        if appendingOnly, let selection = selection {
            for indexPath in selection {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        }
        else {
            toolbarItems = selectionToolbarItems()
        }
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

    func selectionToolbarItems() -> [UIBarButtonItem] {
        let selectedItemCount = tableView.indexPathsForSelectedRows?.count ?? 0
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
        guard
            let viewModel = listingViewModel,
            let indexPaths = tableView.indexPathsForSelectedRows, !indexPaths.isEmpty
        else {
            return
        }
        let items: [ItemViewModel] = indexPaths
            .compactMap(viewModel.item(at:))

        router?.handleSelected(items: items)
    }
}
