// Created by Sinisa Drpa on 11/16/17.

import Foundation
import Kitura
import KituraNet
import KituraWebSocket
import KituraCORS
import LoggerAPI
import SwiftyJSON

public struct Server {
   var service = Service()

   public init() {
      // https://github.com/IBM-Swift/HeliumLogger/issues/49
      struct StandardError: TextOutputStream {
         func write(_ text: String) {
            guard let data = text.data(using: .utf8) else {
               return
            }
            FileHandle.standardError.write(data)
            // Log to file.
            let filename = "coinpricegame.log"
            let cwd = FileManager.default.currentDirectoryPath
            let fileURL = URL(fileURLWithPath: cwd).appendingPathComponent(filename)
            do {
               try data.appendToURL(fileURL: fileURL)
            } catch let e {
               guard let data = e.localizedDescription.data(using: String.Encoding.utf8) else {
                  return
               }
               FileHandle.standardError.write(data)
            }
         }
      }

      let standardError = StandardError()
      let logger = APIStreamLogger(.info, outputStream: standardError)
      Log.logger = logger
   }
   
   public func run() {
      var cors: CORS {
         let options = Options(allowedOrigin: .all,
                               maxAge: 5)
         return CORS(options: options)
      }
      let rate = RateLimitMiddleware(
         total: 1,
         expire: 1, // 1 req/sec
         whitelist: { request in
            request.remoteAddress == "127.0.0.1"
      })

      let router = Router()
      router.all("/",  middleware: cors, rate)
      router.post("*", middleware: BodyLimitMiddleware(), BodyParser())

      router.get("/ping",             handler: Server.ping)
      router.post("/submit",          handler: Server.submit)
      router.get("/prediction/tx",    handler: Server.predictionWithTransactionId)
      router.get("/prediction/price", handler: Server.predictionWithPrice)
      router.get("/all",              handler: Server.allBetweenStartAndDueDate)
      router.get("/previous-best",    handler: Server.previousBest)
      router.get("/dates",            handler: Server.dates)

      WebSocket.register(service: service, onPath: "/price")

      // http://www.kitura.io/en/resources/tutorials/ssl.html
      let server = HTTP.createServer()
      server.delegate = router

      let envVars = ProcessInfo.processInfo.environment
      let portString: String = envVars["PORT"] ?? envVars["CF_INSTANCE_PORT"] ??  envVars["VCAP_APP_PORT"] ?? "8182"
      let port = Int(portString) ?? 8182
      
      do {
         try server.listen(on: port)
         ListenerGroup.waitForListeners()
      } catch {
         print("Could not listen on port \(port): \(error)")
      }
   }
}

extension Server {
   enum err: Swift.Error {
      case invalidPrice
      case invalidTransactionID

      var errorDescription: String? {
         switch self {
         case .invalidPrice:
            return "Invalid price."
         case .invalidTransactionID:
            return "Invalid transaction ID"
         }
      }
   }
}

extension Server {
   static func ping(request: RouterRequest, response: RouterResponse, next: () -> Void) {
      response.status(.OK).send("OK")
      next()
   }

   // curl -d '{"v":"10.2", "txId":"1440867060433296113"}' -H "Content-Type: application/json" -X POST http://localhost:8182/submit
   static func submit(request: RouterRequest, response: RouterResponse, next: () -> Void) {
      defer {
         next()
      }
      guard let body = request.body, let json = body.asJSON else {
         response.status(.badRequest)
         return
      }
      guard let v = json["v"] as? String, let price = Decimal(string: v) else {
         response.status(.badRequest).send(err.invalidPrice.localizedDescription)
         return
      }
      guard let txId = json["txId"] as? String, !txId.isEmpty else {
         response.status(.badRequest).send(err.invalidTransactionID.localizedDescription)
         return
      }
      do {
         let now = Date()
         let transaction = try Lisk().transaction(id: txId)
         let prediction = try API.submit(price: price, transaction: transaction, ip: request.remoteAddress, date: now)
         let data = try JSONEncoder().encode(prediction)
         response.status(.OK).send(data: data)
      } catch let e {
         Log.error(e.localizedDescription)
         response.status(.unprocessableEntity).send(e.localizedDescription)
      }
   }

   // curl -X GET http://localhost:8182/prediction/tx/id=10872755118372042973
   static func predictionWithTransactionId(request: RouterRequest, response: RouterResponse, next: () -> Void) {
      defer {
         next()
      }
      guard let txId = request.queryParameters["id"], !txId.isEmpty else {
         response.status(.badRequest).send(err.invalidTransactionID.localizedDescription)
         return
      }
      do {
         let prediction = try API.prediction(transactionId: txId)
         let data = try JSONEncoder().encode(prediction)
         response.status(.OK).send(data: data)
      } catch let e {
         response.status(.unprocessableEntity).send(e.localizedDescription)
      }
   }

   // curl -X GET http://localhost:8182/prediction/price?v=123.456
   static func predictionWithPrice(request: RouterRequest, response: RouterResponse, next: () -> Void) {
      defer {
         next()
      }
      guard let v = request.queryParameters["v"], !v.isEmpty, let price = Decimal(string: v) else {
         response.status(.badRequest).send(err.invalidPrice.localizedDescription)
         return
      }
      do {
         let prediction = try API.prediction(price: price)
         let data = try JSONEncoder().encode(prediction)
         response.status(.OK).send(data: data)
      } catch let e {
         response.status(.unprocessableEntity).send(e.localizedDescription)
      }
   }

   // curl -X GET http://localhost:8182/all
   static func allBetweenStartAndDueDate(request: RouterRequest, response: RouterResponse, next: () -> Void) {
      defer {
         next()
      }
      do {
         let now = Date()
         let xs = try API.allBetweenStartAndDueDate(date: now)
         let data = try JSONEncoder().encode(["xs": xs])
         response.status(.OK).send(data: data)
      } catch let e {
         Log.error(e.localizedDescription)
         response.status(.unprocessableEntity).send(e.localizedDescription)
      }
   }

   // curl -X GET http://localhost:8182/previous-best
   static func previousBest(request: RouterRequest, response: RouterResponse, next: () -> Void) {
      defer {
         next()
      }
      do {
         let now = Date()
         let xs = try API.previousBest(date: now)
         let data = try JSONEncoder().encode(["xs": xs])
         response.status(.OK).send(data: data)
      } catch let e {
         Log.error(e.localizedDescription)
         response.status(.unprocessableEntity).send(e.localizedDescription)
      }
   }

   // curl -X GET http://localhost:8182/dates
   static func dates(request: RouterRequest, response: RouterResponse, next: () -> Void) {
      defer {
         next()
      }
      do {
         let now = Date()
         let startDate = try API.startDate(for: now)
         let dueDate = try API.dueDate(for: now)
         let endDate = try API.endDate(for: now)

         let data = try JSONEncoder().encode(Dates(start: startDate.timeIntervalSince1970,
                                                   due: dueDate.timeIntervalSince1970,
                                                   end: endDate.timeIntervalSince1970))
         response.status(.OK).send(data: data)
      } catch let e {
         Log.error(e.localizedDescription)
         response.status(.unprocessableEntity).send(e.localizedDescription)
      }
   }
}

fileprivate extension Data {
   func appendToURL(fileURL: URL) throws {
      if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
         defer {
            fileHandle.closeFile()
         }
         fileHandle.seekToEndOfFile()
         fileHandle.write(self)
      }
      else {
         try write(to: fileURL, options: .atomic)
      }
   }
}
