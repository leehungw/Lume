import SwiftUI

struct LMDigestScreen: View {
    @Environment(LMAppRouter.self) private var router
    @State private var viewModel = LMDigestViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                gmailConnectionSection
                digestContentSection
            }
            .padding(20)
        }
        .navigationTitle("Digest")
        .task {
            viewModel.load()
        }
    }

    private var gmailConnectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("Gmail", systemImage: "envelope")
                    .font(.headline)

                Spacer()

                Text(viewModel.isConnected ? "Connected" : "Not Connected")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.isConnected ? .green : .secondary)
            }

            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 12) {
                Button {
                    Task {
                        await viewModel.connectGmail()
                    }
                } label: {
                    if viewModel.isConnecting {
                        ProgressView()
                    } else {
                        Label(viewModel.connectionActionTitle, systemImage: "person.crop.circle.badge.plus")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isBusy)

                if viewModel.isConnected {
                    Button("Disconnect", role: .destructive) {
                        viewModel.disconnectGmail()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isBusy)
                }
            }

            if viewModel.isConnected {
                Button {
                    Task {
                        await viewModel.fetchMediumDigest()
                    }
                } label: {
                    if viewModel.isFetchingDigest {
                        ProgressView()
                    } else {
                        Label("Fetch Medium Digest", systemImage: "tray.and.arrow.down")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isBusy)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var digestContentSection: some View {
        if viewModel.digestEmails.isEmpty {
            ContentUnavailableView(
                "No Digest Yet",
                systemImage: "newspaper",
                description: Text("Fetch Gmail to import your latest Medium digest.")
            )
            .frame(maxWidth: .infinity, minHeight: 260)
        } else {
            VStack(alignment: .leading, spacing: 16) {
                Text("Medium Digest")
                    .font(.title3)
                    .fontWeight(.semibold)

                ForEach(viewModel.digestEmails) { digestEmail in
                    digestEmailSection(digestEmail)
                }
            }
        }
    }

    private func digestEmailSection(_ digestEmail: LMMediumDigestEmail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(digestEmail.subject)
                    .font(.headline)

                Text(digestEmail.sender)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let receivedAtDescription = digestEmail.receivedAtDescription {
                    Text(receivedAtDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(digestEmail.articleLinks) { articleLink in
                Button {
                    router.push(.digestPost(title: articleLink.title, url: articleLink.url))
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.tint.opacity(0.12))
                                .frame(width: 36, height: 36)

                            Image(systemName: "doc.text")
                                .font(.callout)
                                .foregroundStyle(.tint)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(articleLink.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .lineLimit(2)

                            Text(articleLink.url.host ?? "Medium")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
