//
//  CoinbaseSpotPriceResponse.swift
//  CSAI1
//
//  Created by DM on 3/21/25.
//


import Foundation

// Define a model matching the Coinbase spot price response.
struct CoinbaseSpotPriceResponse: Decodable {
    let data: DataField
    
    struct DataField: Decodable {
        let base: String      // e.g., "BTC"
        let currency: String  // e.g., "USD"
        let amount: String    // e.g., "27450.12"
    }
}

class CoinbaseService {
    
    /// Fetch the spot price for a given coin (e.g., "BTC") in a specified fiat (e.g., "USD").
    func fetchSpotPrice(coin: String = "BTC", fiat: String = "USD", completion: @escaping (Double?) -> Void) {
        let endpoint = "https://api.coinbase.com/v2/prices/\(coin)-\(fiat)/spot"
        guard let url = URL(string: endpoint) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let _ = error {
                completion(nil)
                return
            }
            guard let data = data else {
                completion(nil)
                return
            }
            do {
                let decoded = try JSONDecoder().decode(CoinbaseSpotPriceResponse.self, from: data)
                let amountString = decoded.data.amount
                if let amount = Double(amountString) {
                    completion(amount)
                } else {
                    completion(nil)
                }
            } catch {
                print("Decoding error: \(error)")
                completion(nil)
            }
        }.resume()
    }
}