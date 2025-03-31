//
//  GlobalSummaryView.swift
//  CSAI1
//
//  Created by DM on 3/30/25.
//


//
//  GlobalSummaryView.swift
//  CryptoSageAI
//
//  Created by ChatGPT on 3/30/25
//

import SwiftUI

/// A dedicated view for displaying global market stats:
/// Market Cap, Volume, BTC Dominance, MC 24h, etc.
struct GlobalSummaryView: View {
    
    // We'll rely on the same MarketViewModel you already have,
    // since it holds globalData and error states.
    @EnvironmentObject var vm: MarketViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            if let global = vm.globalData {
                // 1) Market Cap & Volume row
                HStack {
                    if let cap = global.total_market_cap?["usd"] {
                        Text("Market Cap: \(cap.formattedWithAbbreviations())")
                            .font(.caption)
                            .foregroundColor(.white)
                    } else {
                        Text("Market Cap: --")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    if let vol = global.total_volume?["usd"] {
                        Text("Volume: \(vol.formattedWithAbbreviations())")
                            .font(.caption)
                            .foregroundColor(.white)
                    } else {
                        Text("Volume: --")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                // 2) BTC Dominance & 24h row
                HStack {
                    if let btcDom = global.market_cap_percentage?["btc"] {
                        Text("BTC Dominance: \(String(format: "%.1f", btcDom))%")
                            .font(.caption2)
                            .foregroundColor(.white)
                    } else {
                        Text("BTC Dominance: --")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    if let mcChange = global.market_cap_change_percentage_24h_usd {
                        Text("MC 24h: \(String(format: "%.2f", mcChange))%")
                            .font(.caption2)
                            .foregroundColor(mcChange >= 0 ? .green : .red)
                    } else {
                        Text("MC 24h: --")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            } else {
                // Show error or loading state
                if let gErr = vm.globalError {
                    Text(gErr)
                        .font(.footnote)
                        .foregroundColor(.red)
                } else {
                    Text("Loading global market data...")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // 3) If there's a coinError, show it
            if let cErr = vm.coinError {
                Text(cErr)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
    }
}