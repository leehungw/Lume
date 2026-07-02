import SwiftUI
import Defaults

struct LMRootScreen: View {
    @Environment(LMAppRouter.self) private var router
    @State var isDoneSplashing: Bool = false
    @Default(.isDoneOnboarding) private var isDoneOnboarding

    var body: some View {
        if isDoneSplashing == false {
            makeSplashScreen()
        } else {
            if isDoneOnboarding {
                makeMainNavigationStack()
            } else {
                LMOnboardingScreen()
                    .transition(.opacity)
            }
        }
    }

    private func makeSplashScreen() -> some View {
        LMSplashScreen()
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
        @Bindable var router = router

        return NavigationStack(path: $router.path) {
            LMMainScreen()
                .navigationDestination(for: LMAppRoute.self) { route in
                    switch route {
                    case .onboarding:
                        LMOnboardingScreen()
                            .toolbarVisibility(.hidden, for: .navigationBar)
                    case .main:
                        LMMainScreen()
                    case .digestPost(let title, let url):
                        LMDigestPostScreen(articleTitle: title, sourceURL: url)
                    }
                }
                .transition(.opacity)
        }
    }
}
