//
//  Created on 10/27/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK

/// Decides whether a given item can be selected for the intended action, and
/// acts on the selected itemswhen the user confirms.
///
/// This could be extended to handle multiple kinds of action, or multiple
/// handlers could be used to decide the availability of several actions.
protocol SelectionHandler {
    func canSelect(item: ItemViewModel) -> Bool
    func handleSelected(items: [ItemViewModel])
}
