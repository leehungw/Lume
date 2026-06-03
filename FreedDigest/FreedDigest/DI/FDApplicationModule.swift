import Foundation
import Factory

extension Container {
    var persistenceController: Factory<FDPersistenceController> {
        self { MainActor.assumeIsolated { FDPersistenceController.shared } }.singleton
    }

    var fdRepository: Factory<FDRepository> {
        self {
            MainActor.assumeIsolated {
                FDRepository(persistenceController: FDPersistenceController.shared)
            }
        }
        .singleton
    }
}
