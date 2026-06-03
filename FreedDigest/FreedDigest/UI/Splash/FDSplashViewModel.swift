import Foundation
import Combine

@MainActor
final class FDSplashViewModel: ObservableObject {
    func continueTapped(router: FDAppRouter) {
        router.setRoot(FDAppRoute.onboarding)
    }
}
