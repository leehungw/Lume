import Foundation
import Combine

@MainActor
final class FDOnboardingViewModel: ObservableObject {
    func finishTapped(router: FDAppRouter) {
        router.setRoot(FDAppRoute.main)
    }
}
