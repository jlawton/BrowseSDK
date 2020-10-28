//
//  Created on 7/25/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK

extension FolderItem {
    var asFolder: Folder? {
        if case let .folder(folder) = self {
            return folder
        }
        return nil
    }

    struct Identifier: Hashable {
        let type: String
        let id: String
    }

    var identifier: Identifier {
        switch self {
        case let .folder(folder): return Identifier(type: folder.type, id: folder.id)
        case let .file(file): return Identifier(type: file.type, id: file.id)
        case let .webLink(webLink): return Identifier(type: webLink.type, id: webLink.id)
        }
    }

    var name: String {
        switch self {
        case let .folder(folder): return folder.name ?? ""
        case let .file(file): return file.name ?? ""
        case let .webLink(webLink): return webLink.name ?? ""
        }
    }

    var pathCollection: [Folder]? {
        switch self {
        case let .folder(folder): return folder.pathCollection?.entries
        case let .file(file): return file.pathCollection?.entries
        case let .webLink(webLink): return webLink.pathCollection?.entries
        }
    }

    var sharedLink: SharedLink? {
        switch self {
        case let .folder(folder): return folder.sharedLink
        case let .file(file): return file.sharedLink
        case let .webLink(webLink): return webLink.sharedLink
        }
    }
}

// MARK: - Permissions

extension FolderItem {
    var permissions: FolderItemCommonPermissions {
        switch self {
        case let .folder(folder): return FolderItemCommonPermissions(folder.permissions)
        case let .file(file): return FolderItemCommonPermissions(file.permissions)
        case let .webLink(webLink): return FolderItemCommonPermissions(webLink.permissions)
        }
    }
}

struct FolderItemCommonPermissions {
    let canDownload: Bool
    let canUpload: Bool
    let canRename: Bool
    let canDelete: Bool
    let canShare: Bool
    let canSetShareAccess: Bool
    let canInviteCollaborator: Bool

    let canMoveOrCopy: Bool

    init(_ permissions: Folder.Permissions?) {
        canDownload = permissions?.canDownload ?? false
        canUpload = permissions?.canUpload ?? false
        canRename = permissions?.canRename ?? false
        canDelete = permissions?.canDelete ?? false
        canShare = permissions?.canShare ?? false
        canSetShareAccess = permissions?.canSetShareAccess ?? false
        canInviteCollaborator = permissions?.canInviteCollaborator ?? false
        canMoveOrCopy = canDownload
    }

    init(_ permissions: File.Permissions?) {
        canDownload = permissions?.canDownload ?? false
        canUpload = permissions?.canUpload ?? false
        canRename = permissions?.canRename ?? false
        canDelete = permissions?.canDelete ?? false
        canShare = permissions?.canShare ?? false
        canSetShareAccess = permissions?.canSetShareAccess ?? false
        canInviteCollaborator = permissions?.canInviteCollaborator ?? false
        canMoveOrCopy = canDownload
    }

    init(_ permissions: WebLink.Permissions?) {
        canDownload = false
        canUpload = false
        canRename = permissions?.canRename ?? false
        canDelete = permissions?.canDelete ?? false
        canShare = permissions?.canShare ?? false
        canSetShareAccess = permissions?.canSetShareAccess ?? false
        canInviteCollaborator = false
        canMoveOrCopy = true
    }
}
