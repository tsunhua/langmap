import Foundation
import Combine

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
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            authToken = nil
            throw NetworkError.unauthorized
        }

        if httpResponse.statusCode >= 400 {
            let errorResponse = try JSONDecoder().decode(ApiError.self, from: data)
            throw NetworkError.apiError(errorResponse.error)
        }

        let decoded = try JSONDecoder().decode(T.self, from: data)
        return decoded
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
