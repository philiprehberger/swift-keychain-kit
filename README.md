# KeychainKit

[![Tests](https://github.com/philiprehberger/swift-keychain-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/swift-keychain-kit/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fphiliprehberger%2Fswift-keychain-kit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/philiprehberger/swift-keychain-kit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fphiliprehberger%2Fswift-keychain-kit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/philiprehberger/swift-keychain-kit)

Modern, type-safe Keychain wrapper with Codable, biometric auth, and async/await

## Requirements

- Swift >= 6.0
- macOS 13+ / iOS 16+ / tvOS 16+ / watchOS 9+

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/philiprehberger/swift-keychain-kit.git", from: "0.1.0")
]
```

Then add `"KeychainKit"` to your target dependencies:

```swift
.target(name: "YourTarget", dependencies: [
    .product(name: "KeychainKit", package: "swift-keychain-kit")
])
```

## Usage

```swift
import KeychainKit

let keychain = Keychain(service: "com.myapp")
try keychain.set("secret-token", for: "api-key")
let token = try keychain.string(for: "api-key")  // => "secret-token"
```

### Codable Storage

Store any `Codable` type as JSON in the Keychain:

```swift
struct Credentials: Codable, Sendable {
    let username: String
    let token: String
}

let creds = Credentials(username: "alice", token: "abc123")
try keychain.set(creds, for: "credentials")

let restored = try keychain.object(for: "credentials", as: Credentials.self)
// => Credentials(username: "alice", token: "abc123")
```

### Biometric Authentication

Protect items with Face ID or Touch ID:

```swift
try keychain.setWithBiometric(
    creds,
    for: "secure-creds",
    policy: .biometricAny,
    prompt: "Authenticate to access credentials"
)

let secured = try await keychain.objectWithBiometric(
    for: "secure-creds",
    as: Credentials.self
)
```

### Access Control

Control when items are accessible:

```swift
try keychain.set("value", for: "key", access: .afterFirstUnlock)
try keychain.set("value", for: "key", access: .whenPasscodeSet)
```

### Key Rotation

Rotate keys atomically:

```swift
try KeyRotation.rotate(in: keychain, from: "v1.token", to: "v2.token")

// Batch rotation with prefix
let count = try KeyRotation.rotateAll(
    in: keychain,
    matchingPrefix: "v1."
) { $0.replacingOccurrences(of: "v1.", with: "v2.") }
```

### Key Management

```swift
try keychain.contains("api-key")   // => true
try keychain.delete("api-key")
try keychain.deleteAll()
let keys = try keychain.allKeys()  // => ["credentials", "secure-creds"]
```

## API

### `Keychain`

| Method | Description |
|--------|-------------|
| `Keychain(service:)` | Create a Keychain scoped to a service identifier |
| `.set(_:for:access:)` | Store a String, Data, Bool, or Codable value |
| `.string(for:)` | Retrieve a string |
| `.data(for:)` | Retrieve raw data |
| `.object(for:as:)` | Retrieve a Codable value |
| `.bool(for:)` | Retrieve a boolean |
| `.contains(_:)` | Check if a key exists |
| `.delete(_:)` | Delete a single key |
| `.deleteAll()` | Delete all items for this service |
| `.allKeys()` | List all stored keys |
| `.setWithBiometric(_:for:policy:prompt:)` | Store with biometric protection |
| `.objectWithBiometric(for:as:prompt:)` | Retrieve with biometric auth (async) |

### `KeyRotation`

| Method | Description |
|--------|-------------|
| `.rotate(in:from:to:)` | Move a value from one key to another |
| `.rotateAll(in:matchingPrefix:transform:)` | Rotate all keys matching a prefix |

### `AccessLevel`

| Value | Description |
|-------|-------------|
| `.whenUnlocked` | Accessible when device is unlocked (default) |
| `.afterFirstUnlock` | Accessible after first unlock since boot |
| `.whenPasscodeSet` | Only when device has a passcode |

### `BiometricPolicy`

| Value | Description |
|-------|-------------|
| `.devicePasscode` | Require device passcode |
| `.biometricAny` | Require Face ID or Touch ID |
| `.biometricCurrentSet` | Require currently enrolled biometric |

### `KeychainError`

| Case | Description |
|------|-------------|
| `.itemNotFound` | Requested item not found |
| `.duplicateItem` | Item already exists |
| `.authenticationFailed` | Biometric or passcode auth failed |
| `.encodingFailed(String)` | Failed to encode value |
| `.decodingFailed(String)` | Failed to decode value |
| `.accessDenied` | Access denied |
| `.unexpectedStatus(Int32)` | Unexpected Security framework status |

## Development

```bash
swift build
swift test
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/swift-keychain-kit)

🐛 [Report issues](https://github.com/philiprehberger/swift-keychain-kit/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/swift-keychain-kit/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
