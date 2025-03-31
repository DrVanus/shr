import Foundation

struct PortfolioItem: Codable {
    let symbol: String
    let balance: Double
    let usdValue: Double
}

struct TradeResult: Codable {
    let success: Bool
    let message: String
}

/// Dummy ShrimpyManager simulating REST API interactions for portfolio tracking and trading.
/// Replace these dummy responses with real API calls once you have your API credentials.
class ShrimpyManager {
    static let shared = ShrimpyManager()
    private init() {}
    
    /// Simulate creating a Shrimpy user.
    func createUser(completion: @escaping (Result<String, Error>) -> Void) {
        // Return dummy user id immediately
        completion(.success("dummy-shrimpy-user-id"))
    }
    
    /// Simulate linking an exchange account.
    func linkExchangeAccount(exchange: String,
                               publicKey: String,
                               privateKey: String,
                               passphrase: String? = nil,
                               completion: @escaping (Result<String, Error>) -> Void) {
        // Return a dummy account id immediately
        completion(.success("dummy-account-id-for-\(exchange)"))
    }
    
    /// Simulate fetching portfolio data.
    func fetchPortfolio(completion: @escaping (Result<[PortfolioItem], Error>) -> Void) {
        // Return a dummy portfolio immediately
        let dummyPortfolio = [
            PortfolioItem(symbol: "BTC", balance: 0.5, usdValue: 15000),
            PortfolioItem(symbol: "ETH", balance: 10.0, usdValue: 2000)
        ]
        completion(.success(dummyPortfolio))
    }
    
    /// Simulate executing a trade.
    func executeTrade(fromSymbol: String,
                      toSymbol: String,
                      amount: Double,
                      completion: @escaping (Result<TradeResult, Error>) -> Void) {
        // Return a simulated trade result immediately
        let result = TradeResult(success: true, message: "Simulated trade: \(amount) \(fromSymbol) to \(toSymbol)")
        completion(.success(result))
    }
}
