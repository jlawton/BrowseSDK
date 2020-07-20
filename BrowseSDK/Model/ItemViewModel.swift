//
//  Created on 7/19/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import Foundation
import UIKit

protocol NeedsItemViewModel: AnyObject {
    var itemViewModel: ItemViewModel? { get set }
}

class ItemViewModel {

    private let item: FolderItem
    private let provider: BoxFolderProvider

    private var thumbnailProgress: Progress?

    init(item: FolderItem, provider: BoxFolderProvider) {
        self.item = item
        self.provider = provider
    }

    var identifier: String {
        switch item {
        case let .folder(folder):
            return folder.id
        case let .file(file):
            return file.id
        case let .webLink(link):
            return link.id
        }
    }

    var name: String {
        switch item {
        case let .folder(folder):
            return folder.name ?? ""
        case let .file(file):
            return file.name ?? ""
        case let .webLink(link):
            return link.name ?? ""
        }
    }

    var detail: String {
        switch item {
        case let .folder(folder):
            return [
                folder.modifiedAt.flatMap(Self.dateFormatter.string(from:))
            ].compactMap { $0 }.joined(separator: " · ")
        case let .file(file):
            return [
                file.size.flatMap(Self.sizeFormatter.string(for:)),
                file.modifiedAt.flatMap(Self.dateFormatter.string(from:))
            ].compactMap { $0 }.joined(separator: " · ")
        case let .webLink(link):
            return [
                link.modifiedAt.flatMap(Self.dateFormatter.string(from:))
            ].compactMap { $0 }.joined(separator: " · ")
        }
    }

    var breadcrumbs: String? {
        let pathCollection: [Folder]?
        switch item {
        case let .folder(folder):
            pathCollection = folder.pathCollection?.entries
        case let .file(file):
            pathCollection = file.pathCollection?.entries
        case let .webLink(link):
            pathCollection = link.pathCollection?.entries
        }
        guard var folders = pathCollection, !folders.isEmpty else {
            return nil
        }
        if folders.count > 1, folders[0].id == BoxFolderProvider.root {
            folders.removeFirst()
        }
        var folderNames: [String] = folders.compactMap { folder in
            folder.name
        }
        if folderNames.count > 3 {
            folderNames.replaceSubrange(2 ..< folderNames.count - 1, with: ["⋯"])
        }
        return folderNames.joined(separator: " ≫ ")
    }

    var icon: UIImage.Icon {
        switch item {
        case let .folder(folder):
            if folder.isExternallyOwned ?? false {
                return .externalFolder
            }
            else if folder.hasCollaborations ?? false {
                return .sharedFolder
            }
            return .personalFolder
        case .file:
            return .genericDocument
        case .webLink:
            return .weblink
        }
    }

    var isFolder: Bool {
        if case .folder = item {
            return true
        }
        return false
    }

    var allowsReading: Bool {
        switch item {
        case .folder:
            return true
        case let .file(file):
            return file.permissions?.canDownload ?? false
        case .webLink:
            return false
        }
    }

    func requestThumbnail(_ completion: @escaping (UIImage) -> Void) {
        if let thumbnail = thumbnail {
            completion(thumbnail)
            return
        }
        guard thumbnailProgress == nil else {
            return
        }

        let progress = Progress.discreteProgress(totalUnitCount: 1)
        thumbnailProgress = progress

        let size = Self.preferredThumbnailSize()
        let load = provider.loadThumbnail(for: identifier, size: size) { thumb in
            guard self.thumbnailProgress == progress, !progress.isCancelled else {
                return
            }
            if let thumb = thumb {
                self.thumbnail = thumb
                completion(thumb)
            }
            self.thumbnailProgress = nil
        }
        progress.addChild(load, withPendingUnitCount: 1)
    }

    func cancelThumbnailLoading() {
        thumbnailProgress?.cancel()
        thumbnailProgress = nil
    }

    func listingViewModel() -> ListingViewModel? {
        guard isFolder else {
            return nil
        }
        let provider = self.provider
        let identifier = self.identifier
        return ListingViewModel(
            title: name,
            provider: provider,
            createEnumerator: { provider.enumerator(for: identifier) }
        )
    }

    func searchViewModel() -> SearchViewModel? {
        guard isFolder else {
            return nil
        }
        return SearchViewModel(provider: provider, folderID: identifier)
    }
}

// MARK: - Equality

extension ItemViewModel: Hashable {
    // Taking equality to mean only item identity
    static func == (lhs: ItemViewModel, rhs: ItemViewModel) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

// MARK: - Thumbnails

extension ItemViewModel {
    /// Calculate the preferred thumbnail size for file listings.
    /// If using the default contentSizeCategory, this must be called on the main thread.
    static func preferredThumbnailSize() -> Int {
        let contentSizeCategory = UITraitCollection.current.preferredContentSizeCategory
        let found = Self.thumbnailSizes.first(where: { contentSizeCategory <= $0.0 })
        return found?.1 ?? 32
    }

    // Keep these ordered by size of the UIContentSizeCategory
    private static let thumbnailSizes: [(UIContentSizeCategory, Int)] = [
        //    (.extraSmall, 32),
        //    (.small, 32),
        //    (.medium, 32),
        //    (.large, 32),
        //    (.extraLarge, 32),
        //    (.extraExtraLarge, 32),
        //    (.extraExtraExtraLarge, 32),
        (.accessibilityMedium, 32),
        (.accessibilityLarge, 39),
        (.accessibilityExtraLarge, 47),
        (.accessibilityExtraExtraLarge, 55),
        (.accessibilityExtraExtraExtraLarge, 62)
    ]

    private var thumbnail: UIImage? {
        get {
            return ItemViewModel.thumbnailCache[identifier]
        }
        set {
            ItemViewModel.thumbnailCache[identifier] = newValue
        }
    }

    private static var thumbnailCache: ImageCache = ImageCache(named: "ItemViewModel.thumbnailCache")
}

// MARK: - Description

extension ItemViewModel: CustomStringConvertible {
    var description: String {
        return "VM(\(item))"
    }
}

extension ItemViewModel {
    static let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}
