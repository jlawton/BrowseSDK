//
//  Created on 10/29/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import UIKit

public class BoxSharedLinkPicker: UINavigationController {
    public static var requiredFields: [String] {
        Array(
            Set(BoxFolderProvider.requiredFields).union(
                BoxSharedLinkPickerSelectionHandler.requiredFields)
        )
    }

    var didSelect: ([FolderItem]) -> Void
    var didFail: ([(FolderItem, BoxSDKError)]) -> Void = { _ in }
    var willCreateSharedLinks: (Progress) -> Void = { _ in }

    public init(
        client: BoxClient,
        folder: Folder,
        withCloseButton: Bool = true,
        didSelect: @escaping ([FolderItem]) -> Void = { _ in }
    ) {
        self.didSelect = didSelect

        super.init(nibName: nil, bundle: nil)

        let provider = BoxFolderProvider(
            client: client,
            additionalFields: Self.requiredFields
        )
        let selectionHandler = BoxSharedLinkPickerSelectionHandler(
            provider: provider,
            picker: self
        )

        BrowseViewController.pushBrowseController(
            provider: provider,
            selectionHandler: selectionHandler,
            folder: folder, withAncestors: true,
            onto: self, animated: false
        )
        if withCloseButton,
           let root = viewControllers.first as? BrowseViewController
        {
            root.navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self, action: #selector(closeButtonPressed(_:))
            )
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func closeButtonPressed(_: AnyObject?) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
