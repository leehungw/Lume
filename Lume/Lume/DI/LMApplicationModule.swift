import Foundation
import Factory

extension Container {
    var persistenceController: Factory<LMPersistenceController> {
        self { MainActor.assumeIsolated { LMPersistenceController.shared } }.singleton
    }

    var lmRepository: Factory<LMRepository> {
        self {
            MainActor.assumeIsolated {
                LMRepository(persistenceController: LMPersistenceController.shared)
            }
        }
        .singleton
    }

    var gmailOAuthService: Factory<LMGmailOAuthService> {
        self {
            MainActor.assumeIsolated {
                LMGmailOAuthService()
            }
        }
        .singleton
    }

    var gmailDigestService: Factory<LMGmailDigestService> {
        self {
            LMGmailDigestService()
        }
        .singleton
    }

    var freediumContentService: Factory<LMFreediumContentService> {
        self {
            LMFreediumContentService()
        }
        .singleton
    }
}
