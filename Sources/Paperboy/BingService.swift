import Foundation

/// One Bing homepage image, from either Bing's live feed or the long-term archive.
struct BingImage: Identifiable, Hashable {
    /// yyyyMMdd
    let startdate: String
    /// Stable short name, e.g. "SneffelsAutumn".
    let slug: String
    let title: String
    let caption: String
    let thumbnailURL: URL
    let previewURL: URL
    let fullURL: URL

    /// Same image on the same day gets the same id from either source; doubles as the local filename.
    var id: String { "\(startdate)-\(slug)" }

    var date: Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: startdate)
    }

    /// `base` is a Bing image path without the size suffix, e.g. "/th?id=OHR.SneffelsAutumn_EN-US3953128777".
    init(startdate: String, title: String, caption: String, bingBase base: String) {
        let name = base.components(separatedBy: "OHR.").last ?? base
        self.init(
            startdate: startdate,
            slug: name.components(separatedBy: "_").first ?? name,
            title: title,
            caption: caption,
            thumbnailURL: URL(string: "https://www.bing.com\(base)_400x240.jpg")!,
            previewURL: URL(string: "https://www.bing.com\(base)_1920x1080.jpg")!,
            fullURL: URL(string: "https://www.bing.com\(base)_UHD.jpg")!
        )
    }

    init(startdate: String, slug: String, title: String, caption: String,
         thumbnailURL: URL, previewURL: URL, fullURL: URL) {
        self.startdate = startdate
        self.slug = slug
        self.title = title
        self.caption = caption
        self.thumbnailURL = thumbnailURL
        self.previewURL = previewURL
        self.fullURL = fullURL
    }
}

enum BingService {
    private struct Feed: Decodable {
        struct Entry: Decodable {
            let startdate: String
            let urlbase: String
            let copyright: String
            let title: String
        }
        let images: [Entry]
    }

    /// Bing exposes roughly the last 15 days: idx 0–7, at most 8 per request.
    static func fetchRecent(market: String = Locale.current.bingMarket) async throws -> [BingImage] {
        async let a = fetch(idx: 0, n: 8, market: market)
        async let b = fetch(idx: 7, n: 8, market: market)
        var seen = Set<String>()
        return (try await a + b)
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.startdate > $1.startdate }
    }

    private static func fetch(idx: Int, n: Int, market: String) async throws -> [BingImage] {
        var c = URLComponents(string: "https://www.bing.com/HPImageArchive.aspx")!
        c.queryItems = [
            .init(name: "format", value: "js"),
            .init(name: "idx", value: "\(idx)"),
            .init(name: "n", value: "\(n)"),
            .init(name: "mkt", value: market),
        ]
        let (data, _) = try await URLSession.shared.data(from: c.url!)
        return try JSONDecoder().decode(Feed.self, from: data).images.map { e in
            // Caption without the trailing "(© credit)".
            let caption = e.copyright.range(of: " (©").map { String(e.copyright[..<$0.lowerBound]) } ?? e.copyright
            return BingImage(startdate: e.startdate, title: e.title, caption: caption, bingBase: e.urlbase)
        }
    }
}

/// Long-term archive (2010–today) from the community-run Bing Wallpaper Archive,
/// https://github.com/npanuhin/Bing-Wallpaper-Archive — Bing itself only serves ~15 days.
enum ArchiveService {
    static let firstYear = 2010

    private struct Entry: Decodable {
        let title: String?
        let caption: String?
        let subtitle: String?
        let date: String
        let bing_url: String?
        let url: String
    }

    /// All images for one year, newest first.
    static func fetchYear(_ year: Int, market: String = Locale.current.bingMarket) async throws -> [BingImage] {
        do {
            return try await fetchYear(year, path: archivePath(for: market))
        } catch URLError.fileDoesNotExist where archivePath(for: market) != "US/en" {
            // Not every market is archived; fall back to the US feed.
            return try await fetchYear(year, path: "US/en")
        }
    }

    private static func fetchYear(_ year: Int, path: String) async throws -> [BingImage] {
        let url = URL(string: "https://bing.npanuhin.me/\(path).\(year).json")!
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(http.statusCode == 404 ? .fileDoesNotExist : .badServerResponse)
        }
        return try JSONDecoder().decode([Entry].self, from: data)
            .compactMap(image)
            .sorted { $0.startdate > $1.startdate }
    }

    private static func image(from e: Entry) -> BingImage? {
        let startdate = e.date.replacingOccurrences(of: "-", with: "")
        let description = e.title ?? ""
        // The archive's `title` is Bing's long description; `caption`/`subtitle` is the short headline.
        let title = e.caption ?? e.subtitle ?? description
        let caption = title == description ? "" : description

        if let bing = e.bing_url, let r = bing.range(of: "/th?id=") {
            let base = String(bing[r.lowerBound...]).replacingOccurrences(of: "_UHD.jpg", with: "")
            return BingImage(startdate: startdate, title: title, caption: caption, bingBase: base)
        }
        // Older entries (pre-2019 or so) only exist on the archive's own host, at a single size.
        guard let url = URL(string: e.url) else { return nil }
        let slug = description.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .prefix(3).map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
        return BingImage(startdate: startdate, slug: slug.isEmpty ? "Archive" : slug, title: title,
                         caption: caption, thumbnailURL: url, previewURL: url, fullURL: url)
    }

    /// "en-US" → "US/en", the archive's directory layout.
    private static func archivePath(for market: String) -> String {
        let parts = market.split(separator: "-")
        guard parts.count == 2 else { return "US/en" }
        return "\(parts[1].uppercased())/\(parts[0].lowercased())"
    }
}

extension Locale {
    var bingMarket: String {
        guard let lang = language.languageCode?.identifier,
              let region = region?.identifier else { return "en-US" }
        return "\(lang)-\(region)"
    }
}
