# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-04-02

### Added
- `set(_:for:expiresIn:)` for storing values with time-to-live
- `isExpired(_:)` for checking if a stored item has passed its TTL
- `cleanExpired()` for removing all expired items
- `stringWithBiometric(for:prompt:)` for biometric-protected string retrieval
- `dataWithBiometric(for:prompt:)` for biometric-protected data retrieval

## [0.1.0] - 2026-04-02

### Added
- Type-safe Keychain wrapper with `Keychain` struct
- String, Data, Bool, and Codable storage with `set`/`get` methods
- `contains`, `delete`, `deleteAll`, and `allKeys` operations
- Configurable access levels (`whenUnlocked`, `afterFirstUnlock`, `whenPasscodeSet`)
- Biometric authentication support with `setWithBiometric` and `objectWithBiometric`
- Async/await API for biometric-protected operations
- Key rotation with `KeyRotation.rotate` and `KeyRotation.rotateAll`
- Service-scoped isolation for multi-module apps
- `Sendable` conformance on all public types
- Zero external dependencies
