import Combine
import Foundation

// MARK: - Publisher on UserDefaultsStore

extension UserDefaultsStore {
    /// Returns a publisher that emits the current value immediately, then emits
    /// again whenever the value for `key` changes in the store.
    ///
    /// The publisher never fails. Removing a value from the store causes it to
    /// emit the key's `defaultValue`.
    ///
    /// ```swift
    /// let store = UserDefaultsStore.standard
    ///
    /// store.publisher(for: .onboardingComplete)
    ///     .sink { isComplete in
    ///         print("Onboarding complete:", isComplete)
    ///     }
    ///     .store(in: &cancellables)
    /// ```
    public func publisher<Value>(for key: UserDefaultsKey<Value>) -> AnyPublisher<Value, Never> {
        // Emit on every UserDefaults change notification for this suite,
        // then map to the current value for the specific key.
        let changePublisher = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification, object: _defaults)
            .map { [self] _ in self.get(key) }

        // Prepend the current value so subscribers always get an initial emission.
        return Just(get(key))
            .merge(with: changePublisher)
            .eraseToAnyPublisher()
    }
}
