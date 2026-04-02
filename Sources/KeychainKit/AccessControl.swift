import Foundation
#if canImport(Security)
import Security
#endif

/// Controls when a Keychain item is accessible.
public enum AccessLevel: Sendable {
    /// Accessible when the device is unlocked (default).
    case whenUnlocked

    /// Accessible after the first unlock since boot.
    case afterFirstUnlock

    /// Accessible only when the device has a passcode set.
    case whenPasscodeSet
}

/// Biometric authentication policy for protected Keychain items.
public enum BiometricPolicy: Sendable {
    /// Require device passcode.
    case devicePasscode

    /// Require any enrolled biometric (Face ID or Touch ID).
    case biometricAny

    /// Require the currently enrolled biometric set.
    case biometricCurrentSet
}

#if canImport(Security)
extension AccessLevel {
    var secAttrAccessible: CFString {
        switch self {
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .whenPasscodeSet:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        }
    }
}

extension BiometricPolicy {
    var secAccessControlFlags: SecAccessControlCreateFlags {
        switch self {
        case .devicePasscode:
            return .devicePasscode
        case .biometricAny:
            return .biometryAny
        case .biometricCurrentSet:
            return .biometryCurrentSet
        }
    }
}
#endif
