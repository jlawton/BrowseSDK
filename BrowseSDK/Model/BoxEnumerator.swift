//
//  Created on 7/18/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK
import Foundation

/// An adapter to make folder enumeration a bit nicer to connect to UI.
class BoxEnumerator {
    typealias PageResult = Result<[FolderItem], Error>
    typealias Iterator = PagingIterator<FolderItem>

    private let pageSize: Int
    private var iteratorResult: Result<Iterator, Error>?
    // This is gross, and shouldn't be necessary
    private var pageCallbacks: [(PageResult) -> Void] = []

    init(pageSize: Int, _ createIterator: @escaping (@escaping Callback<Iterator>) -> Void) {
        self.pageSize = pageSize
        // I think it's pretty gross that the init causes a fetch from the
        // network, but otherwise there's more state to track
        createIterator { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                self.iteratorResult = result.mapError { $0 }
                for pageCallback in self.pageCallbacks {
                    self.getNextPage(completion: pageCallback)
                }
                self.pageCallbacks.removeAll()
            }
        }
    }

    // This must be called from the main thread!
    func getNextPage(completion: @escaping (PageResult) -> Void) {
        guard let iteratorResult = self.iteratorResult else {
            pageCallbacks.append(completion)
            return
        }
        switch iteratorResult {
        case let .success(iterator):
            iterator.nextPage(pageSize: pageSize) { pageResult in
                DispatchQueue.main.async {
                    completion(pageResult.mapError { $0 })
                }
            }
        case let .failure(error):
            completion(.failure(error))
        }
    }
}

extension PagingIterator {
    // This is gross, and shouldn't be necessary
    func nextPage(pageSize: Int, completion: @escaping Callback<[Element]>) {
        var calledCompletion = false
        var elements: [Element] = []
        for index in 0 ..< pageSize {
            next { result in
                switch result {
                case let .success(elem):
                    elements.append(elem)
                case let .failure(error):
                    if !calledCompletion {
                        calledCompletion = true
                        if error.message == .endOfList {
                            completion(.success(elements))
                        }
                        else {
                            completion(.failure(error))
                        }
                    }
                }
                if !calledCompletion, index == pageSize - 1 {
                    calledCompletion = true
                    completion(.success(elements))
                }
            }
        }
    }
}
