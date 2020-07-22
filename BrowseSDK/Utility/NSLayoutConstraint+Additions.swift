//
//  Created on 7/21/20.
//  Copyright © 2020 Box. All rights reserved.
//

import UIKit

protocol EdgeAnchors {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
}

extension UIView: EdgeAnchors {}
extension UILayoutGuide: EdgeAnchors {}

extension EdgeAnchors {
    func constrain(_ view: EdgeAnchors, insets: NSDirectionalEdgeInsets) {
        constrain(
            view,
            top: insets.top,
            leading: insets.leading,
            bottom: insets.bottom,
            trailing: insets.trailing
        )
    }

    func constrain(
        _ inner: EdgeAnchors,
        top: CGFloat? = nil,
        leading: CGFloat? = nil,
        bottom: CGFloat? = nil,
        trailing: CGFloat? = nil
    ) {
        NSLayoutConstraint.activate([
            top.map { inner.topAnchor.constraint(equalTo: topAnchor, constant: $0) },
            leading.map { inner.leadingAnchor.constraint(equalTo: leadingAnchor, constant: $0) },
            bottom.map { bottomAnchor.constraint(equalTo: inner.bottomAnchor, constant: $0) },
            trailing.map { trailingAnchor.constraint(equalTo: inner.trailingAnchor, constant: $0) }
        ].compactMap { $0 })
    }
}
