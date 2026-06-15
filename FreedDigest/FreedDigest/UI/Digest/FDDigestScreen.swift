import SwiftUI

struct FDDigestScreen: View {
    var body: some View {
        ContentUnavailableView(
            "No Digest Yet",
            systemImage: "newspaper",
            description: Text("Your daily Medium digest will appear here.")
        )
        .navigationTitle("Digest")
    }
}
