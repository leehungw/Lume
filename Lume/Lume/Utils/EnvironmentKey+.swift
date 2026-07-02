import SwiftUI
import UIKit

private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeWindows = scenes.first(where: { $0.activationState == .foregroundActive })?.windows
        let anyWindows = activeWindows ?? scenes.first?.windows ?? []
        let insets = (anyWindows.first(where: { $0.isKeyWindow }) ?? anyWindows.first)?.safeAreaInsets ?? .zero
        return insets.insets
    }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

private extension UIEdgeInsets {
    var insets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
