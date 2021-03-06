//
//  Created on 7/18/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import UIKit

struct BoxFolderProvider {
    static let requiredFields = [
        "name", "permissions", "sha1", "size", "modified_at", "path_collection",
        "has_collaborations", "is_externally_owned", "extension"
    ]

    let client: BoxClient

    init(client: BoxClient, additionalFields: [String]? = nil) {
        self.client = client
        if let additionalFields = additionalFields {
            fields = Self.requiredFields + Set(additionalFields).subtracting(Self.requiredFields)
        }
        else {
            fields = Self.requiredFields
        }
    }

    private let fields: [String]

    // Limit the number of thumbnail requests made at once so there is room for
    // other requests.
    private var thumbnailRequestSema = DispatchSemaphore(value: 4)
    private var thumbnailQueue = DispatchQueue(label: "BoxFolderProvider.thumbnails")

    static let root = BoxSDK.Constants.rootFolder
    private let folderPageSize = 30
    private let searchPageSize = 15

    func rootEnumerator() -> BoxEnumerator {
        enumerator(for: Self.root)
    }

    func enumerator(for identifier: String) -> BoxEnumerator {
        BoxEnumerator(pageSize: folderPageSize) { done in
            client.folders.listItems(
                folderId: identifier,
                usemarker: true,
                limit: folderPageSize,
                fields: fields,
                completion: wrapIterCallback(done)
            )
        }
    }

    // MARK: Searching

    func search(query: String, in folderID: String = Self.root) -> BoxEnumerator {
        BoxEnumerator(pageSize: searchPageSize) { done in
            client.search.query(
                query: query,
                ancestorFolderIDs: (folderID != Self.root) ? [folderID] : nil,
                searchTrash: false,
                fields: fields,
                limit: searchPageSize,
                completion: wrapIterCallback(done)
            )
        }
    }

    // Super gross.
    // This is all because initalizers for PagingIterator and BoxSDKError
    // are internal to the SDK.
    private func wrapIterCallback(
        _ done: @escaping (Result<BoxEnumeratorIterator, BoxSDKErrorEnum>) -> Void
    ) -> Callback<PagingIterator<FolderItem>> {
        return CallbackUtil(done)
            .comap { iter in
                BoxEnumeratorIterator(next: { nextCB in
                    iter.next(completion: CallbackUtil(nextCB)
                        .comapError { $0.message }
                        .callback)
                })
            }
            .comapError { $0.message }
            .callback
    }

    // MARK: Info

    func folderInfo(for identifier: String = Self.root, _ completion: @escaping Callback<Folder>) {
        client.folders.get(
            folderId: identifier,
            fields: fields,
            completion: completion
        )
    }

    // MARK: Folder creation

    func createFolder(name: String, parentID: String, _ completion: @escaping Callback<Folder>) {
        client.folders.create(
            name: name,
            parentId: parentID,
            fields: fields,
            completion: completion
        )
    }

    // MARK: Move and Copy

    func moveItem(_ item: FolderItem, to parentID: String, name: String? = nil, _ completion: @escaping Callback<FolderItem>) {
        switch item {
        case let .folder(folder):
            moveFolder(
                folder.id,
                to: parentID, name: name,
                CallbackUtil(completion).comap(FolderItem.folder).callback
            )
        case let .file(file):
            moveFile(
                file.id,
                to: parentID, name: name,
                CallbackUtil(completion).comap(FolderItem.file).callback
            )
        case let .webLink(webLink):
            moveWebLink(
                webLink.id,
                to: parentID, name: name,
                CallbackUtil(completion).comap(FolderItem.webLink).callback
            )
        }
    }

    func moveFolder(_ folderID: String, to parentID: String, name: String? = nil, _ completion: @escaping Callback<Folder>) {
        client.folders.update(
            folderId: folderID,
            name: name, parentId: parentID,
            fields: fields,
            completion: completion
        )
    }

    func moveFile(_ fileID: String, to parentID: String, name: String? = nil, _ completion: @escaping Callback<File>) {
        client.files.update(
            fileId: fileID,
            name: name, parentId: parentID,
            fields: fields,
            completion: completion
        )
    }

    func moveWebLink(_ webLinkID: String, to parentID: String, name: String? = nil, _ completion: @escaping Callback<WebLink>) {
        client.webLinks.update(
            webLinkId: webLinkID,
            url: nil,
            parentId: parentID, name: name,
            fields: fields,
            completion: completion
        )
    }

    func copyItem(_ item: FolderItem, to parentID: String, name: String? = nil, _ completion: @escaping Callback<FolderItem>) {
        switch item {
        case let .folder(folder):
            copyFolder(
                folder.id,
                to: parentID, name: name,
                CallbackUtil(completion).comap(FolderItem.folder).callback
            )
        case let .file(file):
            copyFile(
                file.id,
                to: parentID, name: name,
                CallbackUtil(completion).comap(FolderItem.file).callback
            )
        case .webLink:
            preconditionFailure("Can't copy weblinks")
        }
    }

    func copyFolder(_ folderID: String, to parentID: String, name: String? = nil, _ completion: @escaping Callback<Folder>) {
        client.folders.copy(
            folderId: folderID,
            destinationFolderID: parentID, name: name,
            fields: fields,
            completion: completion
        )
    }

    func copyFile(_ fileID: String, to parentID: String, name: String? = nil, _ completion: @escaping Callback<File>) {
        client.files.copy(
            fileId: fileID,
            parentId: parentID, name: name,
            fields: fields,
            completion: completion
        )
    }

    // MARK: Thumbnails

    func loadThumbnail(for identifier: String, size: Int, _ completion: @escaping (UIImage?) -> Void) -> Progress {
        let progress = Progress.discreteProgress(totalUnitCount: 10)

        // Always answer asynchronously on the main thread, and only if the
        // progess wasn't cancelled.
        let done = { (image: UIImage?) in
            DispatchQueue.main.async {
                if !progress.isCancelled {
                    completion(image)
                }
            }
        }

        thumbnailQueue.async {
            // Don't make too many requests at once
            thumbnailRequestSema.wait()

            guard !progress.isCancelled else {
                // Free up for another request
                thumbnailRequestSema.signal()
                return
            }

            progress.performAsCurrent(withPendingUnitCount: 8) {
                // Hit the network and cache any successful result
                client.files.getThumbnail(forFile: identifier, extension: .jpg, minHeight: 160, minWidth: 160) { result in
                    switch result {
                    case let .success(data):
                        progress.completedUnitCount = 8
                        let image = UIImage(data: data, scale: 0)?.squareThumbnail(size)
                        progress.completedUnitCount = 10
                        done(image)
                    case .failure:
                        done(nil)
                    }
                    // Free up for another request
                    thumbnailRequestSema.signal()
                }
            }
        }

        return progress
    }
}
