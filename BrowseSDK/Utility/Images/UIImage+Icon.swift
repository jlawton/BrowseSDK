//
//  Created on 7/20/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

extension UIImage {

    enum Icon {
        case personalFolder
        case sharedFolder
        case externalFolder
        case genericDocument
        case weblink
    }

    static func icon(_ icon: Icon) -> UIImage {
        return iconCache["\(icon)", default: createIcon(icon)]
    }

    // Better icons could be added here by changing this to look up in an
    // asset bundle.
    private static func createIcon(_ icon: Icon) -> UIImage {
        let size = ThumbnailSize.preferredThumbnailSize()
        let configuration = UIImage.SymbolConfiguration(pointSize: CGFloat(size * 3))

        switch icon {
        case .personalFolder:
            // swiftlint:disable:next force_unwrapping
            return UIImage(systemName: "folder.fill", withConfiguration: configuration)!
                .withRenderingMode(.alwaysTemplate)
                .squareThumbnail(size, fillColor: UIColor { traits -> UIColor in
                    (traits.userInterfaceStyle == .dark) ? #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1) : #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
                })
        case .sharedFolder:
            // swiftlint:disable:next force_unwrapping
            return UIImage(systemName: "folder.fill", withConfiguration: configuration)!
                .withRenderingMode(.alwaysTemplate)
                .squareThumbnail(size, fillColor: UIColor { traits -> UIColor in
                    (traits.userInterfaceStyle == .dark) ? #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1) : #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
                })
        case .externalFolder:
            // swiftlint:disable:next force_unwrapping
            return UIImage(systemName: "folder.fill", withConfiguration: configuration)!
                .withRenderingMode(.alwaysTemplate)
                .squareThumbnail(size, fillColor: UIColor { traits -> UIColor in
                    (traits.userInterfaceStyle == .dark) ? #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1) : #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                })
        case .genericDocument:
            // swiftlint:disable:next force_unwrapping
            return UIImage(systemName: "doc.fill", withConfiguration: configuration)!
                .withRenderingMode(.alwaysTemplate)
                .squareThumbnail(size, fillColor: UIColor { traits -> UIColor in
                    (traits.userInterfaceStyle == .dark) ? #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1) : #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                })
        case .weblink:
            // swiftlint:disable:next force_unwrapping
            return UIImage(systemName: "link.circle.fill", withConfiguration: configuration)!
                .withRenderingMode(.alwaysTemplate)
                .squareThumbnail(size, fillColor: UIColor { traits -> UIColor in
                    (traits.userInterfaceStyle == .dark) ? #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1) : #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                })
        }
    }

    private static let iconCache = ImageCache(named: "UIImage.iconCache", costLimit: 512 * 1024)
}
