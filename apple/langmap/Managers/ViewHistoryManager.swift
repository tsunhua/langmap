//
//  ViewHistoryManager.swift
//  LangMap
//
//  Manages expression viewing history with local persistence
//

import Foundation
import Combine

@MainActor
final class ViewHistoryManager: ObservableObject {
    static let shared = ViewHistoryManager()

    private let userDefaults = UserDefaults.standard
    private let historyKey = "viewHistory"
    private let maxHistoryCount = 50

    @Published var viewHistory: [ViewHistoryItem] = []

    private init() {
        loadHistory()
    }

    // MARK: - Public Methods

    func addToHistory(_ expression: LMLexiconExpression) {
        // Remove existing entry if present (move to top)
        viewHistory.removeAll { $0.expressionId == expression.id }

        // Add new entry at beginning
        let item = ViewHistoryItem(
            expressionId: expression.id,
            text: expression.text,
            languageCode: expression.languageCode,
            regionName: expression.regionName,
            meaningId: expression.meaningId,
            viewedAt: Date()
        )
        viewHistory.insert(item, at: 0)

        // Keep only recent entries
        if viewHistory.count > maxHistoryCount {
            viewHistory = Array(viewHistory.prefix(maxHistoryCount))
        }

        saveHistory()
    }

    func removeFromHistory(_ item: ViewHistoryItem) {
        viewHistory.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearAllHistory() {
        viewHistory.removeAll()
        saveHistory()
    }

    func getRecentViewed(limit: Int = 20) -> [ViewHistoryItem] {
        return Array(viewHistory.prefix(limit))
    }

    var hasHistory: Bool {
        !viewHistory.isEmpty
    }

    // MARK: - Private Methods

    private func loadHistory() {
        guard let data = userDefaults.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([ViewHistoryItem].self, from: data) else {
            viewHistory = []
            return
        }
        viewHistory = decoded
    }

    private func saveHistory() {
        guard let encoded = try? JSONEncoder().encode(viewHistory) else { return }
        userDefaults.set(encoded, forKey: historyKey)
        userDefaults.synchronize()
    }
}

// MARK: - View History Item Model

struct ViewHistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let expressionId: Int
    let text: String
    let languageCode: String
    let regionName: String?
    let meaningId: Int
    let viewedAt: Date

    init(expressionId: Int, text: String, languageCode: String, regionName: String?, meaningId: Int, viewedAt: Date = Date()) {
        self.id = UUID()
        self.expressionId = expressionId
        self.text = text
        self.languageCode = languageCode
        self.regionName = regionName
        self.meaningId = meaningId
        self.viewedAt = viewedAt
    }

    static func == (lhs: ViewHistoryItem, rhs: ViewHistoryItem) -> Bool {
        lhs.id == rhs.id
    }

    var relativeTime: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(viewedAt) {
            let components = calendar.dateComponents([.hour, .minute], from: viewedAt, to: now)
            if let hours = components.hour, hours > 0 {
                return "\(hours)h ago"
            } else if let minutes = components.minute, minutes > 0 {
                return "\(minutes)m ago"
            }
            return "Just now"
        } else if calendar.isDateInYesterday(viewedAt) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: viewedAt, to: now).day ?? 0
            if days < 7 {
                return "\(days)d ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: viewedAt)
            }
        }
    }
}
