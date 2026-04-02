import Foundation
#if canImport(Security)
import Security
#endif

/// Modern, type-safe wrapper around Apple's Keychain Services.
///
/// Provides a clean API for storing strings, data, booleans, and any `Codable` type
/// in the system Keychain with configurable access control.
public struct Keychain: Sendable {
    /// The service identifier used to scope Keychain items.
    public let service: String

    /// Create a Keychain instance scoped to a service identifier.
    ///
    /// - Parameter service: The service name. Defaults to the app's bundle identifier.
    public init(service: String = "com.philiprehberger.keychain-kit") {
        self.service = service
    }

    // MARK: - String Storage

    /// Store a string value in the Keychain.
    ///
    /// - Parameters:
    ///   - value: The string to store.
    ///   - key: The key to store it under.
    ///   - access: The access level for the item.
    public func set(_ value: String, for key: String, access: AccessLevel = .whenUnlocked) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed("Failed to encode string as UTF-8")
        }
        try setData(data, for: key, access: access)
    }

    /// Retrieve a string value from the Keychain.
    ///
    /// - Parameter key: The key to look up.
    /// - Returns: The stored string, or nil if not found.
    public func string(for key: String) throws -> String? {
        guard let data = try data(for: key) else { return nil }
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed("Failed to decode data as UTF-8 string")
        }
        return string
    }

    // MARK: - Data Storage

    /// Store raw data in the Keychain.
    ///
    /// - Parameters:
    ///   - value: The data to store.
    ///   - key: The key to store it under.
    ///   - access: The access level for the item.
    public func set(_ value: Data, for key: String, access: AccessLevel = .whenUnlocked) throws {
        try setData(value, for: key, access: access)
    }

    /// Retrieve raw data from the Keychain.
    ///
    /// - Parameter key: The key to look up.
    /// - Returns: The stored data, or nil if not found.
    public func data(for key: String) throws -> Data? {
        try getData(for: key)
    }

    // MARK: - Codable Storage

    /// Store any Codable value in the Keychain (serialized as JSON).
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The key to store it under.
    ///   - access: The access level for the item.
    public func set<T: Codable & Sendable>(_ value: T, for key: String, access: AccessLevel = .whenUnlocked) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(value)
        } catch {
            throw KeychainError.encodingFailed(error.localizedDescription)
        }
        try setData(data, for: key, access: access)
    }

    /// Retrieve a Codable value from the Keychain.
    ///
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - type: The expected type.
    /// - Returns: The decoded value, or nil if not found.
    public func object<T: Codable & Sendable>(for key: String, as type: T.Type) throws -> T? {
        guard let data = try getData(for: key) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw KeychainError.decodingFailed(error.localizedDescription)
        }
    }

    // MARK: - Bool Convenience

    /// Store a boolean value in the Keychain.
    ///
    /// - Parameters:
    ///   - value: The boolean to store.
    ///   - key: The key to store it under.
    public func set(_ value: Bool, for key: String) throws {
        let byte: [UInt8] = [value ? 1 : 0]
        try setData(Data(byte), for: key, access: .whenUnlocked)
    }

    /// Retrieve a boolean value from the Keychain.
    ///
    /// - Parameter key: The key to look up.
    /// - Returns: The stored boolean, or nil if not found.
    public func bool(for key: String) throws -> Bool? {
        guard let data = try getData(for: key) else { return nil }
        guard let byte = data.first else { return nil }
        return byte == 1
    }

    // MARK: - Delete & Query

    /// Delete a single item from the Keychain.
    ///
    /// - Parameter key: The key to delete.
    public func delete(_ key: String) throws {
        #if canImport(Security)
        let query = KeychainQuery.deleteQuery(service: service, key: key) as CFDictionary
        let status = SecItemDelete(query)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw mapStatus(status)
        }
        #else
        throw KeychainError.unexpectedStatus(-1)
        #endif
    }

    /// Delete all items for this service from the Keychain.
    public func deleteAll() throws {
        let keys = try allKeys()
        for key in keys {
            try delete(key)
        }
    }

    /// Check if a key exists in the Keychain.
    ///
    /// - Parameter key: The key to check.
    /// - Returns: True if the key exists.
    public func contains(_ key: String) throws -> Bool {
        #if canImport(Security)
        let query = KeychainQuery.existsQuery(service: service, key: key) as CFDictionary
        let status = SecItemCopyMatching(query, nil)
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            return false
        default:
            throw mapStatus(status)
        }
        #else
        throw KeychainError.unexpectedStatus(-1)
        #endif
    }

    /// List all keys stored for this service.
    ///
    /// - Returns: An array of key strings.
    public func allKeys() throws -> [String] {
        #if canImport(Security)
        let query = KeychainQuery.allKeysQuery(service: service) as CFDictionary
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)

        switch status {
        case errSecSuccess:
            guard let items = result as? [[String: Any]] else { return [] }
            return items.compactMap { $0[kSecAttrAccount as String] as? String }
        case errSecItemNotFound:
            return []
        default:
            throw mapStatus(status)
        }
        #else
        throw KeychainError.unexpectedStatus(-1)
        #endif
    }

    // MARK: - Private Helpers

    private func setData(_ data: Data, for key: String, access: AccessLevel) throws {
        #if canImport(Security)
        let deleteQuery = KeychainQuery.deleteQuery(service: service, key: key) as CFDictionary
        SecItemDelete(deleteQuery)

        let addQuery = KeychainQuery.addQuery(
            service: service,
            key: key,
            data: data,
            access: access
        ) as CFDictionary

        let status = SecItemAdd(addQuery, nil)
        guard status == errSecSuccess else {
            throw mapStatus(status)
        }
        #else
        throw KeychainError.unexpectedStatus(-1)
        #endif
    }

    private func getData(for key: String) throws -> Data? {
        #if canImport(Security)
        let query = KeychainQuery.matchQuery(service: service, key: key) as CFDictionary
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw mapStatus(status)
        }
        #else
        throw KeychainError.unexpectedStatus(-1)
        #endif
    }

    #if canImport(Security)
    private func mapStatus(_ status: OSStatus) -> KeychainError {
        switch status {
        case errSecItemNotFound:
            return .itemNotFound
        case errSecDuplicateItem:
            return .duplicateItem
        case errSecAuthFailed:
            return .authenticationFailed
        case errSecInteractionNotAllowed:
            return .accessDenied
        default:
            return .unexpectedStatus(status)
        }
    }
    #endif
}
