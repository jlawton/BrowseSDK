//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

class ListingItemCell: UITableViewCell {

    static let reuseIdentifier = "ListingItemCell"

    var itemViewModel: ItemViewModel? {
        didSet {
            oldValue?.cancelThumbnailLoading()

            textLabel?.text = itemViewModel?.name
            let configuration = UIImage.SymbolConfiguration(pointSize: CGFloat(ItemViewModel.preferredThumbnailSize()))
            if itemViewModel?.isFolder == true {
                accessoryType = .disclosureIndicator
                imageView?.image = UIImage(systemName: "folder.fill", withConfiguration: configuration)
            }
            else {
                accessoryType = .none
                imageView?.image = UIImage(systemName: "doc.fill", withConfiguration: configuration)
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
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        itemViewModel = nil
    }
}
