import Foundation

enum CanLIIClient {
    static let proxyBase = URL(string: "https://canlii-app.vercel.app/api")!

    static func databases() async throws -> [CanLIIDatabase] {
        let url = proxyBase.appendingPathComponent("databases")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(DatabasesResponse.self, from: data).caseDatabases ?? []
    }

    static func search(databaseId: String, query: String) async throws -> [CanLIICase] {
        var url = proxyBase.appendingPathComponent("search")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "databaseId", value: databaseId),
            URLQueryItem(name: "q", value: query),
        ]
        url = components.url!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(SearchResponse.self, from: data).results ?? []
    }
}
