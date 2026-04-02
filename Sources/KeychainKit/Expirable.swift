import Foundation

/// Internal wrapper that pairs a value with an expiration date.
struct ExpirableEntry: Codable {
    let data: Data
    let expiresAt: Date?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date() >= expiresAt
    }
}
