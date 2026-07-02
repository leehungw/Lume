import SwiftUI
import CoreData
import Factory

@main
struct LumeApp: App {
    @Injected(\.persistenceController) private var persistenceController
    @State private var router = LMAppRouter()

    var body: some Scene {
        WindowGroup {
            LMRootScreen()
                .environment(router)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
