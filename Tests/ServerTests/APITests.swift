// Created by Sinisa Drpa on 12/28/17.

import XCTest
@testable import Server

class APITests: XCTestCase {
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
         let tx = Transaction(id: p.transactionId,
                              timestamp: "2018-04-04 23:59:59 +0000".toTimestamp(),
                              senderId: p.senderId,
                              recipientId: C.fundsAccount,
                              amount: 100000000, fee: 10000000)
         let submissionDate = "2018-04-04 23:59:59 +0000".toDate()
         //let endDate = "2018-04-07 23:59:59 +0000".toDate()
         let p1 = try API.submit(price: p.price,
                                 transaction: tx,
                                 ip: generateIP(),
                                 date: submissionDate)
         XCTAssertNotNil(p1)
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }

   func testSubmitNonUniquePrice() {
      do {
         // Insert prediction
         let p = generatePrediction()
         let price = p.price
         try DB.submit(price: price, senderId: p.senderId, transactionId: randomTxId(), ip: generateIP())
         // Try to submit the same price
         let tx = Transaction(id: p.transactionId,
                              timestamp: "2018-04-04 23:59:59 +0000".toTimestamp(),
                              senderId: p.senderId, recipientId: C.fundsAccount,
                              amount: 100000000, fee: 10000000)
         let submissionDate = "2018-04-04 23:59:59 +0000".toDate()
         //let endDate = "2018-04-07 23:59:59 +0000".toDate()
         XCTAssertThrowsError(try API.submit(price: price,
                                             transaction: tx,
                                             ip: generateIP(),
                                             date: submissionDate)) {
            error in
            guard case API.err.priceExists = error else {
               return XCTFail()
            }
         }
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }

   func testSubmitNonUniqueTransationId() {
      do {
         // Insert prediction
         let p = generatePrediction()
         let txId = p.transactionId
         try DB.submit(price: p.price, senderId: p.senderId, transactionId: txId, ip: generateIP())
         // Try to submit a prediction with txId which is already in DB
         let tx = Transaction(id: txId,
                              timestamp: "2018-04-04 23:59:59 +0000".toTimestamp(),
                              senderId: p.senderId,
                              recipientId: C.fundsAccount,
                              amount: 100000000, fee: 10000000)
         let submissionDate = "2018-04-04 23:59:59 +0000".toDate()
         //let endDate = "2018-04-07 23:59:59 +0000".toDate()
         XCTAssertThrowsError(try API.submit(price: randomPrice(),
                                             transaction: tx,
                                             ip: generateIP(),
                                             date: submissionDate)) {
            error in
            guard case API.err.transactionExists = error else {
               return XCTFail()
            }
         }
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }

   func testSubmitBeforeStartDate() {
      let p = generatePrediction()
      let tx = Transaction(id: p.transactionId,
                           timestamp: "2018-03-31 23:59:58 +0000".toTimestamp(),
                           senderId: p.senderId,
                           recipientId: C.fundsAccount,
                           amount: 100000000, fee: 10000000)
      let submissionDate = "2018-04-03 00:00:01 +0000".toDate()
      //let endDate = "2018-04-07 23:59:59 +0000".toDate()
      XCTAssertThrowsError(try API.submit(price: p.price,
                                          transaction: tx,
                                          ip: generateIP(),
                                          date: submissionDate)) {
                                             error in
                                             guard case API.err.transactionDateNotBetween = error else {
                                                return XCTFail()
                                             }
      }
   }

   func testSubmitAtStartDate() {
      do {
         let submissionDate = "2018-04-04 20:00:00 +0000".toDate()
         let p = generatePrediction()
         let tx = Transaction(id: p.transactionId,
                              timestamp: "2018-04-04 20:00:00 +0000".toTimestamp(),
                              senderId: p.senderId,
                              recipientId: C.fundsAccount,
                              amount: 100000000, fee: 10000000)
         let startDate = try API.startDate(for: submissionDate)
         let p1 = try API.submit(price: p.price,
                                 transaction: tx,
                                 ip: generateIP(),
                                 date: startDate)
         XCTAssertNotNil(p1)
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }

   func testSubmitSecondAfterStartDate() {
      do {
         let submissionDate = "2018-04-04 20:00:00 +0000".toDate()
         let p = generatePrediction()
         let tx = Transaction(id: p.transactionId,
                              timestamp: "2018-04-04 20:00:00 +0000".toTimestamp(),
                              senderId: p.senderId,
                              recipientId: C.fundsAccount,
                              amount: 100000000, fee: 10000000)
         let secondAfterStartDate = try API.startDate(for: submissionDate).addingTimeInterval(1)
         let p1 = try API.submit(price: p.price,
                                 transaction: tx,
                                 ip: generateIP(),
                                 date: secondAfterStartDate)
         XCTAssertNotNil(p1)
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }

   func testSubmitSecondBeforeDueDate() {
      do {
         let p = generatePrediction()
         let tx = Transaction(id: p.transactionId,
                              timestamp: "2018-04-06 23:59:58 +0000".toTimestamp(),
                              senderId: p.senderId,
                              recipientId: C.fundsAccount,
                              amount: 100000000, fee: 10000000)
         let submissionDate = "2018-04-06 23:59:58 +0000".toDate()
         //let endDate = "2018-04-07 23:59:59 +0000".toDate()
         let secondBeforeDueDate = try API.dueDate(for: submissionDate).addingTimeInterval(-1)
         let p1 = try API.submit(price: p.price,
                                 transaction: tx,
                                 ip: generateIP(),
                                 date: secondBeforeDueDate)
         XCTAssertNotNil(p1)
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }

   func testSubmitAtDueDate() {
      do {
         let p = generatePrediction()
         let tx = Transaction(id: p.transactionId,
                              timestamp: "2018-04-06 23:59:59 +0000".toTimestamp(),
                              senderId: p.senderId,
                              recipientId: C.fundsAccount,
                              amount: 100000000, fee: 10000000)
         let submissionDate = "2018-04-06 23:59:59 +0000".toDate()
         //let endDate = "2018-04-07 23:59:59 +0000".toDate()
         let dueDate = try API.dueDate(for: submissionDate)
         let p1 = try API.submit(price: p.price,
                                 transaction: tx,
                                 ip: generateIP(),
                                 date: dueDate)
         XCTAssertNotNil(p1)
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }

   func testSubmitSecondAfterDueDate() {
      do {
         let p = generatePrediction()
         let tx = Transaction(id: p.transactionId,
                              timestamp: "2018-04-04 00:00:01 +0000".toTimestamp(),
                              senderId: p.senderId,
                              recipientId: C.fundsAccount,
                              amount: 100000000, fee: 10000000)
         let submissionDate = "2018-04-07 00:00:00 +0000".toDate()
         //let endDate = "2018-04-07 23:59:59 +0000".toDate()
         let secondAfterDueDate = try API.dueDate(for: submissionDate).addingTimeInterval(1)
         XCTAssertThrowsError(try API.submit(price: p.price,
                                             transaction: tx,
                                             ip: generateIP(),
                                             date: secondAfterDueDate)) {
            error in
            guard case API.err.submissionDateNotBetween = error else {
               return XCTFail()
            }
         }
      } catch let e {
         XCTFail(e.localizedDescription)
      }
   }

   func testStartDueEndForDate() {
      do {
         let submissionDate = try API.endDate(for: "2018-04-04 20:00:00 +0000".toDate())

         let start = try API.startDate(for: submissionDate)
         XCTAssertEqual(ComparisonResult.orderedSame,
                        "2018-04-01 00:00:00 +0000".toDate().compare(start))

         let due = try API.dueDate(for: submissionDate)
         XCTAssertEqual(ComparisonResult.orderedSame,
                        "2018-04-06 23:59:59 +0000".toDate().compare(due))

         let end = try API.endDate(for: submissionDate)
         XCTAssertEqual(ComparisonResult.orderedSame,
                        "2018-04-07 23:59:59 +0000".toDate().compare(end))
         // Next week
         let submissionDate1 = end.addingTimeInterval(1)

         let start1 = try API.startDate(for: submissionDate1)
         // The end of the last week should not be the same as the start of the next week
         XCTAssertEqual(ComparisonResult.orderedAscending,end.compare(start1))
         // The next start should be equal to the end of the last week + 1 second
         XCTAssertEqual(ComparisonResult.orderedSame, end.addingTimeInterval(1).compare(start1))

         let due1 = try API.dueDate(for: submissionDate1)
         XCTAssertEqual(ComparisonResult.orderedSame,
                        "2018-04-13 23:59:59 +0000".toDate().compare(due1))

         let end1 = try API.endDate(for: submissionDate1)
         XCTAssertEqual(ComparisonResult.orderedSame,
                        "2018-04-14 23:59:59 +0000".toDate().compare(end1))

      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }

   func testStartDueEndForDateBetweenDueAndEndDate() {
      do {
         let submissionDate = try API.endDate(for: "2018-04-07 12:00:00 +0000".toDate())

         let start = try API.startDate(for: submissionDate)
         XCTAssertEqual(ComparisonResult.orderedSame,
                        "2018-04-01 00:00:00 +0000".toDate().compare(start))

         let due = try API.dueDate(for: submissionDate)
         XCTAssertEqual(ComparisonResult.orderedSame,
                        "2018-04-06 23:59:59 +0000".toDate().compare(due))

         let end = try API.endDate(for: submissionDate)
         XCTAssertEqual(ComparisonResult.orderedSame,
                        "2018-04-07 23:59:59 +0000".toDate().compare(end))
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }

   func testWeekStartDateForEndDate() {
      do {
         let endDate = try API.endDate(for: "2017-12-31 00:00:00 +0000".toDate())
         let expected = "2018-01-06 23:59:59 +0000".toDate()
         XCTAssertEqual(ComparisonResult.orderedSame, expected.compare(endDate))
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }

   func testWeekEndDateForEndDate() {
      do {
         let endDate = try API.endDate(for: "2017-12-30 23:59:59 +0000".toDate())
         let expected = "2017-12-30 23:59:59 +0000".toDate()
         XCTAssertEqual(ComparisonResult.orderedSame, expected.compare(endDate))
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }

   func testAllBetweenStartAndDueDate() {
      do {
         let submissionDate = "2018-04-04 23:59:59 +0000".toDate()
         let startDate = try API.startDate(for: submissionDate)
         let dueDate = try API.dueDate(for: submissionDate)

         let p = generatePrediction()
         let tx = Transaction(id: p.transactionId,
                              timestamp: Int(startDate.timeIntervalSince1970),
                              senderId: p.senderId,
                              recipientId: C.fundsAccount,
                              amount: 100000000, fee: 10000000)
         let s1 = try API.submit(price: p.price,
                                 transaction: tx,
                                 ip: generateIP(),
                                 date: startDate)

         let p1 = generatePrediction()
         let tx1 = Transaction(id: p1.transactionId,
                               timestamp: Int(dueDate.timeIntervalSince1970),
                               senderId: p1.senderId,
                               recipientId: C.fundsAccount,
                               amount: 100000000, fee: 10000000)
         let s2 = try API.submit(price: p1.price,
                                 transaction: tx1,
                                 ip: generateIP(),
                                 date: dueDate)

         // Generate one before start date
         try DB.submit(price: Decimal(1.0),
                       senderId: "64009803294541322542L",
                       transactionId: "81885513403629967466",
                       ip: generateIP(),
                       date: startDate.addingTimeInterval(-1))
         // Generate one after due date
         try DB.submit(price: Decimal(2.0),
                       senderId: "35767668105525227324L",
                       transactionId: "99268768310234069136",
                       ip: generateIP(),
                       date: dueDate.addingTimeInterval(1))

         let all = try API.allBetweenStartAndDueDate(date: submissionDate)
         XCTAssertEqual([s2, s1], all)
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }

   func testPreviousBest() {
      func submit(_ date: Date, price: Decimal, transactionId: String) throws -> Prediction {
         return try DB.submit(price: price,
                              senderId: String.random(20, base: "1234567890") + "L",
                              transactionId: transactionId,
                              ip: generateIP(),
                              date: date)
      }
      func savePrice(_ date: Date, last: Decimal) throws {
         try DB.save(price: Price(last: last, btc: 1.0), date: date)
      }

      do {
         let submissionDate = "2018-04-04 23:59:59 +0000".toDate()
         let startDate = try API.startDate(for: submissionDate)
         let pDueDate = startDate.addingTimeInterval(-60 * 60 * 24)

         //
         let _  = try submit(pDueDate.addingTimeInterval(-1), price: 18.0, transactionId: "1")
         let p2 = try submit(pDueDate.addingTimeInterval(-2), price: 19.0, transactionId: "2")
         let p3 = try submit(pDueDate.addingTimeInterval(-3), price: 20.1, transactionId: "3")
         let p4 = try submit(pDueDate.addingTimeInterval(-4), price: 20.6, transactionId: "4")
         let _  = try submit(pDueDate.addingTimeInterval(-5), price: 22.0, transactionId: "5")
         //
         let _  = try submit(startDate.addingTimeInterval(1), price: 18.1, transactionId: "6")
         let _  = try submit(startDate.addingTimeInterval(2), price: 19.1, transactionId: "7")
         let _  = try submit(startDate.addingTimeInterval(3), price: 20.1, transactionId: "8")
         let _  = try submit(startDate.addingTimeInterval(4), price: 21.1, transactionId: "9")
         let _  = try submit(startDate.addingTimeInterval(5), price: 22.1, transactionId: "10")
         //
         try savePrice(startDate.addingTimeInterval(-2), last: 19.0)
         try savePrice(startDate.addingTimeInterval(-1), last: 20.0)
         try savePrice(startDate.addingTimeInterval(0),  last: 21.0)
         try savePrice(startDate.addingTimeInterval(-1), last: 22.0)
         try savePrice(startDate.addingTimeInterval(-2), last: 23.0)

         guard let xs = try API.previousBest(date: startDate) else {
            return XCTFail()
         }
         XCTAssertEqual([p3, p4, p2], xs)
      } catch let error {
         XCTFail(error.localizedDescription)
      }
   }
}

extension APITests {
   static var allTests = [
      ("testSubmit", testSubmit),
      ("testSubmitNonUniquePrice", testSubmitNonUniquePrice),
      ("testSubmitNonUniqueTransationId", testSubmitNonUniqueTransationId),
      ("testSubmitBeforeStartDate", testSubmitBeforeStartDate),
      ("testSubmitAtStartDate", testSubmitAtStartDate),
      ("testSubmitSecondAfterStartDate", testSubmitSecondAfterStartDate),
      ("testSubmitSecondBeforeDueDate", testSubmitSecondBeforeDueDate),
      ("testSubmitAtDueDate", testSubmitAtDueDate),
      ("testSubmitSecondAfterDueDate", testSubmitSecondAfterDueDate),
      ("testStartDueEndForDate", testStartDueEndForDate),
      ("testStartDueEndForDateBetweenDueAndEndDate", testStartDueEndForDateBetweenDueAndEndDate),
      ("testWeekStartDateForEndDate", testWeekStartDateForEndDate),
      ("testWeekEndDateForEndDate", testWeekEndDateForEndDate),
      ("testAllBetweenStartAndDueDate", testAllBetweenStartAndDueDate),
      ("testPreviousBest", testPreviousBest)
   ]
}
