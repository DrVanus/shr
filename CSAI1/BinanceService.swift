//
//  BinanceService.swift
//  CSAI1
//
//  Created by DM on 3/28/25.
//


//
//  BinanceService.swift
//  CSAI1
//
//  Created by You on [Date].
//

import Foundation

actor BinanceService {
    /// Fetch sparkline data (e.g. daily closes for the last 7 days) from Binance for a symbol like "BTCUSDT".
    static func fetchSparkline(symbol: String) async -> [Double] {
        let pair = symbol.uppercased() + "USDT"
        let urlString = "https://api.binance.com/api/v3/klines?symbol=\(pair)&interval=1d&limit=7"
        guard let url = URL(string: urlString) else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [[Any]] {
                // The 5th element in each array is the "close" price.
                return json.map { arr in
                    Double(arr[4] as? String ?? "0") ?? 0
                }
            }
        } catch {
            print("Binance error: \(error)")
        }
        return []
    }
}