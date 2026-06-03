import SwiftUI
import Defaults

struct FDRootScreen: View {
    @EnvironmentObject private var router: FDAppRouter
    @State var isDoneSplashing: Bool = false
    @Default(.isDoneOnboarding) private var isDoneOnboarding

    var body: some View {
        if isDoneSplashing == false {
            makeSplashScreen()
        } else {
            if isDoneOnboarding {
                makeMainNavigationStack()
            } else {
                FDOnboardingScreen()
                    .transition(.opacity)
            }
        }
    }

    private func makeSplashScreen() -> some View {
        FDSplashScreen()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        isDoneSplashing = true
                    }
                }
            }
            .transition(.opacity)
    }

    private func makeMainNavigationStack() -> some View {
        NavigationStack(path: $router.path) {
            FDMainScreen()
                .navigationDestination(for: FDAppRoute.self) { route in
                    switch route {
                    case .onboarding:
                        FDOnboardingScreen()
                            .toolbarVisibility(.hidden, for: .navigationBar)
                    case .main:
                        FDMainScreen()
                    }
                }
                .transition(.opacity)
        }
    }
}
