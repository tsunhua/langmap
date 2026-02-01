import Combine
import CoreLocation
import Foundation
import MapKit

class AddExpressionViewModel: ObservableObject {
    @Published var expressionText: String = ""
    @Published var selectedLanguage: LMLexiconLanguage?
    // Use ID as canonical selected value to avoid instance identity issues in Picker
    @Published var selectedLanguageId: Int?
    @Published var languages: [LMLexiconLanguage] = []

    // Suppression flag to avoid feedback loops when syncing selectedLanguage <-> selectedLanguageId
    private var suppressSelectedLanguageIdCallback = false
    @Published var region: String = ""
    @Published var tags: [String] = []
    @Published var currentTagInput: String = ""
    @Published var associatedExpression: LMLexiconExpression?
    @Published var searchAssociations: [LMLexiconExpression] = []
    @Published var isLocating: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var hasStartedEditing: Bool = false

    // Combine cancellables for auto-save bindings
    private var cancellables = Set<AnyCancellable>()

    // Track last geocoded coordinate and whether the region was auto-filled
    @Published private(set) var lastLatitude: Double?
    @Published private(set) var lastLongitude: Double?
    private var regionWasAutoFilled: Bool = false

    // Internal flag to suppress treating programmatic region updates as user edits
    private var suppressRegionChangeCallback: Bool = false

    private let locationManager = CLLocationManager()
    private var locationDelegate: LocationDelegate?

    // Reverse geocoding retry state
    private var geocodeRetryCount: Int = 0
    private let maxGeocodeRetries: Int = 3

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
        loadSavedPreferences()
        setupBindings()
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
                    self.geocodeRetryCount = 0
                    if let mapItem = mapItems.first {
                        // Build resolved text
                        var parts: [String] = []
                        if let shortAddress = mapItem.address?.shortAddress, !shortAddress.isEmpty {
                            parts.append(shortAddress)
                        } else if let fullAddress = mapItem.address?.fullAddress, !fullAddress.isEmpty {
                            parts.append(fullAddress)
                        } else if let name = mapItem.name, !name.isEmpty {
                            parts.append(name)
                        }
                        let resolvedText = parts.joined(separator: ", ")

                        // Only set region if empty or previously auto-filled
                        if self.region.isEmpty || self.regionWasAutoFilled {
                            // Mark that this is a programmatic update so our region change subscription doesn't treat it as user input
                            self.suppressRegionChangeCallback = true
                            self.region = resolvedText
                            self.regionWasAutoFilled = true

                            // Save coordinates
                            self.lastLatitude = location.coordinate.latitude
                            self.lastLongitude = location.coordinate.longitude
                            self.savePreferences()

                            print("📍 Auto-resolved region: \(self.region) coords=(\(self.lastLatitude!), \(self.lastLongitude!))")
                        } else {
                            print("ℹ️ Resolved \(resolvedText) but keeping user-edited region: \(self.region)")
                        }
                    } else {
                        print("⚠️ No locations found")
                    }
                }
            } catch {
                print("❌ Reverse geocoding failed: \(error)")

                // Stop locating UI immediately
                await MainActor.run { self.isLocating = false }

                // Save coordinates for fallback and future restores
                self.lastLatitude = location.coordinate.latitude
                self.lastLongitude = location.coordinate.longitude

                // Attempt CLGeocoder fallback first (often more tolerant)
                let didCLFallback = await tryCLGeocoderFallback(location)
                if didCLFallback {
                    // succeeded via CLGeocoder, reset retry counter and exit
                    self.geocodeRetryCount = 0
                    return
                }

                // Decide if the error is recoverable. MKError code 4 has been observed; treat it as non-recoverable to avoid wasted retries.
                var canRetry = true
                let nsErr = error as NSError
                if nsErr.domain == MKErrorDomain {
                    if nsErr.code == 4 {
                        canRetry = false
                        print("ℹ️ MKError code 4 received — will not retry MK reverse geocode")
                    }
                }

                // Retry logic for recoverable errors
                if canRetry && self.geocodeRetryCount < self.maxGeocodeRetries {
                    self.geocodeRetryCount += 1
                    let delaySeconds = UInt64(pow(2.0, Double(self.geocodeRetryCount)))
                    print("⚠️ Geocode failed, scheduling retry #\(self.geocodeRetryCount) in \(delaySeconds)s")

                    Task {
                        try? await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
                        await MainActor.run { self.isLocating = true }
                        self.reverseGeocode(location)
                    }
                    return
                }

                // Final fallback: use coordinates only if we don't already have a user-entered region
                await MainActor.run {
                    if self.region.isEmpty {
                        let lat = String(format: "%.4f", location.coordinate.latitude)
                        let lon = String(format: "%.4f", location.coordinate.longitude)
                        self.region = "\(lat), \(lon)"

                        // Save coordinates and mark as auto-filled
                        self.lastLatitude = location.coordinate.latitude
                        self.lastLongitude = location.coordinate.longitude
                        self.regionWasAutoFilled = true
                        self.savePreferences()

                        print("📍 Using coordinates as fallback: \(self.region)")
                    } else {
                        print("ℹ️ Keeping existing region value: \(self.region)")
                    }

                    // Reset retry counter for next attempt cycle
                    self.geocodeRetryCount = 0
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
        print("\n🔍 === START loadLastLanguage ===")
        print("Step 1: Check if languages list is loaded: \(languages.count) languages available")
        
        // Read saved id robustly (could be NSNumber / Int)
        if let saved = UserDefaults.standard.object(forKey: "selectedLanguageId") {
            print("Step 2a: Found savedSelectedLanguageId in UserDefaults: \(String(describing: saved))")
            var languageId: Int?
            if let intVal = saved as? Int {
                languageId = intVal
                print("Step 2b: Parsed as Int: \(intVal)")
            } else if let num = saved as? NSNumber {
                languageId = num.intValue
                print("Step 2b: Parsed as NSNumber: \(num.intValue)")
            }

            if let id = languageId {
                print("Step 3: languageId = \(id)")
                if let matchedLang = languages.first(where: { $0.id == id }) {
                    self.selectedLanguageId = id
                    print("Step 4a: ✅ Found matching language in list: \(matchedLang.name) (id: \(id))")
                    print("🔍 === END loadLastLanguage (restored from UserDefaults) ===\n")
                    return
                } else {
                    print("Step 4b: ❌ NO matching language in list for id \(id)")
                    print("Available language ids: \(languages.map { $0.id })")
                }
            } else {
                print("Step 3: Failed to parse savedSelectedLanguageId: \(String(describing: saved))")
            }
        } else {
            print("Step 2: NO savedSelectedLanguageId found in UserDefaults")
        }

        // Fallback: try to read an encoded language object
        print("Step 5: Trying JSON fallback...")
        if let data = UserDefaults.standard.data(forKey: "selectedLanguageData") {
            print("Step 5a: Found selectedLanguageData in UserDefaults (\(data.count) bytes)")
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(LMLexiconLanguage.self, from: data)
                print("Step 5b: ✅ Decoded language: \(decoded.name) (id: \(decoded.id))")
                if !languages.contains(where: { $0.id == decoded.id }) {
                    languages.insert(decoded, at: 0)
                    print("Step 5c: Added decoded language to list")
                }
                self.selectedLanguageId = decoded.id
                print("🔍 === END loadLastLanguage (restored from JSON fallback) ===\n")
            } catch {
                print("Step 5b: ❌ Failed to decode selectedLanguageData: \(error)")
            }
        } else {
            print("Step 5: NO selectedLanguageData found in UserDefaults")
        }
        
        print("🔍 === END loadLastLanguage (nothing restored) ===\n")
    }

    private func saveLastLanguage() {
        print("\n🔍 === START saveLastLanguage ===")
        if let id = selectedLanguageId {
            print("Step 1: selectedLanguageId = \(id)")
            UserDefaults.standard.set(id, forKey: "selectedLanguageId")
            print("Step 2: ✅ Wrote selectedLanguageId to UserDefaults")

            // Verify write
            let verify = UserDefaults.standard.object(forKey: "selectedLanguageId")
            print("Step 3: Verification read from UserDefaults: \(String(describing: verify))")

            // Also store an encoded copy when we have the full object available
            if let language = selectedLanguage, language.id == id {
                do {
                    let encoder = JSONEncoder()
                    let data = try encoder.encode(language)
                    UserDefaults.standard.set(data, forKey: "selectedLanguageData")
                    print("Step 4: ✅ Also saved encoded fallback for: \(language.name) (id: \(language.id))")
                } catch {
                    print("Step 4: ❌ Failed to encode selectedLanguage: \(error)")
                }
            } else {
                print("Step 4: ℹ️ No full language object available to encode fallback (selectedLanguage: \(String(describing: selectedLanguage?.name)))")
            }

            print("🔍 === END saveLastLanguage ===\n")
        } else {
            print("Step 1: selectedLanguageId is nil — removing keys")
            UserDefaults.standard.removeObject(forKey: "selectedLanguageId")
            UserDefaults.standard.removeObject(forKey: "selectedLanguageData")
            print("🔍 === END saveLastLanguage (cleared) ===\n")
        }
    }

    /// Persist the currently selected language (callable from the View)
    func persistSelectedLanguage() {
        print("\n🔍 === START persistSelectedLanguage ===")
        print("selectedLanguageId: \(String(describing: selectedLanguageId))")
        print("selectedLanguage: \(String(describing: selectedLanguage?.name))")
        // Ensure id is in sync then save
        if selectedLanguageId == nil {
            selectedLanguageId = selectedLanguage?.id
            print("Synced selectedLanguageId from selectedLanguage: \(String(describing: selectedLanguageId))")
        }
        saveLastLanguage()
        print("🔍 === END persistSelectedLanguage ===\n")
    }

    private func loadSavedPreferences() {
        // Load saved region
        if let savedRegion = UserDefaults.standard.string(forKey: "lastRegion") {
            region = savedRegion
            print("✅ Loaded last region: \(savedRegion)")
        } else {
            print("ℹ️ No saved lastRegion in UserDefaults")
        }

        // Load saved tags
        if let savedTags = UserDefaults.standard.stringArray(forKey: "lastTags") {
            tags = savedTags
            print("✅ Loaded last tags: \(savedTags)")
        } else {
            print("ℹ️ No saved lastTags in UserDefaults")
        }

        // Snapshot helpful keys for debugging
        let keys = ["selectedLanguageId", "lastRegion", "lastTags", "lastLatitude", "lastLongitude"]
        let snapshot = keys.map { key in
            "\(key): \(String(describing: UserDefaults.standard.object(forKey: key)))"
        }
        print("🔍 UserDefaults snapshot: \(snapshot.joined(separator: ", "))")

        // Read saved coordinates
        if let lat = UserDefaults.standard.object(forKey: "lastLatitude") as? Double,
           let lon = UserDefaults.standard.object(forKey: "lastLongitude") as? Double {
            lastLatitude = lat
            lastLongitude = lon
            print("✅ Loaded last coordinates: (\(lat), \(lon))")
        } else {
            print("ℹ️ No saved coordinates found")
        }
    }

    private func setupBindings() {
        // Sync selectedLanguageId -> selectedLanguage (id -> object)
        // This is the source of truth for user selections
        $selectedLanguageId
            .removeDuplicates()
            .sink { [weak self] languageId in
                guard let self = self else { return }
                if let id = languageId {
                    self.selectedLanguage = self.languages.first(where: { $0.id == id })
                } else {
                    self.selectedLanguage = nil
                }
            }
            .store(in: &cancellables)

        // Sync selectedLanguage -> selectedLanguageId (object -> id)
        // Only for programmatic changes from restore
        $selectedLanguage
            .sink { [weak self] language in
                guard let self = self else { return }
                if self.suppressSelectedLanguageIdCallback {
                    self.suppressSelectedLanguageIdCallback = false
                    return
                }
                if let language = language {
                    self.selectedLanguageId = language.id
                } else {
                    print("ℹ️ selectedLanguage became nil — ignoring to avoid clearing selectedLanguageId")
                }
            }
            .store(in: &cancellables)

        // Auto-save region (debounced) and detect user edits vs programmatic sets
        $region
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self = self else { return }
                if self.suppressRegionChangeCallback {
                    // This change was triggered programmatically; ignore and reset the flag
                    self.suppressRegionChangeCallback = false
                    print("ℹ️ Region change suppressed (programmatic): \(newValue)")
                    return
                }

                // Treat as user edit
                self.regionWasAutoFilled = false
                self.savePreferences()
                print("✍️ Region user-edited (debounced) and saved: \(newValue)")
            }
            .store(in: &cancellables)

        // Auto-save tags when they change
        $tags
            .sink { [weak self] _ in
                self?.savePreferences()
                print("💾 Auto-saved tags")
            }
            .store(in: &cancellables)

        // Track when user starts editing expression text
        $expressionText
            .sink { [weak self] text in
                if !text.isEmpty {
                    self?.hasStartedEditing = true
                }
            }
            .store(in: &cancellables)
    }

    private func savePreferences() {
        // Save region
        if !region.isEmpty {
            UserDefaults.standard.set(region, forKey: "lastRegion")
        } else {
            UserDefaults.standard.removeObject(forKey: "lastRegion")
        }

        // Save tags
        if !tags.isEmpty {
            UserDefaults.standard.set(tags, forKey: "lastTags")
        } else {
            UserDefaults.standard.removeObject(forKey: "lastTags")
        }

        // Save coordinates if available
        if let lat = lastLatitude, let lon = lastLongitude {
            UserDefaults.standard.set(lat, forKey: "lastLatitude")
            UserDefaults.standard.set(lon, forKey: "lastLongitude")
        } else {
            UserDefaults.standard.removeObject(forKey: "lastLatitude")
            UserDefaults.standard.removeObject(forKey: "lastLongitude")
        }

        // DO NOT update selectedLanguageId here — it's managed separately by saveLastLanguage()
        // This prevents accidental clearing of saved language when other fields are saved

        print("💾 Saved preferences: region=\(region), tags=\(tags), coords=(\(String(describing: lastLatitude)), \(String(describing: lastLongitude)))")
        // Read back for verification
        let readRegion = UserDefaults.standard.string(forKey: "lastRegion")
        let readTags = UserDefaults.standard.stringArray(forKey: "lastTags")
        let readLat = UserDefaults.standard.object(forKey: "lastLatitude")
        let readLon = UserDefaults.standard.object(forKey: "lastLongitude")
        let readLangId = UserDefaults.standard.object(forKey: "selectedLanguageId")
        print("🔍 After save - lastRegion=\(String(describing: readRegion)), lastTags=\(String(describing: readTags)), selectedLanguageId=\(String(describing: readLangId)), lastLatitude=\(String(describing: readLat)), lastLongitude=\(String(describing: readLon))")
    }

    /// Public helper to restore saved preferences on view appearance
    func restorePreferences() {
        loadSavedPreferences()
        // Try to restore language; if languages haven't loaded yet, loadLastLanguage will be called again after language fetch
        loadLastLanguage()
        print("🔄 restorePreferences() called")
    }

    /// Called when the user manually edits the region field. This ensures we don't overwrite user input with subsequent auto-geocode results.
    func regionEditedByUser() {
        regionWasAutoFilled = false
        savePreferences()
        print("✍️ Region edited by user: \(region)")
    }

    // MARK: - CLGeocoder fallback

    private func tryCLGeocoderFallback(_ location: CLLocation) async -> Bool {
        print("🔁 Attempting reverse geocoding fallback...")

        if #available(iOS 26, macOS 26, *) {
            guard let request = MKReverseGeocodingRequest(location: location) else {
                print("❌ Failed to create MKReverseGeocodingRequest")
                return false
            }

            do {
                let mapItems = try await request.mapItems

                guard let mapItem = mapItems.first else {
                    print("⚠️ MKReverseGeocodingRequest returned no placemarks")
                    return false
                }

                var parts: [String] = []
                if let shortAddress = mapItem.address?.shortAddress, !shortAddress.isEmpty {
                    parts.append(shortAddress)
                } else if let fullAddress = mapItem.address?.fullAddress, !fullAddress.isEmpty {
                    parts.append(fullAddress)
                }
                if let name = mapItem.name { parts.append(name) }

                let resolved = parts.joined(separator: ", ")

                await MainActor.run {
                    if self.region.isEmpty || self.regionWasAutoFilled {
                        self.suppressRegionChangeCallback = true
                        self.region = resolved.isEmpty ? (mapItem.name ?? "") : resolved
                        self.regionWasAutoFilled = true
                        self.savePreferences()
                        print("📍 MKReverseGeocodingRequest resolved region: \(self.region)")
                    } else {
                        print("ℹ️ MKReverseGeocodingRequest resolved \(resolved) but keeping existing region: \(self.region)")
                    }
                }
                return true
            } catch {
                print("❌ MKReverseGeocodingRequest failed: \(error.localizedDescription)")
                return false
            }
        } else {
            return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, clError in
                    guard let self = self else {
                        continuation.resume(returning: false)
                        return
                    }

                    if let clError = clError {
                        print("❌ CLGeocoder failed: \(clError.localizedDescription)")
                        continuation.resume(returning: false)
                        return
                    }

                    if let placemark = placemarks?.first {
                        var parts: [String] = []
                        if let name = placemark.name { parts.append(name) }
                        if let locality = placemark.locality { parts.append(locality) }
                        if let admin = placemark.administrativeArea { parts.append(admin) }
                        if let country = placemark.country { parts.append(country) }

                        let resolved = parts.joined(separator: ", ")

                        Task {
                            await MainActor.run {
                                if self.region.isEmpty || self.regionWasAutoFilled {
                                    self.suppressRegionChangeCallback = true
                                    self.region = resolved.isEmpty ? (placemark.name ?? "") : resolved
                                    self.regionWasAutoFilled = true
                                    self.savePreferences()
                                    print("📍 CLGeocoder fallback resolved region: \(self.region)")
                                } else {
                                    print("ℹ️ CLGeocoder resolved \(resolved) but keeping existing region: \(self.region)")
                                }
                            }
                        }

                        continuation.resume(returning: true)
                        return
                    }

                    print("⚠️ CLGeocoder returned no placemarks")
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func resetForNextEntry() {
        // Clear only expression text and association
        expressionText = ""
        associatedExpression = nil
        searchAssociations = []

        // Keep language, region, and tags for next entry
        print("🔄 Reset for next entry, keeping language/region/tags")
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
        // Persist immediately to avoid any race conditions
        savePreferences()
        print("💾 addTag persisted: \(tags)")
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        savePreferences()
        print("💾 removeTag persisted: \(tags)")
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
        // Only show "required" error after user has started editing
        if expressionText.isEmpty {
            return hasStartedEditing ? "expression_required".localized : nil
        }
        if expressionText.count > 500 {
            return "max_characters".localized
        }
        return nil
    }

    // MARK: - Submit

    func submit() async throws {
        guard isValid else { return }

        isLoading = true
        saveLastLanguage()
        savePreferences()

        defer {
            isLoading = false
        }

        // Prepare request body as JSON
        var requestBody: [String: Any] = [
            "text": expressionText,
            "language_code": selectedLanguage!.code
        ]

        if !region.isEmpty {
            requestBody["region"] = region
        }

        if !tags.isEmpty {
            requestBody["tags"] = tags
        }

        // Use meaning_id for associations instead of association_id
        if let meaningId = associatedExpression?.meaningId {
            requestBody["meaning_id"] = meaningId
        }

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])

        var request = NetworkService.shared.createRequest(
            endpoint: "/expressions",
            method: "POST"
        )
        request.httpBody = jsonData

        let _: LMLexiconExpression = try await NetworkService.shared.performRequest(
            request, responseType: LMLexiconExpression.self
        )

        // Reset for next entry instead of closing
        await MainActor.run {
            resetForNextEntry()
        }
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
