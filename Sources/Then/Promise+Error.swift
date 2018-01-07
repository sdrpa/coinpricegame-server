// Copyright © 2017 s4cha. All rights reserved.

import Foundation

public extension Promise {
   @discardableResult
   public func `catch`(_ block: @escaping (Error) -> Void) -> Promise<Void> {
      tryStartInitialPromiseAndStartIfneeded()
      return registerCatch(block)
   }

   @discardableResult
   public func registerCatch(_ block: @escaping (Error) -> Void) -> Promise<Void> {
      let p = Promise<Void>()
      passAlongFirstPromiseStartFunctionAndStateTo(p)
      syncStateWithCallBacks(
         success: { _ in
            p.fulfill(())
      },
         failure: { e in
            block(e)
            p.fulfill(())
      },
         progress: p.setProgress
      )
      p.start()
      return p
   }
}
