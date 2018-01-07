// Created by Sinisa Drpa on 12/24/17.

import Foundation

struct API {
   enum err: Error, LocalizedError {
      case priceExists
      case insufficientAmount(amount: Int)
      case invalidRecipientID(recipientId: String)
      case transactionDateNotBetween(start: String, due: String, date: String, transactionId: String)
      case submissionDateNotBetween(start: String, due: String)
      case transactionExists(transactionId: String)
      case tickerIsNil
      case predictionNotFound
      case endOfWeekendIsNil

      var errorDescription: String? {
         switch self {
         case .priceExists:
            return "Price has already been submitted."
         case .insufficientAmount(let amount):
            return "Insufficient amount: \(amount). Amount must be greater then \(C.minAmount)"
         case .invalidRecipientID(let recipientId):
            return "Invalid recipient ID. (Recipient ID: \(recipientId))"
         case .transactionDateNotBetween(let start, let due, let date, let transactionId):
            return "Transaction date \(date) is not between start \(start) and due \(due) date. (Transaction ID: \(transactionId))"
         case .submissionDateNotBetween(let start, let due):
            return "Submission must be placed between start \(start) and due \(due) date."
         case .transactionExists(let transactionId):
            return "Only one submission per transaction ID is allowed. (Transaction ID: \(transactionId)"
         case .tickerIsNil:
            return "Could not get ticker value."
         case .predictionNotFound:
            return "Could not find the transaction ID."
         case .endOfWeekendIsNil:
            return "Could not calculate end of the week."
         }
      }
   }
}

extension API {
   /// Submit a prediction
   ///
   /// Note: We don't need end date since end date can be determined from the submission date
   ///
   /// @param date - Submission date
   static func submit(price: Decimal, transaction tx: Transaction, ip: String, date submissionDate: Date) throws -> Prediction {
      // Validate price is unique
      func validate(price: Decimal) throws {
         do {
            if let _ = try DB.prediction(price: price) {
               throw err.priceExists
            }
         } catch let e {
            throw e
         }
      }

      // Validate transaction
      func validate(transaction tx: Transaction, submissionDate: Date) throws {
         // Validate amount
         let sum = Double(tx.amount) / 1e8
         if sum < C.minAmount {
            throw err.insufficientAmount(amount: tx.amount)
         }
         if tx.recipientId != C.fundsAccount {
            throw err.invalidRecipientID(recipientId: tx.recipientId)
         }
         // Validate transaction date falls between start and final date
         let transactionDate = Date(timeIntervalSince1970: Double(tx.timestamp))
         let start = try startDate(for: submissionDate)
         let due = try dueDate(for: submissionDate)
         let isBetween = (start...due).contains(transactionDate)
         if !isBetween {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone(identifier: "UTC")
            throw err.transactionDateNotBetween(start: formatter.string(from: start),
                                                due: formatter.string(from: due),
                                                date: formatter.string(from: transactionDate),
                                                transactionId: tx.id)
         }
         // Validate is unique. (One txId per submission only)
         let prediction = try DB.prediction(transactionId: tx.id)
         if prediction != nil {
            throw err.transactionExists(transactionId: tx.id)
         }
      }

      // Validate prediction is placed at least 24 hours before the final date
      func validate(submissionDate: Date) throws {
         let start = try startDate(for: submissionDate)
         let due = try dueDate(for: submissionDate)
         let isBetween = (start...due).contains(submissionDate)
         if !isBetween {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone(identifier: "UTC")
            throw err.submissionDateNotBetween(start: formatter.string(from: start),
                                               due: formatter.string(from: due))
         }
      }

      do {
         try validate(price: price)
         try validate(transaction: tx, submissionDate: submissionDate)
         try validate(submissionDate: submissionDate)
         try DB.submit(price: price, senderId: tx.senderId, transactionId: tx.id, ip: ip, date: submissionDate)
         return Prediction(senderId: tx.senderId, transactionId: tx.id, price: price, date: submissionDate)
      } catch let e {
         throw e
      }
   }

   /// Get the prediction for the transactionId
   static func prediction(transactionId: String) throws -> Prediction {
      do {
         guard let p = try DB.prediction(transactionId: transactionId) else {
            throw err.predictionNotFound
         }
         return p
      } catch let e {
         throw e
      }
   }

   /// Get the prediction with the specified amount
   static func prediction(price: Decimal) throws -> Prediction {
      do {
         guard let p = try DB.prediction(price: price) else {
            throw err.predictionNotFound
         }
         return p
      } catch let e {
         throw e
      }
   }

   /// Get the details for the predictions between start and dueDate
   static func allBetweenStartAndDueDate(date: Date) throws -> [Prediction] {
      do {
         let start = try startDate(for: date)
         let due = try dueDate(for: date)
         return try DB.all(from: start, to: due)
      } catch let e {
         throw e
      }
   }

   /// 
   static func previousBest(date: Date) throws -> [Prediction]? {
      func find(closest n: Int, in predictions: [Prediction], to price: Decimal) -> [Prediction]? {
         if predictions.count < n {
            return nil
         }
         let sorted = predictions.sorted {
            let a = abs($0.price - price)
            let b = abs($1.price - price)
            return a < b
         }
         return Array(sorted[..<n])
      }

      do {
         let oneWeek = Double(60 * 60 * 24 * 7)
         let previous = date.addingTimeInterval(-oneWeek)
         let pStart = try startDate(for: previous)
         let pDue = try dueDate(for: previous)
         let xs = try DB.all(from: pStart, to: pDue)

         let refDate = try startDate(for: date)
         guard let refLast = try DB.price(nearestToDate: refDate)?.last else {
            return nil
         }
         //print(refLast)
         let closest = find(closest: 3, in: xs, to: refLast)
         return closest
      } catch let e {
         throw e
      }
   }

   static func startDate(for date: Date) throws -> Date {
      do {
         let end = try endDate(for: date)
         // The start date should be equal to end of the last + 1 second
         let oneWeek = Double(60 * 60 * 24 * 7) - 1 // 7 days, 1 second
         return end.addingTimeInterval(-oneWeek)
      } catch let e {
         throw e
      }
   }

   /// A due date is the submission deadline
   static func dueDate(for date: Date) throws -> Date {
      do {
         let end = try endDate(for: date)
         let twentyFourHours = Double(60 * 60 * 24)
         let due = end.addingTimeInterval(-twentyFourHours)
         return due
      } catch let e {
         throw e
      }
   }

   /// Get the final date
   /// https://stackoverflow.com/questions/11681815/current-week-start-and-end-date
   static func endDate(for date: Date) throws -> Date {
      guard let endOfWeek = date.endOfWeek else {
         throw err.endOfWeekendIsNil
      }
      return endOfWeek
   }
}
