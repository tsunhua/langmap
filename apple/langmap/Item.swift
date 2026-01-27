//
//  Item.swift
//  langmap
//
//  Created by Share Lim on 2026/1/27.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
