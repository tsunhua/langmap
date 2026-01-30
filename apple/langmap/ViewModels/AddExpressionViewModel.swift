import Foundation
import Combine
import CoreLocation

class AddExpressionViewModel: ObservableObject {
    @Published var expressionText: String = ""
    @Published var selectedLanguage: LMLexiconLanguage?
    @Published var languages: [LMLexiconLanguage] = []
    @Published var region: String = ""
    @Published var tags: [String] = []
    @Published var currentTagInput: String = ""
    @Published var associatedExpression: LMLexiconExpression?
    @Published var searchAssociations: [LMLexiconExpression] = []
    @Published var isLocating: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""

    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupLocationManager()
        loadLanguages()
        loadLastLanguage()
    }

    // MARK: - Location

    private func setupLocationManager() {
        locationManager.delegate = LocationDelegate(
            onUpdate: { [unowned self] location in
                self.reverseGeocode(location)
            },
            onError: { [unowned self] error in
                self.isLocating = false
            }
        )
    }

    func requestLocation() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
                locationManager.authorizationStatus == .authorizedAlways else {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        isLocating = true
        locationManager.requestLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        let geocoder = CLGeocoder()

        Task {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(from: location)
                await MainActor.run {
                    self?.isLocating = false
                    if let placemark = placemarks.first {
                        self?.region = placemark.name ?? placemark.locality ?? placemark.administrativeArea ?? ""
                    }
                }
            } catch {
                await MainActor.run {
                    self?.isLocating = false
                }
            }
        }
            DispatchQueue.main.async {
                self?.isLocating = false
                if let placemark = placemarks?.first {
                    self?.region = placemark.locality ?? placemark.administrativeArea ?? ""
                }
            }
        }
    }

    // MARK: - Languages

    private func loadLanguages() {
        Task {
            do {
                let request = NetworkService.shared.createRequest(endpoint: "/languages")
                let response: [LMLexiconLanguage] = try await NetworkService.shared.performRequest(
                    request, responseType: [LMLexiconLanguage].self
                )
                await MainActor.run {
                    self.languages = response
                }
            } catch {
                // Handle error
            }
        }
    }

    private func loadLastLanguage() {
        if let languageId = UserDefaults.standard.object(forKey: "selectedLanguageId") as? Int,
           let language = languages.first(where: { $0.id == languageId }) {
            selectedLanguage = language
        }
    }

    private func saveLastLanguage() {
        if let languageId = selectedLanguage?.id {
            UserDefaults.standard.set(languageId, forKey: "selectedLanguageId")
        }
    }

    // MARK: - Tags

    func addTag() {
        let tag = currentTagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty,
              tags.count < 5,
              tag.count <= 20,
              !tags.contains(tag) else { return }

        tags.append(tag)
        currentTagInput = ""
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    // MARK: - Associations

    func searchForAssociations(query: String) {
        guard !query.isEmpty else {
            searchAssociations = []
            return
        }

        Task {
            do {
                let request = NetworkService.shared.createRequest(
                    endpoint: "/expressions/search?q=\(query)"
                )
                let response: [LMLexiconExpression] = try await NetworkService.shared.performRequest(
                    request, responseType: [LMLexiconExpression].self
                )
                await MainActor.run {
                    self.searchAssociations = response
                }
            } catch {
                // Handle error
            }
        }
    }

    func selectAssociation(_ expression: LMLexiconExpression) {
        associatedExpression = expression
        searchAssociations = []
    }

    func clearAssociation() {
        associatedExpression = nil
    }

    // MARK: - Validation

    var isValid: Bool {
        !expressionText.isEmpty &&
        expressionText.count <= 500 &&
        selectedLanguage != nil
    }

    var expressionTextError: String? {
        if expressionText.isEmpty {
            return "Expression is required"
        }
        if expressionText.count > 500 {
            return "Maximum 500 characters"
        }
        return nil
    }

    // MARK: - Submit

    func submit() async throws {
        guard isValid else { return }

        isLoading = true
        saveLastLanguage()

        var components = URLComponents(string: "/expressions")!
        components.queryItems = [
            URLQueryItem(name: "text", value: expressionText),
            URLQueryItem(name: "language_id", value: "\(selectedLanguage!.id)")
        ]

        if !region.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "region", value: region))
        }

        if !tags.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "tags", value: tags.joined(separator: ",")))
        }

        if let associationId = associatedExpression?.id {
            components.queryItems?.append(URLQueryItem(name: "association_id", value: "\(associationId)"))
        }

        let request = NetworkService.shared.createRequest(
            endpoint: components.url!.absoluteString,
            method: "POST"
        )

        let _: LMLexiconExpression = try await NetworkService.shared.performRequest(
            request, responseType: LMLexiconExpression.self
        )

        isLoading = false
    }

// MARK: - Location Delegate

class LocationDelegate: NSObject, CLLocationManagerDelegate {
    let onUpdate: (CLLocation) -> Void
    let onError: (Error) -> Void

    init(onUpdate: @escaping (CLLocation) -> Void, onError: @escaping (Error) -> Void) {
        self.onUpdate = onUpdate
        self.onError = onError
        super.init()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            onUpdate(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onError(error)
    }
}
        }
