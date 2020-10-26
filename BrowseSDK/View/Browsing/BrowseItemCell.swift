//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

class BrowseItemCell: UITableViewCell, NeedsItemViewModel, CanShowDisabled, MultiSelectItem {

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

    var isMultiselecting: Bool = false {
        didSet {
            if let model = itemViewModel {
                setBackgroundAndAccessory(viewModel: model, isMultiSelecting: isMultiselecting)
            }
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
                setBackgroundAndAccessory(viewModel: model, isMultiSelecting: isMultiselecting)
            }
        }
    }

    private func setBackgroundAndAccessory(viewModel: ItemViewModel, isMultiSelecting _: Bool) {
        if isMultiselecting {
            accessoryView = nil
            selectionStyle = .none
            accessoryType = viewModel.selected ? .checkmark : .none
            backgroundColor = viewModel.selected ? .secondarySystemBackground : nil
        }
        else {
            accessoryView = nil
            selectionStyle = .default
            accessoryType = viewModel.isFolder ? .disclosureIndicator : .none
            backgroundColor = nil
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        showDisabled = false
        itemViewModel = nil
        isMultiselecting = false
    }
}
