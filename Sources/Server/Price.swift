// Created by Sinisa Drpa on 12/31/17.

import Foundation

struct Price: Encodable {
   let last: Decimal // Lisk price in Satoshis
   let btc: Decimal  // Bitcoin price in USD
}

extension Price: Mappable {
   init?(rows: [String: Any]) {
      guard let priceRow = rows["price"] as? String,
         let btcRow = rows["btc"] as? String else {
            return nil
      }
      guard let last = Decimal(string: priceRow),
         let btc = Decimal(string: btcRow) else {
         return nil
      }
      self.last = last
      self.btc = btc
   }
}
