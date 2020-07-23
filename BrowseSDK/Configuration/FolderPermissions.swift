//
//  Created on 7/23/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK

public struct FolderPermissions: OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let download = Self(rawValue: 1 << 0)
    public static let upload = Self(rawValue: 1 << 2)
    public static let rename = Self(rawValue: 1 << 4)
    public static let delete = Self(rawValue: 1 << 5)
    public static let share = Self(rawValue: 1 << 6)
    public static let setShareAccess = Self(rawValue: 1 << 7)
    public static let inviteCollaborator = Self(rawValue: 1 << 8)
}

extension FolderPermissions {
    init(_ permissions: Folder.Permissions) {
        self = []
        if permissions.canDownload == true { formUnion(.download) }
        if permissions.canUpload == true { formUnion(.upload) }
        if permissions.canRename == true { formUnion(.rename) }
        if permissions.canDelete == true { formUnion(.delete) }
        if permissions.canShare == true { formUnion(.share) }
        if permissions.canSetShareAccess == true { formUnion(.setShareAccess) }
        if permissions.canInviteCollaborator == true { formUnion(.inviteCollaborator) }
    }

    func matches(_ file: Folder) -> Bool {
        file.permissions.map(Self.init)?.contains(self) ?? false
    }
}
