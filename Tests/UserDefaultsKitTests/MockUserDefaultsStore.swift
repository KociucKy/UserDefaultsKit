import Foundation
@testable import UserDefaultsKit

/// An in-memory ``UserDefaultsStorable`` for use in unit tests.
///
/// No data is written to disk. Each instance starts empty and can be
/// reset at any time via ``reset()``.
///
/// ```swift
/// let store = MockUserDefaultsStore()
/// store.set(true, for: .onboardingComplete)
/// XCTAssertTrue(store.get(.onboardingComplete))
/// ```
public final class MockUserDefaultsStore: UserDefaultsStorable, @unchecked Sendable {

    private let lock = NSLock()
    private var storage: [String: Any] = [:]

    public init() {}

    // MARK: UserDefaultsStorable

    public func get<Value>(_ key: UserDefaultsKey<Value>) -> Value {
        lock.lock()
        defer { lock.unlock() }

        if let codableType = Value.self as? any Codable.Type {
            guard
                let data = storage[key.key] as? Data,
                let decoded = try? JSONDecoder().decode(codableType, from: data)
            else {
                return key.defaultValue
            }
            return decoded as! Value  // swiftlint:disable:this force_cast
        }

        return (storage[key.key] as? Value) ?? key.defaultValue
    }

    public func set<Value>(_ value: Value?, for key: UserDefaultsKey<Value>) {
        lock.lock()
        defer { lock.unlock() }

        guard let value else {
            storage.removeValue(forKey: key.key)
            return
        }

        if let codable = value as? any Encodable,
           let data = try? JSONEncoder().encode(codable) {
            storage[key.key] = data
            return
        }

        storage[key.key] = value
    }

    // MARK: Test helpers

    /// Removes all stored values, returning the store to its initial empty state.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }
}
