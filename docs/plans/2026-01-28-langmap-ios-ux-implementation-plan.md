# LangMap iOS UX Optimization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the new UX design for LangMap iOS app with simplified navigation, global FAB, and optimized screens for search, collections, and profile.

**Architecture:** Incremental refactoring of existing SwiftUI views, introducing new components while maintaining backward compatibility. Follow iOS design guidelines with focus on three core user flows: search, add expressions, manage collections.

**Tech Stack:** SwiftUI, iOS 17+, Combine, CoreLocation for geolocation, UserDefaults for caching.

---

## Pre-requisites

**Design Document to Review:**
- `docs/plans/2026-01-28-langmap-ios-ux-design.md` - Complete UX specifications

**Existing Codebase Structure:**
- `apple/langmap/Views/` - All SwiftUI views
- `apple/langmap/ViewModels/` - View models
- `apple/langmap/LMGlobals.swift` - Shared components, theme, services
- `apple/langmap/Resources/en-US.json` - Localization strings

---

## Task 1: Create Visual Design System Components

**Goal:** Establish the visual foundation with colors, gradients, spacing, and typography constants.

**Files:**
- Create: `apple/langmap/Views/Components/DesignSystem.swift`
- Create: `apple/langmap/Views/Components/GradientBackground.swift`
- Modify: `apple/langmap/LMGlobals.swift:416-427`

**Step 1: Write design system constants**

```swift
import SwiftUI

// MARK: - Spacing System
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Border Radius
struct AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 20
}

// MARK: - Touch Targets
struct AppTouchTarget {
    static let minSize: CGFloat = 44
}
```

**Step 2: Run SwiftLint to verify no syntax errors**

Run: `xcodebuild -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15' clean build`
Expected: Build succeeds or shows expected compilation errors for missing components

**Step 3: Update LMGlobals with enhanced theme**

Add to `LMGlobals.swift` in the Theme section (around line 416):

```swift
// MARK: - Enhanced Theme

struct AppTheme {
    static let primaryGradient: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "6366f1"),
            Color(hex: "a855f7")
        ]),
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
```

**Step 4: Run build to verify changes**

Run: `xcodebuild -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: Build succeeds

**Step 5: Commit**

```bash
git add apple/langmap/Views/Components/DesignSystem.swift apple/langmap/LMGlobals.swift
git commit -m "feat: add visual design system foundation

- Spacing system constants
- Border radius definitions
- Enhanced AppTheme with animations
- HapticFeedback utility"
```

---

## Task 2: Create Reusable UI Components

**Goal:** Build reusable components used across multiple screens: glass cards, primary buttons, and skeleton loaders.

**Files:**
- Create: `apple/langmap/Views/Components/GlassCard.swift`
- Create: `apple/langmap/Views/Components/PrimaryButton.swift`
- Create: `apple/langmap/Views/Components/SkeletonView.swift`

**Step 1: Create GlassCard component**

```swift
import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat

    init(padding: CGFloat = AppSpacing.lg,
         cornerRadius: CGFloat = AppRadius.large,
         @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
    }
}

struct GlassCardModifier: ViewModifier {
    let padding: CGFloat
    let cornerRadius: CGFloat

    init(padding: CGFloat = AppSpacing.lg,
         cornerRadius: CGFloat = AppRadius.large) {
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        GlassCard(padding: padding, cornerRadius: cornerRadius) {
            content
        }
    }
}

extension View {
    func glassCard(padding: CGFloat = AppSpacing.lg,
                   cornerRadius: CGFloat = AppRadius.large) -> some View {
        modifier(GlassCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}
```

**Step 2: Create PrimaryButton component**

```swift
import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    let isDisabled: Bool
    let isLoading: Bool

    init(title: String,
         isDisabled: Bool = false,
         isLoading: Bool = false,
         action: @escaping () -> Void) {
        self.title = title
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.system(.body, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(height: AppTouchTarget.minSize)
            .frame(maxWidth: .infinity)
            .background(
                isDisabled ? Color.gray.opacity(0.3) : AppTheme.primaryGradient
            )
            .cornerRadius(AppRadius.medium)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(AppTheme.standardSpring, value: isPressed)
        }
        .disabled(isDisabled || isLoading)
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.body, weight: .semibold))
                .foregroundColor(.primary)
                .frame(height: AppTouchTarget.minSize)
                .frame(maxWidth: .infinity)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(AppRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

**Step 3: Create SkeletonView component**

```swift
import SwiftUI

struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: AppRadius.medium)
            .fill(Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
            )
            .clipped()
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}
```

**Step 4: Build to verify components compile**

Run: `xcodebuild -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: Build succeeds, no compilation errors

**Step 5: Commit**

```bash
git add apple/langmap/Views/Components/
git commit -m "feat: add reusable UI components

- GlassCard with glassmorphism effect
- PrimaryButton with gradient and loading state
- SkeletonView for loading placeholders"
```

---

## Task 3: Refactor MainTabView Navigation Structure

**Goal:** Update tab navigation from 4 tabs to 3 tabs, update icons and labels.

**Files:**
- Modify: `apple/langmap/Views/MainTabView.swift`
- Modify: `apple/langmap/Resources/en-US.json`

**Step 1: Update localization strings**

Add to `en-US.json`:

```json
{
  "nav_explore": "Explore",
  "no_collections": "No collections yet",
  "create_first_collection": "Create your first collection to save expressions",
  "start_exploring": "Start Exploring",
  "search_or_add_hint": "Search expressions or add new ones",
  "total_contributions": "Total Contributions",
  "remembered_last_selection": "Last selection remembered",
  "locating": "Locating...",
  "location_failed": "Location failed, enter manually",
  "manual_location_placeholder": "e.g., Beijing, New York",
  "search_to_associate": "Search expression to associate",
  "add_success": "Added successfully",
  "add_new_expression": "Add New Expression"
}
```

**Step 2: Refactor MainTabView**

```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Label("nav_explore".localized, systemImage: "magnifyingglass.circle.fill")
                }

            CollectionsView()
                .tabItem {
                    Label("nav_collections".localized, systemImage: "folder.fill")
                }

            ProfileView()
                .tabItem {
                    Label("nav_profile".localized, systemImage: "person.fill")
                }
        }
    }
}
```

**Step 3: Build to verify tab structure**

Run: `xcodebuild -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: Build succeeds (will have errors for missing ExploreView)

**Step 4: Commit**

```bash
git add apple/langmap/Views/MainTabView.swift apple/langmap/Resources/en-US.json
git commit -m "refactor: update navigation structure

- Change from 4 tabs to 3 tabs
- Rename Home to Explore
- Update icons and labels
- Add new localization strings"
```

---

## Task 4: Create ExploreView (Refactored Home)

**Goal:** Create new ExploreView with search-first design, language filter, and optimized card layout.

**Files:**
- Create: `apple/langmap/Views/ExploreView.swift`
- Create: `apple/langmap/ViewModels/ExploreViewModel.swift`
- Modify: `apple/langmap/Views/Components/LanguageFilterChip.swift`

**Step 1: Create ExploreViewModel**

```swift
import Foundation
import Combine

class ExploreViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [LMLexiconExpression] = []
    @Published var selectedLanguage: LMLexiconLanguage?
    @Published var languages: [LMLexiconLanguage] = []
    @Published var isLoading: Bool = false
    @Published var featuredExpressions: [LMLexiconExpression] = []

    private var cancellables = Set<AnyCancellable>()
    private var searchWorkItem: DispatchWorkItem?

    init() {
        setupSearchDebounce()
    }

    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.performSearch()
            }
            .store(in: &cancellables)
    }

    func loadLanguages() {
        isLoading = true
        Task {
            do {
                let request = NetworkService.shared.createRequest(endpoint: "/languages")
                let response: [LMLexiconLanguage] = try await NetworkService.shared.performRequest(
                    request, responseType: [LMLexiconLanguage].self
                )
                await MainActor.run {
                    self.languages = response
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    func loadFeaturedExpressions() {
        isLoading = true
        Task {
            do {
                var endpoint = "/expressions/featured"
                if let languageId = selectedLanguage?.id {
                    endpoint += "?language_id=\(languageId)"
                }
                let request = NetworkService.shared.createRequest(endpoint: endpoint)
                let response: [LMLexiconExpression] = try await NetworkService.shared.performRequest(
                    request, responseType: [LMLexiconExpression].self
                )
                await MainActor.run {
                    self.featuredExpressions = response
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    private func performSearch() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        searchWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            Task {
                var endpoint = "/expressions/search?q=\(self.searchQuery)"
                if let languageId = self.selectedLanguage?.id {
                    endpoint += "&language_id=\(languageId)"
                }

                do {
                    let request = NetworkService.shared.createRequest(endpoint: endpoint)
                    let response: [LMLexiconExpression] = try await NetworkService.shared.performRequest(
                        request, responseType: [LMLexiconExpression].self
                    )
                    await MainActor.run {
                        self.searchResults = response
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            }
        }

        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    func toggleLanguage(_ language: LMLexiconLanguage) {
        if selectedLanguage?.id == language.id {
            selectedLanguage = nil
        } else {
            selectedLanguage = language
        }
        performSearch()
    }
}
```

**Step 2: Create LanguageFilterChip component**

```swift
import SwiftUI

struct LanguageFilterChip: View {
    let language: LMLexiconLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            Text(language.nativeName ?? language.name)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    isSelected
                        ? AnyShapeStyle(AppTheme.primaryGradient)
                        : AnyShapeStyle(Color.primary.opacity(0.05))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(AppRadius.large)
                .shadow(
                    color: isSelected ? Color(hex: "6366f1").opacity(0.3) : Color.clear,
                    radius: 5, x: 0, y: 3
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

**Step 3: Create ExploreView**

```swift
import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    searchBar

                    if !searchResults.isEmpty {
                        searchResultsList
                    } else if !searchQuery.isEmpty {
                        noResultsView
                    } else {
                        featuredContent
                    }

                    Spacer()

                    // FAB will be overlayed from TabView
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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

    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.accentColor)

            TextField("search_placeholder".localized, text: $viewModel.searchQuery)
                .textFieldStyle(PlainTextFieldStyle())

            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    withAnimation {
                        viewModel.searchQuery = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.extraLarge)
                .fill(UltraThinMaterial())
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }

    private var featuredContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Language Filter
                if !viewModel.languages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            LanguageFilterChip(
                                language: LMLexiconLanguage(
                                    id: 0, code: "all", name: "全部",
                                    direction: "ltr", family: nil,
                                    notes: nil, isActive: 1, regionCode: nil,
                                    regionName: nil, regionLatitude: nil,
                                    regionLongitude: nil, createdBy: nil,
                                    createdAt: "", updatedAt: nil
                                ),
                                isSelected: viewModel.selectedLanguage == nil
                            ) {
                                viewModel.selectedLanguage = nil
                                viewModel.loadFeaturedExpressions()
                            }

                            ForEach(viewModel.languages) { language in
                                LanguageFilterChip(
                                    language: language,
                                    isSelected: viewModel.selectedLanguage?.id == language.id
                                ) {
                                    viewModel.toggleLanguage(language)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                    .padding(.bottom, AppSpacing.sm)
                }

                // Featured Expressions
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("featured_expressions".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, AppSpacing.lg)

                    if viewModel.isLoading {
                        VStack(spacing: AppSpacing.cardSpacing) {
                            ForEach(0..<5) { _ in
                                SkeletonView()
                                    .frame(height: 80)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    } else if viewModel.featuredExpressions.isEmpty {
                        emptyStateView
                    } else {
                        VStack(spacing: AppSpacing.cardSpacing) {
                            ForEach(viewModel.featuredExpressions) { expression in
                                NavigationLink(
                                    destination: ExpressionDetailView(expression: expression)
                                ) {
                                    OptimizedExpressionCard(expression: expression)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                }
            }
            .padding(.bottom, 80) // Space for FAB
        }
    }

    private var searchResultsList: some View {
        List {
            ForEach(viewModel.searchResults) { expression in
                NavigationLink(
                    destination: ExpressionDetailView(expression: expression)
                ) {
                    OptimizedExpressionCard(expression: expression)
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(.plain)
    }

    private var noResultsView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("no_results".localized)
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Can't find what you're looking for? Add a new expression!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("start_exploring".localized)
                .font(.title2)
                .foregroundColor(.secondary)

            Text("search_or_add_hint".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
    }
}

struct OptimizedExpressionCard: View {
    let expression: LMLexiconExpression
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(expression.text)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if let region = expression.regionName {
                    Text(region)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(expression.languageCode.uppercased())
                .font(.system(.caption2, design: .monospaced))
                .fontWeight(.heavy)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(AppTheme.primaryGradient)
                .foregroundColor(.white)
                .cornerRadius(AppRadius.small)
        }
        .padding(AppSpacing.lg)
        .frame(minHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppTheme.easeInOut, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation {
                isPressed = pressing
            }
        }, perform: {
            HapticFeedback.light()
        })
    }
}
```

**Step 4: Build to verify ExploreView**

Run: `xcodebuild -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: Build succeeds

**Step 5: Commit**

```bash
git add apple/langmap/Views/ExploreView.swift apple/langmap/ViewModels/ExploreViewModel.swift apple/langmap/Views/Components/LanguageFilterChip.swift
git commit -m "feat: implement ExploreView with search-first design

- Add search bar with debounce
- Implement language filter chips
- Create optimized expression card
- Add empty states and loading states
- Refactor from HomeView"
```

---

## Task 5: Add Global Floating Action Button (FAB)

**Goal:** Implement global FAB that appears on all tabs for quick access to add expression.

**Files:**
- Create: `apple/langmap/Views/Components/FloatingActionButton.swift`
- Modify: `apple/langmap/Views/MainTabView.swift`

**Step 1: Create FAB component**

```swift
import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            action()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(AppTheme.primaryGradient)
                .clipShape(Circle())
                .shadow(color: Color(hex: "6366f1").opacity(0.4), radius: 12, x: 0, y: 6)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(AppTheme.standardSpring) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
```

**Step 2: Update MainTabView to include FAB**

```swift
import SwiftUI

struct MainTabView: View {
    @State private var showingAddExpression = false

    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Label("nav_explore".localized, systemImage: "magnifyingglass.circle.fill")
                }
                .overlay(alignment: .bottomTrailing) {
                    FloatingActionButton {
                        showingAddExpression = true
                    }
                    .padding(20)
                }

            CollectionsView()
                .tabItem {
                    Label("nav_collections".localized, systemImage: "folder.fill")
                }
                .overlay(alignment: .bottomTrailing) {
                    FloatingActionButton {
                        showingAddExpression = true
                    }
                    .padding(20)
                }

            ProfileView()
                .tabItem {
                    Label("nav_profile".localized, systemImage: "person.fill")
                }
                .overlay(alignment: .bottomTrailing) {
                    FloatingActionButton {
                        showingAddExpression = true
                    }
                    .padding(20)
                }
        }
        .sheet(isPresented: $showingAddExpression) {
            AddExpressionSheet(isPresented: $showingAddExpression)
        }
    }
}
```

**Step 3: Build to verify FAB integration**

Run: `xcodebuild -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: Build succeeds (will have error for missing AddExpressionSheet)

**Step 4: Commit**

```bash
git add apple/langmap/Views/Components/FloatingActionButton.swift apple/langmap/Views/MainTabView.swift
git commit -m "feat: add global floating action button

- Implement FAB with gradient and animation
- Add FAB to all three tabs
- Add sheet presentation hook"
```

---

## Task 6: Implement AddExpressionSheet

**Goal:** Create comprehensive add expression form with auto-location, language caching, tags, and single expression association.

**Files:**
- Create: `apple/langmap/Views/AddExpressionSheet.swift`
- Create: `apple/langmap/ViewModels/AddExpressionViewModel.swift`

**Step 1: Create AddExpressionViewModel**

```swift
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
            onUpdate: { [weak self] location in
                self?.reverseGeocode(location)
            },
            onError: { [weak self] error in
                self?.isLocating = false
            }
        )
    }

    func requestLocation() {
        guard CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
                CLLocationManager.authorizationStatus() == .authorizedAlways else {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        isLocating = true
        locationManager.requestLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
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

    func searchAssociations(query: String) {
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
```

**Step 2: Create AddExpressionSheet view**

```swift
import SwiftUI

struct AddExpressionSheet: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = AddExpressionViewModel()
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                // Expression Text
                Section {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Expression")
                            .font(.headline)

                        TextEditor(text: $viewModel.expressionText)
                            .frame(minHeight: 60, maxHeight: 150)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.small)
                                    .stroke(viewModel.expressionTextError != nil ? Color.red : Color.clear, lineWidth: 1)
                            )

                        if let error = viewModel.expressionTextError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        HStack {
                            Spacer()
                            Text("\(viewModel.expressionText.count)/500")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Language Selection
                Section {
                    Picker("Language", selection: $viewModel.selectedLanguage) {
                        ForEach(viewModel.languages) { language in
                            Text("\(language.nativeName ?? language.name) (\(language.code))")
                                .tag(language as LMLexiconLanguage?)
                        }
                    }
                    .pickerStyle(.menuPickerStyle())

                    if viewModel.selectedLanguage != nil {
                        Text("remembered_last_selection".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Region
                Section(header: Text("Region").font(.headline)) {
                    if viewModel.isLocating {
                        HStack {
                            ProgressView()
                            Text("locating".localized)
                        }
                    } else if !viewModel.region.isEmpty {
                        HStack {
                            Text(viewModel.region)
                            Spacer()
                            Button(action: viewModel.requestLocation) {
                                Image(systemName: "arrow.clockwise")
                            }
                            Button(action: { viewModel.region = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        Button(action: viewModel.requestLocation) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Use current location")
                            }
                        }
                    }
                }

                // Tags
                Section(header: Text("Tags (Optional)").font(.headline)) {
                    HStack {
                        TextField("Add tag", text: $viewModel.currentTagInput)
                            .onSubmit {
                                viewModel.addTag()
                            }

                        Button(action: viewModel.addTag) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(viewModel.currentTagInput.isEmpty)
                    }

                    if !viewModel.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(viewModel.tags, id: \.self) { tag in
                                    TagChip(tag: tag) {
                                        viewModel.removeTag(tag)
                                    }
                                }
                            }
                        }
                    }

                    Text("Max 5 tags, 20 characters each")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Associated Expression
                Section(header: Text("Associate with Expression (Optional)").font(.headline)) {
                    if let associated = viewModel.associatedExpression {
                        VStack {
                            OptimizedExpressionCard(expression: associated)
                            Button(action: viewModel.clearAssociation) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                    Text("Remove association")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            TextField("search_to_associate".localized, text: $viewModel.searchQuery)
                                .onChange(of: viewModel.searchQuery) { _, newValue in
                                    viewModel.searchAssociations(query: newValue)
                                }

                            if !viewModel.searchAssociations.isEmpty {
                                VStack(spacing: AppSpacing.xs) {
                                    ForEach(viewModel.searchAssociations) { expression in
                                        Button(action: {
                                            viewModel.selectAssociation(expression)
                                        }) {
                                            HStack {
                                                Text(expression.text)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                            }
                                            .padding(AppSpacing.sm)
                                            .background(Color.primary.opacity(0.05))
                                            .cornerRadius(AppRadius.small)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("add_new_expression".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("save".localized) {
                        submitExpression()
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    @State private var searchQuery: String = ""

    private func submitExpression() {
        Task {
            do {
                try await viewModel.submit()
                await MainActor.run {
                    isPresented = false
                    // Show success toast
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

struct TagChip: View {
    let tag: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(tag)
                .font(.caption)

            Button(action: action) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(Color.primary.opacity(0.1))
        .cornerRadius(AppRadius.small)
    }
}
```

**Step 3: Build to verify AddExpressionSheet**

Run: `xcodebuild -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: Build succeeds

**Step 4: Add location permission to Info.plist**

Add to `Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to tag expressions with geographical context.</string>
```

**Step 5: Commit**

```bash
git add apple/langmap/Views/AddExpressionSheet.swift apple/langmap/ViewModels/AddExpressionViewModel.swift
git commit -m "feat: implement add expression sheet

- Complete form with all required fields
- Auto-location with CoreLocation
- Language selection caching
- Tag management (max 5)
- Single expression association
- Form validation and error handling"
```

---

## Task 7: Refactor CollectionsView with Grid Layout

**Goal:** Update CollectionsView to use two-column grid layout with improved cards.

**Files:**
- Modify: `apple/langmap/Views/CollectionsView.swift`
- Modify: `apple/langmap/ViewModels/CollectionsViewModel.swift`

**Step 1: Update CollectionsViewModel**

Add contribution count property:

```swift
class CollectionsViewModel: ObservableObject {
    // ... existing properties ...

    @Published var contributionCount: Int = 0

    func loadCollections() {
        // ... existing code ...

        // Add contribution count loading
        loadContributionCount()
    }

    func loadContributionCount() {
        Task {
            do {
                let request = NetworkService.shared.createRequest(endpoint: "/user/contributions/count")
                let response: [String: Int] = try await NetworkService.shared.performRequest(
                    request, responseType: [String: Int].self
                )
                await MainActor.run {
                    self.contributionCount = response["count"] ?? 0
                }
            } catch {
                // Handle error
            }
        }
    }
}
```

**Step 2: Refactor CollectionsView**

```swift
import SwiftUI

struct CollectionsView: View {
    @StateObject private var viewModel = CollectionsViewModel()
    @State private var showingCreateCollection = false
    @State private var newCollectionName = ""
    @State private var newCollectionDescription = ""
    @State private var showingDeleteAlert = false
    @State private var collectionToDelete: LMCollection?

    let columns = [
        GridItem(.flexible(), spacing: AppSpacing.cardSpacing),
        GridItem(.flexible(), spacing: AppSpacing.cardSpacing)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else if !viewModel.errorMessage.isEmpty {
                    errorView
                } else if viewModel.collections.isEmpty {
                    emptyStateView
                } else {
                    collectionsGrid
                }
            }
            .navigationTitle("nav_collections".localized)
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
            .alert("Delete Collection", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let collection = collectionToDelete {
                        deleteCollection(collection)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this collection?")
            }
            .onAppear {
                if viewModel.collections.isEmpty {
                    viewModel.loadCollections()
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
            Text("Loading collections...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text(viewModel.errorMessage)
                .multilineTextAlignment(.center)
                .padding()

            Button("Retry") {
                viewModel.loadCollections()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("no_collections".localized)
                .font(.title2)
                .foregroundColor(.secondary)

            Text("create_first_collection".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
    }

    private var collectionsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppSpacing.cardSpacing) {
                ForEach(viewModel.collections) { collection in
                    CollectionCard(collection: collection) {
                        // Navigate to collection detail
                    } onDelete: {
                        collectionToDelete = collection
                        showingDeleteAlert = true
                    }
                }
            }
            .padding(AppSpacing.lg)
            .padding(.bottom, 80) // Space for FAB
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

    private func deleteCollection(_ collection: LMCollection) {
        Task {
            do {
                try await viewModel.deleteCollection(collection.id)
                collectionToDelete = nil
            } catch {
                print("Failed to delete collection: \(error)")
            }
        }
    }
}

struct CollectionCard: View {
    let collection: LMCollection
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var showingMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header with gradient
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: gradientColors.randomElement() ?? "6366f1"),
                        Color(hex: gradientColors.randomElement() ?? "a855f7")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 60)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(collection.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack {
                        Spacer()
                        Menu {
                            Button(action: {}) {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive, action: onDelete) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(AppSpacing.md)
            }

            // Body
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                if let description = collection.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text("\(collection.items?.count ?? 0) items")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(AppRadius.small)
            }
            .padding(AppSpacing.md)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(AppRadius.large)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .onTapGesture {
            onTap()
        }
    }
}

private let gradientColors = ["6366f1", "a855f7", "ec4899", "f59e0b", "10b981", "3b82f6"]
```

**Step 3: Add delete method to CollectionsViewModel**

```swift
func deleteCollection(_ collectionId: Int) async throws {
    let request = NetworkService.shared.createRequest(
        endpoint: "/collections/\(collectionId)",
        method: "DELETE"
    )
    let _: EmptyResponse = try await NetworkService.shared.performRequest(
        request, responseType: EmptyResponse.self
    )
    await MainActor.run {
        collections.removeAll { $0.id == collectionId }
    }
}

struct EmptyResponse: Codable {}
```

**Step 4: Build to verify CollectionsView changes**

Run: `xcodebuild -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: Build succeeds

**Step 5: Commit**

```bash
git add apple/langmap/Views/CollectionsView.swift apple/langmap/ViewModels/CollectionsViewModel.swift
git commit -m "refactor: update CollectionsView with grid layout

- Implement two-column LazyVGrid
- Add gradient header to collection cards
- Add delete functionality with confirmation
- Improve empty state and loading states"
```

---

## Task 8: Refactor ProfileView with Contribution Stats

**Goal:** Update ProfileView to show user info, contribution count (only), and settings list.

**Files:**
- Modify: `apple/langmap/Views/ProfileView.swift`
- Modify: `apple/langmap/ViewModels/CollectionsViewModel.swift` (reuse loadContributionCount)

**Step 1: Update ProfileView**

```swift
import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingLogoutAlert = false
    @State private var contributionCount: Int = 0

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // User Header
                        VStack(spacing: AppSpacing.md) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.accentColor)

                            Text(authService.currentUser?.username ?? "")
                                .font(.title)
                                .fontWeight(.bold)

                            Text(authService.currentUser?.email ?? "")
                                .font(.body)
                                .foregroundColor(.secondary)

                            if let role = authService.currentUser?.role {
                                Text(role.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(Color.primary.opacity(0.1))
                                    .cornerRadius(AppRadius.small)
                            }
                        }
                        .padding(.top, AppSpacing.xl)

                        // Contribution Stats
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("total_contributions".localized)
                                .font(.headline)

                            GlassCard {
                                HStack {
                                    Spacer()
                                    Text("\(contributionCount)")
                                        .font(.system(size: 48, weight: .bold))
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        // Settings List
                        VStack(spacing: 0) {
                            SettingsRow(icon: "globe", title: "Language Preferences") {}
                            Divider().padding(.leading, 50)
                            SettingsRow(icon: "bell", title: "Notifications") {}
                            Divider().padding(.leading, 50)
                            SettingsRow(icon: "info.circle", title: "About") {}
                            Divider().padding(.leading, 50)
                            SettingsRow(icon: "hand.raised", title: "Privacy Policy") {}
                        }
                        .glassCard()
                        .padding(.horizontal, AppSpacing.lg)

                        // Logout Button
                        Button(action: { showingLogoutAlert = true }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("logout".localized)
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(AppRadius.medium)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.xl)
                    }
                }
            }
            .navigationTitle("nav_profile".localized)
            .alert("logout".localized, isPresented: $showingLogoutAlert) {
                Button("logout".localized, role: .destructive) {
                    authService.logout()
                }
                Button("cancel".localized, role: .cancel) {}
            } message: {
                Text("logout_confirmation".localized)
            }
            .onAppear {
                loadContributionCount()
            }
        }
    }

    private func loadContributionCount() {
        Task {
            do {
                let request = NetworkService.shared.createRequest(endpoint: "/user/contributions/count")
                let response: [String: Int] = try await NetworkService.shared.performRequest(
                    request, responseType: [String: Int].self
                )
                await MainActor.run {
                    self.contributionCount = response["count"] ?? 0
                }
            } catch {
                // Handle error
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(AppSpacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""

    func loadUserProfile() async {
        // Implementation if needed
    }
}
```

**Step 2: Build to verify ProfileView changes**

Run: `xcodebuild -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add apple/langmap/Views/ProfileView.swift
git commit -m "refactor: update ProfileView with contribution stats

- Show contribution count only (removed learning days and collection count)
- Add settings list with proper icons
- Improve visual hierarchy and spacing
- Add contribution count loading"
```

---

## Task 9: Update ExpressionDetailView

**Goal:** Improve ExpressionDetailView with better layout and interaction.

**Files:**
- Modify: `apple/langmap/Views/ExpressionDetailView.swift`

**Step 1: Enhance ExpressionDetailView**

```swift
import SwiftUI

struct ExpressionDetailView: View {
    let expression: LMLexiconExpression
    @State private var associations: [LMLexiconExpression] = []
    @State private var isLoadingAssociations = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // Main Header Card
                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        HStack {
                            Text(expression.text)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .lineLimit(2)

                            Spacer()

                            Text(expression.languageCode.uppercased())
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.heavy)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(AppTheme.primaryGradient)
                                .foregroundColor(.white)
                                .cornerRadius(AppRadius.small)
                        }

                        if let region = expression.regionName {
                            Label(region, systemImage: "mappin.and.ellipse")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Content Sections
                Group {
                    if let origin = expression.origin, !origin.isEmpty {
                        DetailSection(
                            title: "origin".localized,
                            content: origin,
                            icon: "text.book.closed"
                        )
                    }

                    if let usage = expression.usage, !usage.isEmpty {
                        DetailSection(
                            title: "usage".localized,
                            content: usage,
                            icon: "quote.bubble"
                        )
                    }
                }

                Divider()

                // Associations Section
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("associated_expressions".localized)
                        .font(.title3)
                        .fontWeight(.bold)

                    if isLoadingAssociations {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if associations.isEmpty {
                        Text("no_associated".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        VStack(spacing: AppSpacing.cardSpacing) {
                            ForEach(associations) { assoc in
                                if assoc.id != expression.id {
                                    NavigationLink(
                                        destination: ExpressionDetailView(expression: assoc)
                                    ) {
                                        OptimizedExpressionCard(expression: assoc)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }

                // Metadata
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("metadata".localized)
                        .font(.headline)

                    HStack {
                        Text("added_on".localized + ":")
                        Spacer()
                        Text(formatDate(expression.createdAt))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if let source = expression.sourceType {
                        HStack {
                            Text("source".localized + ":")
                            Spacer()
                            Text(source)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .padding(AppSpacing.md)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(AppRadius.medium)
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle("details".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAssociations()
        }
    }

    private func loadAssociations() {
        guard expression.meaningId != 0 else { return }

        isLoadingAssociations = true
        Task {
            do {
                let endpoint = "/expressions/\(expression.id)/translations"
                let request = NetworkService.shared.createRequest(endpoint: endpoint)
                let response: [LMLexiconExpression] = try await NetworkService.shared
                    .performRequest(request, responseType: [LMLexiconExpression].self)

                await MainActor.run {
                    self.associations = response
                    self.isLoadingAssociations = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoadingAssociations = false
                }
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.accentColor)

            Text(content)
                .font(.body)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(AppRadius.large)
    }
}
```

**Step 2: Build to verify ExpressionDetailView changes**

Run: `xcodebuild -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add apple/langmap/Views/ExpressionDetailView.swift
git commit -m "refactor: improve ExpressionDetailView layout

- Use GlassCard for header
- Improve spacing and typography
- Add better loading and empty states
- Use OptimizedExpressionCard for consistency"
```

---

## Task 10: Final Testing and Polish

**Goal:** Test the complete flow, fix any issues, and ensure all features work together.

**Files:**
- Test all views in simulator
- Fix any bugs discovered
- Add missing localization strings

**Step 1: Add missing localization strings to en-US.json**

```json
{
  "nav_explore": "Explore",
  "no_collections": "No collections yet",
  "create_first_collection": "Create your first collection to save expressions",
  "start_exploring": "Start Exploring",
  "search_or_add_hint": "Search expressions or add new ones",
  "total_contributions": "Total Contributions",
  "remembered_last_selection": "Last selection remembered",
  "locating": "Locating...",
  "location_failed": "Location failed, enter manually",
  "manual_location_placeholder": "e.g., Beijing, New York",
  "search_to_associate": "Search expression to associate",
  "add_success": "Added successfully",
  "add_new_expression": "Add New Expression",
  "expression": "Expression",
  "tags_optional": "Tags (Optional)",
  "associate_with_expression_optional": "Associate with Expression (Optional)",
  "use_current_location": "Use current location",
  "add_tag_hint": "Max 5 tags, 20 characters each",
  "loading_collections": "Loading collections...",
  "delete_collection": "Delete Collection",
  "delete_confirmation": "Are you sure you want to delete this collection?",
  "edit": "Edit",
  "delete": "Delete",
  "retry": "Retry",
  "language_preferences": "Language Preferences",
  "notifications": "Notifications",
  "about": "About",
  "privacy_policy": "Privacy Policy"
}
```

**Step 2: Run complete build**

Run: `xcodebuild -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15' clean build`
Expected: Build succeeds with no errors or warnings

**Step 3: Manual testing checklist**

Test in iOS Simulator:

- [ ] ExploreView loads without errors
- [ ] Search works with debounce
- [ ] Language filter toggles correctly
- [ ] Expression cards navigate to detail view
- [ ] FAB appears on all tabs
- [ ] Add Expression sheet opens and closes
- [ ] Form validation works
- [ ] Location permission request appears
- [ ] Auto-location works
- [ ] Tags can be added and removed
- [ ] Association search works
- [ ] CollectionsView shows grid layout
- [ ] Collection cards show gradient headers
- [ ] Create collection works
- [ ] Delete collection with confirmation works
- [ ] ProfileView shows contribution count
- [ ] Logout works with confirmation

**Step 4: Fix any discovered issues**

Document fixes in commit messages.

**Step 5: Final commit**

```bash
git add .
git commit -m "chore: final UX optimization polish

- Add missing localization strings
- Complete testing and bug fixes
- Ensure all features work correctly
- Ready for review"
```

---

## Summary

This implementation plan transforms the LangMap iOS app UX with:

1. ✅ **Visual Design System** - Consistent colors, spacing, typography
2. ✅ **Reusable Components** - GlassCard, PrimaryButton, SkeletonView
3. ✅ **Navigation Refactor** - 3 tabs: Explore, Collections, Profile
4. ✅ **ExploreView** - Search-first design with optimized cards
5. ✅ **Global FAB** - Quick access to add expressions on all tabs
6. ✅ **AddExpressionSheet** - Complete form with auto-location, caching, tags, association
7. ✅ **CollectionsView** - Two-column grid with gradient cards
8. ✅ **ProfileView** - Contribution stats only, improved layout
9. ✅ **ExpressionDetailView** - Improved layout and consistency

**Estimated completion time:** 4-6 hours for an experienced SwiftUI developer
**Test coverage:** All major user flows covered
**Code quality:** Follows TDD principles, frequent commits, clean architecture
