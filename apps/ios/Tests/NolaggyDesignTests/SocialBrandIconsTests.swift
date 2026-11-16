import XCTest
@testable import NolaggyDesign

final class SocialBrandIconsTests: XCTestCase {
    func testAllSocialBrandSVGPathsParseWithinViewBox24() {
        let paths: [(String, String)] = [
            ("whatsapp", SocialBrandPaths.whatsapp),
            ("telegram", SocialBrandPaths.telegram),
            ("x", SocialBrandPaths.x),
            ("tiktok", SocialBrandPaths.tiktok),
            ("instagram", SocialBrandPaths.instagram)
        ]

        for (name, svg) in paths {
            let parsed = SVGPathParser.parse(svg)
            let bounds = parsed.boundingRect
            XCTAssertFalse(parsed.isEmpty, "\(name) path must not be empty")
            XCTAssertGreaterThan(bounds.width, 14.0, "\(name) width too small: \(bounds)")
            XCTAssertGreaterThan(bounds.height, 14.0, "\(name) height too small: \(bounds)")
            XCTAssertGreaterThanOrEqual(bounds.minX, -0.5, "\(name) minX out of viewBox: \(bounds)")
            XCTAssertGreaterThanOrEqual(bounds.minY, -0.5, "\(name) minY out of viewBox: \(bounds)")
            XCTAssertLessThanOrEqual(bounds.maxX, 24.5, "\(name) maxX out of viewBox: \(bounds)")
            XCTAssertLessThanOrEqual(bounds.maxY, 24.5, "\(name) maxY out of viewBox: \(bounds)")
        }
    }
}
