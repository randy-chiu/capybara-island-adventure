import Foundation

final class ProgressStore {
    private let defaults: UserDefaults
    private let key = "capybara.adventure.progress.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> SavedProgress {
        guard let data = defaults.data(forKey: key),
              let progress = try? JSONDecoder().decode(SavedProgress.self, from: data) else {
            return SavedProgress()
        }
        return progress
    }

    func save(_ progress: SavedProgress) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: key)
    }

    func erase() {
        defaults.removeObject(forKey: key)
    }
}
