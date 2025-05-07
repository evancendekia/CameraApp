//
//  Session.swift
//  Camera
//
//  Created by acqmal on 5/7/25.
//

import Foundation

struct Session: Identifiable {
    var id: Int
    let createdDate: Date
    var items: [Item]
}
