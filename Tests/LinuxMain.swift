import XCTest
@testable import ServerTests

XCTMain([
    testCase(APITests.allTests),
    testCase(BittrexTests.allTests),
    testCase(DBTests.allTests),
    testCase(LiskTests.allTests),
    //testCase(ServerTests.allTests)
])
