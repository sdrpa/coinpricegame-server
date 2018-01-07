// Copyright © 2017 s4cha. All rights reserved.

import Foundation

extension Promise {
   @discardableResult
   public func validate(withError: Error = PromiseError.validationFailed,
                        _ assertionBlock:@escaping ((T) -> Bool)) -> Promise<T> {
      let p = newLinkedPromise()
      syncStateWithCallBacks(
         success: { t in
            if assertionBlock(t) {
               p.fulfill(t)
            } else {
               p.reject(withError)
            }
      },
         failure: p.reject,
         progress: p.setProgress
      )
      return p
   }
}
