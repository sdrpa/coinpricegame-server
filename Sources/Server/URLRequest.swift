// Created by Sinisa Drpa on 12/31/17.

import Foundation

extension URLRequest {
   init(path: String, method: String) {
      self.init(path: path, method: method, params: [:])
   }

   init(path: String, method: String, params: [String: String]) {
      guard var url = URL(string: path) else {
         fatalError()
      }
      url = url.appendingQueryParameters(params)
      self = URLRequest(url: url)
      self.httpMethod = method
   }
}

// MARK: -

protocol URLQueryParameterStringConvertible {
   var queryParameters: String {get}
}

extension Dictionary: URLQueryParameterStringConvertible {
   /**
    This computed property returns a query parameters string from the given NSDictionary. For
    example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
    string will be @"day=Tuesday&month=January".
    @return The computed parameters string.
    */
   var queryParameters: String {
      var parts: [String] = []
      for (aKey, aValue) in self {
         let key = String(describing: aKey).encodingAddingPercent()
         let value = String(describing: aValue).encodingAddingPercent()
         parts.append("\(key)=\(value)")
      }
      return parts.joined(separator: "&")
   }
}

extension URL {
   /**
    Creates a new URL by adding the given query parameters.
    @param parametersDictionary The query parameter dictionary to add.
    @return A new URL.
    */
   func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
      let URLString : String = "\(self.absoluteString)?\(parametersDictionary.queryParameters)"
      return URL(string: URLString)!
   }
}

extension String {
   func lastIndexOf(target: String) -> Int? {
      if let range = self.range(of: target, options: .backwards) {
         return self.distance(from: startIndex, to: range.lowerBound)
      } else {
         return nil
      }
   }

   func encodingAddingPercent() -> String {
      guard let string = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
         fatalError()
      }
      return string
   }
}

