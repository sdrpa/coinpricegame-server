// Created by Sinisa Drpa on 9/19/17.

import Foundation
import SwiftKuery
import Then

extension Connection {
   func connect() -> Promise<QueryError?> {
      return Promise { resolve, reject in
         self.connect() { error in
            if let error = error {
               reject(error)
            } else {
               resolve(nil)
            }
         }
      }
   }

   func execute(_ query: Query) -> Promise<QueryResult> {
      return Promise { resolve, _ in
         self.execute(query: query) { result in
            resolve(result)
         }
      }
   }

   func execute(_ query: Query, parameters: [Any]) -> Promise<QueryResult> {
      return Promise { resolve, _ in
         self.execute(query: query, parameters: parameters) { result in
            resolve(result)
         }
      }
   }

   func execute(_ raw: String, parameters: [Any?]) -> Promise<QueryResult> {
      return Promise { resolve, _ in
         self.execute(raw, parameters: parameters) { result in
            resolve(result)
         }
      }
   }

   func execute(_ raw: String) -> Promise<QueryResult> {
      return Promise { fulfill, _ in
         self.execute(raw) { result in
            fulfill(result)
         }
      }
   }
}
