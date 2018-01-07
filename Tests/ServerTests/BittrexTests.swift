// Created by Sinisa Drpa on 12/25/17.

import XCTest
@testable import Server

class BittrexTests: XCTestCase {
   func testCurrentPrice() {
      do {
         _ = try Bittrex().price()
      } catch let e {
         XCTFail(e.localizedDescription)
      }
   }
}

extension BittrexTests {
   static var allTests = [
      ("testCurrentPrice", testCurrentPrice)
   ]
}
