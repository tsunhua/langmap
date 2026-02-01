//
//  SearchHistoryManager.swift
//  LangMap
//
//  Manages search history with local persistence
//

import Foundation
import Observation

@Observable
@MainActor
final class SearchHistoryManager {
    static let shared = SearchHistoryManager()

    private let userDefaults = UserDefaults.standard
    private let historyKey = "searchHistory"
    private let maxHistoryCount = 20

    var searchHistory: [SearchHistoryItem] = []

    private init() {
        loadHistory()
    }

    // MARK: - Public Methods

    func addToHistory(query: String, languageCode: String? = nil, resultCount: Int = 0) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        // Remove existing entry if present
        searchHistory.removeAll { $0.query == trimmedQuery }

        // Add new entry at the beginning
        let item = SearchHistoryItem(
            query: trimmedQuery,
            languageCode: languageCode,
            resultCount: resultCount,
            timestamp: Date()
        )
        searchHistory.insert(item, at: 0)

        // Keep only recent entries
        if searchHistory.count > maxHistoryCount {
            searchHistory = Array(searchHistory.prefix(maxHistoryCount))
        }

        saveHistory()
    }

    func removeFromHistory(_ item: SearchHistoryItem) {
        searchHistory.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearAllHistory() {
        searchHistory.removeAll()
        saveHistory()
    }

    func getRecentSearches(limit: Int = 10) -> [SearchHistoryItem] {
        return Array(searchHistory.prefix(limit))
    }

    // MARK: - Private Methods

    private func loadHistory() {
        guard let data = userDefaults.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) else {
            searchHistory = []
            return
        }
        searchHistory = decoded
    }

    private func saveHistory() {
        guard let encoded = try? JSONEncoder().encode(searchHistory) else { return }
        userDefaults.set(encoded, forKey: historyKey)
    }
}

// MARK: - Search History Item Model

struct SearchHistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let query: String
    let languageCode: String?
    let resultCount: Int
    let timestamp: Date

    init(query: String, languageCode: String? = nil, resultCount: Int = 0, timestamp: Date = Date()) {
        self.id = UUID()
        self.query = query
        self.languageCode = languageCode
        self.resultCount = resultCount
        self.timestamp = timestamp
    }

    static func == (lhs: SearchHistoryItem, rhs: SearchHistoryItem) -> Bool {
        lhs.id == rhs.id
    }

    var relativeTime: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(timestamp) {
            let components = calendar.dateComponents([.hour, .minute], from: timestamp, to: now)
            if let hours = components.hour, hours > 0 {
                return "\(hours)h ago"
            } else if let minutes = components.minute, minutes > 0 {
                return "\(minutes)m ago"
            }
            return "Just now"
        } else if calendar.isDateInYesterday(timestamp) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: timestamp, to: now).day ?? 0
            if days < 7 {
                return "\(days)d ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: timestamp)
            }
        }
    }
}
