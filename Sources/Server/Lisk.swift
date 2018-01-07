// Created by Sinisa Drpa on 12/24/17.

import Foundation
import Then

// https://docs.lisk.io/docs/lisk-api-080-transactions
final class Lisk {
   // http://node08.lisk.io:8000/api/transactions/get?id=
   private static var basePath: String {
      let port = String(8000)
      let path = "http://node08.lisk.io:" + port + "/api"
      return path
   }

   private let session = URLSession(configuration: .default)
   private var dataTask: URLSessionDataTask?
}

extension Lisk {
   enum err: Error, LocalizedError {
      case invalidTransaction

      var errorDescription: String? {
         switch self {
         case .invalidTransaction:
            return "Could not find the transaction. Have you sent 1 LSK to 6300871565689347639L?. Please be advised that it may take a minute for a transaction to appear in the blockchain. Wait a minute, then try again."
         }
      }
   }
}

extension Lisk {
   // curl -k -X GET http://node08.lisk.io:8000/api/transactions/get?id=1440867060433296113
   // https://explorer.lisk.io/tx/1440867060433296113
   func transaction(id: String) throws -> Transaction {
      let request = URLRequest(path: Lisk.basePath + "/transactions/get",
                               method: "GET",
                               params: ["id": id])
      let transaction = try await(gettransaction(request: request))
      return transaction
   }
}

extension Lisk {
   private func gettransaction(request: URLRequest) -> Promise<Transaction> {
      func decode(transaction data: Data) throws -> Transaction {
         struct Result: Decodable {
            let success: Bool
            let transaction: Transaction?
         }
         let decoder = JSONDecoder()
         do {
            let result = try decoder.decode(Result.self, from: data)
            guard let tx = result.transaction else {
               throw err.invalidTransaction
            }
            let customEpoch = "2016-5-24 17:00:00 +0000".toDate(format: "yyyy-MM-dd HH:mm:ss ZZZ").timeIntervalSince1970
            let timestamp = Int(customEpoch + Double(tx.timestamp))

            let transaction = Transaction(id: tx.id, timestamp: timestamp, senderId: tx.senderId, recipientId: tx.recipientId, amount: tx.amount, fee: tx.fee)
            return transaction
         } catch let e {
            throw e
         }
      }

      return Promise { [weak self] resolve, reject in
         self?.dataTask = self?.session.dataTask(with: request) { data, response, error in
            if let error = error {
               reject(error)
            } else if let data = data,
               let response = response as? HTTPURLResponse,
               response.statusCode == 200 {
                  do {
                     let t = try decode(transaction: data)
                     resolve(t)
                  } catch let e {
                     reject(e)
                  }
            }
         }
         self?.dataTask?.resume()
      }
   }
}
