//
//  to.swift
//  CSAI1
//
//  Created by DM on 3/18/25.
//


import Foundation

// Simple struct to decode CoinGecko's response for a single coin
struct CoinGeckoPriceResponse: Decodable {
    let id: String
    let symbol: String
    let name: String
    let image: String
    let current_price: Double
}

// A service that fetches live data from CoinGecko
class CryptoAPIService {
    static let shared = CryptoAPIService()
    
    private init() {} // Singleton
    
    private let session = URLSession.shared
    private let baseURL = "https://api.coingecko.com/api/v3"
    
    // Fetch current market data for a single coin ID (e.g., "bitcoin", "ethereum")
    func fetchCoinData(coinID: String, completion: @escaping (CoinGeckoPriceResponse?) -> Void) {
        // Example endpoint: /coins/markets?vs_currency=usd&ids=bitcoin
        let urlString = "\(baseURL)/coins/markets?vs_currency=usd&ids=\(coinID)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        session.dataTask(with: url) { data, response, error in
            // Basic error handling
            guard
                let data = data,
                error == nil,
                let decoded = try? JSONDecoder().decode([CoinGeckoPriceResponse].self, from: data),
                let firstCoin = decoded.first
            else {
                completion(nil)
                return
            }
            completion(firstCoin)
        }.resume()
    }
}