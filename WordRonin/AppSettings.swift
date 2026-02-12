import Foundation

enum AppSettingsKeys {
    static let soundEnabled = "soundEnabled"
    static let musicEnabled = "musicEnabled"
}

struct AppSettingsStore {
    static var soundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: AppSettingsKeys.soundEnabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: AppSettingsKeys.soundEnabled) }
    }

    static var musicEnabled: Bool {
        get { UserDefaults.standard.object(forKey: AppSettingsKeys.musicEnabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: AppSettingsKeys.musicEnabled) }
    }
}
