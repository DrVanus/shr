import Foundation

struct Transaction: Identifiable, Codable {
    let id = UUID()
    let coinSymbol: String
    let date: Date
    let quantity: Double
    let pricePerUnit: Double
    let isBuy: Bool
}
