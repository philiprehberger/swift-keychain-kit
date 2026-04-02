import XCTest
@testable import KeychainKit

final class KeyRotationTests: XCTestCase {
    private var keychain: Keychain!

    override func setUp() {
        super.setUp()
        keychain = Keychain(service: "com.test.rotation.\(UUID().uuidString)")
    }

    override func tearDown() {
        try? keychain.deleteAll()
        super.tearDown()
    }

    #if canImport(Security)
    func testRotateKey() throws {
        try keychain.set("secret", for: "old-key")
        try KeyRotation.rotate(in: keychain, from: "old-key", to: "new-key")
        XCTAssertEqual(try keychain.string(for: "new-key"), "secret")
    }

    func testRotateDeletesOldKey() throws {
        try keychain.set("secret", for: "old-key")
        try KeyRotation.rotate(in: keychain, from: "old-key", to: "new-key")
        XCTAssertNil(try keychain.string(for: "old-key"))
    }

    func testRotateNonexistentKeyThrows() throws {
        XCTAssertThrowsError(
            try KeyRotation.rotate(in: keychain, from: "missing", to: "new")
        ) { error in
            guard case KeychainError.itemNotFound = error else {
                XCTFail("Expected itemNotFound, got \(error)")
                return
            }
        }
    }

    func testRotateAllWithPrefix() throws {
        try keychain.set("v1-a", for: "v1.token-a")
        try keychain.set("v1-b", for: "v1.token-b")
        try keychain.set("other", for: "unrelated")

        let count = try KeyRotation.rotateAll(
            in: keychain,
            matchingPrefix: "v1."
        ) { key in
            key.replacingOccurrences(of: "v1.", with: "v2.")
        }

        XCTAssertEqual(count, 2)
        XCTAssertEqual(try keychain.string(for: "v2.token-a"), "v1-a")
        XCTAssertEqual(try keychain.string(for: "v2.token-b"), "v1-b")
        XCTAssertEqual(try keychain.string(for: "unrelated"), "other")
    }

    func testRotateAllReturnsZeroForNoMatches() throws {
        try keychain.set("value", for: "key")
        let count = try KeyRotation.rotateAll(
            in: keychain,
            matchingPrefix: "nomatch."
        ) { $0 }
        XCTAssertEqual(count, 0)
    }
    #else
    func testSkippedOnLinux() {}
    #endif
}
