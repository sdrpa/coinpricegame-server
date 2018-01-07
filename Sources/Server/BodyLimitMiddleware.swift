// Created by Sinisa Drpa on 12/6/17.

import Foundation
import Kitura

struct BodyLimitMiddleware: RouterMiddleware {
   let maxPostSizeInBytes = 1024

   func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
      // "Content-Length" - exact byte length of the HTTP body
      guard let value = request.headers["Content-Length"],
         let contentLength = Int(value),
         contentLength <= maxPostSizeInBytes else {
            _ = response.send(status: .requestTooLong)
            return try response.end()
      }
      next()
   }
}
