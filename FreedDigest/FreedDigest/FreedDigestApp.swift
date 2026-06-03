import SwiftUI
import CoreData
import Factory

@main
struct FreedDigestApp: App {
    @Injected(\.persistenceController) private var persistenceController
    @State private var router = FDAppRouter()

    var body: some Scene {
        WindowGroup {
            FDRootScreen()
                .environment(router)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
