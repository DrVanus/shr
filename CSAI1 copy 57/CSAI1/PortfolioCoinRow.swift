//
//  PortfolioCoinRow.swift
//  CSAI1
//
//  Created by DM on 3/26/25.
//


import SwiftUI

struct PortfolioCoinRow: View {
    @ObservedObject var viewModel: PortfolioViewModel
    let holding: Holding
    
    var body: some View {
        let rowPL = holding.profitLoss  // profitLoss should be computed (see note below)
        
        HStack(spacing: 12) {
            // Coin image using AsyncImage; fallback to a system image if not available.
            if let urlStr = holding.imageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Image(systemName: "bitcoinsign.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.gray)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "bitcoinsign.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(holding.coinName) (\(holding.coinSymbol))")
                        .font(.headline)
                    Button {
                        viewModel.toggleFavorite(holding)
                    } label: {
                        Image(systemName: holding.isFavorite ? "star.fill" : "star")
                            .foregroundColor(holding.isFavorite ? .yellow : .gray)
                    }
                    .buttonStyle(.plain)
                }
                
                Text(String(format: "24h: %.2f%%", holding.dailyChange))
                    .foregroundColor(holding.dailyChange >= 0 ? .green : .red)
                    .font(.caption)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(holding.currentPrice, specifier: "%.2f")")
                    .font(.headline)
                Text(String(format: "P/L: $%.2f", rowPL))
                    .foregroundColor(rowPL >= 0 ? .green : .red)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 8)
        .background(rowPL >= 0 ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
        .cornerRadius(8)
    }
}

struct PortfolioCoinRow_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = PortfolioViewModel()
        let sampleHolding = Holding(
            id: UUID(),
            coinName: "Bitcoin",
            coinSymbol: "BTC",
            quantity: 1.0,
            currentPrice: 30000,
            costBasis: 25000,
            imageUrl: nil,
            isFavorite: true,
            dailyChange: 2.0,
            purchaseDate: Date()
        )
        PortfolioCoinRow(viewModel: viewModel, holding: sampleHolding)
            .previewLayout(.sizeThatFits)
    }
}