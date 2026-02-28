import Combine
import SwiftUI
import UserDefaultsKit

/// A single row in ``UserDefaultsDevSettingsView``.
///
/// Renders the appropriate SwiftUI control for the entry's value type and
/// stays in sync with the store via the Combine publisher.
struct UserDefaultsRowView: View {
    private let store: any UserDefaultsStorable
    private let entry: UserDefaultsDevEntry

    init(store: any UserDefaultsStorable, entry: UserDefaultsDevEntry) {
        self.store = store
        self.entry = entry
    }

    var body: some View {
        switch entry {
        case .bool(let key, let label):
            BoolRow(label: label, key: key, store: store)
        case .int(let key, let label):
            IntRow(label: label, key: key, store: store)
        case .string(let key, let label):
            StringRow(label: label, key: key, store: store)
        case .double(let key, let label):
            DoubleRow(label: label, key: key, store: store)
        }
    }
}

// MARK: - Bool row

@MainActor
private final class BoolRowModel: ObservableObject {
    @Published var value: Bool
    private let key: UserDefaultsKey<Bool>
    private let store: any UserDefaultsStorable
    private var cancellable: AnyCancellable?

    init(key: UserDefaultsKey<Bool>, store: any UserDefaultsStorable) {
        self.key = key
        self.store = store
        self.value = store.get(key)
        cancellable = store.publisher(for: key)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self, self.value != newValue else { return }
                self.value = newValue
            }
    }

    func commit(_ newValue: Bool) {
        guard newValue != store.get(key) else { return }
        store.set(newValue, for: key)
    }
}

private struct BoolRow: View {
    let label: String
    let key: UserDefaultsKey<Bool>
    let store: any UserDefaultsStorable
    @StateObject private var model: BoolRowModel

    init(label: String, key: UserDefaultsKey<Bool>, store: any UserDefaultsStorable) {
        self.label = label
        self.key = key
        self.store = store
        _model = StateObject(wrappedValue: BoolRowModel(key: key, store: store))
    }

    var body: some View {
        Toggle(label, isOn: Binding(
            get: { model.value },
            set: { model.commit($0) }
        ))
    }
}

// MARK: - Int row

@MainActor
private final class IntRowModel: ObservableObject {
    @Published var value: Int
    private let key: UserDefaultsKey<Int>
    private let store: any UserDefaultsStorable
    private var cancellable: AnyCancellable?

    init(key: UserDefaultsKey<Int>, store: any UserDefaultsStorable) {
        self.key = key
        self.store = store
        self.value = store.get(key)
        cancellable = store.publisher(for: key)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self, self.value != newValue else { return }
                self.value = newValue
            }
    }

    func commit(_ newValue: Int) {
        guard newValue != store.get(key) else { return }
        store.set(newValue, for: key)
    }
}

private struct IntRow: View {
    let label: String
    let key: UserDefaultsKey<Int>
    let store: any UserDefaultsStorable
    @StateObject private var model: IntRowModel

    init(label: String, key: UserDefaultsKey<Int>, store: any UserDefaultsStorable) {
        self.label = label
        self.key = key
        self.store = store
        _model = StateObject(wrappedValue: IntRowModel(key: key, store: store))
    }

    var body: some View {
        Stepper("\(label): \(model.value)", value: Binding(
            get: { model.value },
            set: { model.commit($0) }
        ))
    }
}

// MARK: - String row

@MainActor
private final class StringRowModel: ObservableObject {
    @Published var value: String
    private let key: UserDefaultsKey<String>
    private let store: any UserDefaultsStorable
    private var cancellable: AnyCancellable?

    init(key: UserDefaultsKey<String>, store: any UserDefaultsStorable) {
        self.key = key
        self.store = store
        self.value = store.get(key)
        cancellable = store.publisher(for: key)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self, self.value != newValue else { return }
                self.value = newValue
            }
    }

    func commit(_ newValue: String) {
        guard newValue != store.get(key) else { return }
        store.set(newValue, for: key)
    }
}

private struct StringRow: View {
    let label: String
    let key: UserDefaultsKey<String>
    let store: any UserDefaultsStorable
    @StateObject private var model: StringRowModel

    init(label: String, key: UserDefaultsKey<String>, store: any UserDefaultsStorable) {
        self.label = label
        self.key = key
        self.store = store
        _model = StateObject(wrappedValue: StringRowModel(key: key, store: store))
    }

    var body: some View {
        LabeledContent(label) {
            TextField("", text: Binding(
                get: { model.value },
                set: { model.commit($0) }
            ))
            .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Double row

@MainActor
private final class DoubleRowModel: ObservableObject {
    @Published var text: String
    private let key: UserDefaultsKey<Double>
    private let store: any UserDefaultsStorable
    private var cancellable: AnyCancellable?

    init(key: UserDefaultsKey<Double>, store: any UserDefaultsStorable) {
        self.key = key
        self.store = store
        let initial = store.get(key)
        self.text = initial == 0 ? "" : String(initial)
        cancellable = store.publisher(for: key)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                // Don't clobber in-progress input (e.g. "3." while typing "3.14").
                guard Double(self.text) != newValue else { return }
                self.text = newValue == 0 ? "" : String(newValue)
            }
    }

    func commit(_ newText: String) {
        guard let parsed = Double(newText) else { return }
        guard parsed != store.get(key) else { return }
        store.set(parsed, for: key)
    }
}

private struct DoubleRow: View {
    let label: String
    let key: UserDefaultsKey<Double>
    let store: any UserDefaultsStorable
    @StateObject private var model: DoubleRowModel

    init(label: String, key: UserDefaultsKey<Double>, store: any UserDefaultsStorable) {
        self.label = label
        self.key = key
        self.store = store
        _model = StateObject(wrappedValue: DoubleRowModel(key: key, store: store))
    }

    var body: some View {
        LabeledContent(label) {
            TextField("", text: Binding(
                get: { model.text },
                set: { model.commit($0) }
            ))
            .multilineTextAlignment(.trailing)
#if os(iOS) || os(tvOS)
            .keyboardType(.decimalPad)
#endif
        }
    }
}
