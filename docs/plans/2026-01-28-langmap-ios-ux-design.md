# LangMap iOS App UX Design Specification

**Version:** 1.0
**Date:** 2026-01-28
**Platform:** iOS 17+
**Language:** SwiftUI

---

## Executive Summary

This document defines the UX design specifications for the LangMap iOS application. The design prioritizes three core user goals: **searching expressions**, **adding new expressions**, and **managing collections**. The design philosophy emphasizes simplicity, elegance, and intuitive interaction patterns.

**Key Design Decisions:**
- Global floating action button (FAB) for quick access to add expressions
- Streamlined navigation with 3 tabs: Explore, Collections, Profile
- Compact card layouts for efficient content scanning
- Auto-location for region selection with manual override
- Language selection caching to reduce repetitive actions
- Single expression association constraint

---

## Table of Contents

1. [Navigation Structure](#1-navigation-structure)
2. [Explore Screen](#2-explore-screen)
3. [Collections Screen](#3-collections-screen)
4. [Profile Screen](#4-profile-screen)
5. [Add Expression Sheet](#5-add-expression-sheet)
6. [Visual Design System](#6-visual-design-system)
7. [Interaction Patterns](#7-interaction-patterns)
8. [Accessibility](#8-accessibility)

---

## 1. Navigation Structure

### 1.1 Tab Bar Configuration

The application uses a bottom tab bar with 3 tabs. Each tab represents a primary user flow.

| Tab | Icon | Label | Purpose |
|-----|------|-------|---------|
| Explore | `magnifyingglass.circle.fill` | 探索 | Search and discover expressions |
| Collections | `folder.fill` | 收藏 | Manage user collections |
| Profile | `person.fill` | 我的 | User profile and settings |

**Implementation:**
- Use `TabView` with SwiftUI
- Unselected icons: outline style
- Selected icons: filled style
- Accent color: primary gradient (indigo → purple)
- Tab bar background: system background with blur effect

### 1.2 Global Floating Action Button (FAB)

**Position:** Fixed at bottom-right, 20px from edges

**Dimensions:**
- Size: 56x56 points (large touch target)
- Border radius: 28 points (circular)

**Visual Design:**
- Background: `AppTheme.primaryGradient`
- Icon: `plus` in white, 24 points
- Shadow: Subtle drop shadow for elevation

**Interaction:**
- Always visible across all 3 tabs
- Tap trigger: `showAddExpression = true`
- Animation: Scale down to 0.95 on press, spring back on release

**Z-Index:** Highest layer, floats above all content

---

## 2. Explore Screen

### 2.1 Layout Structure

```
┌─────────────────────────────────┐
│ Search Bar (sticky top)          │
├─────────────────────────────────┤
│ Language Filter (horizontal)     │
├─────────────────────────────────┤
│                                 │
│ Expression Card 1                │
│ Expression Card 2                │
│ Expression Card 3                │
│ ...                              │
│                                 │
└─────────────────────────────────┘
```

### 2.2 Search Bar

**Position:** Top of ScrollView, sticky header

**Dimensions:** Width 90%, height 44 points

**Style:**
- Background: Glass morphism effect (blur + semi-transparent)
- Corner radius: 22 points
- Left icon: `magnifyingglass`, accent color
- Placeholder: "search_placeholder".localized
- Clear button: `xmark.circle.fill`, secondary color, visible only when text exists

**Behavior:**
- Debounce: 300ms before triggering search
- Focus state: Language filter remains visible below
- Keyboard: `.searchPad` type
- Dismiss: Tap outside to dismiss keyboard

### 2.3 Language Filter

**Position:** Below search bar, horizontal scroll

**Style:**
- Pill-shaped buttons (capsule)
- Height: 32 points
- Padding: Horizontal 16px, Vertical 8px
- Corner radius: 16 points

**States:**
- **Unselected:**
  - Background: `Color.primary.opacity(0.05)`
  - Text: `.primary`, font weight `.bold`
  - Font: `.system(.caption, design: .rounded)`
- **Selected:**
  - Background: `AppTheme.primaryGradient`
  - Text: `.white`, font weight `.bold`
  - Shadow: Accent color opacity 0.3, radius 5
- **First Item:** "全部" (All languages), special styling

**Interaction:**
- Single selection mode
- Tap to toggle selection
- Animated selection transition
- Auto-scroll to keep selected item visible

### 2.4 Expression Card

**Dimensions:**
- Width: 100% of screen width (minus horizontal padding)
- Height: ~80 points (adaptive based on content)
- Corner radius: 16 points

**Layout:**
```
┌─────────────────────────────────────┐
│ [Expression Text]           [Language│
│  (large, bold)                  Tag] │
│ [Region (gray, small)]              │
└─────────────────────────────────────┘
```

**Typography:**
- Expression text: `.system(.title3, design: .rounded)`, `.bold`
- Region: `.subheadline`, `.secondary`
- Language tag: `.system(.caption2, design: .monospaced)`, `.heavy`

**Color:**
- Background: `AppTheme.cardBackground`
- Border: `.primary.opacity(0.05)`, 1 point
- Shadow: `.black.opacity(0.05)`, radius 10, y offset 5

**Spacing:**
- Card-to-card: 12 points
- Padding inside card: 16 points

**Interaction:**
- Tap: Navigate to `ExpressionDetailView`
- Press animation: Scale to 0.98, bounce back
- Haptic feedback: `.light` on tap

### 2.5 Empty States

**Initial State (no search):**
- Illustration: Large `magnifyingglass` icon, 50 points
- Text: "开始探索" (Start Exploring), `.title2`, `.secondary`
- Subtext: "搜索词句或添加新的表达" (Search expressions or add new)

**No Results:**
- Illustration: `magnifyingglass`, 50 points
- Text: "no_results".localized, `.title2`, `.secondary`
- CTA: "添加新词句" (Add New Expression) button
- FAB visible: Yes

---

## 3. Collections Screen

### 3.1 Layout Structure

```
┌─────────────────────────────────┐
│ Title: "我的收藏"                │
│                                 │
│ ┌──────┐  ┌──────┐              │
│ │Card1 │  │Card2 │              │
│ │  5   │  │  12  │              │
│ └──────┘  └──────┘              │
│                                 │
│ ┌──────┐  ┌──────┐              │
│ │Card3 │  │Card4 │              │
│ │  8   │  │  3   │              │
│ └──────┘  └──────┘              │
│                                 │
└─────────────────────────────────┘
```

### 3.2 Collection Card

**Dimensions:**
- Width: ~45% of screen width
- Height: Adaptive (minimum 120 points)
- Corner radius: 16 points

**Layout:**
```
┌──────────────────┐
│ Gradient Header  │
│ [Name]          [⋮]│
│ Description...   │
│                  │
│ [12 items]       │
└──────────────────┘
```

**Header:**
- Gradient: Random or language-based color
- Height: 60 points
- Content: Collection name, `.headline`

**Body:**
- Description: `.caption`, line limit 2
- Item count: Badge, `.caption2`, monospace

**Menu (⋮):**
- Position: Top-right, 20x20 points
- Tap: Show action sheet (Edit, Delete, Share)

**Interactions:**
- Tap: Navigate to `CollectionDetailView`
- Long press: Enter edit mode
- Swipe: Delete (iOS native gesture)
- Tap menu: Show action sheet

### 3.3 Grid Layout

**Implementation:**
- `LazyVGrid` with 2 columns
- Spacing: 12 points
- Padding: 16 points
- Performance: Lazy loading

**Loading State:**
- Skeleton screens with shimmer animation
- 4 placeholder cards visible

### 3.4 Empty State

**Visual:**
- Icon: `folder`, 60 points, `.secondary`
- Text: "no_collections".localized, `.title2`, `.secondary`
- Subtext: "create_first_collection".localized, `.subheadline`
- CTA: "创建第一个集合" (Create First Collection) button
- FAB visible: Yes

---

## 4. Profile Screen

### 4.1 Layout Structure

```
┌─────────────────────────────────┐
│  [Avatar]                        │
│  Username                        │
│  email@example.com               │
│                                 │
│  ┌──────────────────────┐       │
│  │                      │       │
│  │    贡献数: 47        │       │
│  │                      │       │
│  └──────────────────────┘       │
│                                 │
│  Settings List:                  │
│  • Language Preferences        │
│  • Notifications               │
│  • About                       │
│  • Privacy Policy              │
│                                 │
│  [退出登录]                      │
└─────────────────────────────────┘
```

### 4.2 User Header

**Avatar:**
- Size: 80x80 points
- Shape: Circular
- Default: `person.circle.fill` system icon
- Color: Accent color
- Tap: Future feature (upload avatar)

**Text:**
- Username: `.title`, `.bold`
- Email: `.body`, `.secondary`
- Role badge (optional): Pill tag, `.caption2`

**Spacing:**
- Top padding: 40 points
- Avatar to username: 15 points
- Username to email: 5 points

### 4.3 Statistics Card

**Layout:**
- Single centered card
- Width: 100% (minus horizontal padding)
- Height: 100 points
- Corner radius: 16 points
- Background: Soft gradient (light version of primary)

**Content:**
- Number: Large display, `.system(size: 48, weight: .bold)`
- Label: "总贡献" (Total Contributions), `.subheadline`, `.secondary`
- Tap: Navigate to contribution history

### 4.4 Settings List

**Style:** iOS native list style

**Row Layout:**
```
[Icon]  [Label]          [→]
 24pt     body           16pt
```

**Items:**
1. Language Preferences - `globe`
2. Notifications - `bell`
3. About - `info.circle`
4. Privacy Policy - `hand.raised`

**Interaction:**
- Tap: Navigate to settings page
- Haptic: `.light` on tap
- Animation: Subtle scale down (0.98)

### 4.5 Logout Button

**Style:**
- Red danger button
- Full width (minus padding)
- Height: 44 points
- Background: `.red.opacity(0.1)`
- Text: `.red`, `.bold`
- Icon: `rectangle.portrait.and.arrow.right`

**Interaction:**
- Tap: Show confirmation alert
- Alert buttons:
  - "退出登录" (Logout) - Destructive
  - "cancel".localized - Cancel

---

## 5. Add Expression Sheet

### 5.1 Sheet Configuration

**Presentation:**
- Modal sheet from bottom
- Height: Adaptive (based on content)
- Maximum height: 90% of screen
- Corner radius: 20 points at top
- Drag indicator: Visible

**Header:**
- Title: "添加新词句" (Add New Expression), `.headline`
- Close button: `xmark`, top-right, 20x20 points
- Background: System background

### 5.2 Form Fields

#### Field 1: Expression Text (Required)

**Type:** `TextField` with multiline support

**Layout:**
- Width: 90%
- Height: Adaptive (min 60 points, max 150 points)
- Corner radius: 12 points
- Background: `.primary.opacity(0.03)`
- Border: `.primary.opacity(0.1)`, 1 point

**Placeholder:** "输入词句或短语" (Enter expression or phrase)

**Character Counter:**
- Position: Bottom-right
- Format: "X/500"
- Color: `.secondary`
- Font: `.caption2`

**Validation:**
- Required: 1-500 characters
- Error: Red message below field
- Real-time validation

#### Field 2: Language Selection (Required)

**Type:** Picker with menu style

**Layout:**
- Width: 90%
- Height: 44 points
- Corner radius: 12 points
- Background: `.primary.opacity(0.03)`

**Display Format:**
- "语言名 (代码)" e.g., "中文 (zh)"
- Default: Cached language from UserDefaults

**Caching:**
- Save selected language to UserDefaults
- Key: `selectedLanguageId`
- Load on next open
- Show hint: "已记住上次选择" (Last selection remembered), `.caption`, `.secondary`

**Search Filter:**
- Type to filter languages
- Debounce: 200ms

#### Field 3: Region (Optional - Auto Location)

**Toggle:** Collapsible section

**Initial State:**
- Icon: `location.fill`, accent color
- Text: "正在定位..." (Locating...)
- Loading: `ProgressView`, small

**Located State:**
- Icon: `location.fill`, green color
- Text: Region name (e.g., "北京市")
- Edit button: `pencil`, 16x16 points
- Relocate button: `arrow.clockwise`, 16x16 points

**Manual Edit State:**
- TextField: Manual input
- Placeholder: "如：北京、纽约" (e.g., Beijing, New York)
- Save button: Checkmark icon

**Error State:**
- Icon: `location.slash`, red color
- Text: "定位失败，请手动输入" (Location failed, enter manually)
- Manual input field appears

**Implementation:**
- Use `CLLocationManager`
- Permission: Request on first use
- Fallback: Manual input if denied

#### Field 4: Tags (Optional)

**Toggle:** Collapsible section

**Layout:**
- TextField + Add button, horizontal
- Selected tags: Capsule chips below

**Tag Chip:**
- Background: `.primary.opacity(0.1)`
- Text: Tag name
- Delete: `xmark.circle.fill`, 16x16 points

**Constraints:**
- Maximum 5 tags
- Maximum 20 characters per tag
- Validation on add

**Interaction:**
- Enter key or tap add to add tag
- Tap delete to remove tag

#### Field 5: Associated Expression (Optional, Single Only)

**Toggle:** Collapsible section

**Title:** "关联到其他词句" (Associate with other expression)

**Unselected State:**
- Search bar: Same style as Explore screen
- Placeholder: "搜索要关联的词句" (Search expression to associate)

**Selected State:**
- Show `ExpressionCardView` in compact form
- Delete button: `trash` icon, red color
- Search bar hidden

**Constraints:**
- Maximum 1 association
- Select new → Replace old with confirmation

**Search Behavior:**
- Real-time search with debounce
- Show top 5 results
- Tap to select

### 5.3 Form Actions

**Layout:** Fixed at bottom of sheet

**Buttons:**
- Cancel: Secondary style, left
- Submit: Primary gradient, right

**States:**
- **Submit Disabled:** Required fields incomplete
- **Submit Loading:** Show spinner, disable interaction
- **Submit Success:** Close sheet + show toast

**Toast Notification:**
- Message: "添加成功" (Added successfully)
- Duration: 2 seconds
- Position: Top of screen

### 5.4 Form Validation

**Real-time Validation:**
- Expression text: 1-500 characters
- Language: Required selection
- Show error messages immediately below fields

**Error Display:**
- Red text, `.caption`
- Shake animation on submit if invalid

---

## 6. Visual Design System

### 6.1 Color Palette

**Primary Gradient:**
```swift
LinearGradient(
    gradient: Gradient(colors: [
        Color(hex: "6366f1"),  // Indigo
        Color(hex: "a855f7")   // Purple
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

**Backgrounds:**
- Primary background: `Color(.systemBackground)`
- Card background: `Color.primary.opacity(0.03)`
- Sheet background: `Color(.secondarySystemBackground)`
- Input background: `Color.primary.opacity(0.03)`

**Text Colors:**
- Primary: `Color.primary`
- Secondary: `Color.secondary`
- Accent: Primary gradient colors

**Semantic Colors:**
- Error: `.red`
- Success: `.green`
- Warning: `.orange`

### 6.2 Typography

**Font Family:**
- Primary: `.rounded` design
- Monospace: `.monospaced` for codes/tags

**Sizes:**
- Large Title: 34pt, `.bold`
- Title 1: 28pt, `.bold`
- Title 2: 22pt, `.bold`
- Title 3: 20pt, `.bold`
- Headline: 17pt, `.semibold`
- Body: 17pt, `.regular`
- Subheadline: 15pt, `.regular`
- Footnote: 13pt, `.regular`
- Caption: 12pt, `.regular`
- Caption 2: 11pt, `.regular`

**Weights:**
- Heavy: 900
- Bold: 700
- Semibold: 600
- Medium: 500
- Regular: 400
- Light: 300

### 6.3 Spacing System

**Scale (based on 8pt grid):**
- Extra Small: 4pt
- Small: 8pt
- Medium: 12pt
- Large: 16pt
- Extra Large: 24pt
- Huge: 32pt

**Application:**
- Padding: 16pt (Large)
- Card spacing: 12pt (Medium)
- Button height: 44pt
- Touch target minimum: 44x44pt

### 6.4 Border Radius

**Small:** 8pt (chips, badges)
**Medium:** 12pt (inputs, buttons)
**Large:** 16pt (cards, modals)
**Extra Large:** 20pt (sheets, alerts)
**Circle:** 28pt (FAB), 40pt (avatar)

### 6.5 Shadows

**Light (subtle):**
```swift
shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
```

**Medium (cards):**
```swift
shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
```

**Heavy (elevation):**
```swift
shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)
```

### 6.6 Glassmorphism

**Effect:**
```swift
.background(
    UltraThinMaterial()
    .opacity(0.9)
)
```

**Application:**
- Search bar background
- Tab bar background
- Overlay backgrounds

---

## 7. Interaction Patterns

### 7.1 Animations

**Standard Spring:**
```swift
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)
```

**Ease In Out:**
```swift
.animation(.easeInOut(duration: 0.2), value: state)
```

**Bounce:**
```swift
.animation(.spring(response: 0.4, dampingFraction: 0.5), value: state)
```

### 7.2 Button Press States

**Scale Animation:**
```swift
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
```

**Haptic Feedback:**
- Light tap: `.impact(.light)`
- Medium tap: `.impact(.medium)`
- Heavy tap: `.impact(.heavy)`
- Success: `.notification(.success)`
- Error: `.notification(.error)`

### 7.3 Loading States

**Spinner:** `ProgressView()`, medium size

**Skeleton Screens:**
- Shimmer animation
- Placeholder dimensions match content
- Duration: 1.5s cycle

**Pull to Refresh:**
- Native SwiftUI `.refreshable`
- Show spinner during data fetch

### 7.4 Transitions

**Modal Sheet:**
```swift
.sheet(isPresented: $isPresented) {
    Content()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
```

**Navigation Push:**
- Native SwiftUI `NavigationLink`
- Slide from right

**Tab Switch:**
- Fade + slide from bottom
- Native `TabView` behavior

### 7.5 Gesture Recognizers

**Tap:**
- Primary interaction for navigation
- Haptic feedback on success

**Long Press:**
- Context menus
- Edit mode trigger
- Minimum duration: 0.5s

**Swipe:**
- Delete items in lists
- Native iOS gestures

**Drag:**
- Sheet dismissal
- Reorder items (future)

---

## 8. Accessibility

### 8.1 Dynamic Type

**Support:** All text supports dynamic type scaling

**Implementation:**
```swift
.font(.system(.body))
.dynamicTypeSize(.medium... .xxxLarge)
```

### 8.1 VoiceOver

**Labels:** All interactive elements have descriptive labels

**Traits:** Proper traits for buttons, links, headers

**Implementation:**
```swift
.accessibilityLabel("Add new expression")
.accessibilityHint("Opens form to add a new expression")
.accessibilityAddTraits(.isButton)
```

### 8.3 Color Contrast

**Minimum Contrast Ratio:** 4.5:1 for normal text, 3:1 for large text

**Validation:** Use Accessibility Inspector to verify

### 8.4 Touch Targets

**Minimum Size:** 44x44 points for all interactive elements

**Spacing:** Minimum 8pt between touch targets

### 8.5 Focus Management

**Focus Order:** Logical navigation order

**Keyboard:** Proper keyboard types for input fields

**Dismiss:** Tap outside to dismiss keyboard

---

## Implementation Notes

### 9.1 SwiftUI Versions

- Minimum: iOS 17+
- Recommended: iOS 18+ for latest features

### 9.2 State Management

- `@StateObject` for view models
- `@EnvironmentObject` for shared services
- `@Published` properties for reactive updates

### 9.3 Data Persistence

- UserDefaults: User preferences, language cache
- Keychain: Authentication tokens
- Core Data: Local caching (future)

### 9.4 API Integration

- Network service: Singleton pattern
- Async/await for all network calls
- Proper error handling and loading states

### 9.5 Testing

- Unit tests: View models and business logic
- UI tests: Critical user flows
- Snapshot tests: Visual regression testing

---

## Appendix

### A. Icon Reference

| Icon | Usage |
|------|-------|
| `house.fill` | Home/Explore tab |
| `magnifyingglass` | Search |
| `magnifyingglass.circle.fill` | Explore tab |
| `folder.fill` | Collections tab |
| `person.fill` | Profile tab |
| `plus` | Add button |
| `xmark.circle.fill` | Clear button |
| `location.fill` | Location |
| `pencil` | Edit |
| `trash` | Delete |
| `bell` | Notifications |
| `globe` | Language |

### B. Localization Keys

```
- nav_home, nav_explore
- nav_collections
- nav_profile
- search_placeholder
- no_results
- start_typing
- featured_expressions
- language
- add_expression
- add_success
- validation_required
- validation_length
```

### C. Color Hex Codes

| Name | Hex |
|------|-----|
| Indigo | #6366f1 |
| Purple | #a855f7 |
| Gray-100 | #f3f4f6 |
| Gray-200 | #e5e7eb |

---

**Document Status:** ✅ Final
**Next Steps:** Begin implementation following this specification
**Review Cycle:** After first implementation pass
