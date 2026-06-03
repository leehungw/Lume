import SwiftUI

struct FDOnboardingScreen: View {
    @Environment(FDAppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Text("Onboarding")
                .font(.title)
                .fontWeight(.semibold)
            Text("A short intro before you start.")
                .foregroundStyle(.secondary)
            Button("Finish") {
                router.setRoot(FDAppRoute.main)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
    }
}
