import Foundation

// MARK: - Coin Models

struct CoinGeckoCoin: Identifiable, Codable {
    let id: String
    let symbol: String
    let name: String?
    let image: String?
    let current_price: Double?
    
    let market_cap: Double?
    let market_cap_rank: Int?
    let total_volume: Double?
    let high_24h: Double?
    let low_24h: Double?
    let price_change_24h: Double?
    let price_change_percentage_24h: Double?
    let price_change_percentage_1h_in_currency: Double?
    
    let fully_diluted_valuation: Double?
    let circulating_supply: Double?
    let total_supply: Double?
    let ath: Double?
    let ath_change_percentage: Double?
    let ath_date: String?
    let atl: Double?
    let atl_change_percentage: Double?
    let atl_date: String?
    let last_updated: String?
    
    // For trending endpoint
    let coin_id: Int?
    let thumb: String?
    let small: String?
    let large: String?
    let slug: String?
}

struct TrendingResponse: Codable {
    let coins: [TrendingCoinItem]
}

struct TrendingCoinItem: Codable {
    let item: CoinGeckoCoin
}

// MARK: - Chat Message Model

/// Represents a single chat message from either the user or the AI.
struct ChatMessage: Identifiable, Codable {
    var id: UUID = UUID()
    var sender: String   // "user" or "ai"
    var text: String
    var timestamp: Date = Date()
    var isError: Bool = false
}

// MARK: - Portfolio Models

/// Represents a cryptocurrency holding in the portfolio.
struct Holding: Identifiable, Codable, Equatable {  // Conforms to Equatable
    var id: UUID = UUID()
    var coinName: String
    var coinSymbol: String
    var quantity: Double
    var currentPrice: Double
    var costBasis: Double
    var imageUrl: String?
    var isFavorite: Bool
    var dailyChange: Double
    var purchaseDate: Date

    /// The current value of this holding.
    var currentValue: Double {
        return quantity * currentPrice
    }
    
    /// The profit or loss for this holding.
    var profitLoss: Double {
        return (currentPrice - costBasis) * quantity
    }
}

/// Unified Transaction model used in the app to represent both manual and exchange transactions.
struct Transaction: Identifiable, Codable {
    /// Unique identifier for the transaction.
    let id: UUID
    /// The symbol of the cryptocurrency (e.g., "BTC").
    let coinSymbol: String
    /// The quantity of cryptocurrency transacted.
    let quantity: Double
    /// The price per coin at the time of the transaction.
    let pricePerUnit: Double
    /// The date when the transaction occurred.
    let date: Date
    /// Indicates whether this is a buy transaction (true) or a sell (false).
    let isBuy: Bool
    /// Flag indicating if this transaction was manually entered (true) or synced from an exchange/wallet (false).
    let isManual: Bool
    
    /// Initializes a new Transaction.
    /// - Parameters:
    ///   - id: A unique identifier (defaults to a new UUID).
    ///   - coinSymbol: The cryptocurrency symbol.
    ///   - quantity: The quantity of cryptocurrency transacted.
    ///   - pricePerUnit: The price per coin at the time of the transaction.
    ///   - date: The transaction date.
    ///   - isBuy: True for a buy transaction, false for a sell.
    ///   - isManual: True if the transaction is user-entered, false if it’s synced (defaults to true).
    init(id: UUID = UUID(), coinSymbol: String, quantity: Double, pricePerUnit: Double, date: Date, isBuy: Bool, isManual: Bool = true) {
        self.id = id
        self.coinSymbol = coinSymbol
        self.quantity = quantity
        self.pricePerUnit = pricePerUnit
        self.date = date
        self.isBuy = isBuy
        self.isManual = isManual
    }
}

extension CoinGeckoCoin {
    /// Returns the 1H percentage change, defaulting to 0.0 if nil
    var change1h: Double {
        return price_change_percentage_1h_in_currency ?? 0.0
    }
    
    /// Returns the 24H percentage change, defaulting to 0.0 if nil
    var change24h: Double {
        return price_change_percentage_24h ?? 0.0
    }
}
