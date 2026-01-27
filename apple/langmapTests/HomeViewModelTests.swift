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

        let expectation = XCTestExpectation(description: "Load languages")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }
}
