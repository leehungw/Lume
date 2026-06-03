import SwiftUI

struct FDSplashScreen: View {
    @EnvironmentObject private var router: FDAppRouter
    @StateObject private var viewModel = FDSplashViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("FreedDigest")
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text("Welcome back.")
                .foregroundStyle(.secondary)
            Button("Continue") {
                viewModel.continueTapped(router: router)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
    }
}
