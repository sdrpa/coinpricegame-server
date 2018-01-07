// Created by Sinisa Drpa on 12/24/17.

import Dispatch
import Foundation
import Then

// https://bittrex.com/home/api
final class Bittrex {
   private let session = URLSession(configuration: .default)
   private var dataTask: URLSessionDataTask?
}

extension Bittrex {
   enum err: Error, LocalizedError {
      case summaryIsNil

      var errorDescription: String? {
         switch self {
         case .summaryIsNil:
            return "Could not get market summary."
         }
      }
   }
}

extension Bittrex {
   // https://bittrex.com/api/v1.1/public/getmarketsummaries
   func price() throws -> Price {
      do {
         let path = "https://bittrex.com/api/v1.1/public/getmarketsummaries"
         let request = URLRequest(path: path, method: "GET")
         let p = try await(getmarketsummaries(request: request))
         return p
      } catch let e {
         throw e
      }
   }
   
   private func getmarketsummaries(request: URLRequest) -> Promise<Price> {
      func decode(summaries data: Data) throws -> Price {
         let decoder = JSONDecoder()
         do {
            let response = try decoder.decode(Response.self, from: data)
            let summaries = response.result
            guard let lsk = summaries.first(where: { s in s.marketName == "BTC-LSK" }),
               let btc = summaries.first(where: { s in s.marketName == "USDT-BTC" }) else {
                  throw err.summaryIsNil
            }
            return Price(last: lsk.last, btc: btc.last)
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
                     let t = try decode(summaries: data)
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

// MARK: -

fileprivate struct Summary: Decodable {
   let marketName: String
   let bid: Decimal
   let ask: Decimal
   let last: Decimal

   enum CodingKeys: String, CodingKey {
      case marketName = "MarketName"
      case bid = "Bid"
      case ask = "Ask"
      case last = "Last"
   }
}

fileprivate struct Response: Decodable {
   let success: Bool
   let result: [Summary]
}
