//
//  Created on 7/25/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import Foundation

class MoveOrCopyViewModel {
    private let sourceItems: [FolderItem]
    private let provider: BoxFolderProvider

    init(sourceItems: [FolderItem], provider: BoxFolderProvider) {
        self.sourceItems = sourceItems
        self.provider = provider
    }

    var initialPath: [Folder] {
        let path = sourceItems.compactMap { (item) -> [Folder]? in
            guard let path = item.pathCollection, !path.isEmpty else {
                return nil
            }
            return path
        }.first
        if let path = path {
            return path
        }

        // HACK!
        do {
            let root = try Folder(json: [
                "type": "folder",
                "id": BoxFolderProvider.root
            ])
            return [root]
        }
        catch {
            return []
        }
    }

    func listingViewModel(for folder: Folder) -> FolderListingViewModel {
        let folderID = folder.id
        let provider = self.provider
        return MoveOrCopyToFolderListingViewModel(
            actionViewModel: self,
            folder: folder,
            provider: provider,
            createEnumerator: { provider.enumerator(for: folderID) }
        )
    }

    func searchViewModel(for folder: Folder) -> SearchViewModel? {
        return SearchViewModel(provider: provider, folderID: folder.id)
    }

    func canMoveOrCopy(to folder: Folder) -> Bool {
        !possibleActions(to: folder).isEmpty
    }

    func possibleActions(to folder: Folder) -> Set<Action> {
        sourceItems.reduce(into: Set(Action.allCases)) { actions, item in
            let actionsForItem = Self.possibleActions(item, to: folder)
            actions.formIntersection(actionsForItem)
        }
    }

    func move(
        to parentID: String,
        completion: @escaping ([FolderItem.Identifier: Result<FolderItem, Error>]) -> Void
    ) {
        let collection = CollectingCallbacks<FolderItem.Identifier, Result<FolderItem, Error>>()
        for item in sourceItems {
            provider.moveItem(
                item,
                to: parentID,
                CallbackUtil(collection.callback(item.identifier)).comapError { $0 }.callback
            )
        }
        collection.setCompletion(completion)
    }

    func copy(
        to parentID: String,
        completion: @escaping ([FolderItem.Identifier: Result<FolderItem, Error>]) -> Void
    ) {
        let collection = CollectingCallbacks<FolderItem.Identifier, Result<FolderItem, Error>>()
        for item in sourceItems {
            provider.copyItem(
                item,
                to: parentID,
                CallbackUtil(collection.callback(item.identifier)).comapError { $0 }.callback
            )
        }
        collection.setCompletion(completion)
    }
}

extension MoveOrCopyViewModel {
    enum Action: CaseIterable {
        case move
        case copy
    }

    static func canMoveOrCopy(_ item: FolderItem) -> Bool {
        // This only deals with the source side
        item.permissions.canMoveOrCopy
    }

    static func canMoveOrCopy(to folder: Folder) -> Bool {
        folder.permissions?.canUpload ?? false
    }

    static func possibleActions(_ item: FolderItem, to folder: Folder) -> Set<Action> {
        guard canMoveOrCopy(item), canMoveOrCopy(to: folder) else {
            return []
        }

        // Can't move or copy an item inside itself
        if let id = item.asFolder?.id,
            folder.id == id
            || (folder.pathCollection?.entries?.contains(where: { $0.id == id }) ?? false)
        {
            return []
        }

        var allowed: Set<Action> = [.copy]
        // Can't move an item where it already lives
        if item.pathCollection?.last?.id != folder.id {
            allowed.insert(.move)
        }
        return allowed
    }
}
