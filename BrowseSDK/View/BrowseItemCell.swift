//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

class BrowseItemCell: UITableViewCell, NeedsItemViewModel, CanShowDisabled {

    override init(style _: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var mode: ItemViewModel.Mode = .browse

    var showDisabled: Bool = false {
        didSet {
            textLabel?.textColor = showDisabled ? .secondaryLabel : .label
        }
    }

    var itemViewModel: ItemViewModel? {
        didSet {
            oldValue?.cancelThumbnailLoading()

            textLabel?.text = itemViewModel?.name
            detailTextLabel?.text = itemViewModel?.detail(for: mode)

            if itemViewModel?.isFolder == true {
                accessoryType = .disclosureIndicator
                imageView?.image = (itemViewModel?.icon).map(UIImage.icon(_:))
            }
            else {
                accessoryType = .none
                imageView?.image = (itemViewModel?.icon).map(UIImage.icon(_:))
                itemViewModel?.requestThumbnail { thumb in
                    self.imageView?.image = thumb
                    self.setNeedsLayout()
                }
            }
            detailTextLabel?.textColor = .secondaryLabel
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        showDisabled = false
        itemViewModel = nil
    }
}
