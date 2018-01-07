// Created by Sinisa Drpa on 12/24/17.

import XCTest
@testable import Server

class DBTests: XCTestCase {
   override func setUp() {
      super.setUp()
      try? DB.truncate()
   }

   override func tearDown() {
      try? DB.truncate()
      super.tearDown()
   }

   func testSubmit() {
      do {
         let p = generatePrediction()
         try DB.submit(price: p.price, senderId: p.senderId, transactionId: p.transactionId, ip: generateIP())
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }

   func testPredictionWithTransactionIdAndPrice() {
      do {
         let p = generatePrediction()
         try DB.submit(price: p.price, senderId: p.senderId, transactionId: p.transactionId, ip: generateIP())

         let p1 = try DB.prediction(transactionId: p.transactionId)
         XCTAssertNotNil(p1)
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }

   func testPredictionWithPrice() {
      do {
         let p = generatePrediction()
         try DB.submit(price: p.price, senderId: p.senderId, transactionId: p.transactionId, ip: generateIP())

         let p1 = try DB.prediction(price: p.price)
         XCTAssertNotNil(p1)
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }
}

extension DBTests {
   static var allTests = [
      ("testSubmit", testSubmit),
      ("testPredictionWithTransactionIdAndPrice", testPredictionWithTransactionIdAndPrice),
      ("testPredictionWithPrice", testPredictionWithPrice)
   ]
}

