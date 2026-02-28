import Foundation

/// A property wrapper that reads and writes a value in a ``UserDefaultsStorable`` store.
///
/// Declare it on any class (manager, view model, etc.) by providing a typed
/// ``UserDefaultsKey``. The store defaults to ``UserDefaultsStore/standard``
/// but can be injected for custom suites or testing.
///
/// ## Usage
///
/// ```swift
/// extension UserDefaultsKey where Value == Bool {
///     static let onboardingComplete = UserDefaultsKey("onboardingComplete", defaultValue: false)
/// }
///
/// final class OnboardingManager {
///     @UserDefault(.onboardingComplete)
///     var onboardingComplete: Bool
///
///     // With a custom store (e.g. App Group):
///     @UserDefault(.onboardingComplete, store: UserDefaultsStore(UserDefaults(suiteName: "group.com.example")!))
///     var onboardingCompleteShared: Bool
/// }
/// ```
///
/// Setting `wrappedValue` to `nil` removes the value from the store,
/// causing subsequent reads to return the key's `defaultValue`.
@propertyWrapper
public struct UserDefault<Value: Sendable>: Sendable {

    private let key: UserDefaultsKey<Value>
    private let store: any UserDefaultsStorable

    /// Creates the property wrapper.
    ///
    /// - Parameters:
    ///   - key: The typed key identifying the stored value.
    ///   - store: The backing store. Defaults to ``UserDefaultsStore/standard``.
    public init(_ key: UserDefaultsKey<Value>, store: any UserDefaultsStorable = UserDefaultsStore.standard) {
        self.key = key
        self.store = store
    }

    /// The stored value, or the key's `defaultValue` when absent.
    ///
    /// Assigning `nil` removes the entry from the store.
    public var wrappedValue: Value {
        get { store.get(key) }
        set { store.set(newValue, for: key) }
    }
}
