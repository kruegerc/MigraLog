import XCTest
@testable import MigraLog

final class HeadacheEntryTests: XCTestCase {
    func testIntensityIsClamped() {
        XCTAssertEqual(HeadacheEntry.clampedIntensity(-1), 0)
        XCTAssertEqual(HeadacheEntry.clampedIntensity(6), 6)
        XCTAssertEqual(HeadacheEntry.clampedIntensity(11), 10)
    }

    func testDurationUsesStartAndEnd() {
        let start = Date(timeIntervalSince1970: 100)
        let end = Date(timeIntervalSince1970: 3_700)
        let entry = HeadacheEntry(startedAt: start, endedAt: end, intensity: 5)

        XCTAssertEqual(entry.duration, 3_600)
    }

    func testOpenEntryHasNoDuration() {
        let entry = HeadacheEntry(startedAt: Date(), intensity: 5)

        XCTAssertNil(entry.duration)
    }

    func testListEncodingRoundTrip() {
        let values = ["Stress", "Schlafmangel"]

        XCTAssertEqual(HeadacheEntry.decode(HeadacheEntry.encode(values)), values.sorted())
    }
}
