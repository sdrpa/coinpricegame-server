// Copyright © 2017 s4cha. All rights reserved.

import Foundation
import Dispatch

public func await<T>(_ promise: Promise<T>) throws -> T {
   var result: T!
   var error: Error?
   let group = DispatchGroup()
   group.enter()
   promise.then { t in
      result = t
      group.leave()
      }.catch { e in
         error = e
         group.leave()
   }
   group.wait()
   if let e = error {
      throw e
   }
   return result
}
