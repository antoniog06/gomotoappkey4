//
//  Item.swift
//  GoMoto
//
//  Created by AnthonyGarcia on 20/12/2024.
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
