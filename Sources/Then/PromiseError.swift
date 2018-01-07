// Copyright © 2017 s4cha. All rights reserved.

import Foundation

public enum PromiseError: Error {
   case `default`
   case validationFailed
   case retryInvalidInput
   case raceAllFailed(lastError: Error)
   case unwrappingFailed
   case timeout
}

extension PromiseError: Equatable {
   public static func == (lhs: PromiseError, rhs: PromiseError) -> Bool {
      switch (lhs, rhs) {
      case (.default, .default):
         return true
      case (.validationFailed, .validationFailed):
         return true
      case (.retryInvalidInput, .retryInvalidInput):
         return true
      case (.raceAllFailed, .raceAllFailed):
         return true
      case (.unwrappingFailed, .unwrappingFailed):
         return true
      default:
         return false
      }
   }
}
