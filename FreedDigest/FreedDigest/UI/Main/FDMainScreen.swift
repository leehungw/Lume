import SwiftUI

struct FDMainScreen: View {
    @State private var selectedTab: FDMainTab = .digest

    var body: some View {
        TabView(selection: $selectedTab) {
            FDDigestScreen()
                .tabItem {
                    Label("Digest", systemImage: "newspaper")
                }
                .tag(FDMainTab.digest)

            FDLibraryScreen()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(FDMainTab.library)
        }
    }
}

private enum FDMainTab: Hashable {
    case digest
    case library
}
