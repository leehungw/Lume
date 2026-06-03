import SwiftUI
import Defaults

struct FDOnboardingScreen: View {
    @Environment(FDAppRouter.self) private var router
    @Default(.isDoneOnboarding) private var isDoneOnboarding

    var body: some View {
        VStack(spacing: 16) {
            Text("Onboarding")
                .font(.title)
                .fontWeight(.semibold)
            Text("A short intro before you start.")
                .foregroundStyle(.secondary)
            Button("Finish") {
                isDoneOnboarding = true
                router.setRoot(FDAppRoute.main)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
    }
}
