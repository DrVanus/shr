import Foundation

enum CryptoAPIError: Error {
    case invalidURL
    case requestFailed
    case decodingError
}

class CryptoAPIService {
    static let shared = CryptoAPIService()
    private init() {}
    
    /// Fetches the current USD prices for a list of coin IDs.
    /// - Parameters:
    ///   - coinIDs: An array of coin IDs (for example: "bitcoin", "ethereum", etc.).
    ///   - completion: Returns a dictionary mapping each coin ID to its current price in USD.
    func fetchCurrentPrices(for coinIDs: [String], completion: @escaping (Result<[String: Double], Error>) -> Void) {
        let ids = coinIDs.joined(separator: ",")
        let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=\(ids)&vs_currencies=usd"
        guard let url = URL(string: urlString) else {
            completion(.failure(CryptoAPIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(CryptoAPIError.requestFailed))
                return
            }
            
            do {
                // Expected JSON format:
                // { "bitcoin": {"usd": 35000}, "ethereum": {"usd": 1800}, ... }
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    var prices: [String: Double] = [:]
                    for (coin, value) in json {
                        if let dict = value as? [String: Double],
                           let usdPrice = dict["usd"] {
                            prices[coin] = usdPrice
                        }
                    }
                    completion(.success(prices))
                } else {
                    completion(.failure(CryptoAPIError.decodingError))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// (Optional) Fetches historical price data for a specific coin over the past given number of days.
    /// - Parameters:
    ///   - coinID: The coin's ID (e.g. "bitcoin").
    ///   - days: The number of days for which to fetch historical data.
    ///   - completion: Returns an array of (Date, Double) tuples, where Date is the timestamp and Double is the price.
    func fetchHistoricalPrices(for coinID: String, days: Int, completion: @escaping (Result<[(Date, Double)], Error>) -> Void) {
        let urlString = "https://api.coingecko.com/api/v3/coins/\(coinID)/market_chart?vs_currency=usd&days=\(days)"
        guard let url = URL(string: urlString) else {
            completion(.failure(CryptoAPIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(CryptoAPIError.requestFailed))
                return
            }
            
            do {
                // Expected JSON format: { "prices": [[timestamp, price], ...] }
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let pricesArray = json["prices"] as? [[Any]] {
                    var historicalPrices: [(Date, Double)] = []
                    for entry in pricesArray {
                        if let timestamp = entry[0] as? Double,
                           let price = entry[1] as? Double {
                            // API returns timestamp in milliseconds; convert to seconds.
                            let date = Date(timeIntervalSince1970: timestamp / 1000)
                            historicalPrices.append((date, price))
                        }
                    }
                    completion(.success(historicalPrices))
                } else {
                    completion(.failure(CryptoAPIError.decodingError))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
