//
//  Face.swift
//  Camera
//
//  Created by acqmal on 5/7/25.
//

import Foundation

struct FaceData: Identifiable, Equatable {
    let id: UUID
    var expression: String
    var lastSeen: Date
}
