//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

class BrowseItemCell: UITableViewCell, NeedsItemViewModel {

    override init(style _: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var itemViewModel: ItemViewModel? {
        didSet {
            oldValue?.cancelThumbnailLoading()

            textLabel?.text = itemViewModel?.name
            detailTextLabel?.text = itemViewModel?.detail

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
            if itemViewModel?.allowsReading == false {
                textLabel?.textColor = .secondaryLabel
            }
            else {
                textLabel?.textColor = .label
            }
            detailTextLabel?.textColor = .secondaryLabel
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        itemViewModel = nil
    }
}
