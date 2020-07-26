//
//  Created on 7/26/20.
//  Copyright © 2020 Box. All rights reserved.
//

import Foundation

final class CollectingCallbacks<Index: Hashable, Value> {
    typealias Callback = (Value) -> Void
    private var results: [Index: Value] = [:]
    private var waitingCount: Int = 0
    private let lock = DispatchQueue(label: "CollectedCallbacks.lock")

    private var completion: (([Index: Value]) -> Void)? {
        didSet {
            // This can only be set once
            precondition(oldValue == nil && completion != nil)
            lock.sync(execute: completeIfNeeded)
        }
    }

    func callback(_ index: Index) -> Callback {
        lock.sync {
            waitingCount += 1
        }
        var called: Bool = false
        return { result in
            self.lock.sync {
                // Each callback should be called exactly once
                precondition(self.waitingCount > 0 && !called)
                called = true
                self.results[index] = result
                self.waitingCount -= 1
                self.completeIfNeeded()
            }
        }
    }

    // MUST be called while locked
    private func completeIfNeeded() {
        if let completion = completion, waitingCount == 0 {
            completion(results)
        }
    }
}

extension CollectingCallbacks {
    func setCompletion(
        _ done: @escaping ([Index: Value]) -> Void
    ) {
        completion = done
    }

    func setCompletion<T, E: Error>(
        _: @escaping (_ successes: [Index: T], _ failures: [Index: E]) -> Void
    ) where Value == Result<T, E> {
        completion = { results in
            var successes = [Index: T]()
            var failures = [Index: E]()
            for (idx, res) in results {
                switch res {
                case let .success(val):
                    successes[idx] = val
                case let .failure(err):
                    failures[idx] = err
                }
            }
        }
    }
}
