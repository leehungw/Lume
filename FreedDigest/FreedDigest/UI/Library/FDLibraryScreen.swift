import SwiftUI

struct FDLibraryScreen: View {
    var body: some View {
        ContentUnavailableView(
            "No Saved Posts Yet",
            systemImage: "books.vertical",
            description: Text("Saved posts and collections will appear here.")
        )
        .navigationTitle("Library")
    }
}
