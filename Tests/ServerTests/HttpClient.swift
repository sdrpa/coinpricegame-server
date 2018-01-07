// Created by Sinisa Drpa on 8/13/17.

import Then
import XCTest
@testable import Server

enum HttpMethod : String {
   case  GET
   case  POST
   case  DELETE
   case  PUT
}

struct HttpResponse {
   let status: Int
   let data: Data
}

typealias Params = Dictionary<String, Any>?

final class HttpClient {
   func makeRequest(_ path: String, params: Params = nil, method: HttpMethod) -> Promise<HttpResponse> {
      let session = URLSession(configuration: .default)
      let timeoutInterval: TimeInterval = 1

      // Configure request
      guard let url = URL(string: path) else { fatalError() }
      var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
      if let params = params {
         let jsonData = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         request.httpBody = jsonData
      }
      request.httpMethod = method.rawValue

      return Promise { resolve, reject in
         session.dataTask(with: url, completionHandler: { data, response, error in
            if let error = error {
               return reject(error)
            }
            guard let data = data, let response = response as? HTTPURLResponse else {
               fatalError()
            }
            resolve(HttpResponse(status: response.statusCode, data: data))
         }).resume()
      }
   }

   func request(_ path: String, method: HttpMethod) throws -> HttpResponse {
      do {
         return try await(makeRequest(path, method: method))
      } catch let e {
         throw e
      }
   }
}
