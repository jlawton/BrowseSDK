//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

enum ThumbnailSize {
    /// Calculate the preferred thumbnail size for file listings.
    /// If using the default contentSizeCategory, this must be called on the main thread.
    static func preferredThumbnailSize() -> Int {
        let contentSizeCategory = UITraitCollection.current.preferredContentSizeCategory
        let found = Self.thumbnailSizes.first(where: { contentSizeCategory <= $0.0 })
        return found?.1 ?? 32
    }

    // Keep these ordered by size of the UIContentSizeCategory
    private static let thumbnailSizes: [(UIContentSizeCategory, Int)] = [
        //    (.extraSmall, 32),
        //    (.small, 32),
        //    (.medium, 32),
        //    (.large, 32),
        //    (.extraLarge, 32),
        //    (.extraExtraLarge, 32),
        //    (.extraExtraExtraLarge, 32),
        (.accessibilityMedium, 32),
        (.accessibilityLarge, 39),
        (.accessibilityExtraLarge, 47),
        (.accessibilityExtraExtraLarge, 55),
        (.accessibilityExtraExtraExtraLarge, 62)
    ]
}
