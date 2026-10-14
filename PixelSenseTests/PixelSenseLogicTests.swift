import XCTest
@testable import PixelSense

final class PixelSenseLogicTests: XCTestCase {
    func testPromptAndRecipeLogic() {
        let failures = PromptLogicChecks.all.compactMap { check in
            check.run().map { "\(check.name): \($0)" }
        }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }
}
