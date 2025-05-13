//
//  Session.swift
//  Camera
//
//  Created by acqmal on 5/7/25.
//

import Foundation
import SwiftData

@Model
class Session: Identifiable {
    var id: String
    var createdDate: Date
    var finishedDate: Date?
    
    init(id: String, createdDate: Date, finishedDate: Date? = nil) {
        self.id = id
        self.createdDate = createdDate
        self.finishedDate = finishedDate
    }
}
