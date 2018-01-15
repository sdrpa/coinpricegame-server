// Created by Sinisa Drpa on 1/15/18.

import Foundation
import Kitura
import LoggerAPI
import SSLService

enum SSLError: Error, LocalizedError {
   case invalidPath(path: String)

   var errorDescription: String? {
      switch self {
      case .invalidPath(let path):
         return "Could not find file at \(path)."
      }
   }
}

#if os(Linux)
func certChain() throws -> SSLService.Configuration {
   let certChainPath = "/etc/letsencrypt/live/coinpricegame.com/chain.pem"
   let certPath = "/etc/letsencrypt/live/coinpricegame.com/cert.pem"
   let privKeyPath = "/etc/letsencrypt/live/coinpricegame.com/privkey.pem"

   let fileManager = FileManager.default
   guard fileManager.fileExists(atPath: certChainPath) else {
      throw SSLError.invalidPath(path: certChainPath)
   }
   guard fileManager.fileExists(atPath: certPath) else {
      Log.error("Could not find file at \(certPath).")
      throw SSLError.invalidPath(path: certPath)
   }
   guard fileManager.fileExists(atPath: privKeyPath) else {
      throw SSLError.invalidPath(path: privKeyPath)
   }

   return SSLService.Configuration(withCACertificateDirectory: nil, usingCertificateFile: certPath, withKeyFile: privKeyPath, usingSelfSignedCerts: true)
}
#endif
