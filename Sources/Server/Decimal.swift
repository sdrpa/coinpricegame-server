// Created by Sinisa Drpa on 12/31/17.

import Foundation

extension Double {
   func string(fractionDigits: Int) -> String {
      let formatter = NumberFormatter()
      formatter.minimumFractionDigits = fractionDigits
      formatter.maximumFractionDigits = fractionDigits
      return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
   }
}

extension Decimal {
   init(double: Double, fractionDigits: Int) {
      let string = double.string(fractionDigits: fractionDigits)
      guard let d = Decimal(string: string) else {
         fatalError()
      }
      self = d
   }

   init(_ decimal: Decimal, fractionDigits: Int) {
      let string = decimal.doubleValue.string(fractionDigits: fractionDigits)
      guard let d = Decimal(string: string) else {
         fatalError()
      }
      self = d
   }

   var doubleValue:Double {
      return NSDecimalNumber(decimal:self).doubleValue
   }


}
