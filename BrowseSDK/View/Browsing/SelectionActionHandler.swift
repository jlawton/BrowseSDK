//
//  Created on 10/27/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import Foundation

protocol BrowseViewControllerSelectionDelegate: AnyObject {
    func browseViewController(_ controller: BrowseViewController, willGenerateShareLinks progress: Progress)
    func browseViewController(_ controller: BrowseViewController, completedSelection: [String: Result<SharedLink, BoxSDKError>])
    func browseViewControllerCancelled(_ controller: BrowseViewController)
}

class SelectionActionHandler {

    private let provider: BoxFolderProvider
    private let workQueue = DispatchQueue(label: "box.SelectionActionsViewModel")

    weak var browseController: BrowseViewController?
    weak var delegate: BrowseViewControllerSelectionDelegate?

    init(provider: BoxFolderProvider) {
        self.provider = provider
    }

    func handleSelected(items vms: [ItemViewModel]) {
        let items = vms.map { $0.item }
        guard let controller = browseController else {
            return
        }

        var sharedLinks: [String: Result<SharedLink, BoxSDKError>] = [:]

        let totalProgress = Progress.discreteProgress(totalUnitCount: Int64(items.count))
        totalProgress.cancellationHandler = {
            if let controller = self.browseController {
                self.delegate?.browseViewControllerCancelled(controller)
            }
        }
        delegate?.browseViewController(controller, willGenerateShareLinks: totalProgress)

        let grp = DispatchGroup()
        for item in items {
            if totalProgress.isCancelled {
                return
            }

            grp.enter()
            let progress = provider.setSharedLink(forItem: item) { result in
                self.workQueue.async {
                    sharedLinks[item.identifier.id] = result
                    grp.leave()
                }
            }
            totalProgress.addChild(progress, withPendingUnitCount: 1)
        }

        grp.notify(queue: DispatchQueue.main) {
            if let controller = self.browseController, !totalProgress.isCancelled {
                self.delegate?.browseViewController(controller, completedSelection: sharedLinks)
            }
        }
    }
}
