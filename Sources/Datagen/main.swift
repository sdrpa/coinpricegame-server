// Created by Sinisa Drpa on 11/27/17.

import Foundation
@testable import Server

func generatePredictions(count: Int) -> [Prediction] {
   var ps: [Prediction] = []
   ps.append(predictionWithValidTransaction())

   for _ in 0..<numPredictions {
      let senderId = String.random(20, base: "1234567890") + "L"
      let txId = String.random(20, base: "1234567890")
      let price = Decimal(double: Double.random(lower: 1, upper: 100), fractionDigits: 4)
      let days = Int.random(lower: 0, upper: 7)
      let p = Prediction(senderId: senderId, transactionId: txId, price: price, date: Date.randomWithinDaysBeforeToday(days: days))
      ps.append(p)
   }
   return ps
}

func predictionWithValidTransaction() -> Prediction {
   let senderId = "10872755118372042973L"
   let txId = "1440867060433296113"
   let price = Decimal(12.3456)
   return Prediction(senderId: senderId, transactionId: txId, price: price, date: Date())
}

func generateIP() -> String {
   var ip: String = ""
   for _ in 0..<4 {
      ip += String(Int.random(lower: 0, upper: 255))
   }
   return ip
}

func truncateTable() {
   do {
      try DB.truncate()
   } catch let e {
      fatalError(e.localizedDescription)
   }
}

let numPredictions = 10
let ps = generatePredictions(count: numPredictions)
truncateTable()

print("Please wait...")
ps.forEach { p in
   do {
      try DB.submit(price: p.price, senderId: p.senderId, transactionId: p.transactionId, ip: generateIP(), date: p.date)
   } catch let e {
      fatalError(e.localizedDescription)
   }
}
