/// A type-safe key used to read and write a value in a ``UserDefaultsStorable`` store.
///
/// Keys are parameterised by their `Value` type, so the compiler enforces
/// that the correct type is always used at every call site.
///
/// Every key requires a `defaultValue`, so reads are always non-optional.
///
/// ## Defining keys
///
/// Extend `UserDefaultsKey` with a constrained `where Value == …` clause
/// and declare your keys as static constants:
///
/// ```swift
/// extension UserDefaultsKey where Value == Bool {
///     static let onboardingComplete = UserDefaultsKey("onboardingComplete", defaultValue: false)
/// }
///
/// extension UserDefaultsKey where Value == String {
///     static let username = UserDefaultsKey("username", defaultValue: "")
/// }
/// ```
public struct UserDefaultsKey<Value: Sendable>: Sendable {
    /// The raw string used as the key in `UserDefaults`.
    public let key: String

    /// The value returned when no value has been stored for this key yet.
    public let defaultValue: Value

    /// Creates a new key.
    ///
    /// - Parameters:
    ///   - key: The raw string key stored in `UserDefaults`.
    ///   - defaultValue: The value returned when the key is absent from the store.
    public init(_ key: String, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }
}
