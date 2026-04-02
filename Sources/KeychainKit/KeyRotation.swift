import Foundation

/// Utilities for rotating Keychain keys.
public enum KeyRotation: Sendable {
    /// Rotate a value from one key to another.
    ///
    /// Reads the value under `oldKey`, writes it under `newKey`, then deletes `oldKey`.
    ///
    /// - Parameters:
    ///   - keychain: The Keychain instance to operate on.
    ///   - oldKey: The current key name.
    ///   - newKey: The new key name.
    /// - Throws: `KeychainError.itemNotFound` if `oldKey` does not exist.
    public static func rotate(
        in keychain: Keychain,
        from oldKey: String,
        to newKey: String
    ) throws {
        guard let data = try keychain.data(for: oldKey) else {
            throw KeychainError.itemNotFound
        }
        try keychain.set(data, for: newKey)
        try keychain.delete(oldKey)
    }

    /// Rotate all keys matching a prefix using a transform function.
    ///
    /// For each key that starts with `prefix`, the `transform` closure generates
    /// the new key name. The value is moved and the old key is deleted.
    ///
    /// - Parameters:
    ///   - keychain: The Keychain instance to operate on.
    ///   - prefix: The key prefix to match.
    ///   - transform: A closure that takes the old key and returns the new key.
    /// - Returns: The number of keys that were rotated.
    @discardableResult
    public static func rotateAll(
        in keychain: Keychain,
        matchingPrefix prefix: String,
        transform: (String) -> String
    ) throws -> Int {
        let keys = try keychain.allKeys().filter { $0.hasPrefix(prefix) }
        for key in keys {
            let newKey = transform(key)
            try rotate(in: keychain, from: key, to: newKey)
        }
        return keys.count
    }
}
