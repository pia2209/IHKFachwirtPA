//
//  IHKFachwirtPAApp.swift
//  IHKFachwirtPA
//
//  Created by Pia Adibelli on 25.10.26.
//

import SwiftUI
import CoreData

@main
struct IHKFachwirtPAApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
