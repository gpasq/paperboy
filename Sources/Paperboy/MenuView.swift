import SwiftUI

struct MenuView: View {
    @Environment(WallpaperStore.self) private var store
    @State private var selection: BingImage?

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 8)]

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 10) {
            header

            if let selected = selection ?? store.images.first {
                PreviewPanel(image: selected)
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(store.images) { image in
                        Thumbnail(image: image, isSelected: image.id == (selection ?? store.images.first)?.id)
                            .onTapGesture { selection = image }
                    }
                }
            }
            .frame(height: 220)

            if let error = store.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }

            Divider()

            Toggle("Automatically use today's image", isOn: $store.autoApplyLatest)
            Toggle("Launch at login", isOn: $store.launchAtLogin)

            HStack {
                Button("Open Folder") { store.openFolder() }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
        .toggleStyle(.checkbox)
        .padding(14)
        .frame(width: 420)
    }

    private var header: some View {
        HStack {
            Text("Paperboy").font(.headline)
            Text("Bing wallpapers").foregroundStyle(.secondary)
            Spacer()
            if store.isLoading {
                ProgressView().controlSize(.small)
            } else {
                Button {
                    Task { await store.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh")
            }
        }
    }
}

private struct PreviewPanel: View {
    @Environment(WallpaperStore.self) private var store
    let image: BingImage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: image.previewURL) { phase in
                if let img = phase.image {
                    img.resizable().aspectRatio(16 / 9, contentMode: .fill)
                } else {
                    Rectangle().fill(.quaternary)
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(image.title).font(.subheadline.bold())
            Text(image.caption).font(.caption).foregroundStyle(.secondary).lineLimit(2)

            HStack {
                if let date = image.date {
                    Text(date, format: .dateTime.month().day().year())
                        .font(.caption).foregroundStyle(.tertiary)
                }
                Spacer()
                if store.busyID == image.id {
                    ProgressView().controlSize(.small)
                }
                Button("Download") {
                    Task { try? await store.download(image) }
                }
                .disabled(store.isDownloaded(image))
                Button(store.activeID == image.id ? "Active" : "Set as Wallpaper") {
                    Task { await store.apply(image) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.busyID != nil)
            }
        }
    }
}

private struct Thumbnail: View {
    @Environment(WallpaperStore.self) private var store
    let image: BingImage
    let isSelected: Bool

    var body: some View {
        AsyncImage(url: image.thumbnailURL) { phase in
            if let img = phase.image {
                img.resizable().aspectRatio(16 / 9, contentMode: .fill)
            } else {
                Rectangle().fill(.quaternary)
            }
        }
        .frame(height: 68)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 3)
        )
        .overlay(alignment: .topTrailing) {
            if store.activeID == image.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white, Color.accentColor)
                    .padding(4)
            }
        }
        .help(image.title)
        .contentShape(Rectangle())
    }
}
