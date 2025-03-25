//
//  PortfolioViewModel.swift
//  CSAI1
//
//  Manages holdings, calculates totals, persists data, handles sorting/favorites,
//  and generates chart data. Now with 6 coins totaling ~65k, each with correct icons.
//

import SwiftUI

enum ChartTimeRange: String, CaseIterable {
    case week = "1W"
    case month = "1M"
    case year = "1Y"
}

enum SortOption {
    case name, value, profitLoss
}

class PortfolioViewModel: ObservableObject {
    @Published var holdings: [Holding] = []
    
    // Summaries
    @Published var totalValue: Double = 0.0
    @Published var totalProfitLoss: Double = 0.0
    
    // Chart data for the mini performance chart
    @Published var performanceData: [Double] = []
    
    // Sorting & filtering
    @Published var sortOption: SortOption = .name
    @Published var showFavoritesOnly: Bool = false
    
    init() {
        loadFromUserDefaults()
        if holdings.isEmpty {
            loadSampleHoldings()
        }
        recalcTotals()
        generatePerformanceData(for: .week)
    }
    
    // MARK: - Sample Data (~$65k total)
    func loadSampleHoldings() {
        holdings = [
            // BTC: ~35k total
            Holding(
                coinName: "Bitcoin",
                coinSymbol: "BTC",
                quantity: 1.0,
                currentPrice: 35000,
                costBasis: 20000,
                imageUrl: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png",
                isFavorite: true,
                dailyChange: 2.1
            ),
            // ETH: ~18k total
            Holding(
                coinName: "Ethereum",
                coinSymbol: "ETH",
                quantity: 10.0,
                currentPrice: 1800,
                costBasis: 15000,
                imageUrl: "https://assets.coingecko.com/coins/images/279/large/ethereum.png",
                isFavorite: false,
                dailyChange: -1.2
            ),
            // SOL: ~2k total
            Holding(
                coinName: "Solana",
                coinSymbol: "SOL",
                quantity: 100.0,
                currentPrice: 20,
                costBasis: 2000,
                imageUrl: "https://assets.coingecko.com/coins/images/4128/large/solana.png",
                isFavorite: false,
                dailyChange: 3.5
            ),
            // DOGE: ~800 total
            Holding(
                coinName: "Dogecoin",
                coinSymbol: "DOGE",
                quantity: 10000.0,
                currentPrice: 0.08,
                costBasis: 500,
                imageUrl: "https://assets.coingecko.com/coins/images/5/large/dogecoin.png",
                isFavorite: false,
                dailyChange: -0.3
            ),
            // LTC: ~4k total
            Holding(
                coinName: "Litecoin",
                coinSymbol: "LTC",
                quantity: 50.0,
                currentPrice: 80,
                costBasis: 3000,
                imageUrl: "https://assets.coingecko.com/coins/images/2/large/litecoin.png",
                isFavorite: false,
                dailyChange: 1.0
            ),
            // BNB: ~6k total
            Holding(
                coinName: "BNB",
                coinSymbol: "BNB",
                quantity: 20.0,
                currentPrice: 300,
                costBasis: 3000,
                imageUrl: "https://assets.coingecko.com/coins/images/12591/large/binance-coin-bnb.png",
                isFavorite: false,
                dailyChange: 2.2
            )
        ]
    }
    
    // MARK: - Persistence
    func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(holdings)
            UserDefaults.standard.set(data, forKey: "holdings")
        } catch {
            print("Error saving holdings: \(error)")
        }
    }
    
    func loadFromUserDefaults() {
        guard let data = UserDefaults.standard.data(forKey: "holdings") else { return }
        do {
            let decoded = try JSONDecoder().decode([Holding].self, from: data)
            holdings = decoded
        } catch {
            print("Error loading holdings: \(error)")
        }
    }
    
    // MARK: - Totals
    func recalcTotals() {
        totalValue = holdings.reduce(0) { $0 + $1.currentValue }
        totalProfitLoss = holdings.reduce(0) { $0 + $1.profitLoss }
    }
    
    // MARK: - CRUD
    func addHolding(coinName: String,
                    coinSymbol: String,
                    quantity: Double,
                    currentPrice: Double,
                    costBasis: Double,
                    imageUrl: String?) {
        // Random dailyChange for new coins
        let dailyChange = Double.random(in: -5...5)
        
        let newHolding = Holding(
            coinName: coinName,
            coinSymbol: coinSymbol,
            quantity: quantity,
            currentPrice: currentPrice,
            costBasis: costBasis,
            imageUrl: imageUrl,
            isFavorite: false,
            dailyChange: dailyChange
        )
        holdings.append(newHolding)
        recalcTotals()
        saveToUserDefaults()
    }
    
    func removeHolding(at offsets: IndexSet) {
        holdings.remove(atOffsets: offsets)
        recalcTotals()
        saveToUserDefaults()
    }
    
    func toggleFavorite(_ holding: Holding) {
        guard let idx = holdings.firstIndex(where: { $0.id == holding.id }) else { return }
        holdings[idx].isFavorite.toggle()
        saveToUserDefaults()
    }
    
    // MARK: - Chart Data
    func generatePerformanceData(for range: ChartTimeRange) {
        let base = totalValue
        let count: Int
        switch range {
        case .week:
            count = 7
        case .month:
            count = 30
        case .year:
            count = 52
        }
        performanceData = (0..<count).map { _ in
            let variation = Double.random(in: -2000...2000)
            return max(0, base + variation)
        }
    }
    
    // MARK: - Sorting & Favorites
    var displayedHoldings: [Holding] {
        let filtered = showFavoritesOnly
            ? holdings.filter { $0.isFavorite }
            : holdings
        
        switch sortOption {
        case .name:
            return filtered.sorted { $0.coinName.lowercased() < $1.coinName.lowercased() }
        case .value:
            return filtered.sorted { $0.currentValue > $1.currentValue }
        case .profitLoss:
            return filtered.sorted { $0.profitLoss > $1.profitLoss }
        }
    }
}
