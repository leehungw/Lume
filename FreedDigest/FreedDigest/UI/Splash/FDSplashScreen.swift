import SwiftUI

struct FDSplashScreen: View {
    @Environment(FDAppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Text("FreedDigest")
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text("Welcome back.")
                .foregroundStyle(.secondary)
            Button("Continue") {
                router.setRoot(FDAppRoute.onboarding)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
    }
}
