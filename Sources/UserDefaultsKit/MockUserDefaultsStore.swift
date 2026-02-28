import Combine
import Foundation

/// An in-memory ``UserDefaultsStorable`` for use in unit tests and SwiftUI Previews.
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

    /// Fires with the raw string key whenever any value is written or removed.
    private let changeSubject = PassthroughSubject<String, Never>()

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

        guard let value else {
            storage.removeValue(forKey: key.key)
            lock.unlock()
            changeSubject.send(key.key)
            return
        }

        if let codable = value as? any Encodable,
           let data = try? JSONEncoder().encode(codable) {
            storage[key.key] = data
            lock.unlock()
            changeSubject.send(key.key)
            return
        }

        storage[key.key] = value
        lock.unlock()
        changeSubject.send(key.key)
    }

    public func publisher<Value>(for key: UserDefaultsKey<Value>) -> AnyPublisher<Value, Never> {
        let changePublisher = changeSubject
            .filter { $0 == key.key }
            .map { [self] _ in self.get(key) }

        return Just(get(key))
            .merge(with: changePublisher)
            .eraseToAnyPublisher()
    }

    // MARK: Test helpers

    /// Removes all stored values, returning the store to its initial empty state.
    public func reset() {
        lock.lock()
        let keys = Array(storage.keys)
        storage.removeAll()
        lock.unlock()
        keys.forEach { changeSubject.send($0) }
    }
}
