// Created by Sinisa Drpa on 1/5/18.

import XCTest
@testable import Server

class IsolatedTests: XCTestCase {
   override func setUp() {
      super.setUp()
      try? DB.truncate()
   }

   override func tearDown() {
      try? DB.truncate()
      super.tearDown()
   }
}
