//
//  Created on 10/28/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import Foundation

/// Handles selection of items from Box by attempting to create shared links.
class BoxSharedLinkPickerSelectionHandler: SelectionHandler {
    static var requiredFields: [String] {
        ["shared_link", "permissions"]
    }

    private let provider: BoxFolderProvider
    private let workQueue = DispatchQueue(label: "box.SharedLinkSelectionActionHandler")
    private weak var picker: BoxSharedLinkPicker?

    init(provider: BoxFolderProvider, picker: BoxSharedLinkPicker) {
        self.provider = provider
        self.picker = picker
    }

    // The item has a shared link already, or we expect to be able to create one
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

    // Create shared links for items that don't have one before returning the results.
    func handleSelected(items vms: [ItemViewModel]) {
        let items = vms.map { $0.item }
        var successes: [FolderItem] = []
        var failures: [(FolderItem, BoxSDKError)] = []

        let totalProgress = Progress.discreteProgress(totalUnitCount: Int64(items.count))
        willCreateSharedLinks(progress: totalProgress)

        let grp = DispatchGroup()
        for item in items {
            if totalProgress.isCancelled {
                return
            }

            grp.enter()
            let progress = provider.setSharedLink(forItem: item) { result in
                self.workQueue.async {
                    switch result {
                    case let .success(itemWithLink): successes.append(itemWithLink)
                    case let .failure(error): failures.append((item, error))
                    }
                    grp.leave()
                }
            }
            totalProgress.addChild(progress, withPendingUnitCount: 1)
        }

        grp.notify(queue: workQueue) {
            if !totalProgress.isCancelled {
                self.complete(successes: successes, failures: failures)
            }
        }
    }

    private func complete(successes: [FolderItem], failures: [(FolderItem, BoxSDKError)]) {
        if let picker = picker {
            DispatchQueue.main.async {
                if !failures.isEmpty {
                    picker.didFail(failures)
                }
                if !successes.isEmpty {
                    picker.didSelect(successes)
                }
            }
        }
    }

    private func willCreateSharedLinks(progress: Progress) {
        if let picker = picker {
            DispatchQueue.main.async {
                picker.willCreateSharedLinks(progress)
            }
        }
    }
}
