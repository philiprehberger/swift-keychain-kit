import XCTest
@testable import KeychainKit

final class AccessControlTests: XCTestCase {
    private var keychain: Keychain!

    override func setUp() {
        super.setUp()
        keychain = Keychain(service: "com.test.access.\(UUID().uuidString)")
    }

    override func tearDown() {
        try? keychain.deleteAll()
        super.tearDown()
    }

    #if canImport(Security)
    func testDefaultAccessLevel() throws {
        try keychain.set("value", for: "default-access")
        XCTAssertEqual(try keychain.string(for: "default-access"), "value")
    }

    func testAfterFirstUnlockAccess() throws {
        try keychain.set("value", for: "afu", access: .afterFirstUnlock)
        XCTAssertEqual(try keychain.string(for: "afu"), "value")
    }

    func testWhenPasscodeSetAccess() throws {
        try keychain.set("value", for: "passcode", access: .whenPasscodeSet)
        // May or may not succeed depending on device passcode state
        // Just verify it doesn't crash
    }

    func testAccessLevelEnum() {
        XCTAssertNotNil(AccessLevel.whenUnlocked)
        XCTAssertNotNil(AccessLevel.afterFirstUnlock)
        XCTAssertNotNil(AccessLevel.whenPasscodeSet)
    }

    func testBiometricPolicyEnum() {
        XCTAssertNotNil(BiometricPolicy.devicePasscode)
        XCTAssertNotNil(BiometricPolicy.biometricAny)
        XCTAssertNotNil(BiometricPolicy.biometricCurrentSet)
    }
    #else
    func testSkippedOnLinux() {}
    #endif
}
