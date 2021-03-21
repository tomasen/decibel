//
//  decibelApp.swift
//  Shared
//
//  Created by SHEN SHENG on 3/21/21.
//

import SwiftUI

@main
struct decibelApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
