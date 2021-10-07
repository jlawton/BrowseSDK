//
//  Created on 10/7/21.
//  Copyright © 2021 Box. All rights reserved.
//

import BoxSDK
import Foundation

protocol ItemActionHandler {
    func canAct(on item: ItemViewModel) -> Bool
    func act(on item: ItemViewModel)
}

class BoxFilePickerHandler: ItemActionHandler {
    private let canActOnFile: (File) -> Bool
    private let actOnFile: (File) -> Void

    init(canAct: @escaping (File) -> Bool, act: @escaping (File) -> Void) {
        canActOnFile = canAct
        actOnFile = act
    }

    func canAct(on item: ItemViewModel) -> Bool {
        if case let .file(file) = item.item {
            return canActOnFile(file)
        }
        return false
    }

    func act(on item: ItemViewModel) {
        if case let .file(file) = item.item {
            return actOnFile(file)
        }
    }
}
