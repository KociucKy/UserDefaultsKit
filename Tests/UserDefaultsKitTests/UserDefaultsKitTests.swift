import Combine
import Foundation
import Testing
@testable import UserDefaultsKit

// MARK: - Keys used across tests

extension UserDefaultsKey where Value == Bool {
    static let flag = UserDefaultsKey("flag", defaultValue: false)
}

extension UserDefaultsKey where Value == Int {
    static let count = UserDefaultsKey("count", defaultValue: 0)
}

extension UserDefaultsKey where Value == String {
    static let username = UserDefaultsKey("username", defaultValue: "")
}

extension UserDefaultsKey where Value == Double {
    static let score = UserDefaultsKey("score", defaultValue: 0.0)
}

struct Color: Codable, Equatable, Sendable {
    var red: Double
    var green: Double
    var blue: Double
}

extension UserDefaultsKey where Value == Color {
    static let accentColor = UserDefaultsKey("accentColor", defaultValue: Color(red: 0, green: 0, blue: 0))
}

extension UserDefaultsKey where Value == [String] {
    static let tags = UserDefaultsKey("tags", defaultValue: [])
}

// MARK: - UserDefaultsKey

@Suite("UserDefaultsKey")
struct UserDefaultsKeyTests {
    @Test("stores key string and default value")
    func keyProperties() {
        let key = UserDefaultsKey("myKey", defaultValue: 42)
        #expect(key.key == "myKey")
        #expect(key.defaultValue == 42)
    }
}

// MARK: - MockUserDefaultsStore

@Suite("MockUserDefaultsStore")
struct MockUserDefaultsStoreTests {
    let store = MockUserDefaultsStore()

    @Test("returns default when key is absent")
    func defaultValue() {
        #expect(store.get(.flag) == false)
        #expect(store.get(.count) == 0)
        #expect(store.get(.username) == "")
    }

    @Test("stores and retrieves a Bool")
    func storeBool() {
        store.set(true, for: .flag)
        #expect(store.get(.flag) == true)
    }

    @Test("stores and retrieves an Int")
    func storeInt() {
        store.set(7, for: .count)
        #expect(store.get(.count) == 7)
    }

    @Test("stores and retrieves a String")
    func storeString() {
        store.set("alice", for: .username)
        #expect(store.get(.username) == "alice")
    }

    @Test("stores and retrieves a Double")
    func storeDouble() {
        store.set(3.14, for: .score)
        #expect(store.get(.score) == 3.14)
    }

    @Test("stores and retrieves a Codable struct")
    func storeCodable() {
        let color = Color(red: 1.0, green: 0.5, blue: 0.0)
        store.set(color, for: .accentColor)
        #expect(store.get(.accentColor) == color)
    }

    @Test("stores and retrieves a Codable array")
    func storeCodableArray() {
        store.set(["swift", "ios"], for: .tags)
        #expect(store.get(.tags) == ["swift", "ios"])
    }

    @Test("removing a value returns the default")
    func removeValue() {
        store.set(true, for: .flag)
        store.set(nil, for: .flag)
        #expect(store.get(.flag) == false)
    }

    @Test("reset clears all stored values")
    func reset() {
        store.set(true, for: .flag)
        store.set(99, for: .count)
        store.reset()
        #expect(store.get(.flag) == false)
        #expect(store.get(.count) == 0)
    }
}

// MARK: - @UserDefault property wrapper

@Suite("@UserDefault property wrapper")
struct UserDefaultPropertyWrapperTests {
    @Test("reads default when nothing stored")
    func readDefault() {
        let store = MockUserDefaultsStore()
        @UserDefault(.flag, store: store) var flag: Bool
        #expect(flag == false)
    }

    @Test("write then read round-trips correctly")
    func writeAndRead() {
        let store = MockUserDefaultsStore()
        @UserDefault(.count, store: store) var count: Int
        count = 42
        #expect(count == 42)
    }

    @Test("setting nil restores default")
    func setNilRestoresDefault() {
        let store = MockUserDefaultsStore()
        @UserDefault(.username, store: store) var name: String
        name = "bob"
        store.set(nil as String?, for: .username)
        #expect(name == "")
    }

    @Test("Codable value round-trips correctly")
    func codableRoundTrip() {
        let store = MockUserDefaultsStore()
        @UserDefault(.accentColor, store: store) var color: Color
        let expected = Color(red: 0.2, green: 0.4, blue: 0.6)
        color = expected
        #expect(color == expected)
    }
}

// MARK: - Combine publisher

@Suite("UserDefaultsStore publisher")
struct UserDefaultsPublisherTests {
    @Test("publisher emits initial value immediately")
    func emitsInitialValue() async {
        let defaults = UserDefaults(suiteName: #function)!
        defer { defaults.removePersistentDomain(forName: #function) }

        let store = UserDefaultsStore(defaults)
        var received: [Bool] = []
        var cancellables = Set<AnyCancellable>()

        store.publisher(for: .flag)
            .sink { received.append($0) }
            .store(in: &cancellables)

        #expect(received == [false])
    }

    @Test("publisher emits updated value after write")
    func emitsOnChange() async throws {
        let defaults = UserDefaults(suiteName: #function)!
        defer { defaults.removePersistentDomain(forName: #function) }

        let store = UserDefaultsStore(defaults)
        var received: [Bool] = []
        var cancellables = Set<AnyCancellable>()

        store.publisher(for: .flag)
            .sink { received.append($0) }
            .store(in: &cancellables)

        store.set(true, for: .flag)

        // Allow the notification to propagate on the run loop.
        try await Task.sleep(for: .milliseconds(50))

        #expect(received.last == true)
    }
}
