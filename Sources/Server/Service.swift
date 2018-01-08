// Created by Sinisa Drpa on 11/17/17.

import Dispatch
import Foundation
import KituraWebSocket
import LoggerAPI

final class Service {
   private let delay = 1.0
   private let timer = DispatchSource.makeTimerSource()
   private let bittrex = Bittrex()
   private var connections = [String: WebSocketConnection]()

   init() {
      timer.setEventHandler() { [weak self] in
         //print("Service timer tick at \(Date()).")
         func broadcast(price p: Price) throws {
            let dictionary = [
               "last": Decimal(p.last * p.btc, fractionDigits: 4)]
            do {
               let data = try JSONEncoder().encode(dictionary)
               if let conns =  self?.connections {
                  for (_, connection) in conns {
                     connection.send(message: data, asBinary: false)
                  }
               }
            } catch let e {
               throw e
            }
         }

         do {
            guard let price = try self?.bittrex.price() else {
               Log.error("Bittrex ticker is nil.")
               return
            }
            try broadcast(price: price)
            try DB.save(price: price, date: Date())
         } catch let e{
            Log.error(e.localizedDescription)
         }
      }

      let now = DispatchTime.now()
      let deadline = DispatchTime(uptimeNanoseconds: now.uptimeNanoseconds + (UInt64(delay * 1e9)))
      timer.schedule(deadline: deadline, repeating: delay)
      timer.resume()
   }

   deinit {
      timer.suspend()
   }
}

// https://developer.ibm.com/swift/2017/01/17/working-websockets-kitura-based-server/
// http://www.websocket.org/echo.html
extension Service: WebSocketService {
   func connected(connection: WebSocketConnection) {
      connections[connection.id] = connection
   }

   func disconnected(connection: WebSocketConnection, reason: WebSocketCloseReasonCode) {
      connections.removeValue(forKey: connection.id)
   }

   func received(message: Data, from: WebSocketConnection) {
      from.close(reason: .invalidDataType, description: "Server only accepts text messages.")
      connections.removeValue(forKey: from.id)
   }

   func received(message: String, from: WebSocketConnection) {
      //for (connectionId, connection) in connections {
      //   if connectionId != from.id {
      //      connection.send(message: message)
      //   }
      //}
   }
}
