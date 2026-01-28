import Combine
import Security
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

// MARK: - Localization

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: String = "en-US" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "appLanguage")
            loadLocalizations()
        }
    }

    private var localizations: [String: [String: String]] = [:]

    private init() {
        currentLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en-US"
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

// MARK: - Core Models

struct LMLexiconExpression: Codable, Identifiable {
    let id: Int
    let text: String
    let meaningId: Int
    let audioUrl: String?
    let languageCode: String
    let regionCode: String?
    let regionName: String?
    let regionLatitude: Double?
    let regionLongitude: Double?
    let tags: String?
    let sourceType: String?
    let sourceRef: String?
    let reviewStatus: String?
    let createdBy: String?
    let createdAt: String
    let updatedAt: String
    let origin: String?
    let usage: String?

    var phrase: String {
        return text
    }

    var translation: String {
        return ""
    }

    enum CodingKeys: String, CodingKey {
        case id, text, tags, origin, usage
        case meaningId = "meaning_id"
        case audioUrl = "audio_url"
        case languageCode = "language_code"
        case regionCode = "region_code"
        case regionName = "region_name"
        case regionLatitude = "region_latitude"
        case regionLongitude = "region_longitude"
        case sourceType = "source_type"
        case sourceRef = "source_ref"
        case reviewStatus = "review_status"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct LMLexiconLanguage: Codable, Identifiable, Hashable {
    let id: Int
    let code: String
    let name: String
    let direction: String
    let family: String?
    let notes: String?
    let isActive: Int
    let regionCode: String?
    let regionName: String?
    let regionLatitude: Double?
    let regionLongitude: Double?
    let createdBy: String?
    let createdAt: String
    let updatedAt: String?

    var nativeName: String? {
        return name
    }

    enum CodingKeys: String, CodingKey {
        case id, code, name, direction, family, notes
        case isActive = "is_active"
        case regionCode = "region_code"
        case regionName = "region_name"
        case regionLatitude = "region_latitude"
        case regionLongitude = "region_longitude"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct LMCollection: Codable, Identifiable {
    let id: Int
    let userId: Int
    let name: String
    let description: String?
    let isPublic: Int?
    let items: [CollectionItem]?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, items
        case userId = "user_id"
        case isPublic = "is_public"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CollectionItem: Codable, Identifiable {
    let id: Int
    let collectionId: Int
    let expressionId: Int
    let note: String?
    let createdAt: String
    let updatedAt: String?
    let expression: LMLexiconExpression?

    enum CodingKeys: String, CodingKey {
        case id, note, expression
        case collectionId = "collection_id"
        case expressionId = "expression_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CollectionDetail: Codable {
    let id: Int
    let userId: Int
    let name: String
    let description: String?
    let isPublic: Int?
    let createdAt: String
    let updatedAt: String?
    let items: [CollectionItem]?

    enum CodingKeys: String, CodingKey {
        case id, name, description, items
        case userId = "user_id"
        case isPublic = "is_public"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let role: String
    let emailVerified: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, username, email, role
        case emailVerified = "email_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AuthResponse: Codable {
    let success: Bool
    let data: AuthData
}

struct AuthData: Codable {
    let token: String
    let user: User
}

struct LMApiResponse<T: Codable>: Codable {
    let data: T
}

struct ApiError: Codable {
    let error: String
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
            // Try direct decoding first
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("⚠️ Direct decoding failed: \(error). Trying to unwrap LMApiResponse...")

            // Try unwrapping if it's an LMApiResponse
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

class AuthService: ObservableObject {
    private let networkService = NetworkService.shared

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?

    private var cancellables = Set<AnyCancellable>()

    init() {
        checkAuthStatus()
        setupAuthObservation()
    }

    private func setupAuthObservation() {
        networkService.$authToken
            .receive(on: RunLoop.main)
            .sink { [weak self] token in
                self?.isAuthenticated = token != nil
            }
            .store(in: &cancellables)
    }

    func login(email: String, password: String) async throws {
        var request = networkService.createRequest(
            endpoint: "/auth/login",
            method: "POST"
        )

        let credentials = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(credentials)

        let response: AuthResponse = try await networkService.performRequest(
            request, responseType: AuthResponse.self)
        networkService.authToken = response.data.token
        currentUser = response.data.user
        isAuthenticated = true
    }

    func register(email: String, username: String, password: String) async throws {
        var request = networkService.createRequest(
            endpoint: "/auth/register",
            method: "POST"
        )

        let userData = ["email": email, "username": username, "password": password]
        request.httpBody = try JSONEncoder().encode(userData)

        let response: AuthResponse = try await networkService.performRequest(
            request, responseType: AuthResponse.self)
        networkService.authToken = response.data.token
        currentUser = response.data.user
        isAuthenticated = true
    }

    func logout() {
        networkService.authToken = nil
        currentUser = nil
        isAuthenticated = false
    }

    func fetchCurrentUser() async throws {
        let request = networkService.createRequest(endpoint: "/auth/me")
        let response: User = try await networkService.performRequest(
            request, responseType: User.self)
        currentUser = response
        isAuthenticated = true
    }

    func checkAuthStatus() {
        isAuthenticated = networkService.authToken != nil
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case apiError(String)
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Please log in again"
        case .apiError(let message):
            return message
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Theme

struct AppTheme {
    static let primaryGradient: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "6366f1"), Color(hex: "a855f7")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardBackground = Color.primary.opacity(0.03)
    static let inputBackground = Color.primary.opacity(0.03)
    static let secondaryText = Color.secondary

    // Animation configurations
    static let standardSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let easeInOut = Animation.easeInOut(duration: 0.2)
    static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.5)

    // Spacing
    static let cardSpacing: CGFloat = 12
    static let cardPadding: CGFloat = 16
}

struct HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppRadius.extraLarge)
                    .fill(AppTheme.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.extraLarge)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
    }
}

// MARK: - Extensions

extension String {
    var localized: String {
        return LocalizationManager.L(self)
    }
}

extension View {
    func glassCardStyle() -> some View {
        modifier(GlassCardModifier())
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
