//
//  Holding.swift
//  CSAI1
//
//  Represents a coin holding with dailyChange, costBasis, etc.
//

import Foundation

struct Holding: Identifiable, Codable, Equatable {
    var id = UUID()  // Changed to var so it can be overwritten during decoding if needed
    
    var coinName: String
    var coinSymbol: String
    
    // The number of coins the user holds
    var quantity: Double
    
    // The coin's current price in USD
    var currentPrice: Double
    
    // The total cost basis (quantity * average cost)
    var costBasis: Double
    
    // An optional image URL for the coin's icon
    var imageUrl: String?
    
    // Whether this coin is marked as favorite
    var isFavorite: Bool
    
    // The daily percentage change, e.g. +2.5 means +2.5%
    var dailyChange: Double
    
    // Computed properties
    var currentValue: Double {
        quantity * currentPrice
    }
    
    var profitLoss: Double {
        currentValue - costBasis
    }
}
