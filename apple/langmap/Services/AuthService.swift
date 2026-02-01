import Foundation
import Combine

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    private let networkService = NetworkService.shared

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?

    private var cancellables = Set<AnyCancellable>()

    init() {
        checkAuthStatus()
        loadUserFromStorage()
        setupAuthObservation()
    }

    private func setupAuthObservation() {
        networkService.$authToken
            .receive(on: RunLoop.main)
            .sink { [weak self] token in
                self?.isAuthenticated = token != nil
                if token == nil {
                    self?.clearUserFromStorage()
                } else if self?.currentUser == nil {
                    Task {
                        try? await self?.fetchCurrentUser()
                    }
                }
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
        saveUserToStorage(response.data.user)
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
        saveUserToStorage(response.data.user)
    }

    func logout() {
        networkService.authToken = nil
        currentUser = nil
        isAuthenticated = false
        clearUserFromStorage()
    }

    func fetchCurrentUser() async throws {
        let request = networkService.createRequest(endpoint: "/auth/me")
        let response: User = try await networkService.performRequest(
            request, responseType: User.self)
        currentUser = response
        isAuthenticated = true
        saveUserToStorage(response)
    }

    func checkAuthStatus() {
        isAuthenticated = networkService.authToken != nil
    }

    private func saveUserToStorage(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }

    private func loadUserFromStorage() {
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
        }
    }

    private func clearUserFromStorage() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
}
