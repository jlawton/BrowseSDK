//
//  Created on 7/22/20.
//  Copyright © 2020 Box. All rights reserved.
//

import Foundation

// Utilities to transform callbacks
struct CallbackUtil<T, E: Error> {
    let callback: (Result<T, E>) -> Void
    init(_ callback: @escaping (Result<T, E>) -> Void) {
        self.callback = callback
    }

    func comap<U>(_ transform: @escaping (U) -> T) -> CallbackUtil<U, E> {
        return CallbackUtil<U, E>(Self.comap(callback, transform))
    }

    func comapError<F: Error>(_ transform: @escaping (F) -> E) -> CallbackUtil<T, F> {
        return CallbackUtil<T, F>(Self.comapError(callback, transform))
    }

    func coflatMap<U>(_ transform: @escaping (U) -> Result<T, E>) -> CallbackUtil<U, E> {
        return CallbackUtil<U, E>(Self.coflatMap(callback, transform))
    }

    func coflatMapError<F: Error>(_ transform: @escaping (F) -> Result<T, E>) -> CallbackUtil<T, F> {
        return CallbackUtil<T, F>(Self.coflatMapError(callback, transform))
    }

    func dispatchToMainThread() -> CallbackUtil<T, E> {
        CallbackUtil<T, E> { result in
            DispatchQueue.main.async {
                callback(result)
            }
        }
    }
}

extension CallbackUtil {
    static func comap<U>(
        _ callback: @escaping (Result<T, E>) -> Void,
        _ transform: @escaping (U) -> T
    ) -> (Result<U, E>) -> Void {
        return { resultT in
            callback(resultT.map(transform))
        }
    }

    static func comapError<F: Error>(
        _ callback: @escaping (Result<T, E>) -> Void,
        _ transform: @escaping (F) -> E
    ) -> (Result<T, F>) -> Void {
        return { resultE in
            callback(resultE.mapError(transform))
        }
    }

    static func coflatMap<U>(
        _ callback: @escaping (Result<T, E>) -> Void,
        _ transform: @escaping (U) -> Result<T, E>
    ) -> (Result<U, E>) -> Void {
        return { resultT in
            callback(resultT.flatMap(transform))
        }
    }

    static func coflatMapError<F: Error>(
        _ callback: @escaping (Result<T, E>) -> Void,
        _ transform: @escaping (F) -> Result<T, E>
    ) -> (Result<T, F>) -> Void {
        return { resultE in
            callback(resultE.flatMapError(transform))
        }
    }
}
