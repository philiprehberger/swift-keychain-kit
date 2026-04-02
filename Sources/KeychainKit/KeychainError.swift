import Foundation

/// Errors that can occur during Keychain operations.
public enum KeychainError: Error, Sendable, CustomStringConvertible {
    /// The requested item was not found in the Keychain.
    case itemNotFound

    /// An item with the same key already exists.
    case duplicateItem

    /// Biometric or passcode authentication failed.
    case authenticationFailed

    /// Failed to encode the value for storage.
    case encodingFailed(String)

    /// Failed to decode the stored value.
    case decodingFailed(String)

    /// Access to the Keychain item was denied.
    case accessDenied

    /// An unexpected Security framework status code was returned.
    case unexpectedStatus(Int32)

    public var description: String {
        switch self {
        case .itemNotFound:
            return "Keychain item not found"
        case .duplicateItem:
            return "Keychain item already exists"
        case .authenticationFailed:
            return "Authentication failed"
        case .encodingFailed(let detail):
            return "Encoding failed: \(detail)"
        case .decodingFailed(let detail):
            return "Decoding failed: \(detail)"
        case .accessDenied:
            return "Access denied"
        case .unexpectedStatus(let status):
            return "Unexpected Keychain status: \(status)"
        }
    }
}
