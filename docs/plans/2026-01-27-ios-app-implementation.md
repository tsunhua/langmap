# iOS App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native SwiftUI iOS app for LangMap that connects to the existing Cloudflare Workers backend with D1 database, supporting offline caching, internationalization, and user authentication.

**Architecture:** Model-View-ViewModel (MVVM) with SwiftUI, using URLSession for API communication, Core Data for offline caching, and Keychain Services for secure token storage.

**Tech Stack:** SwiftUI (iOS 15+), Core Data, URLSession, Keychain Services, XCTest

---

## Prerequisites

### Task 0: Project Structure Setup

**Files:**
- Create: `apple/langmap/Models/`
- Create: `apple/langmap/Views/`
- Create: `apple/langmap/ViewModels/`
- Create: `apple/langmap/Services/`
- Create: `apple/langmap/Resources/`
- Create: `apple/langmap/Utils/`
- Create: `apple/langmap/Core Data/`

**Step 1: Create directory structure**

```bash
cd apple/langmap
mkdir -p Models Views ViewModels Services Resources Utils "Core Data"
```

**Step 2: Verify structure**

```bash
ls -la
```
Expected: All directories created

**Step 3: Commit**

```bash
git add apple/langmap
git commit -m "feat: create iOS app directory structure"
```

---

## Phase 1: Foundation Layer

### Task 1: Core Data Model Setup

**Files:**
- Create: `apple/langmap/Core Data/LangMap.xcdatamodeld/LangMap.xcdatamodeld/contents`

**Step 1: Create Core Data model**

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<model type="com.apple.IDECoreDataModeler.DataModel" documentVersion="1.0" lastSavedToolsVersion="22225" systemVersion="23A344" minimumToolsVersion="Automatic" sourceLanguage="Swift" userDefinedModelVersionIdentifier="">
    <entity name="CachedLanguage" representedClassName="CachedLanguage" syncable="YES">
        <attribute name="code" optional="NO" attributeType="String"/>
        <attribute name="name" optional="NO" attributeType="String"/>
        <attribute name="nativeName" optional="YES" attributeType="String"/>
        <attribute name="isActive" optional="NO" attributeType="Boolean" defaultValueString="YES"/>
    </entity>
    <entity name="CachedExpression" representedClassName="CachedExpression" syncable="YES">
        <attribute name="id" optional="NO" attributeType="Integer 64" defaultValueString="0"/>
        <attribute name="phrase" optional="NO" attributeType="String"/>
        <attribute name="translation" optional="NO" attributeType="String"/>
        <attribute name="languageCode" optional="NO" attributeType="String"/>
        <attribute name="origin" optional="YES" attributeType="String"/>
        <attribute name="usage" optional="YES" attributeType="String"/>
        <attribute name="createdAt" optional="NO" attributeType="Date"/>
    </entity>
    <entity name="CachedCollection" representedClassName="CachedCollection" syncable="YES">
        <attribute name="id" optional="NO" attributeType="Integer 64" defaultValueString="0"/>
        <attribute name="name" optional="NO" attributeType="String"/>
        <attribute name="description" optional="YES" attributeType="String"/>
        <attribute name="createdAt" optional="NO" attributeType="Date"/>
    </entity>
</model>
```

**Step 2: Commit**

```bash
git add "apple/langmap/Core Data/LangMap.xcdatamodeld"
git commit -m "feat: add Core Data model for caching"
```

### Task 2: Persistence Controller

**Files:**
- Create: `apple/langmap/Core Data/PersistenceController.swift`

**Step 1: Write Persistence Controller**

```swift
import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LangMap")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add "apple/langmap/Core Data/PersistenceController.swift"
git commit -m "feat: add persistence controller for Core Data"
```

### Task 3: API Response Models

**Files:**
- Create: `apple/langmap/Models/User.swift`
- Create: `apple/langmap/Models/Language.swift`
- Create: `apple/langmap/Models/Expression.swift`
- Create: `apple/langmap/Models/Collection.swift`

**Step 1: Write User model**

```swift
import Foundation

struct User: Codable {
    let id: Int
    let email: String
    let username: String
    let createdAt: String
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct ApiError: Codable {
    let error: String
}
```

**Step 2: Write Language model**

```swift
import Foundation

struct Language: Codable, Identifiable {
    let id: Int
    let code: String
    let name: String
    let nativeName: String?
    let isActive: Int
}
```

**Step 3: Write Expression model**

```swift
import Foundation

struct Expression: Codable, Identifiable {
    let id: Int
    let phrase: String
    let translation: String
    let languageCode: String
    let origin: String?
    let usage: String?
    let createdAt: String
    let language: Language?
}

struct ExpressionListResponse: Codable {
    let data: [Expression]
    let total: Int
    let page: Int
}
```

**Step 4: Write Collection model**

```swift
import Foundation

struct Collection: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let createdAt: String
    let userId: Int
}

struct CollectionDetail: Codable {
    let id: Int
    let name: String
    let description: String?
    let createdAt: String
    let expressions: [Expression]
}
```

**Step 5: Commit**

```bash
git add apple/langmap/Models/
git commit -m "feat: add API response models"
```

### Task 4: Network Service Base

**Files:**
- Create: `apple/langmap/Services/NetworkService.swift`

**Step 1: Write Network Service**

```swift
import Foundation

class NetworkService: ObservableObject {
    static let shared = NetworkService()
    private let baseURL = "https://api.langmap.com/api/v1"

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

    private func createRequest(endpoint: String, method: String = "GET") -> URLRequest {
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
```

**Step 2: Commit**

```bash
git add apple/langmap/Services/NetworkService.swift
git commit -m "feat: add base network service"
```

### Task 5: Keychain Helper

**Files:**
- Create: `apple/langmap/Utils/KeychainHelper.swift`

**Step 1: Write Keychain Helper**

```swift
import Foundation
import Security

class KeychainHelper {
    static func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
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
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/Utils/KeychainHelper.swift
git commit -m "feat: add keychain helper for secure storage"
```

---

## Phase 2: Authentication

### Task 6: Auth Service

**Files:**
- Create: `apple/langmap/Services/AuthService.swift`

**Step 1: Write Auth Service**

```swift
import Foundation

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
        networkService.authToken = response.token
        currentUser = response.user
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
        networkService.authToken = response.token
        currentUser = response.user
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
```

**Step 2: Commit**

```bash
git add apple/langmap/Services/AuthService.swift
git commit -m "feat: add authentication service"
```

### Task 7: Login View

**Files:**
- Create: `apple/langmap/Views/LoginView.swift`

**Step 1: Write Login View**

```swift
import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService()
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showRegister = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo/Title
                Text("LangMap")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Form fields
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                // Login button
                Button(action: handleLogin) {
                    if isLoading {
                        ProgressView()
                            .foregroundColor(.white)
                    } else {
                        Text("Sign In")
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .disabled(isLoading)

                // Register link
                HStack {
                    Text("Don't have an account?")
                    Button(action: { showRegister = true }) {
                        Text("Sign Up")
                            .fontWeight(.bold)
                    }
                }
            }
            .padding()
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }

    private func handleLogin() {
        isLoading = true
        errorMessage = ""

        Task {
            do {
                try await authService.login(email: email, password: password)
                isLoading = false
                presentationMode.wrappedValue.dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/Views/LoginView.swift
git commit -m "feat: add login view"
```

### Task 8: Register View

**Files:**
- Create: `apple/langmap/Views/RegisterView.swift`

**Step 1: Write Register View**

```swift
import SwiftUI

struct RegisterView: View {
    @StateObject private var authService = AuthService()
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: handleRegister) {
                    if isLoading {
                        ProgressView()
                            .foregroundColor(.white)
                    } else {
                        Text("Create Account")
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .disabled(isLoading || !isFormValid)
            }
            .padding()
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !username.isEmpty && !password.isEmpty &&
        password == confirmPassword && password.count >= 6
    }

    private func handleRegister() {
        isLoading = true
        errorMessage = ""

        Task {
            do {
                try await authService.register(email: email, username: username, password: password)
                isLoading = false
                presentationMode.wrappedValue.dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/Views/RegisterView.swift
git commit -m "feat: add register view"
```

---

## Phase 3: Main App Structure

### Task 9: App Entry Point with Auth

**Files:**
- Modify: `apple/langmap/langmapApp.swift`

**Step 1: Update App Entry Point**

```swift
import SwiftUI
import CoreData

@main
struct langmapApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MainTabView()
                    .environmentObject(authService)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/langmapApp.swift
git commit -m "feat: integrate auth flow into app entry point"
```

### Task 10: Main Tab View

**Files:**
- Create: `apple/langmap/Views/MainTabView.swift`

**Step 1: Write Tab View**

```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            CollectionsView()
                .tabItem {
                    Label("Collections", systemImage: "folder.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/Views/MainTabView.swift
git commit -m "feat: add main tab view"
```

---

## Phase 4: Home Feature

### Task 11: Home ViewModel

**Files:**
- Create: `apple/langmap/ViewModels/HomeViewModel.swift`

**Step 1: Write Home ViewModel**

```swift
import Foundation
import CoreData
import SwiftUI

class HomeViewModel: ObservableObject {
    private let networkService = NetworkService.shared
    private let persistenceController = PersistenceController.shared

    @Published var featuredExpressions: [Expression] = []
    @Published var languages: [Language] = []
    @Published var selectedLanguage: Language?
    @Published var isLoading = false
    @Published var errorMessage = ""

    func loadLanguages() {
        isLoading = true

        Task {
            do {
                let request = networkService.createRequest(endpoint: "/languages")
                let response: [Language] = try await networkService.performRequest(request, responseType: [Language].self)

                await MainActor.run {
                    self.languages = response.filter { $0.isActive == 1 }
                    if self.selectedLanguage == nil && !self.languages.isEmpty {
                        self.selectedLanguage = self.languages.first
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func loadFeaturedExpressions() {
        isLoading = true

        Task {
            do {
                var endpoint = "/expressions?limit=10"
                if let langCode = selectedLanguage?.code {
                    endpoint += "&language_code=\(langCode)"
                }

                let request = networkService.createRequest(endpoint: endpoint)
                let response: ExpressionListResponse = try await networkService.performRequest(request, responseType: ExpressionListResponse.self)

                await MainActor.run {
                    self.featuredExpressions = response.data
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/ViewModels/HomeViewModel.swift
git commit -m "feat: add home view model"
```

### Task 12: Home View

**Files:**
- Create: `apple/langmap/Views/HomeView.swift`

**Step 1: Write Home View**

```swift
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Language picker
                    if !viewModel.languages.isEmpty {
                        Picker("Language", selection: $viewModel.selectedLanguage) {
                            ForEach(viewModel.languages) { language in
                                Text(language.nativeName ?? language.name).tag(language as Language?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)
                        .onChange(of: viewModel.selectedLanguage) { _ in
                            viewModel.loadFeaturedExpressions()
                        }
                    }

                    // Featured expressions
                    VStack(alignment: .leading) {
                        Text("Featured Expressions")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if viewModel.featuredExpressions.isEmpty {
                            Text("No expressions found")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(viewModel.featuredExpressions) { expression in
                                NavigationLink(destination: ExpressionDetailView(expression: expression)) {
                                    ExpressionCardView(expression: expression)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("LangMap")
            .onAppear {
                if viewModel.languages.isEmpty {
                    viewModel.loadLanguages()
                }
                if viewModel.featuredExpressions.isEmpty {
                    viewModel.loadFeaturedExpressions()
                }
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/Views/HomeView.swift
git commit -m "feat: add home view"
```

---

## Phase 5: Search Feature

### Task 13: Search ViewModel

**Files:**
- Create: `apple/langmap/ViewModels/SearchViewModel.swift`

**Step 1: Write Search ViewModel**

```swift
import Foundation

class SearchViewModel: ObservableObject {
    private let networkService = NetworkService.shared

    @Published var searchQuery = ""
    @Published var searchResults: [Expression] = []
    @Published var languages: [Language] = []
    @Published var selectedLanguage: Language?
    @Published var isLoading = false

    private var searchTask: Task<Void, Never>?

    func loadLanguages() {
        Task {
            do {
                let request = networkService.createRequest(endpoint: "/languages")
                let response: [Language] = try await networkService.performRequest(request, responseType: [Language].self)

                await MainActor.run {
                    self.languages = response.filter { $0.isActive == 1 }
                }
            } catch {
                print("Failed to load languages: \(error)")
            }
        }
    }

    func search() {
        searchTask?.cancel()

        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        searchTask = Task {
            isLoading = true

            do {
                var endpoint = "/expressions?query=\(searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

                if let langCode = selectedLanguage?.code {
                    endpoint += "&language_code=\(langCode)"
                }

                let request = networkService.createRequest(endpoint: endpoint)
                let response: ExpressionListResponse = try await networkService.performRequest(request, responseType: ExpressionListResponse.self)

                if !Task.isCancelled {
                    await MainActor.run {
                        self.searchResults = response.data
                        self.isLoading = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/ViewModels/SearchViewModel.swift
git commit -m "feat: add search view model"
```

### Task 14: Search View

**Files:**
- Create: `apple/langmap/Views/SearchView.swift`

**Step 1: Write Search View**

```swift
import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search expressions...", text: $viewModel.searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: viewModel.searchQuery) { _ in
                            viewModel.search()
                        }

                    if !viewModel.searchQuery.isEmpty {
                        Button(action: { viewModel.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))

                Divider()

                // Language filter
                if !viewModel.languages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.languages) { language in
                                LanguageFilterView(
                                    language: language,
                                    isSelected: viewModel.selectedLanguage?.id == language.id
                                ) {
                                    withAnimation {
                                        if viewModel.selectedLanguage?.id == language.id {
                                            viewModel.selectedLanguage = nil
                                        } else {
                                            viewModel.selectedLanguage = language
                                        }
                                        viewModel.search()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }

                // Results
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                    Text("No results found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty {
                    Text("Start typing to search")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.searchResults) { expression in
                        NavigationLink(destination: ExpressionDetailView(expression: expression)) {
                            ExpressionCardView(expression: expression)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Search")
            .onAppear {
                if viewModel.languages.isEmpty {
                    viewModel.loadLanguages()
                }
            }
        }
    }
}

struct LanguageFilterView: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(language.nativeName ?? language.name)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/Views/SearchView.swift
git commit -m "feat: add search view"
```

---

## Phase 6: Expression Detail

### Task 15: Expression Detail View

**Files:**
- Create: `apple/langmap/Views/ExpressionDetailView.swift`

**Step 1: Write Expression Detail View**

```swift
import SwiftUI

struct ExpressionDetailView: View {
    let expression: Expression

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Phrase
                Text(expression.phrase)
                    .font(.title)
                    .fontWeight(.bold)

                // Translation
                VStack(alignment: .leading) {
                    Text("Translation")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(expression.translation)
                        .font(.title2)
                }

                // Language
                if let language = expression.language {
                    HStack {
                        Image(systemName: "globe")
                        Text(language.nativeName ?? language.name)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }

                Divider()

                // Origin
                if let origin = expression.origin, !origin.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Origin")
                            .font(.headline)

                        Text(origin)
                            .font(.body)
                    }
                }

                // Usage
                if let usage = expression.usage, !usage.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Usage")
                            .font(.headline)

                        Text(usage)
                            .font(.body)
                    }
                }

                Divider()

                // Date
                HStack {
                    Text("Added on")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formatDate(expression.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Expression")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return dateString
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/Views/ExpressionDetailView.swift
git commit -m "feat: add expression detail view"
```

---

## Phase 7: Shared Components

### Task 16: Expression Card Component

**Files:**
- Create: `apple/langmap/Views/ExpressionCardView.swift`

**Step 1: Write Expression Card**

```swift
import SwiftUI

struct ExpressionCardView: View {
    let expression: Expression

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(expression.phrase)
                .font(.headline)

            Text(expression.translation)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let language = expression.language {
                HStack {
                    Image(systemName: "globe")
                        .font(.caption)
                    Text(language.nativeName ?? language.name)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/Views/ExpressionCardView.swift
git commit -m "feat: add expression card component"
```

---

## Phase 8: Collections Feature

### Task 17: Collections ViewModel

**Files:**
- Create: `apple/langmap/ViewModels/CollectionsViewModel.swift`

**Step 1: Write Collections ViewModel**

```swift
import Foundation

class CollectionsViewModel: ObservableObject {
    private let networkService = NetworkService.shared

    @Published var collections: [Collection] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showCreateCollection = false

    func loadCollections() {
        isLoading = true

        Task {
            do {
                let request = networkService.createRequest(endpoint: "/collections")
                let response: [Collection] = try await networkService.performRequest(request, responseType: [Collection].self)

                await MainActor.run {
                    self.collections = response
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func createCollection(name: String, description: String) async throws {
        var request = networkService.createRequest(endpoint: "/collections", method: "POST")

        let collectionData: [String: Any] = [
            "name": name,
            "description": description
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: collectionData)

        let _: Collection = try await networkService.performRequest(request, responseType: Collection.self)
        await loadCollections()
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/ViewModels/CollectionsViewModel.swift
git commit -m "feat: add collections view model"
```

### Task 18: Collections View

**Files:**
- Create: `apple/langmap/Views/CollectionsView.swift`

**Step 1: Write Collections View**

```swift
import SwiftUI

struct CollectionsView: View {
    @StateObject private var viewModel = CollectionsViewModel()
    @State private var showingCreateCollection = false
    @State private var newCollectionName = ""
    @State private var newCollectionDescription = ""

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.collections.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No collections yet")
                            .font(.title2)
                            .foregroundColor(.secondary)

                        Text("Create your first collection to save expressions")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(viewModel.collections) { collection in
                        NavigationLink(destination: CollectionDetailView(collectionId: collection.id)) {
                            CollectionCardView(collection: collection)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateCollection = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateCollection) {
                CreateCollectionSheet(
                    isPresented: $showingCreateCollection,
                    name: $newCollectionName,
                    description: $newCollectionDescription,
                    onCreate: handleCreateCollection
                )
            }
            .onAppear {
                if viewModel.collections.isEmpty {
                    viewModel.loadCollections()
                }
            }
        }
    }

    private func handleCreateCollection() {
        Task {
            do {
                try await viewModel.createCollection(
                    name: newCollectionName,
                    description: newCollectionDescription
                )
                newCollectionName = ""
                newCollectionDescription = ""
                showingCreateCollection = false
            } catch {
                print("Failed to create collection: \(error)")
            }
        }
    }
}

struct CollectionCardView: View {
    let collection: Collection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(collection.name)
                .font(.headline)

            if let description = collection.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/Views/CollectionsView.swift
git commit -m "feat: add collections view"
```

### Task 19: Create Collection Sheet

**Files:**
- Create: `apple/langmap/Views/CreateCollectionSheet.swift`

**Step 1: Write Create Collection Sheet**

```swift
import SwiftUI

struct CreateCollectionSheet: View {
    @Binding var isPresented: Bool
    @Binding var name: String
    @Binding var description: String
    let onCreate: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Collection Info")) {
                    TextField("Name", text: $name)

                    TextField("Description (optional)", text: $description)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        onCreate()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/Views/CreateCollectionSheet.swift
git commit -m "feat: add create collection sheet"
```

### Task 20: Collection Detail View

**Files:**
- Create: `apple/langmap/Views/CollectionDetailView.swift`

**Step 1: Write Collection Detail View**

```swift
import SwiftUI

struct CollectionDetailView: View {
    let collectionId: Int
    @State private var collection: CollectionDetail?
    @State private var isLoading = true
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let collection = collection {
                List(collection.expressions) { expression in
                    NavigationLink(destination: ExpressionDetailView(expression: expression)) {
                        ExpressionCardView(expression: expression)
                    }
                }
                .listStyle(PlainListStyle())
            } else {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(collection?.name ?? "Collection")
        .onAppear {
            loadCollection()
        }
    }

    private func loadCollection() {
        isLoading = true

        Task {
            do {
                let request = NetworkService.shared.createRequest(endpoint: "/collections/\(collectionId)")
                let response: CollectionDetail = try await NetworkService.shared.performRequest(request, responseType: CollectionDetail.self)

                await MainActor.run {
                    self.collection = response
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/Views/CollectionDetailView.swift
git commit -m "feat: add collection detail view"
```

---

## Phase 9: Profile Feature

### Task 21: Profile View

**Files:**
- Create: `apple/langmap/Views/ProfileView.swift`

**Step 1: Write Profile View**

```swift
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    if let user = authService.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading) {
                                Text(user.username)
                                    .font(.headline)

                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "person.circle")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)

                            Text("Guest")
                                .font(.headline)
                        }
                    }
                }

                Section("Settings") {
                    HStack {
                        Image(systemName: "globe")
                        Text("Language")
                        Spacer()
                        Text("English")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "bell")
                        Text("Notifications")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("About LangMap")
                    }

                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Help & Support")
                    }

                    HStack {
                        Image(systemName: "star")
                        Text("Rate App")
                    }
                }

                Section {
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                            Text("Log Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    authService.logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add apple/langmap/Views/ProfileView.swift
git commit -m "feat: add profile view"
```

---

## Phase 10: Localization

### Task 22: Localization Setup

**Files:**
- Create: `apple/langmap/Resources/en-US.json`
- Create: `apple/langmap/Resources/LocalizationManager.swift`

**Step 1: Create English localization file**

```json
{
  "app_name": "LangMap",
  "nav_home": "Home",
  "nav_search": "Search",
  "nav_collections": "Collections",
  "nav_profile": "Profile",
  "login_title": "Sign In",
  "login_subtitle": "Sign in to continue",
  "email": "Email",
  "password": "Password",
  "sign_in": "Sign In",
  "dont_have_account": "Don't have an account?",
  "sign_up": "Sign Up",
  "create_account": "Create Account",
  "username": "Username",
  "confirm_password": "Confirm Password",
  "search_placeholder": "Search expressions...",
  "no_results": "No results found",
  "featured_expressions": "Featured Expressions",
  "language": "Language",
  "translation": "Translation",
  "origin": "Origin",
  "usage": "Usage",
  "added_on": "Added on",
  "no_collections": "No collections yet",
  "create_first_collection": "Create your first collection to save expressions",
  "new_collection": "New Collection",
  "collection_name": "Name",
  "collection_description": "Description (optional)",
  "logout": "Log Out",
  "logout_confirmation": "Are you sure you want to log out?"
}
```

**Step 2: Create Localization Manager**

```swift
import Foundation

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
        // Load English first (default)
        if let path = Bundle.main.path(forResource: "en-US", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            localizations["en-US"] = json
        }

        // Load other languages as needed
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
```

**Step 3: Commit**

```bash
git add apple/langmap/Resources/
git commit -m "feat: add localization infrastructure"
```

---

## Testing

### Task 23: Network Service Tests

**Files:**
- Create: `apple/langmapTests/NetworkServiceTests.swift`

**Step 1: Write Network Service Tests**

```swift
import XCTest
@testable import langmap

class NetworkServiceTests: XCTestCase {
    var networkService: NetworkService!

    override func setUp() {
        super.setUp()
        networkService = NetworkService.shared
    }

    override func tearDown() {
        networkService = nil
        super.tearDown()
    }

    func testCreateRequest() {
        let request = networkService.createRequest(endpoint: "/test", method: "POST")

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testRequestWithAuthToken() {
        networkService.authToken = "test-token"
        let request = networkService.createRequest(endpoint: "/test")

        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
    }
}
```

**Step 2: Run tests**

```bash
cd apple && xcodebuild test -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Step 3: Commit**

```bash
git add apple/langmapTests/NetworkServiceTests.swift
git commit -m "test: add network service tests"
```

### Task 24: ViewModel Tests

**Files:**
- Create: `apple/langmapTests/HomeViewModelTests.swift`

**Step 1: Write Home ViewModel Tests**

```swift
import XCTest
@testable import langmap

class HomeViewModelTests: XCTestCase {
    var viewModel: HomeViewModel!

    override func setUp() {
        super.setUp()
        viewModel = HomeViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertTrue(viewModel.featuredExpressions.isEmpty)
        XCTAssertTrue(viewModel.languages.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadLanguages() {
        viewModel.loadLanguages()

        // Wait for async operation
        let expectation = XCTestExpectation(description: "Load languages")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }
}
```

**Step 2: Run tests**

```bash
cd apple && xcodebuild test -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Step 3: Commit**

```bash
git add apple/langmapTests/HomeViewModelTests.swift
git commit -m "test: add home view model tests"
```

---

## Final Steps

### Task 25: Build and Verify

**Step 1: Build the project**

```bash
cd apple
xcodebuild -scheme langmap -configuration Debug build
```

**Expected:** Build succeeds with no errors

**Step 2: Run all tests**

```bash
xcodebuild test -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Expected:** All tests pass

**Step 3: Verify build**

```bash
ls -la build/Debug-iphoneos/
```

**Expected:** langmap.app exists

**Step 4: Commit**

```bash
git add .
git commit -m "build: verify iOS app builds successfully"
```

### Task 26: Documentation

**Files:**
- Create: `apple/README.md`

**Step 1: Write README**

```markdown
# LangMap iOS App

Native iOS application for LangMap language map.

## Prerequisites

- Xcode 15+
- iOS 15.0+ deployment target
- macOS 13+ (Ventura)

## Setup

1. Open `apple/langmap.xcodeproj` in Xcode
2. Select your development team in signing settings
3. Build and run (Cmd+R)

## Architecture

- **MVVM Pattern**: Separates UI from business logic
- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Offline caching
- **URLSession**: API networking

## Testing

Run tests: Cmd+U in Xcode or:

```bash
xcodebuild test -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Building for App Store

1. Select Release configuration
2. Update version and build numbers
3. Archive: Product > Archive
4. Upload to App Store Connect
```

**Step 2: Commit**

```bash
git add apple/README.md
git commit -m "docs: add iOS app README"
```

---

## Summary

This implementation plan covers:

✅ Core Data setup for offline caching
✅ Network service for API communication
✅ Authentication flow (login/register)
✅ Home screen with featured expressions
✅ Search functionality with filters
✅ Expression detail view
✅ Collections management
✅ User profile
✅ Localization infrastructure
✅ Unit tests for critical components
✅ Build verification
✅ Documentation

**Total tasks:** 26
**Estimated time:** 20-30 hours for complete implementation
**Target iOS version:** 15.0+
**Test coverage:** Core services and ViewModels
