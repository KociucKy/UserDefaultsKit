import Foundation

// MARK: - Protocol

/// An abstraction over a UserDefaults-backed store.
///
/// Conforming to this protocol allows both the live ``UserDefaultsStore``
/// and test doubles such as ``MockUserDefaultsStore`` to be used
/// interchangeably at any call site.
public protocol UserDefaultsStorable: Sendable {
    /// Returns the stored value for `key`, or the key's `defaultValue` if absent.
    func get<Value>(_ key: UserDefaultsKey<Value>) -> Value

    /// Writes `value` to the store for `key`.
    ///
    /// Pass `nil` to remove the value, causing subsequent reads to return
    /// the key's `defaultValue`.
    func set<Value>(_ value: Value?, for key: UserDefaultsKey<Value>)
}

// MARK: - Live implementation

/// A ``UserDefaultsStorable`` backed by a `UserDefaults` instance.
///
/// Use ``standard`` for the shared `UserDefaults.standard` store, or
/// initialise with a custom suite for App Group sharing:
///
/// ```swift
/// let store = UserDefaultsStore(UserDefaults(suiteName: "group.com.example")!)
/// ```
///
/// `UserDefaults` is documented as thread-safe, so this class is marked
/// `@unchecked Sendable` — no additional synchronisation is required.
public final class UserDefaultsStore: UserDefaultsStorable, @unchecked Sendable {

    // MARK: Shared instance

    /// A store backed by `UserDefaults.standard`.
    public static let standard = UserDefaultsStore(.standard)

    // MARK: Storage

    let _defaults: UserDefaults

    // MARK: Init

    /// Creates a store backed by the given `UserDefaults` instance.
    public init(_ defaults: UserDefaults) {
        self._defaults = defaults
    }

    // MARK: UserDefaultsStorable

    public func get<Value>(_ key: UserDefaultsKey<Value>) -> Value {
        if let codableType = Value.self as? any Codable.Type {
            // Route Codable types through JSON decoding.
            guard
                let data = _defaults.data(forKey: key.key),
                let decoded = try? JSONDecoder().decode(codableType, from: data)
            else {
                return key.defaultValue
            }
            // Safe: decoded is the same type as Value.
            return decoded as! Value  // swiftlint:disable:this force_cast
        }

        // Primitive types stored natively by UserDefaults.
        return (_defaults.object(forKey: key.key) as? Value) ?? key.defaultValue
    }

    public func set<Value>(_ value: Value?, for key: UserDefaultsKey<Value>) {
        guard let value else {
            _defaults.removeObject(forKey: key.key)
            return
        }

        if let codable = value as? any Encodable {
            if let data = try? JSONEncoder().encode(codable) {
                _defaults.set(data, forKey: key.key)
            }
            return
        }

        // Primitive types stored natively.
        _defaults.set(value, forKey: key.key)
    }
}
