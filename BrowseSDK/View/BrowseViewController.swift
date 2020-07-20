//
//  Created on 7/18/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

public class BrowseViewController: AbstractListingViewController {


    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(BrowseItemCell.self, forCellReuseIdentifier: reuseIdentifier)

    }

    override public func viewWillAppear(_ animated: Bool) {
        assert(listingViewModel != nil)
        super.viewWillAppear(animated)
    }
}

