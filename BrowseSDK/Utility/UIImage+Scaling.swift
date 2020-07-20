//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

extension UIImage {
    /// Create a square thumbnail with transparent padding if necessary
    func squareThumbnail(_ maxSide: Int) -> UIImage {
        let bounds = CGRect(x: 0, y: 0, width: maxSide, height: maxSide)
        if size == bounds.size {
            return self
        }
        let newSize = size.scale(by: min(size.scaleThatFits(in: bounds.size), 1))
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { (_: UIGraphicsImageRendererContext) in
            self.draw(in: newSize.centered(in: bounds))
        }
    }
}
