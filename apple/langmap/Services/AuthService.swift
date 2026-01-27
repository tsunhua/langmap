import Foundation
import Combine

class AuthService: ObservableObject {
    private let networkService = NetworkService.shared

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?

    init() {
        checkAuthStatus()
    }

    func login(email: String, password: String) async throws {
        var request = networkService.createRequest(
            endpoint: "/auth/login",
            method: "POST"
        )

        let credentials = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(credentials)

        let response: AuthResponse = try await networkService.performRequest(request, responseType: AuthResponse.self)
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

        let response: AuthResponse = try await networkService.performRequest(request, responseType: AuthResponse.self)
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
        let response: User = try await networkService.performRequest(request, responseType: User.self)
        currentUser = response
        isAuthenticated = true
    }

    private func checkAuthStatus() {
        isAuthenticated = networkService.authToken != nil
    }
}
