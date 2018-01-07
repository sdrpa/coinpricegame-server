// Created by Sinisa Drpa on 12/24/17.

import Foundation

struct Prediction: Encodable, Equatable, CustomDebugStringConvertible {
   let senderId: String
   let transactionId: String
   let price: Decimal
   let date: Date

   static func ==(lhs: Prediction, rhs: Prediction) -> Bool {
      return lhs.senderId == rhs.senderId &&
         lhs.transactionId == rhs.transactionId &&
         lhs.price == rhs.price
   }

   var debugDescription: String {
      return transactionId
   }
}

extension Prediction: Mappable {
   init?(rows: [String: Any]) {
      guard let senderId = rows["sender_id"] as? String,
         let transactionId = rows["transaction_id"] as? String,
         let date = rows["created_at"] as? Date else {
            return nil
      }
      guard let p = rows["price"] as? String,
         let price = Decimal(string: p) else {
            return nil
      }
      self.senderId = senderId
      self.transactionId = transactionId
      self.price = price
      self.date = date
   }
}
