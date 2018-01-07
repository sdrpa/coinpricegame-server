// Created by Sinisa Drpa on 11/24/17.

import Foundation

extension Date {
   struct Formatter {
      static let iso8601: DateFormatter = {
         let formatter = DateFormatter()
         formatter.calendar = Calendar(identifier: .iso8601)
         formatter.locale = Locale(identifier: "en_US_POSIX")
         formatter.timeZone = TimeZone(identifier: "UTC")
         formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
         return formatter
      }()
   }

   var iso8601: String {
      var data = Formatter.iso8601.string(from: self)
      if let fractionStart = data.range(of: "."),
         let fractionEnd = data.index(fractionStart.lowerBound, offsetBy: 7, limitedBy: data.endIndex) {
         let fractionRange = fractionStart.lowerBound..<fractionEnd
         let intVal = Int64(1000000 * self.timeIntervalSince1970)
         let newFraction = String(format: ".%06d", intVal % 1000000)
         data.replaceSubrange(fractionRange, with: newFraction)
      }
      return data
   }

   var startOfWeek: Date? {
      var calendar = Calendar(identifier: .gregorian)
      guard let tz = TimeZone(identifier: "UTC") else {
         return nil
      }
      calendar.timeZone = tz
      guard let date = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else {
            return nil
      }
      return date
   }

   var endOfWeek: Date? {
      guard let startOfWeek = self.startOfWeek else {
         return nil
      }
      var calendar = Calendar(identifier: .gregorian)
      guard let tz = TimeZone(identifier: "UTC") else {
         return nil
      }
      calendar.timeZone = tz
      return calendar.date(byAdding: .second, value: 604799, to: startOfWeek)
   }
}

extension String {
   var dateFromISO8601: Date? {
      guard let parsedDate = Date.Formatter.iso8601.date(from: self) else {
         return nil
      }

      var preliminaryDate = Date(timeIntervalSinceReferenceDate: floor(parsedDate.timeIntervalSinceReferenceDate))

      if let fractionStart = self.range(of: "."),
         let fractionEnd = self.index(fractionStart.lowerBound, offsetBy: 7, limitedBy: self.endIndex) {
         let fractionRange = fractionStart.lowerBound..<fractionEnd
         //let fractionStr = self.substring(with: fractionRange)
         let fractionStr = self[fractionRange]

         if var fraction = Double(fractionStr) {
            fraction = Double(floor(1000000*fraction)/1000000)
            preliminaryDate.addTimeInterval(fraction)
         }
      }
      return preliminaryDate
   }

   func toDate(format: String) -> Date {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = format
      dateFormatter.timeZone = TimeZone(identifier: "UTC")
      if let date = dateFormatter.date(from: self) {
         return date
      }
      fatalError()
   }
}
