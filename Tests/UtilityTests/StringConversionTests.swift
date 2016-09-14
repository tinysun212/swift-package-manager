/*
This source file is part of the Swift.org open source project

Copyright 2016 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See http://swift.org/LICENSE.txt for license information
See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
import Utility

class StringConversionTests: XCTestCase {

    func testManglingToC99ExtendedIdentifier() {
        
        // Simple cases.
        XCTAssertEqual("foo".mangledToC99ExtendedIdentifier(), "foo")
        
        // Edge cases.
        XCTAssertEqual("".mangledToC99ExtendedIdentifier(), "")
        XCTAssertEqual("_".mangledToC99ExtendedIdentifier(), "_")
        XCTAssertEqual("\n".mangledToC99ExtendedIdentifier(), "_")
        
        // Invalid non-leading characters.
        XCTAssertEqual("_-".mangledToC99ExtendedIdentifier(), "__")
        XCTAssertEqual("foo-bar".mangledToC99ExtendedIdentifier(), "foo_bar")
        
        // Invalid leading characters.
        XCTAssertEqual("1".mangledToC99ExtendedIdentifier(), "_")
        XCTAssertEqual("1foo".mangledToC99ExtendedIdentifier(), "_foo")
        
        // FIXME: There are lots more interesting test cases to add here.
        var str1 = ""
        str1.mangleToC99ExtendedIdentifier()
        XCTAssertEqual(str1, "")

        var str2 = "_"
        str2.mangleToC99ExtendedIdentifier()
        XCTAssertEqual(str2, "_")

        var str3 = "-"
        str3.mangleToC99ExtendedIdentifier()
        XCTAssertEqual(str3, "_")
}

    static var allTests = [
        ("testManglingToC99ExtendedIdentifier", testManglingToC99ExtendedIdentifier),
    ]
}
