//
//  PortfolioLegendView.swift
//  CSAI1
//
//  Created by DM on 3/26/25.
//


import SwiftUI

struct PortfolioLegendView: View {
    let holdings: [Holding]
    let totalValue: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(holdings) { holding in
                let val = holding.currentPrice * holding.quantity
                let pct = totalValue > 0 ? (val / totalValue * 100) : 0
                HStack(spacing: 6) {
                    Circle()
                        .fill(sliceColor(for: holding.coinSymbol))
                        .frame(width: 8, height: 8)
                    
                    Text("\(holding.coinSymbol) \(String(format: "%.1f", pct))%")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func sliceColor(for symbol: String) -> Color {
        let donutSliceColors: [Color] = [
            .green, Color("BrandAccent"), .mint, .blue, .teal, .purple, Color("GoldAccent")
        ]
        let hash = abs(symbol.hashValue)
        return donutSliceColors[hash % donutSliceColors.count]
    }
}

struct PortfolioLegendView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioLegendView(holdings: [
            Holding(id: UUID(), coinName: "Bitcoin", coinSymbol: "BTC", quantity: 1.0, currentPrice: 30000, costBasis: 25000, imageUrl: nil, isFavorite: false, dailyChange: 2.0, purchaseDate: Date()),
            Holding(id: UUID(), coinName: "Ethereum", coinSymbol: "ETH", quantity: 10, currentPrice: 2000, costBasis: 1800, imageUrl: nil, isFavorite: false, dailyChange: -1.5, purchaseDate: Date())
        ], totalValue: (30000 * 1.0) + (2000 * 10))
        .preferredColorScheme(.dark)
        .previewLayout(.sizeThatFits)
    }
}