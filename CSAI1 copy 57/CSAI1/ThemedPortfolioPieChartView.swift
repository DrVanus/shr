import SwiftUI
import Charts

/// A donut (pie) chart view that displays each coin’s share of the portfolio
/// based on its current value (quantity * currentPrice).
struct ThemedPortfolioPieChartView: View {
    let holdings: [Holding]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart(holdings, id: \.id) { holding in
                SectorMark(
                    // Use current value to define slice size
                    angle: .value("Value", holding.currentPrice * holding.quantity),
                    innerRadius: .ratio(0.6),
                    outerRadius: .ratio(0.95)
                )
                .foregroundStyle(sliceColor(for: holding.coinSymbol))
            }
            // Hide the default legend
            .chartLegend(.hidden)
        } else {
            Text("Pie chart requires iOS 16+.")
                .foregroundColor(.gray)
        }
    }
    
    /// Returns a color based on the coin symbol.
    private func sliceColor(for symbol: String) -> Color {
        // Customize your slice colors here.
        let donutSliceColors: [Color] = [
            .green, Color("BrandAccent"), .mint, .blue, .teal, .purple, Color("GoldAccent")
        ]
        let hash = abs(symbol.hashValue)
        return donutSliceColors[hash % donutSliceColors.count]
    }
}

// MARK: - Preview
struct ThemedPortfolioPieChartView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample data for preview.
        let sampleHoldings: [Holding] = [
            Holding(
                id: UUID(),
                coinName: "Bitcoin",
                coinSymbol: "BTC",
                quantity: 1.5,
                currentPrice: 28000,
                costBasis: 25000,
                imageUrl: nil,
                isFavorite: false,
                dailyChange: 2.5,
                purchaseDate: Date()
            ),
            Holding(
                id: UUID(),
                coinName: "Ethereum",
                coinSymbol: "ETH",
                quantity: 10,
                currentPrice: 1800,
                costBasis: 15000,
                imageUrl: nil,
                isFavorite: false,
                dailyChange: -1.2,
                purchaseDate: Date()
            )
        ]
        
        ThemedPortfolioPieChartView(holdings: sampleHoldings)
            .frame(width: 150, height: 150)
            .preferredColorScheme(.dark)
    }
}
