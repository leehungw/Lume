import SwiftUI

struct FDMainScreen: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    var body: some View {
        ZStack {
            Color.black
        }
        .ignoresSafeArea()
        .onAppear {
            UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
            UIScrollView.appearance().automaticallyAdjustsScrollIndicatorInsets = false
        }
    }
}
