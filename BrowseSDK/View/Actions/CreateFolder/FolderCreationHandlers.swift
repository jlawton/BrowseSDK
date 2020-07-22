//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import Foundation

struct FolderCreationHandlers {
    enum LocalNameValidationResult {
        case valid(name: String)
        case warning(reason: String)
        case invalid(reason: String)
    }

    typealias SuccessCallback = (Result<Void, Error>) -> Void
    typealias CreateFolder = (_ name: String, _ done: @escaping SuccessCallback) -> Void

    var validateName: (_ name: String) -> LocalNameValidationResult = Self.basicNameValidation
    var createFolder: CreateFolder
}

// MARK: - Basic Validation

extension FolderCreationHandlers {
    // The intention here is not to avoid all invalid names, but to catch some
    // basic mistakes.
    static func basicNameValidation(_ text: String) -> LocalNameValidationResult {
        let name = text.trimmingCharacters(in: CharacterSet.whitespaces)
        guard !name.isEmpty else {
            return .invalid(reason: "The folder name cannot be empty.")
        }
        guard name.count <= 255 else {
            return .invalid(reason: "The folder name is too long.")
        }
        guard !name.contains("/"), !name.contains("\\") else {
            return .invalid(reason: "The folder name cannot contain \"/\" or \"\\\".")
        }
        guard ![".", ".."].contains(name) else {
            return .invalid(reason: "The names \".\" and \"..\" are reserved.")
        }
        guard !name.unicodeScalars.contains(where: unsafeChars.contains) else {
            return .warning(reason: "Consider avoiding special characters.")
        }
        guard !name.unicodeScalars.contains(where: { $0.properties.isEmoji }) else {
            return .invalid(reason: "The folder name cannot contain emoji.")
        }
        return .valid(name: name)
    }

    private static var unsafeChars: CharacterSet {
        var unsafeChars = CharacterSet(charactersIn: "<>:\"|?*")
        unsafeChars.insert(charactersIn: "\u{00}" ... "\u{1F}")
        return unsafeChars
    }
}
