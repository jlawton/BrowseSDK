//
//  Created on 7/22/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK

public struct FilePermissions: OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let download = Self(rawValue: 1 << 0)
    public static let preview = Self(rawValue: 1 << 1)
    public static let upload = Self(rawValue: 1 << 2)
    public static let comment = Self(rawValue: 1 << 3)
    public static let rename = Self(rawValue: 1 << 4)
    public static let delete = Self(rawValue: 1 << 5)
    public static let share = Self(rawValue: 1 << 6)
    public static let setShareAccess = Self(rawValue: 1 << 7)
    public static let inviteCollaborator = Self(rawValue: 1 << 8)
    public static let annotate = Self(rawValue: 1 << 9)
    public static let viewAnnotationsAll = Self(rawValue: 1 << 10)
    public static let viewAnnotationsSelf = Self(rawValue: 1 << 11)
}

extension FilePermissions {
    // swiftlint:disable:next cyclomatic_complexity
    init(_ permissions: File.Permissions) {
        self = []
        if permissions.canDownload == true { formUnion(.download) }
        if permissions.canPreview == true { formUnion(.preview) }
        if permissions.canUpload == true { formUnion(.upload) }
        if permissions.canComment == true { formUnion(.comment) }
        if permissions.canRename == true { formUnion(.rename) }
        if permissions.canDelete == true { formUnion(.delete) }
        if permissions.canShare == true { formUnion(.share) }
        if permissions.canSetShareAccess == true { formUnion(.setShareAccess) }
        if permissions.canInviteCollaborator == true { formUnion(.inviteCollaborator) }
        if permissions.canViewAnnotationsAll == true { formUnion(.viewAnnotationsAll) }
        if permissions.canViewAnnotationsSelf == true { formUnion(.viewAnnotationsSelf) }
    }

    func matches(_ file: File) -> Bool {
        file.permissions.map(Self.init)?.contains(self) ?? false
    }
}
