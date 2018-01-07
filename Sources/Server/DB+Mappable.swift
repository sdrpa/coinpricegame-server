// Created by Sinisa Drpa on 11/27/17.

import Foundation
import SwiftKuery

protocol Mappable {
   init?(rows: [String: Any])
}

extension DB {
   static func rows(from resultSet: ResultSet) -> [[String: Any]] {
      let ts = resultSet.rows.map {
         zip(resultSet.titles, $0)
      }
      let xs: [[String: Any]] = ts.map {
         var dictionaries = [String: Any]()
         $0.forEach {
            let (title, value) = $0
            dictionaries[title] = value
         }
         return dictionaries
      }
      return xs
   }
}
