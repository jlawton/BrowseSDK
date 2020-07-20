//
//  Created on 7/19/20.
//  Copyright © 2020 Box. All rights reserved.
//

import Foundation
import UIKit

/// A simple in-memory image cache
final class ImageCache {
    private let cache: NSCache<NSString, UIImage>

    init(named: String, costLimit: Int = 8 * 1024 * 1024) {
        cache = NSCache<NSString, UIImage>()
        cache.name = named
        cache.countLimit = 200
        cache.totalCostLimit = costLimit
    }

    subscript(key: String) -> UIImage? {
        get {
            return cache.object(forKey: key as NSString)
        }
        set {
            if let image = newValue {
                cache.setObject(image, forKey: key as NSString, cost: image.estimatedMemoryCost)
            }
            else {
                cache.removeObject(forKey: key as NSString)
            }
        }
    }

    subscript(key: String, default create: @autoclosure () -> UIImage) -> UIImage {
        if let cached = self[key] {
            return cached
        }
        let created = create()
        self[key] = created
        return created
    }
}

extension UIImage {
    /// Returns roughly the number of bytes we expect this image to be consuming in memory
    var estimatedMemoryCost: Int {
        if let frames = images {
            return frames.reduce(0) { $0 + $1.estimatedMemoryCost }
        }
        let pixels = Int(size.height * size.width * scale * scale)
        return pixels * 4
    }
}
