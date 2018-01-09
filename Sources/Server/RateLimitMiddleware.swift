// Created by Sinisa Drpa on 1/2/18.
// https://github.com/teechap/kitura-limiter

import Foundation
import Kitura
import KituraNet
import KituraCache

typealias By = (_ request: RouterRequest) -> String
typealias NextFunc = () -> Void
typealias WhiteList = (_ request: RouterRequest) -> Bool

// Custom handler for rate-limited clients (default returns a 429 response and tries to end())
func defaultOnRateLimited(request: RouterRequest, response: RouterResponse, next: @escaping NextFunc) throws {
   response.status(HTTPStatusCode.tooManyRequests).send("Rate limit exceeded.")
   try response.end()
}

func defaultWhitelist(request: RouterRequest) -> Bool {
   return false
}

// Function which returns a unique key to identify the client (the default fn uses the client's request.remoteAddress)
func defaultByFunc(request: RouterRequest) -> String {
   return request.remoteAddress
}

class RateLimitMiddleware: RouterMiddleware {
   struct Limit: CustomDebugStringConvertible {
      var total: Int
      var remaining: Int
      var reset: Int

      var debugDescription: String {
         return "Total: \(total), Remaining: \(remaining), Reset: \(Date(timeIntervalSince1970: Double(reset)))"
      }
   }

   let by: By
   let onRateLimited: RouterHandler
   let expire: Int
   let total: Int
   let whitelist: WhiteList
   let defaultLimit: Limit

   let store = KituraCache(defaultTTL: 0, checkFrequency: 600) // [String: Limit]

   // 150 req/hour default
   init(by: @escaping By = defaultByFunc, total: Int = 150, expire: Int = 60 * 60, onRateLimited: @escaping RouterHandler = defaultOnRateLimited, whitelist: @escaping WhiteList = defaultWhitelist) {
      self.by = by
      self.total = total
      self.expire = expire * 1000
      self.onRateLimited = onRateLimited
      self.whitelist = whitelist
      self.defaultLimit = Limit(
         total: total,
         remaining: total,
         reset: now() + expire
      )
   }

   func handle(request: RouterRequest, response: RouterResponse, next: @escaping NextFunc) throws {
      if whitelist(request) {
         return next()
      }

      let key = "\(self.by(request))"
      var limit = store.object(forKey: key) as? Limit ?? defaultLimit

      let t = now()
      if t > limit.reset {
         limit.reset = t + expire
         limit.remaining = total
      }
      limit.remaining = max(limit.remaining - 1, -1)
      //print(limit)
      store.setObject(limit, forKey: key)

      response.headers.append("X-RateLimit-Limit", value: "\(total)")
      response.headers.append("X-RateLimit-Reset", value: "\(ceil(Double(limit.reset) / 1000))")
      response.headers.append("X-RateLimit-Remaining", value: "\(max(limit.remaining, 0))")

      if limit.remaining >= 0 {
         next()
      } else {
         let after = (limit.reset - now()) / 1000
         response.headers.append("Retry-After", value: "\(after)")
      }
      return try onRateLimited(request, response, next)
   }
}

fileprivate func now() -> Int { // miliseconds since epoch
   return Int(Date().timeIntervalSince1970 * 1000)
}
