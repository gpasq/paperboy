import Foundation

/// One entry from Bing's homepage image archive.
struct BingImage: Identifiable, Hashable, Decodable {
    let startdate: String
    let urlbase: String
    let copyright: String
    let title: String
    let hsh: String

    var id: String { hsh }

    /// Stable short name, e.g. "SneffelsAutumn".
    var slug: String {
        let name = urlbase.components(separatedBy: "OHR.").last ?? urlbase
        return name.components(separatedBy: "_").first ?? name
    }

    var thumbnailURL: URL { URL(string: "https://www.bing.com\(urlbase)_400x240.jpg")! }
    var previewURL: URL { URL(string: "https://www.bing.com\(urlbase)_1920x1080.jpg")! }
    var fullURL: URL { URL(string: "https://www.bing.com\(urlbase)_UHD.jpg")! }

    var date: Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: startdate)
    }

    /// Caption without the trailing "(© credit)".
    var caption: String {
        if let r = copyright.range(of: " (©") { return String(copyright[..<r.lowerBound]) }
        return copyright
    }
}

enum BingService {
    private struct Archive: Decodable { let images: [BingImage] }

    /// Bing exposes roughly the last 15 days: idx 0–7, at most 8 per request.
    static func fetchRecent(market: String = Locale.current.bingMarket) async throws -> [BingImage] {
        async let a = fetch(idx: 0, n: 8, market: market)
        async let b = fetch(idx: 7, n: 8, market: market)
        var seen = Set<String>()
        return (try await a + b)
            .filter { seen.insert($0.hsh).inserted }
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
        return try JSONDecoder().decode(Archive.self, from: data).images
    }
}

extension Locale {
    var bingMarket: String {
        guard let lang = language.languageCode?.identifier,
              let region = region?.identifier else { return "en-US" }
        return "\(lang)-\(region)"
    }
}
