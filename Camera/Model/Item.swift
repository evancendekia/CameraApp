//
//  Item.swift
//  Camera
//
//  Created by acqmal on 5/7/25.
//

import SwiftUI

struct Item: Identifiable {
    var id: UUID = UUID()
//    var session: Session
    var url: URL
    let creationDate: Date?
}



extension Item: Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id && lhs.id == rhs.id
    }
}
