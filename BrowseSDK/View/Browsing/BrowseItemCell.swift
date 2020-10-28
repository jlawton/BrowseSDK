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

    var showDisabledWhileNotEditing: Bool = false {
        didSet {
            if !isEditing {
                showDisabled = showDisabledWhileNotEditing
            }
        }
    }

    var showDisabledDuringEditing: Bool = false {
        didSet {
            if isEditing {
                showDisabled = showDisabledDuringEditing
            }
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        showDisabled = editing
            ? showDisabledDuringEditing
            : showDisabledWhileNotEditing
    }

    private var showDisabled: Bool = false {
        didSet {
            textLabel?.textColor = showDisabled ? .secondaryLabel : .label
        }
    }

    var itemViewModel: ItemViewModel? {
        didSet {
            // Deal with thumbnail loading
            if oldValue != itemViewModel {
                oldValue?.cancelThumbnailLoading()
                imageView?.image = (itemViewModel?.icon).map(UIImage.icon(_:))
                if !(itemViewModel?.isFolder ?? true) {
                    itemViewModel?.requestThumbnail { thumb in
                        self.imageView?.image = thumb
                        self.setNeedsLayout()
                    }
                }
            }

            textLabel?.text = itemViewModel?.name
            detailTextLabel?.text = itemViewModel?.detail(for: mode)
            detailTextLabel?.textColor = .secondaryLabel

            if let model = itemViewModel {
                accessoryType = model.isFolder ? .disclosureIndicator : .none
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        itemViewModel = nil
        showDisabledWhileNotEditing = false
        showDisabledDuringEditing = false
    }
}
