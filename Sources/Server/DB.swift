// Created by Sinisa Drpa on 12/24/17.

import Foundation
import SwiftKuery
import SwiftKueryPostgreSQL
import Then

struct DB {
   enum err: Error {
      case fatal(String?)
   }
}

extension DB {
   @discardableResult
   static func submit(price: Decimal, senderId: String, transactionId: String, ip: String, date: Date = Date()) throws -> Prediction {
      let connection = PostgreSQLConnection(host: C.db.host, port: C.db.port, options: [.userName(C.db.user), .password(C.db.pass), .databaseName(C.db.name)])
      defer { connection.closeConnection() }
      do {
         let raw =
         """
         INSERT INTO predictions (sender_id, transaction_id, price, created_at, ip)
         VALUES ($1, $2, $3, $4, $5);
         """
         _ = try await(connection.connect())
         let result = try await(connection.execute(raw, parameters: [senderId, transactionId, price, date.iso8601, ip]))
         if let queryError = result.asError {
            throw queryError
         }
         return Prediction(senderId: senderId, transactionId: transactionId, price: price, date: date)
      } catch let e {
         throw e
      }
   }

   static func all(from start: Date, to end: Date) throws -> [Prediction] {
      func postgresDate(from date: Date) -> String {
         let formatter = DateFormatter()
         formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
         formatter.timeZone = TimeZone(identifier: "UTC")
         return formatter.string(from: date)
      }

      let connection = PostgreSQLConnection(host: C.db.host, port: C.db.port, options: [.userName(C.db.user), .password(C.db.pass), .databaseName(C.db.name)])
      defer { connection.closeConnection() }
      do {
         let raw =
         """
         SELECT sender_id, transaction_id, price, created_at
         FROM predictions
         WHERE created_at BETWEEN $1 AND $2
         ORDER BY created_at DESC;
         """
         _ = try await(connection.connect())
         let params = [postgresDate(from: start), postgresDate(from: end)]
         let result = try await(connection.execute(raw, parameters: params))
         switch result {
         case .resultSet(let resultSet):
            let all = DB.rows(from: resultSet).flatMap(Prediction.init(rows:))
            return all
         case .success(_), .successNoData:
            return []
         case .error(_):
            return []
         }
      } catch let e {
         throw e
      }
   }

   static func prediction(transactionId: String) throws -> Prediction? {
      let connection = PostgreSQLConnection(host: C.db.host, port: C.db.port, options: [.userName(C.db.user), .password(C.db.pass), .databaseName(C.db.name)])
      defer { connection.closeConnection() }
      do {
         let raw =
         """
         SELECT sender_id, transaction_id, price, created_at
         FROM predictions
         WHERE transaction_id = $1;
         """
         _ = try await(connection.connect())
         let result = try await(connection.execute(raw, parameters: [transactionId]))
         switch result {
         case .resultSet(let resultSet):
            guard let prediction = DB.rows(from: resultSet).flatMap(Prediction.init(rows:)).first else {
               return nil
            }
            return prediction
         case .success(_), .successNoData:
            return nil
         case .error(_):
            return nil
         }
      } catch let e {
         throw e
      }
   }

   static func prediction(price: Decimal) throws -> Prediction? {
      let connection = PostgreSQLConnection(host: C.db.host, port: C.db.port, options: [.userName(C.db.user), .password(C.db.pass), .databaseName(C.db.name)])
      defer { connection.closeConnection() }
      do {
         let raw =
         """
         SELECT sender_id, transaction_id, price, created_at
         FROM predictions
         WHERE price = $1;
         """
         _ = try await(connection.connect())
         let result = try await(connection.execute(raw, parameters: [price]))
         switch result {
         case .resultSet(let resultSet):
            guard let prediction = DB.rows(from: resultSet).flatMap(Prediction.init(rows:)).first else {
               return nil
            }
            return prediction
         case .success(_), .successNoData:
            return nil
         case .error(_):
            return nil
         }
      } catch let e {
         throw e
      }
   }

   static func save(price: Price, date: Date) throws {
      let connection = PostgreSQLConnection(host: C.db.host, port: C.db.port, options: [.userName(C.db.user), .password(C.db.pass), .databaseName(C.db.name)])
      defer { connection.closeConnection() }
      do {
         let raw =
         """
         INSERT INTO prices (price, btc, updated_at)
         VALUES ($1, $2, $3);
         """
         _ = try await(connection.connect())
         let params: [Any] = [price.last, price.btc, date.iso8601]
         let result = try await(connection.execute(raw, parameters: params))
         if let queryError = result.asError {
            throw queryError
         }
      } catch let e {
         throw e
      }
   }

   static func price(nearestToDate date: Date) throws -> Price? {
      let connection = PostgreSQLConnection(host: C.db.host, port: C.db.port, options: [.userName(C.db.user), .password(C.db.pass), .databaseName(C.db.name)])
      defer { connection.closeConnection() }
      do {
         let raw =
         """
         SELECT price, btc, updated_at
         FROM prices
         WHERE updated_at < $1
         ORDER BY updated_at DESC
         LIMIT 1;
         """
         _ = try await(connection.connect())
         let result = try await(connection.execute(raw, parameters: [date]))
         switch result {
         case .resultSet(let resultSet):
            guard let price = DB.rows(from: resultSet).flatMap(Price.init(rows:)).first else {
               return nil
            }
            return price
         case .success(_), .successNoData:
            return nil
         case .error(_):
            return nil
         }
      } catch let e {
         throw e
      }
   }
}

extension DB {
   static func truncate() throws {
      let connection = PostgreSQLConnection(host: C.db.host, port: C.db.port, options: [.userName(C.db.user), .password(C.db.pass), .databaseName(C.db.name)])
      defer {
         connection.closeConnection()
      }
      do {
         let raw = "TRUNCATE predictions, prices;"
         _ = try await(connection.connect())
         let result = try await(connection.execute(raw))
         if let error = result.asError {
            throw error
         }
      } catch let e {
         throw e
      }
   }
}
