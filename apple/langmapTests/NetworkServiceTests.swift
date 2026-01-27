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
