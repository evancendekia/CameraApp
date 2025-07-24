//
//  CameraApp.swift
//  Camera
//
//  Created by M. Evan Cendekia Suryandaru on 02/05/25.
//

import SwiftUI
import SwiftData

@main
struct CameraApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    var modelContainer: ModelContainer {
        let schema = Schema([TakenPhoto.self, Session.self])
        let modelContainer = try! ModelContainer(for: schema)
//        let taken3 = TakenPhoto(id: UUID(), timestamp: Date(), filename: "E84C582B-07F2-4D43-9C3C-BF153F063D9F.jpg", session: "testsessionid")
//        let taken4 = TakenPhoto(id: UUID(), timestamp: Date(), filename: "6DFA2241-49D1-4C2C-94EB-8B670C7BD65A.jpg", session: "testsessionid")
//        let taken5 = TakenPhoto(id: UUID(), timestamp: Date(), filename: "B5CD2663-11AA-4762-AF39-58FD2F3E30CD.jpg", session: "testsessionid")
//    
//        modelContainer.mainContext.insert(taken3)
//        modelContainer.mainContext.insert(taken4)
//        modelContainer.mainContext.insert(taken5)
        return modelContainer
    }
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if hasSeenOnboarding {
                    ShowCamera()
                        .preferredColorScheme(.dark)
                } else {
                    OnBoarding()
                        .preferredColorScheme(.dark)
                }
            }
        }
        .modelContainer(modelContainer)
    }
}



