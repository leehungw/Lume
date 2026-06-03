import Combine
import Foundation

@MainActor
final class FDAppRouter: ObservableObject {
    @Published var path: [FDAppRoute] = []

    func setRoot(_ route: FDAppRoute) {
        path.removeAll()

        guard route != .main else { return }
        path.append(route)
    }
}
