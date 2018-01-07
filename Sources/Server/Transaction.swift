// Created by Sinisa Drpa on 12/31/17.

import Foundation

struct Transaction: Decodable {
   let id: String
   let timestamp: Int
   let senderId: String
   let recipientId: String
   let amount: Int
   let fee: Int
}
