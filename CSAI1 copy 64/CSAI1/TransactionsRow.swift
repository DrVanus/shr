//
//  TransactionsRow.swift
//  CSAI1
//
//  Created by DM on 3/26/25.
//


import SwiftUI

struct TransactionsRow: View {
    let symbol: String
    let quantity: Double
    let price: Double
    let date: Date
    let isBuy: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isBuy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(isBuy ? .green : .red)
            
            VStack(alignment: .leading) {
                Text("\(isBuy ? "Buy" : "Sell") \(symbol)")
                    .font(.headline)
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(quantity, specifier: "%.2f") @ $\(price, specifier: "%.2f")")
                .font(.subheadline)
        }
        .padding(.vertical, 6)
    }
}

struct TransactionsRow_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsRow(symbol: "BTC", quantity: 0.5, price: 20000, date: Date(), isBuy: true)
            .previewLayout(.sizeThatFits)
    }
}