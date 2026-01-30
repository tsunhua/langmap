import Combine
import CoreLocation
import Foundation
import MapKit

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
    private var locationDelegate: LocationDelegate?
    init() {
        locationDelegate = LocationDelegate(
            onUpdate: { [weak self] location in
                self?.reverseGeocode(location)
            },
            onError: { [weak self] _ in
                self?.isLocating = false
            },
            onAuthorizationChange: { [weak self] in
                self?.locationManager.requestLocation()
            }
        )
        setupLocationManager()
        loadLanguages()
    }

    // MARK: - Location

    private func setupLocationManager() {
        locationManager.delegate = locationDelegate
    }

    func requestLocation() {
        print("📍 Requesting current location...")
        #if os(iOS)
            let status = locationManager.authorizationStatus
            print("🗺️ Authorization status: \(status.rawValue)")

            if status == .notDetermined {
                print("⚠️ Requesting location authorization...")
                isLocating = true
                locationManager.requestWhenInUseAuthorization()
                // Location will be requested automatically in locationManagerDidChangeAuthorization
                return
            }

            guard status == .authorizedWhenInUse || status == .authorizedAlways else {
                print("❌ Location permission denied")
                return
            }
        #endif
        isLocating = true
        locationManager.requestLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        print(
            "🗺️ Reverse geocoding location: \(location.coordinate.latitude), \(location.coordinate.longitude)"
        )

        guard let request = MKReverseGeocodingRequest(location: location) else {
            print("❌ Failed to create MKReverseGeocodingRequest")
            self.isLocating = false
            return
        }

        Task {
            do {
                let mapItems = try await request.mapItems
                print("✅ Geocoding successful: \(mapItems.count) locations found")

                await MainActor.run {
                    self.isLocating = false
                    if let mapItem = mapItems.first {
                        // Use shortAddress if available, otherwise fallback to fullAddress or name
                        if let shortAddress = mapItem.address?.shortAddress, !shortAddress.isEmpty {
                            self.region = shortAddress
                        } else if let fullAddress = mapItem.address?.fullAddress,
                            !fullAddress.isEmpty
                        {
                            self.region = fullAddress
                        } else if let name = mapItem.name, !name.isEmpty {
                            self.region = name
                        }

                        print("📍 Resolved region: \(self.region)")
                    } else {
                        print("⚠️ No locations found")
                    }
                }
            } catch {
                print("❌ Reverse geocoding failed: \(error)")
                await MainActor.run {
                    self.isLocating = false
                    // Fallback: show coordinates if geocoding fails
                    let lat = String(format: "%.4f", location.coordinate.latitude)
                    let lon = String(format: "%.4f", location.coordinate.longitude)
                    self.region = "\(lat), \(lon)"
                    print("📍 Using coordinates as fallback: \(self.region)")
                }
            }
        }
    }

    // MARK: - Languages

    private func loadLanguages() {
        Task {
            do {
                print("🌐 Loading languages for AddExpression...")
                let request = NetworkService.shared.createRequest(endpoint: "/languages")
                let response: [LMLexiconLanguage] = try await NetworkService.shared.performRequest(
                    request, responseType: [LMLexiconLanguage].self
                )
                print("✅ Languages loaded: \(response.count)")
                await MainActor.run {
                    self.languages = response
                    self.loadLastLanguage()
                }
            } catch {
                print("❌ Failed to load languages: \(error)")
            }
        }
    }

    private func loadLastLanguage() {
        if let languageId = UserDefaults.standard.object(forKey: "selectedLanguageId") as? Int,
            let language = languages.first(where: { $0.id == languageId })
        {
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
            !tags.contains(tag)
        else { return }

        tags.append(tag)
        currentTagInput = ""
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    // MARK: - Associations

    func searchForAssociations(query: String) {
        print("🔍 Searching for associations with query: '\(query)'")

        guard !query.isEmpty else {
            searchAssociations = []
            print("⚠️ Query is empty, clearing results")
            return
        }

        Task {
            do {
                var endpoint =
                    "/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

                if !region.isEmpty {
                    endpoint +=
                        "&region=\(region.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                }

                if !tags.isEmpty {
                    endpoint +=
                        "&tags=\(tags.joined(separator: ",").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                }

                if let associationId = associatedExpression?.id {
                    endpoint += "&association_id=\(associationId)"
                }

                print("🌐 Association search endpoint: \(endpoint)")

                let request = NetworkService.shared.createRequest(
                    endpoint: endpoint,
                    method: "GET"
                )
                let response: [LMLexiconExpression] = try await NetworkService.shared
                    .performRequest(
                        request, responseType: [LMLexiconExpression].self
                    )

                print("✅ Association search successful: \(response.count) results")

                await MainActor.run {
                    self.searchAssociations = response
                    print("📝 Updated searchAssociations with \(response.count) items")
                }
            } catch {
                print("❌ Association search failed: \(error)")
                print("❌ Error details: \(error.localizedDescription)")
                await MainActor.run {
                    self.searchAssociations = []
                }
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
        !expressionText.isEmpty && expressionText.count <= 500 && selectedLanguage != nil
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

        var endpoint =
            "/expressions?text=\(expressionText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        endpoint += "&language_id=\(selectedLanguage!.id)"

        if !region.isEmpty {
            endpoint +=
                "&region=\(region.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }

        if !tags.isEmpty {
            endpoint +=
                "&tags=\(tags.joined(separator: ",").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }

        if let associationId = associatedExpression?.id {
            endpoint += "&association_id=\(associationId)"
        }

        let request = NetworkService.shared.createRequest(
            endpoint: endpoint,
            method: "POST"
        )

        let _: LMLexiconExpression = try await NetworkService.shared.performRequest(
            request, responseType: LMLexiconExpression.self
        )

        isLoading = false
    }
}

// MARK: - Location Delegate

class LocationDelegate: NSObject, CLLocationManagerDelegate {
    let onUpdate: (CLLocation) -> Void
    let onError: (Error) -> Void
    let onAuthorizationChange: (() -> Void)?

    init(
        onUpdate: @escaping (CLLocation) -> Void,
        onError: @escaping (Error) -> Void,
        onAuthorizationChange: (() -> Void)? = nil
    ) {
        self.onUpdate = onUpdate
        self.onError = onError
        self.onAuthorizationChange = onAuthorizationChange
        super.init()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("📡 Location manager updated locations: \(locations.count)")
        if let location = locations.last {
            onUpdate(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager failed: \(error)")
        onError(error)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        #if os(iOS)
            let status = manager.authorizationStatus
            print("🔐 Authorization changed to: \(status.rawValue)")

            if status == .authorizedWhenInUse || status == .authorizedAlways {
                print("✅ Permission granted, requesting location...")
                onAuthorizationChange?()
            } else if status == .denied || status == .restricted {
                print("❌ Permission denied or restricted")
            }
        #endif
    }
}
