import Foundation

struct CanLIIDatabase: Decodable, Identifiable, Hashable {
    var id: String { databaseId }
    let databaseId: String
    let jurisdiction: String
    let name: String
}

struct DatabasesResponse: Decodable {
    let caseDatabases: [CanLIIDatabase]?
}

struct CanLIICase: Decodable, Identifiable, Hashable {
    var id: String { caseId.en ?? UUID().uuidString }
    let caseId: CaseIdValue
    let title: String
    let citation: String?

    struct CaseIdValue: Decodable, Hashable {
        let en: String?
    }
}

struct SearchResponse: Decodable {
    let results: [CanLIICase]?
}
