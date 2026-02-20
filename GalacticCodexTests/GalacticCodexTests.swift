import XCTest

/// Aggregate test target for the GalacticCodex app.
/// Individual package tests run via `swift test --package-path Packages/<Name>`.
/// This target enables `xcodebuild test` for the main scheme.
final class GalacticCodexTests: XCTestCase {
    func testAppLaunches() {
        // Smoke test — verifies the test host builds and launches.
        XCTAssertTrue(true)
    }
}
