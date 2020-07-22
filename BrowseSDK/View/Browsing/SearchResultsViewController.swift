//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

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
}
