//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

/// List search results within some context in Box.
///
/// * General listing logic in base class.
/// * Actual search input is handled in the context the search bar is displayed.
/// * Uses a special search style for cells that shows their location in Box
///   instead of the usual details.
///
public class SearchResultsViewController: AbstractListingViewController {

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(BrowseItemCell.self, forCellReuseIdentifier: reuseIdentifier)
    }

    override func configure(_ cell: ListingItemCell, at indexPath: IndexPath) {
        if let browseCell = cell as? BrowseItemCell {
            browseCell.mode = .search
        }
        super.configure(cell, at: indexPath)
    }

    override public func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        didSetEditing(editing)
    }

    var didSetEditing: (Bool) -> Void = { _ in }

    override func selectionUpdated(animated: Bool = false) {
        super.selectionUpdated(animated: animated)
        didUpdateSelection()
    }

    var didUpdateSelection: () -> Void = {}

    @objc func toggleEditing() {
        setEditing(!isEditing, animated: true)
    }
}
