import SwiftUI
import UserDefaultsKit

// MARK: - Entry

/// A type-erased description of a single UserDefaults value to display
/// in ``UserDefaultsDevSettingsView``.
///
/// Create entries using the static factory methods and pass them to the view:
///
/// ```swift
/// UserDefaultsDevSettingsView(store: store, entries: [
///     .bool(.featureEnabled,  label: "Feature Enabled"),
///     .int(.launchCount,      label: "Launch Count"),
///     .string(.username,      label: "Username"),
///     .double(.score,         label: "Score"),
/// ])
/// ```
public enum UserDefaultsDevEntry: Sendable {
    case bool(_ key: UserDefaultsKey<Bool>,   label: String)
    case int(_ key: UserDefaultsKey<Int>,     label: String)
    case string(_ key: UserDefaultsKey<String>, label: String)
    case double(_ key: UserDefaultsKey<Double>, label: String)

    var label: String {
        switch self {
        case .bool(_, let label),
             .int(_, let label),
             .string(_, let label),
             .double(_, let label):
            return label
        }
    }
}

// MARK: - View

/// A SwiftUI `List` view for inspecting and modifying UserDefaults values at runtime.
///
/// Intended for use inside a developer settings screen. Each entry renders
/// an appropriate control:
///
/// | Type     | Control                          |
/// |----------|----------------------------------|
/// | `Bool`   | `Toggle`                         |
/// | `Int`    | `Stepper`                        |
/// | `String` | `TextField`                      |
/// | `Double` | `TextField` (decimal pad)        |
///
/// Swipe left on any row to reset it to its `defaultValue`.
///
/// Works with any ``UserDefaultsStorable``, including ``MockUserDefaultsStore``
/// for SwiftUI Previews.
///
/// ```swift
/// UserDefaultsDevSettingsView(store: .standard, entries: [
///     .bool(.featureEnabled, label: "Feature Enabled"),
///     .int(.launchCount,     label: "Launch Count"),
/// ])
/// ```
public struct UserDefaultsDevSettingsView: View {
    private let store: any UserDefaultsStorable
    private let entries: [UserDefaultsDevEntry]

    public init(store: any UserDefaultsStorable = UserDefaultsStore.standard, entries: [UserDefaultsDevEntry]) {
        self.store = store
        self.entries = entries
    }

    public var body: some View {
        List {
            ForEach(entries.indices, id: \.self) { index in
                UserDefaultsRowView(store: store, entry: entries[index])
                    .swipeActions(edge: .trailing) {
                        Button("Reset", role: .destructive) {
                            reset(entries[index])
                        }
                    }
            }
        }
        .navigationTitle("UserDefaults")
    }

    private func reset(_ entry: UserDefaultsDevEntry) {
        switch entry {
        case .bool(let key, _):   store.set(nil, for: key)
        case .int(let key, _):    store.set(nil, for: key)
        case .string(let key, _): store.set(nil, for: key)
        case .double(let key, _): store.set(nil, for: key)
        }
    }
}

// MARK: - Preview

#Preview {
    let store = MockUserDefaultsStore()
    return NavigationStack {
        UserDefaultsDevSettingsView(store: store, entries: [
            .bool(.previewFlag,    label: "Feature Enabled"),
            .int(.previewCount,    label: "Launch Count"),
            .string(.previewName,  label: "Username"),
            .double(.previewScore, label: "Score"),
        ])
    }
}

// MARK: - Preview keys (file-private)

private extension UserDefaultsKey where Value == Bool {
    static let previewFlag = UserDefaultsKey("previewFlag", defaultValue: false)
}
private extension UserDefaultsKey where Value == Int {
    static let previewCount = UserDefaultsKey("previewCount", defaultValue: 0)
}
private extension UserDefaultsKey where Value == String {
    static let previewName = UserDefaultsKey("previewName", defaultValue: "")
}
private extension UserDefaultsKey where Value == Double {
    static let previewScore = UserDefaultsKey("previewScore", defaultValue: 0.0)
}
