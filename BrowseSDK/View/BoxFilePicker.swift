//
//  Created on 10/7/21.
//  Copyright © 2021 Box. All rights reserved.
//

import BoxSDK
import UIKit

public class BoxFilePicker: UINavigationController {

    public init(
        client: BoxClient,
        folder: Folder,
        withCloseButton: Bool = true,
        additionalFields: [String]? = nil,
        canPick: @escaping (File) -> Bool = { _ in false },
        didPick: @escaping (File) -> Void = { _ in }
    ) {
        super.init(nibName: nil, bundle: nil)

        let provider = BoxFolderProvider(
            client: client,
            additionalFields: additionalFields
        )
        let handler = BoxFilePickerHandler(canAct: canPick, act: didPick)

        let router = DefaultBrowseRouter(
            navigationController: self,
            fileBrowseHandler: handler
        )

        BrowseViewController.pushBrowseController(
            provider: provider,
            router: router,
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
