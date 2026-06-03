import SwiftUI
import CoreData
import Factory

@main
struct FreedDigestApp: App {
    @Injected(\.persistenceController) private var persistenceController
    @StateObject private var router = FDAppRouter()

    var body: some Scene {
        WindowGroup {
            FDRootScreen()
                .environmentObject(router)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
