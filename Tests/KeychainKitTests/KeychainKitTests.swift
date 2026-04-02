import XCTest
@testable import KeychainKit

final class KeychainKitTests: XCTestCase {
    private var keychain: Keychain!

    override func setUp() {
        super.setUp()
        keychain = Keychain(service: "com.test.keychain-kit.\(UUID().uuidString)")
    }

    override func tearDown() {
        try? keychain.deleteAll()
        super.tearDown()
    }

    #if canImport(Security)
    // MARK: - String Storage

    func testSetAndGetString() throws {
        try keychain.set("hello", for: "greeting")
        let result = try keychain.string(for: "greeting")
        XCTAssertEqual(result, "hello")
    }

    func testGetNonexistentStringReturnsNil() throws {
        let result = try keychain.string(for: "missing")
        XCTAssertNil(result)
    }

    func testOverwriteString() throws {
        try keychain.set("first", for: "key")
        try keychain.set("second", for: "key")
        XCTAssertEqual(try keychain.string(for: "key"), "second")
    }

    // MARK: - Data Storage

    func testSetAndGetData() throws {
        let data = Data([0x01, 0x02, 0x03])
        try keychain.set(data, for: "raw")
        let result = try keychain.data(for: "raw")
        XCTAssertEqual(result, data)
    }

    // MARK: - Bool Storage

    func testSetAndGetBoolTrue() throws {
        try keychain.set(true, for: "flag")
        XCTAssertEqual(try keychain.bool(for: "flag"), true)
    }

    func testSetAndGetBoolFalse() throws {
        try keychain.set(false, for: "flag")
        XCTAssertEqual(try keychain.bool(for: "flag"), false)
    }

    func testGetNonexistentBoolReturnsNil() throws {
        XCTAssertNil(try keychain.bool(for: "missing"))
    }

    // MARK: - Contains

    func testContainsExistingKey() throws {
        try keychain.set("value", for: "exists")
        XCTAssertTrue(try keychain.contains("exists"))
    }

    func testContainsMissingKey() throws {
        XCTAssertFalse(try keychain.contains("missing"))
    }

    // MARK: - Delete

    func testDeleteKey() throws {
        try keychain.set("value", for: "deleteme")
        try keychain.delete("deleteme")
        XCTAssertNil(try keychain.string(for: "deleteme"))
    }

    func testDeleteNonexistentKeyDoesNotThrow() throws {
        XCTAssertNoThrow(try keychain.delete("nonexistent"))
    }

    // MARK: - Delete All

    func testDeleteAll() throws {
        try keychain.set("a", for: "key1")
        try keychain.set("b", for: "key2")
        try keychain.deleteAll()
        XCTAssertNil(try keychain.string(for: "key1"))
        XCTAssertNil(try keychain.string(for: "key2"))
    }

    // MARK: - All Keys

    func testAllKeys() throws {
        try keychain.set("a", for: "alpha")
        try keychain.set("b", for: "beta")
        let keys = try keychain.allKeys()
        XCTAssertTrue(keys.contains("alpha"))
        XCTAssertTrue(keys.contains("beta"))
    }

    func testAllKeysEmptyKeychain() throws {
        let keys = try keychain.allKeys()
        XCTAssertTrue(keys.isEmpty)
    }

    // MARK: - Service Isolation

    func testSeparateServicesAreIsolated() throws {
        let other = Keychain(service: "com.test.other.\(UUID().uuidString)")
        try keychain.set("value", for: "shared-key")
        XCTAssertNil(try other.string(for: "shared-key"))
        try? other.deleteAll()
    }
    #else
    func testSkippedOnLinux() {
        // Keychain APIs require the Security framework (Apple platforms only)
    }
    #endif
}
