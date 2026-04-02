import Foundation
#if canImport(Security)
import Security
#endif

extension Keychain {
    /// Store a value protected by biometric authentication.
    ///
    /// The value will require Face ID, Touch ID, or device passcode to access,
    /// depending on the specified policy.
    ///
    /// - Parameters:
    ///   - value: The Codable value to store.
    ///   - key: The key to store it under.
    ///   - policy: The biometric policy to enforce.
    ///   - prompt: The message shown during biometric authentication.
    public func setWithBiometric<T: Codable & Sendable>(
        _ value: T,
        for key: String,
        policy: BiometricPolicy = .biometricAny,
        prompt: String = "Authenticate to access secure data"
    ) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(value)
        } catch {
            throw KeychainError.encodingFailed(error.localizedDescription)
        }

        #if canImport(Security)
        let deleteQuery = KeychainQuery.deleteQuery(service: service, key: key) as CFDictionary
        SecItemDelete(deleteQuery)

        var accessError: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            policy.secAccessControlFlags,
            &accessError
        ) else {
            throw KeychainError.accessDenied
        }

        let query = KeychainQuery.addQuery(
            service: service,
            key: key,
            data: data,
            accessControl: accessControl,
            prompt: prompt
        ) as CFDictionary

        let status = SecItemAdd(query, nil)
        guard status == errSecSuccess else {
            throw mapBiometricStatus(status)
        }
        #else
        throw KeychainError.unexpectedStatus(-1)
        #endif
    }

    /// Retrieve a biometric-protected value from the Keychain.
    ///
    /// This triggers Face ID, Touch ID, or passcode depending on how the item was stored.
    ///
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - type: The expected Codable type.
    ///   - prompt: The message shown during biometric authentication.
    /// - Returns: The decoded value, or nil if not found.
    public func objectWithBiometric<T: Codable & Sendable>(
        for key: String,
        as type: T.Type,
        prompt: String = "Authenticate to access secure data"
    ) async throws -> T? {
        #if canImport(Security)
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let query = KeychainQuery.matchQuery(
                        service: self.service,
                        key: key,
                        prompt: prompt
                    ) as CFDictionary

                    var result: AnyObject?
                    let status = SecItemCopyMatching(query, &result)

                    switch status {
                    case errSecSuccess:
                        guard let data = result as? Data else {
                            continuation.resume(returning: nil)
                            return
                        }
                        do {
                            let decoded = try JSONDecoder().decode(type, from: data)
                            continuation.resume(returning: decoded)
                        } catch {
                            continuation.resume(throwing: KeychainError.decodingFailed(error.localizedDescription))
                        }
                    case errSecItemNotFound:
                        continuation.resume(returning: nil)
                    default:
                        continuation.resume(throwing: self.mapBiometricStatus(status))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        #else
        throw KeychainError.unexpectedStatus(-1)
        #endif
    }

    #if canImport(Security)
    private func mapBiometricStatus(_ status: OSStatus) -> KeychainError {
        switch status {
        case errSecAuthFailed:
            return .authenticationFailed
        case errSecUserCanceled:
            return .authenticationFailed
        case errSecInteractionNotAllowed:
            return .accessDenied
        case errSecItemNotFound:
            return .itemNotFound
        case errSecDuplicateItem:
            return .duplicateItem
        default:
            return .unexpectedStatus(status)
        }
    }
    #endif
}
