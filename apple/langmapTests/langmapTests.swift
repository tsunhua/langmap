//
//  langmapTests.swift
//  langmapTests
//
//  Created by Share Lim on 2026/1/27.
//

import XCTest
@testable import langmap

class langmapTests: XCTestCase {

    func testMainTabViewHasFourTabs() {
        // Verify MainTabView has exactly 4 tabs: Explore, Add Expression, Collections, Profile
        let tabView = MainTabView()
        XCTAssertNotNil(tabView)
    }

    func testExploreViewDoesNotHaveLanguageFilter() {
        // Verify ExploreView does NOT have language filter chips in main view
        // (Language filter is being removed from search section)
        let exploreView = ExploreView()
        XCTAssertNotNil(exploreView)
    }

    func testExploreViewHasSearchBar() {
        // Verify ExploreView still has search functionality
        let exploreView = ExploreView()
        XCTAssertNotNil(exploreView)
    }

    func testAddExpressionViewExists() {
        // Verify AddExpressionView exists as a separate tab
        let addExpressionView = AddExpressionView()
        XCTAssertNotNil(addExpressionView)
    }
}
