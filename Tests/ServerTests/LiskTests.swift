// Created by Sinisa Drpa on 12/28/17.

import XCTest
@testable import Server

class LiskTests: XCTestCase {
   func testTransaction() {
      do {
         let t = try Lisk().transaction(id: "1440867060433296113")
         XCTAssertNotNil(t)
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }
}

extension LiskTests {
   static var allTests = [
      ("testTransaction", testTransaction)
   ]
}
