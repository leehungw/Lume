import SwiftUI

struct FDOnboardingScreen: View {
    @EnvironmentObject private var router: FDAppRouter
    @StateObject private var viewModel = FDOnboardingViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Onboarding")
                .font(.title)
                .fontWeight(.semibold)
            Text("A short intro before you start.")
                .foregroundStyle(.secondary)
            Button("Finish") {
                viewModel.finishTapped(router: router)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
    }
}
