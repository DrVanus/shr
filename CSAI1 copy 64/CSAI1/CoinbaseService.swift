//
//  CoinbaseService.swift
//  CSAI1
//
//  Created by DM on 3/21/25.
//  Updated with more robust error handling
//

import Foundation

struct CoinbaseSpotPriceResponse: Decodable {
    // We *expect* a "data" field, but to avoid crashing on missing data,
    // we can mark it optional or handle it carefully.
    let data: DataField?

    struct DataField: Decodable {
        let base: String      // e.g., "BTC"
        let currency: String  // e.g., "USD"
        let amount: String    // e.g., "27450.12"
    }
}

actor CoinbaseService {

    /// Asynchronously fetch the spot price for a given coin (e.g., "BTC") in a specified fiat (e.g., "USD").
    /// If parsing fails or the response is missing "data", we return nil.
    /// We also catch timeouts and general networking errors.
    func fetchSpotPrice(coin: String = "BTC", fiat: String = "USD") async -> Double? {
        let endpoint = "https://api.coinbase.com/v2/prices/\(coin)-\(fiat)/spot"

        // In case user is offline or the endpoint is unreachable
        guard let url = URL(string: endpoint) else {
            print("CoinbaseService: Invalid URL: \(endpoint)")
            return nil
        }

        do {
            // We can set a custom timeout if needed:
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10
            config.timeoutIntervalForResource = 15
            let session = URLSession(configuration: config)

            let (data, response) = try await session.data(from: url)

            // Optional: check status code
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                print("CoinbaseService: HTTP status code = \(httpResponse.statusCode)")
                return nil
            }

            // Attempt to decode
            let decoded = try JSONDecoder().decode(CoinbaseSpotPriceResponse.self, from: data)

            // If `decoded.data` is missing or nil, return nil
            guard let dataField = decoded.data else {
                print("CoinbaseService: 'data' field was missing in the response.")
                return nil
            }

            // Convert amount to Double
            return Double(dataField.amount)

        } catch {
            // We'll see errors about timeouts or keyNotFound
            print("CoinbaseService error: \(error.localizedDescription)")
            return nil
        }
    }
}
