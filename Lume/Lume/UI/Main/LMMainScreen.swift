import SwiftUI

struct LMMainScreen: View {
    @State private var selectedTab: LMMainTab = .digest

    var body: some View {
        TabView(selection: $selectedTab) {
            LMDigestScreen()
                .tabItem {
                    Label("Digest", systemImage: "newspaper")
                }
                .tag(LMMainTab.digest)
            LMLibraryScreen()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(LMMainTab.library)
                .containerRelativeFrame(.horizontal) { length, _ in length * 0.85}
        }
    }
}

private enum LMMainTab: Hashable {
    case digest
    case library
}
