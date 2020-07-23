//
//  Created on 7/22/20.
//  Copyright © 2020 Box. All rights reserved.
//

import BoxSDK

public struct BrowseConfiguration {
    public var browseToFile = BrowseToFile()
    public var folderActions = FolderActionCustomization()
    public var additionalFields: [String] = []

    public init() {}
}
