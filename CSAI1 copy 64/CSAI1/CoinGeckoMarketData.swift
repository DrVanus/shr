//
//  CoinGeckoMarketData.swift
//  CSAI1
//
//  Created by DM on 3/28/25.
//

import Foundation

struct CoinGeckoMarketData: Codable {
    let id: String
    let symbol: String
    let name: String
    let image: String
    let current_price: Double
    let total_volume: Double
    let market_cap: Double?            // Added new property for market capitalization
    let price_change_percentage_24h: Double?
    let price_change_percentage_1h_in_currency: Double?
    let sparkline_in_7d: SparklineData?
}

struct SparklineData: Codable {
    let price: [Double]
}
