//
//  CoinbaseService.swift
//  CSAI1
//
//  Created by DM on 3/21/25.
//  Updated to use async/await concurrency.
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

actor CoinbaseService {
    
    /// Asynchronously fetch the spot price for a given coin (e.g., "BTC") in a specified fiat (e.g., "USD").
    func fetchSpotPrice(coin: String = "BTC", fiat: String = "USD") async -> Double? {
        let endpoint = "https://api.coinbase.com/v2/prices/\(coin)-\(fiat)/spot"
        guard let url = URL(string: endpoint) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(CoinbaseSpotPriceResponse.self, from: data)
            return Double(decoded.data.amount)
        } catch {
            print("Coinbase error: \(error)")
            return nil
        }
    }
}
