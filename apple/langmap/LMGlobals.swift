import Combine
import Security
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

// MARK: - Localization

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "appLanguage")
            loadLocalizations()
        }
    }

    private var localizations: [String: [String: String]] = [:]

    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") {
            currentLanguage = savedLanguage
        } else {
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            let systemRegion = Locale.current.region?.identifier ?? ""
            let supportedLanguages = ["en-US", "zh-CN"]
            let potentialLanguage = "\(systemLanguage)-\(systemRegion)"

            if supportedLanguages.contains(potentialLanguage) {
                currentLanguage = potentialLanguage
            } else {
                currentLanguage = "en-US"
            }
        }
        loadLocalizations()
    }

    private func loadLocalizations() {
        localizations = [:]
        if let path = Bundle.main.path(forResource: "en-US", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        {
            localizations["en-US"] = json
        }

        if currentLanguage != "en-US" {
            if let path = Bundle.main.path(forResource: currentLanguage, ofType: "json"),
                let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
            {
                localizations[currentLanguage] = json
            }
        }
    }

    func localize(_ key: String) -> String {
        return localizations[currentLanguage]?[key] ?? localizations["en-US"]?[key] ?? key
    }

    static func L(_ key: String) -> String {
        return shared.localize(key)
    }
}

// MARK: - Services

class KeychainHelper {
    static func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)
    }
}

class NetworkService: ObservableObject {
    static let shared = NetworkService()
    private let baseURL = "https://langmap.io/api/v1"

    @Published var authToken: String? {
        didSet {
            if let token = authToken {
                KeychainHelper.save(key: "authToken", value: token)
            } else {
                KeychainHelper.delete(key: "authToken")
            }
        }
    }

    private init() {
        authToken = KeychainHelper.load(key: "authToken")
    }

    func createRequest(endpoint: String, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: URL(string: "\(baseURL)\(endpoint)")!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    func performRequest<T: Codable>(
        _ request: URLRequest,
        responseType: T.Type
    ) async throws -> T {
        print("🌐 Requesting: \(request.url?.absoluteString ?? "unknown")")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let jsonString = String(data: data, encoding: .utf8) {
            print("📝 Raw Response: \(jsonString.prefix(500))...")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            authToken = nil
            throw NetworkError.unauthorized
        }

        if httpResponse.statusCode >= 400 {
            let errorResponse = try? JSONDecoder().decode(ApiError.self, from: data)
            throw NetworkError.apiError(
                errorResponse?.error ?? "Unknown error (\(httpResponse.statusCode))")
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("⚠️ Direct decoding failed: \(error). Trying to unwrap LMApiResponse...")

            do {
                let wrapped = try JSONDecoder().decode(LMApiResponse<T>.self, from: data)
                return wrapped.data
            } catch {
                print("❌ Unwrapping failed: \(error)")
                throw NetworkError.decodingError
            }
        }
    }
}

struct ApiError: Codable {
    let error: String
}

struct LMApiResponse<T: Codable>: Codable {
    let data: T
}

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case apiError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized access"
        case .apiError(let message):
            return message
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

// MARK: - Theme

struct AppTheme {
    static let primaryColor = Color.blue
    static let secondaryColor = Color.gray
    static let backgroundColor = Color(UIColor.systemBackground)
    static let cardBackgroundColor = Color(UIColor.secondarySystemBackground)
    static let textColor = Color(UIColor.label)
    static let secondaryTextColor = Color(UIColor.secondaryLabel)
}

// MARK: - Haptic Feedback

struct HapticFeedback {
    static func light() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func medium() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func error() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }
}

// MARK: - Glass Card

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }
}

extension View {
    func glassCardStyle() -> some View {
        modifier(GlassCardModifier())
    }
}

// MARK: - Extensions

extension String {
    var localized: String {
        return LocalizationManager.L(self)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

struct AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 20
}

struct AppTouchTarget {
    static let minSize: CGFloat = 44
}
