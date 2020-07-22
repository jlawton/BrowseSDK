//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import Foundation

protocol NeedsCreateFolderViewModel: AnyObject {
    var createFolderViewModel: CreateFolderViewModel? { get set }
}

struct CreateFolderViewModel {
    enum LocalNameValidationResult {
        case valid(name: String)
        case warning(name: String, reason: String)
        case invalid(reason: String)
    }

    private let folder: Folder
    private let provider: BoxFolderProvider
    let suggestedName: String?

    init(folder: Folder, provider: BoxFolderProvider, suggestedName: String? = nil) {
        self.folder = folder
        self.provider = provider
        self.suggestedName = suggestedName
    }

    var breadcrumbs: String? {
        Breadcrumbs(folder: folder).abbreviatedString
    }

    func validate(name: String) -> LocalNameValidationResult {
        Self.basicNameValidation(name)
    }

    func createFolder(
        name: String,
        completion: @escaping (Result<Folder, Error>) -> Void
    ) {
        provider.createFolder(
            name: name,
            parentID: folder.id,
            CallbackUtil(completion)
                .comapError { $0 }
                .dispatchToMainThread()
                .callback
        )
    }
}

// MARK: - Basic Validation

extension CreateFolderViewModel {
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
            return .warning(name: name, reason: "Consider avoiding special characters.")
        }
        guard !containsEmoji(name) else {
            return .invalid(reason: "The folder name cannot contain emoji.")
        }
        return .valid(name: name)
    }

    private static var unsafeChars: CharacterSet {
        var unsafeChars = CharacterSet(charactersIn: "<>:\"|?*")
        unsafeChars.insert(charactersIn: "\u{00}" ... "\u{1F}")
        return unsafeChars
    }

    private static func containsEmoji(_ name: String) -> Bool {
        name.unicodeScalars.contains { scalar in
            scalar.properties.isEmojiPresentation // Defaults to emoji rendering
                || scalar == "\u{FE0F}" // Emoji variation selector applied to previous scalar
        }
    }
}
