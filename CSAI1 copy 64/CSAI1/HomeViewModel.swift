//
//  HomeViewModel.swift
//  CRYPTOSAI
//
//  Minimal ViewModel to avoid duplication of coin structs.
//  Provides placeholders for watchlist, trending, and news.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    // Example portfolio data
    @Published var portfolioValue: Double = 65000
    @Published var dailyChangePercentage: Double = 2.34
    @Published var dailyChangeAmount: Double = 1500
    
    // AI highlight or insight text
    @Published var aiInsight: String = "Your portfolio rose 2.3% in the last 24 hours."
    
    // Basic watchlist as [String], e.g., "BTC", "ETH"
    @Published var watchlist: [String] = ["BTC", "ETH", "SOL"]
    
    // **Trending** array that HomeView references
    @Published var trending: [String] = ["XRP", "DOGE", "ADA"]
    
    // News headlines placeholders
    @Published var newsHeadlines: [String] = [
        "BTC Approaches $100K",
        "XRP Gains Legal Clarity",
        "ETH2 Merge Update"
    ]
    
    // If you want to store or fetch real data from an API, add it here
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Optionally do any initial fetch calls
        // fetchData()
    }
    
    func fetchData() {
        // If you want real data, put your API calls here
        // For now, placeholders
    }
}
