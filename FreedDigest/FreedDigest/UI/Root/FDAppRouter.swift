import SwiftUI
import Foundation
import Observation

@Observable
@MainActor
final class FDAppRouter: Loggable {
    public var path = NavigationPath()

    init(path: NavigationPath = NavigationPath()) {
        logInfo("init path -> \(String(describing: path))")
        self.path = path
    }
    
    func setRoot(_ route: FDAppRoute) {
        logInfo("setRoot -> \(String(describing: route))")
        path = NavigationPath()

        guard route != .main else { return }

        path.append(route)
    }
    
    func push(_ route: FDAppRoute) {
        logInfo("push -> \(String(describing: route)) | currentCount: \(path.count)")
        path.append(route)
    }
    
    func pop() {
        guard !path.isEmpty else {
            logDebug("pop ignored, path is empty")
            return
        }
        logInfo("pop -> currentCount: \(path.count)")
        path.removeLast()
    }
    
    func popToRoot() {
        logInfo("popToRoot -> remove \(path.count - 1) items (keep root)")
        guard path.count > 1 else { return }
        path.removeLast(path.count - 1)
    }
    
    func replace(with routes: [FDAppRoute]) {
        logInfo("replace -> routes count: \(routes.count)")
        path = NavigationPath()
        routes.forEach { route in
            path.append(route)
        }
    }
}
