import XCTest
@testable import KeychainKit

final class CodableTests: XCTestCase {
    private var keychain: Keychain!

    override func setUp() {
        super.setUp()
        keychain = Keychain(service: "com.test.codable.\(UUID().uuidString)")
    }

    override func tearDown() {
        try? keychain.deleteAll()
        super.tearDown()
    }

    #if canImport(Security)
    struct UserProfile: Codable, Sendable, Equatable {
        let name: String
        let age: Int
        let email: String?
    }

    struct Nested: Codable, Sendable, Equatable {
        let label: String
        let profile: UserProfile
    }

    func testSetAndGetCodable() throws {
        let profile = UserProfile(name: "Alice", age: 30, email: "alice@example.com")
        try keychain.set(profile, for: "user")
        let result = try keychain.object(for: "user", as: UserProfile.self)
        XCTAssertEqual(result, profile)
    }

    func testSetAndGetArray() throws {
        let tags = ["swift", "keychain", "security"]
        try keychain.set(tags, for: "tags")
        let result = try keychain.object(for: "tags", as: [String].self)
        XCTAssertEqual(result, tags)
    }

    func testSetAndGetNestedStruct() throws {
        let nested = Nested(
            label: "primary",
            profile: UserProfile(name: "Bob", age: 25, email: nil)
        )
        try keychain.set(nested, for: "nested")
        let result = try keychain.object(for: "nested", as: Nested.self)
        XCTAssertEqual(result, nested)
    }

    func testDecodingWrongType() throws {
        try keychain.set("plain string", for: "str")
        XCTAssertThrowsError(try keychain.object(for: "str", as: UserProfile.self)) { error in
            guard case KeychainError.decodingFailed = error else {
                XCTFail("Expected decodingFailed, got \(error)")
                return
            }
        }
    }

    func testCodableWithOptionals() throws {
        let profile = UserProfile(name: "Charlie", age: 40, email: nil)
        try keychain.set(profile, for: "optional")
        let result = try keychain.object(for: "optional", as: UserProfile.self)
        XCTAssertEqual(result, profile)
        XCTAssertNil(result?.email)
    }

    func testGetNonexistentCodableReturnsNil() throws {
        let result = try keychain.object(for: "missing", as: UserProfile.self)
        XCTAssertNil(result)
    }
    #else
    func testSkippedOnLinux() {}
    #endif
}
