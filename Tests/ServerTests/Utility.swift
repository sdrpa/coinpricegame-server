// Created by Sinisa Drpa on 12/28/17.

import Foundation
@testable import Server

func generatePrediction() -> Prediction {
   let senderId = String.random(20, base: "1234567890") + "L"
   let txId = String.random(20, base: "1234567890")
   let price = Decimal(double: Double.random(lower: 1, upper: 100), fractionDigits: 4)
   let days = Int.random(lower: 0, upper: 7)
   return Prediction(senderId: senderId, transactionId: txId, price: price, date: Date.randomWithinDaysBeforeToday(days: days))
}

func generateIP() -> String {
   var ip: String = ""
   for _ in 0..<4 {
      ip += String(Int.random(lower: 0, upper: 255))
   }
   return ip
}

extension String {
   func toDate() -> Date {
      let dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
      return self.toDate(format: dateFormat)
   }

   func toTimestamp() -> Int {
      return Int(self.toDate().timeIntervalSince1970)
   }
}

func randomPrice() -> Decimal {
   return Decimal.random(lower: 1.0, upper: 100.0)
}

func randomTxId() -> String {
   return String.random(20, base: "1234567890")
}
