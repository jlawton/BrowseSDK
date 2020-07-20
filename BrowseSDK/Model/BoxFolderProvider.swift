//
//  Created on 7/18/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import UIKit

struct BoxFolderProvider {
    let client: BoxClient

    // So we don't have to re-fetch thumbnails constantly.
    // This would probably be better as an on-disk cache somewhere else.
    private let imageCache = ImageCache(named: "BoxFolderProvider")
    // Limit the number of thumbnail requests made at once so there is room for
    // other requests.
    private var thumbnailRequestSema = DispatchSemaphore(value: 4)
    private var thumbnailQueue = DispatchQueue(label: "BoxFolderProvider.thumbnails")

    private static let root = BoxSDK.Constants.rootFolder
    private let folderPageSize = 35
    private let searchPageSize = 20

    func rootEnumerator() -> BoxFolderEnumerator {
        enumerator(for: Self.root)
    }

    func enumerator(for identifier: String) -> BoxFolderEnumerator {
        BoxFolderEnumerator(pageSize: folderPageSize) { done in
            client.folders.listItems(
                folderId: identifier,
                usemarker: true,
                limit: folderPageSize,
                fields: nil,
                completion: done
            )
        }
    }

    // MARK: Searching

    func search(query: String, in folderID: String = Self.root) -> BoxFolderEnumerator {
        BoxFolderEnumerator(pageSize: searchPageSize) { done in
            client.search.query(
                query: query,
                ancestorFolderIDs: (folderID != Self.root) ? [folderID] : nil,
                searchTrash: false,
                fields: nil,
                limit: searchPageSize,
                completion: done
            )
        }
    }

    // MARK: Thumbnails

    func loadThumbnail(for identifier: String, size _: Int, _ completion: @escaping (UIImage?) -> Void) -> Progress {
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
            // Try the in-memory cache first
            if let cached = imageCache[identifier] {
                progress.completedUnitCount = 10
                done(cached)
                return
            }

            // Don't make too many requests at once
            thumbnailRequestSema.wait()

            progress.performAsCurrent(withPendingUnitCount: 8) {
                // Hit the network and cache any successful result
                client.files.getThumbnail(forFile: identifier, extension: .jpg) { result in
                    switch result {
                    case let .success(data):
                        progress.completedUnitCount = 8
                        let image = UIImage(data: data, scale: 0)
                        imageCache[identifier] = image
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
