// Created by Sinisa Drpa on 12/28/17.

import XCTest
@testable import Server

class ServerTests: XCTestCase {
   override func setUp() {
      super.setUp()
      try? DB.truncate()
   }

   override func tearDown() {
      try? DB.truncate()
      super.tearDown()
   }

   private let apiRoot = "http://localhost:8182"

   func testDates() {
      do {
         let httpResponse = try HttpClient().request("\(apiRoot)/dates", method: .GET)
         XCTAssertEqual(200, httpResponse.status)
         let dates = try JSONDecoder().decode(Dates.self, from: httpResponse.data)
         XCTAssertTrue(dates.start != 0)
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }
}

extension ServerTests {
   static var allTests = [
      ("testDates", testDates)
   ]
}

