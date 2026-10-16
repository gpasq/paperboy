import SwiftUI

struct MenuView: View {
    private enum Source: Hashable { case recent, archive }

    @Environment(WallpaperStore.self) private var store
    @State private var selection: BingImage?
    @State private var source = Source.recent
    @State private var year = Calendar.current.component(.year, from: .now)
    /// 1–12, or nil for the whole year.
    @State private var month: Int?

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 8)]
    private let years = Array((ArchiveService.firstYear...Calendar.current.component(.year, from: .now)).reversed())

    private var shown: [BingImage] {
        switch source {
        case .recent:
            return store.images
        case .archive:
            let all = store.archive[year] ?? []
            guard let month else { return all }
            let prefix = String(format: "%04d%02d", year, month)
            return all.filter { $0.startdate.hasPrefix(prefix) }
        }
    }

    /// The tapped image if it's still in the grid, otherwise the newest one shown.
    private var current: BingImage? {
        if let selection, shown.contains(selection) { return selection }
        return shown.first
    }

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 10) {
            header

            if source == .archive {
                archiveControls
            }

            if let selected = current {
                PreviewPanel(image: selected)
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(shown) { image in
                        Thumbnail(image: image, isSelected: image.id == current?.id)
                            .onTapGesture { selection = image }
                    }
                }
            }
            .frame(height: 220)
            .overlay {
                if source == .archive && store.archiveLoadingYear == year {
                    ProgressView()
                } else if source == .archive && store.archive[year] != nil && shown.isEmpty {
                    Text("No images for this month").foregroundStyle(.secondary)
                }
            }

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
        .onChange(of: source) { loadArchiveIfNeeded() }
        .onChange(of: year) { loadArchiveIfNeeded() }
    }

    private var archiveControls: some View {
        HStack {
            Picker("Year", selection: $year) {
                ForEach(years, id: \.self) { Text(String($0)).tag($0) }
            }
            .fixedSize()
            Picker("Month", selection: $month) {
                Text("All months").tag(Int?.none)
                Divider()
                ForEach(1...12, id: \.self) { m in
                    Text(Calendar.current.monthSymbols[m - 1]).tag(Int?.some(m))
                }
            }
            .fixedSize()
            Spacer()
            Button {
                Task { await shuffle() }
            } label: {
                Image(systemName: "shuffle")
            }
            .help("Random image from the archive")
        }
        .labelsHidden()
    }

    private func loadArchiveIfNeeded() {
        guard source == .archive else { return }
        let year = year
        Task { await store.loadArchive(year: year) }
    }

    /// Jump to a random day anywhere in the archive.
    private func shuffle() async {
        let pick = years.randomElement()!
        await store.loadArchive(year: pick)
        guard let image = store.archive[pick]?.randomElement() else { return }
        year = pick
        month = Int(image.startdate.dropFirst(4).prefix(2))
        selection = image
    }

    private var header: some View {
        HStack {
            Text("Paperboy").font(.headline)
            Spacer()
            Picker("Source", selection: $source) {
                Text("Recent").tag(Source.recent)
                Text("Archive").tag(Source.archive)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
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
