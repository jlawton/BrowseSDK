//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import Foundation

protocol NeedsSearchViewModel: AnyObject {
    var searchViewModel: SearchViewModel? { get set }
}

class SearchViewModel {
    // To avoid searching very frequently while the user is typing, delay a bit
    // after the most recent keystroke, before updating the search.
    // This value could be fine-tuned by collecting typing speed data.
    private let searchDelay: TimeInterval = 0.35

    let provider: BoxFolderProvider
    let folderID: String

    init(provider: BoxFolderProvider, folderID: String) {
        self.provider = provider
        self.folderID = folderID
    }

    private var query: String = ""
    private(set) lazy var listingViewModel = ListingViewModel(
        title: "Search",
        provider: self.provider,
        createEnumerator: self.createEnumerator
    )
    private var updateTimer: Timer?

    private func createEnumerator() -> BoxEnumerator {
        if query.isEmpty {
            return BoxEnumerator(pageSize: 1) { done in
                done(.failure(.endOfList))
            }
        }
        else {
            return provider.search(query: query, in: folderID)
        }
    }

    func update(query: String) {
        // Only refresh a short time after the last query update, to avoid
        // spamming the server too much
        if updateTimer != nil {
            updateTimer?.invalidate()
        }
        // Update to the empty state instantly
        guard !query.isEmpty else {
            updateImmediately(query: "")
            return
        }
        updateTimer = Timer.scheduledTimer(withTimeInterval: searchDelay, repeats: false) { [weak self] timer in
            guard let self = self else {
                return
            }
            if self.updateTimer == timer {
                self.updateTimer?.invalidate()
                self.updateTimer = nil
                self.updateImmediately(query: query)
            }
        }
    }

    private func updateImmediately(query rawQuery: String) {
        let query = rawQuery
            .trimmingCharacters(in: CharacterSet.whitespaces)
            .lowercased()

        guard query != self.query else {
            return
        }
        self.query = query
        listingViewModel.reloadFirstPage()
    }
}
