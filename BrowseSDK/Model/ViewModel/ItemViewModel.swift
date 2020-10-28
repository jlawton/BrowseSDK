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

    let item: FolderItem
    let provider: BoxFolderProvider
    var selected: Bool

    private var thumbnailProgress: Progress?

    init(item: FolderItem, provider: BoxFolderProvider, selected: Bool = false) {
        self.item = item
        self.provider = provider
        self.selected = selected
    }

    var fileModel: File? {
        if case let .file(file) = item {
            return file
        }
        return nil
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

    enum Mode {
        case browse
        case search
    }

    func detail(for mode: Mode) -> String {
        switch mode {
        case .browse: return sizeAndModification
        case .search: return breadcrumbs ?? sizeAndModification
        }
    }

    var sizeAndModification: String {
        // TODO: NSLocalizedString
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
        Breadcrumbs(item: item).abbreviatedString
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

        let size = ThumbnailSize.preferredThumbnailSize()
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
        guard case let .folder(folder) = item else {
            return nil
        }
        let provider = self.provider
        let identifier = self.identifier
        return FolderListingViewModel(
            folder: folder,
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
    private var thumbnail: UIImage? {
        get {
            return ItemViewModel.thumbnailCache[identifier]
        }
        set {
            ItemViewModel.thumbnailCache[identifier] = newValue
        }
    }

    private static var thumbnailCache = ImageCache(named: "ItemViewModel.thumbnailCache")
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
