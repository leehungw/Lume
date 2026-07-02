import SwiftUI

struct LMSplashScreen: View {
    var body: some View {
        ZStack {
            Image(.imgSplashBg)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Image(.imgAppIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 132, height: 132)
                .shadow(color: .black.opacity(0.24), radius: 24, y: 12)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .navigationBarBackButtonHidden(true)
    }
}
