# UserDefaultsKit

A Swift 6 package for type-safe, reactive `UserDefaults` management — designed for use in managers, view models, and anywhere outside of SwiftUI views.

## Features

- **Type-safe keys** — `UserDefaultsKey<Value>` enforces the correct type at every call site
- **Non-optional reads** — every key carries a required default value, so reads never return `nil`
- **`@UserDefault` property wrapper** — simple, declarative read/write on any class or struct
- **Codable support** — any `Codable` type is transparently JSON-encoded and decoded
- **Custom suites** — inject any `UserDefaults` instance for App Group sharing
- **Combine publisher** — observe changes to any key with `publisher(for:)`
- **Testable by design** — `MockUserDefaultsStore` provides an in-memory store with full publisher support
- **Optional SwiftUI target** — `UserDefaultsKitUI` ships a ready-made dev settings view

## Requirements

- Swift 6
- iOS 16+ / macOS 13+ / watchOS 9+ / tvOS 16+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/your-org/UserDefaultsKit.git", from: "1.0.0")
]
```

Add `UserDefaultsKit` to your target dependencies. If you need the SwiftUI dev settings view, also add `UserDefaultsKitUI`.

```swift
.target(
    name: "MyApp",
    dependencies: [
        "UserDefaultsKit",
        "UserDefaultsKitUI", // optional
    ]
)
```

---

## Usage

### 1. Define keys

Extend `UserDefaultsKey` with a constrained `where Value ==` clause and declare your keys as `static` constants:

```swift
extension UserDefaultsKey where Value == Bool {
    static let onboardingComplete = UserDefaultsKey("onboardingComplete", defaultValue: false)
}

extension UserDefaultsKey where Value == String {
    static let username = UserDefaultsKey("username", defaultValue: "")
}

extension UserDefaultsKey where Value == Int {
    static let launchCount = UserDefaultsKey("launchCount", defaultValue: 0)
}
```

Any `Codable` type works too:

```swift
struct AppTheme: Codable {
    var accentColor: String
    var useDarkMode: Bool
}

extension UserDefaultsKey where Value == AppTheme {
    static let theme = UserDefaultsKey("theme", defaultValue: AppTheme(accentColor: "blue", useDarkMode: false))
}
```

---

### 2. Use the `@UserDefault` property wrapper

Declare stored properties on a manager or view model. The store defaults to `UserDefaultsStore.standard`:

```swift
final class SettingsManager {
    @UserDefault(.onboardingComplete)
    var onboardingComplete: Bool

    @UserDefault(.username)
    var username: String

    @UserDefault(.theme)
    var theme: AppTheme
}
```

Set a value to `nil` via the store to remove it and fall back to the key's `defaultValue`:

```swift
store.set(nil, for: .username)
```

#### Custom suite (App Groups)

```swift
final class SharedSettingsManager {
    private let store = UserDefaultsStore(UserDefaults(suiteName: "group.com.example")!)

    @UserDefault(.onboardingComplete, store: store)
    var onboardingComplete: Bool
}
```

---

### 3. Observe changes with Combine

`UserDefaultsStore` exposes a publisher for any key. It emits the current value immediately, then again on every change:

```swift
let store = UserDefaultsStore.standard

store.publisher(for: .onboardingComplete)
    .sink { isComplete in
        print("Onboarding complete:", isComplete)
    }
    .store(in: &cancellables)
```

---

## Testing

Use `MockUserDefaultsStore` in unit tests and SwiftUI Previews. It is backed by an in-memory dictionary — no disk I/O — and supports the full `publisher(for:)` API.

```swift
final class SettingsManagerTests: XCTestCase {
    func testOnboardingDefault() {
        let store = MockUserDefaultsStore()
        let manager = SettingsManager(store: store)
        XCTAssertFalse(manager.onboardingComplete)
    }

    func testOnboardingCompleted() {
        let store = MockUserDefaultsStore()
        let manager = SettingsManager(store: store)
        manager.onboardingComplete = true
        XCTAssertTrue(store.get(.onboardingComplete))
    }
}
```

Call `store.reset()` between tests to clear all stored values.

---

## UserDefaultsKitUI

Import `UserDefaultsKitUI` to get a ready-made developer settings view for inspecting and modifying `UserDefaults` values at runtime.

### Supported controls

| Type     | Control                   |
|----------|---------------------------|
| `Bool`   | `Toggle`                  |
| `Int`    | `Stepper`                 |
| `String` | `TextField`               |
| `Double` | `TextField` (decimal pad) |

Swipe left on any row to reset it to its `defaultValue`.

### Example

```swift
import UserDefaultsKit
import UserDefaultsKitUI

struct DevSettingsView: View {
    var body: some View {
        UserDefaultsDevSettingsView(store: .standard, entries: [
            .bool(.onboardingComplete, label: "Onboarding Complete"),
            .int(.launchCount,         label: "Launch Count"),
            .string(.username,         label: "Username"),
        ])
    }
}
```

### SwiftUI Preview with a mock store

```swift
#Preview {
    NavigationStack {
        UserDefaultsDevSettingsView(store: MockUserDefaultsStore(), entries: [
            .bool(.onboardingComplete, label: "Onboarding Complete"),
            .int(.launchCount,         label: "Launch Count"),
        ])
    }
}
```

---

## Architecture

```
UserDefaultsKit
├── UserDefaultsKey<Value>          # Typed key with a required default value
├── UserDefaultsStorable            # Protocol: get / set / publisher(for:)
├── UserDefaultsStore               # Live implementation backed by UserDefaults
├── MockUserDefaultsStore           # In-memory implementation for tests & previews
└── @UserDefault                    # Property wrapper

UserDefaultsKitUI
├── UserDefaultsDevEntry            # Type-erased entry description (Bool/Int/String/Double)
├── UserDefaultsDevSettingsView     # List view for dev settings
└── UserDefaultsRowView             # Per-key row with appropriate SwiftUI control
```

## License

MIT
