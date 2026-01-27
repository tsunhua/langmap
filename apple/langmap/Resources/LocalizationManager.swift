import Foundation
import Combine

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: String = "en-US" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "appLanguage")
        }
    }

    private var localizations: [String: [String: String]] = [:]

    private init() {
        loadLocalizations()
        currentLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en-US"
    }

    private func loadLocalizations() {
        if let path = Bundle.main.path(forResource: "en-US", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            localizations["en-US"] = json
        }
    }

    func localize(_ key: String) -> String {
        return localizations[currentLanguage]?[key] ?? localizations["en-US"]?[key] ?? key
    }

    func setLanguage(_ code: String) {
        if localizations[code] != nil {
            currentLanguage = code
        }
    }
}
