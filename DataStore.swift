import Foundation
import Combine

class DataStore: ObservableObject {
    @Published private(set) var entries: [EyeDropEntry] = [] {
        didSet { save() }
    }
    
    private let key = "EyeDropEntries"
    private let maxDays: Int = 180
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        load()
        prune()
    }
    
    // MARK: - Public API
    func addEntry(type: EyeDropType) {
        entries.insert(EyeDropEntry(date: Date(), type: type), at: 0)
        prune()
    }
    
    // MARK: - Persistence
    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([EyeDropEntry].self, from: data) else { return }
        entries = decoded
    }
    
    // Remove entries older than maxDays
    private func prune() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -maxDays, to: Date())!
        entries = entries.filter { $0.date >= cutoff }
    }
}
