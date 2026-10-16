import AppKit
import Observation
import ServiceManagement

@MainActor
@Observable
final class WallpaperStore {
    var images: [BingImage] = []
    var isLoading = false
    var busyID: String?
    var errorMessage: String?
    var activeID: String? {
        didSet { UserDefaults.standard.set(activeID, forKey: "activeID") }
    }
    var autoApplyLatest: Bool {
        didSet {
            UserDefaults.standard.set(autoApplyLatest, forKey: "autoApplyLatest")
            if autoApplyLatest { Task { await refresh() } }
        }
    }
    var launchAtLogin: Bool {
        didSet { setLaunchAtLogin(launchAtLogin) }
    }

    /// ~/Pictures/Paperboy
    let folder: URL = {
        let pics = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
        let dir = pics.appendingPathComponent("Paperboy", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private var timer: Timer?

    init() {
        activeID = UserDefaults.standard.string(forKey: "activeID")
        autoApplyLatest = UserDefaults.standard.bool(forKey: "autoApplyLatest")
        launchAtLogin = SMAppService.mainApp.status == .enabled

        Task { await refresh() }
        // Bing rotates once a day; checking hourly is plenty.
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
        // Re-apply to newly attached displays.
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reapplyActive() }
        }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            images = try await BingService.fetchRecent()
            errorMessage = nil
            if autoApplyLatest, let latest = images.first, latest.id != activeID {
                await apply(latest)
            }
        } catch {
            errorMessage = "Couldn't reach Bing: \(error.localizedDescription)"
        }
    }

    func localURL(for image: BingImage) -> URL {
        folder.appendingPathComponent("\(image.startdate)-\(image.slug).jpg")
    }

    func isDownloaded(_ image: BingImage) -> Bool {
        FileManager.default.fileExists(atPath: localURL(for: image).path)
    }

    @discardableResult
    func download(_ image: BingImage) async throws -> URL {
        let dest = localURL(for: image)
        if FileManager.default.fileExists(atPath: dest.path) { return dest }
        let (tmp, response) = try await URLSession.shared.download(from: image.fullURL)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        try FileManager.default.moveItem(at: tmp, to: dest)
        return dest
    }

    func apply(_ image: BingImage) async {
        busyID = image.id
        defer { busyID = nil }
        do {
            let url = try await download(image)
            try setDesktop(url)
            activeID = image.id
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't set wallpaper: \(error.localizedDescription)"
        }
    }

    private func reapplyActive() {
        guard let id = activeID, let image = images.first(where: { $0.id == id }),
              isDownloaded(image) else { return }
        try? setDesktop(localURL(for: image))
    }

    private func setDesktop(_ url: URL) throws {
        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
            .allowClipping: true,
        ]
        for screen in NSScreen.screens {
            try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: options)
        }
    }

    func openFolder() {
        NSWorkspace.shared.open(folder)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            errorMessage = "Launch at login: \(error.localizedDescription)"
        }
    }
}
