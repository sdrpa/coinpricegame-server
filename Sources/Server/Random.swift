// Created by Sinisa Drpa on 12/26/17.

import Foundation

#if os(Linux)
import SwiftGlibc

func arc4random_uniform(_ max: UInt32) -> Int32 {
   return (SwiftGlibc.rand() % Int32(max-1))
}
#endif

extension String {
   static func random(_ length: Int, base: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ") -> String {
      var randomString: String = ""

      let max = UInt32(base.count)
      for _ in 0..<length {
         #if os(Linux)
            let randomValue =  Int(SwiftGlibc.random() % Int(max))
         #else
            let randomValue = Int(arc4random_uniform(UInt32(max)))
         #endif
         randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
      }
      return randomString
   }
}

extension Int {
   static func random (lower: Int, upper: Int) -> Int {
      return lower + Int(arc4random_uniform(UInt32(upper - lower + 1)))
   }
}

public extension Double {
   public static var random: Double {
      #if os(Linux)
         return Double(SwiftGlibc.random()) / 0xFFFFFFFF
      #else
         return Double(arc4random()) / 0xFFFFFFFF
      #endif
   }

   public static func random(lower: Double, upper: Double) -> Double {
      return Double.random * (upper - lower) + lower
   }
}

public extension Decimal {
   public static var random: Decimal {
      return Decimal(Double.random)
   }

   public static func random(lower: Double, upper: Double) -> Decimal {
      return Decimal(Double.random * (upper - lower) + lower)
   }
}

extension Date {
   static func randomWithinDaysBeforeToday(days: Int) -> Date {
      let today = Date()

      let gregorian = Calendar(identifier: .gregorian)
      let r1 = arc4random_uniform(UInt32(days))
      let r2 = arc4random_uniform(UInt32(23))
      let r3 = arc4random_uniform(UInt32(59))
      let r4 = arc4random_uniform(UInt32(59))

      var offsetComponents = DateComponents()
      offsetComponents.day = Int(r1) * -1
      offsetComponents.hour = Int(r2)
      offsetComponents.minute = Int(r3)
      offsetComponents.second = Int(r4)

      guard let randomDate = gregorian.date(byAdding: offsetComponents as DateComponents, to: today as Date, wrappingComponents: false) else {
         // Randoming failed
         fatalError()
      }
      return randomDate
   }
}
