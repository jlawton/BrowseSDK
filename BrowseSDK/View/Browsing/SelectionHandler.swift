//
//  Created on 10/27/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK

protocol SelectionHandler {
    func canSelect(item: ItemViewModel) -> Bool
    func handleSelected(items: [ItemViewModel])
}
