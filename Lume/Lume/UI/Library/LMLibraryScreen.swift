import SwiftUI

struct LMLibraryScreen: View {
    var body: some View {
        ContentUnavailableView(
            "No Saved Posts Yet",
            systemImage: "books.vertical",
            description: Text("Saved posts and collections will appear here.")
        )
        .navigationTitle("Library")
    }
}
