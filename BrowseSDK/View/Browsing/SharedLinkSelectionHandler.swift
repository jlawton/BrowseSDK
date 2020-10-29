//
//  Created on 10/28/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import Foundation

class SharedLinkSelectionHandler: SelectionHandler {
    private let provider: BoxFolderProvider
    private let workQueue = DispatchQueue(label: "box.SharedLinkSelectionActionHandler")

    init(provider: BoxFolderProvider) {
        self.provider = provider
    }

    func canSelect(item: ItemViewModel) -> Bool {
        switch item.item {
        case let .folder(folder):
            return (folder.sharedLink != nil)
                || (folder.permissions?.canShare ?? false)
        case let .file(file):
            return (file.sharedLink != nil)
                || (file.permissions?.canShare ?? false)
        case let .webLink(link):
            return (link.sharedLink != nil)
                || (link.permissions?.canShare ?? false)
        }
    }

    func handleSelected(items: [ItemViewModel]) {
        handleSelected(items: items) { _ in
        } completion: { _ in
        }
    }

    func handleSelected(items vms: [ItemViewModel], progress: (Progress) -> Void, completion: @escaping ([String: Result<SharedLink, BoxSDKError>]) -> Void) {
        let items = vms.map { $0.item }
        var sharedLinks: [String: Result<SharedLink, BoxSDKError>] = [:]

        let totalProgress = Progress.discreteProgress(totalUnitCount: Int64(items.count))
        progress(totalProgress)

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

        grp.notify(queue: workQueue) {
            if !totalProgress.isCancelled {
                completion(sharedLinks)
            }
        }
    }
}
