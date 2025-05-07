//
//  TakenPhoto.swift
//  Camera
//
//  Created by M. Evan Cendekia Suryandaru on 07/05/25.
//

import Foundation
import SwiftData

@Model
class TakenPhoto: Identifiable {
    var id: UUID
    var timestamp: Date
    var filename: String
    var session: String
    
    init(id: UUID, timestamp: Date, filename: String, session: String) {
        self.id = id
        self.timestamp = timestamp
        self.filename = filename
        self.session = session
    }
}
