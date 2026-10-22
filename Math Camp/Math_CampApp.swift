//
//  Math_CampApp.swift
//  Math Camp
//
//  Created by Sebastian Strus on 2026-10-19.
//

import SwiftUI
import SwiftData

@main
struct Math_CampApp: App {
    @State private var premium = PremiumAccess()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        Task.detached(priority: .utility) { ContentValidator.logResults() }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(premium)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await premium.refreshEntitlements() } }
                }
        }
        .modelContainer(for: TaskResult.self)
    }
}
