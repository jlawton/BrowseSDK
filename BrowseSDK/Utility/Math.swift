//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import CoreGraphics
import Foundation

extension CGSize {
    func scale(by scale: CGFloat) -> CGSize {
        return CGSize(width: width * scale, height: height * scale)
    }

    func scaleThatFits(in containing: CGSize) -> CGFloat {
        let wscale = containing.width / width
        let hscale = containing.height / height
        return min(wscale, hscale)
    }

    func scaleThatFills(in containing: CGSize) -> CGFloat {
        let wscale = containing.width / width
        let hscale = containing.height / height
        return max(wscale, hscale)
    }

    func centered(in rect: CGRect) -> CGRect {
        return CGRect(
            x: rect.midX - width * 0.5,
            y: rect.midY - height * 0.5,
            width: width,
            height: height
        )
    }
}
