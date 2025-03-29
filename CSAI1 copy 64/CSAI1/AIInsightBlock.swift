//
//  AIInsightBlock.swift
//  CSAI1
//
//  Created by DM on 3/25/25.
//


import SwiftUI

/// A view that displays AI-generated insights about the user's portfolio.
struct AIInsightBlock: View {
    // Example: pass in any data or view models you need from the outside.
    @ObservedObject var portfolioViewModel: PortfolioChartViewModel

    // If you want to store AI results or load them asynchronously, you could:
    @State private var aiInsightText: String = "Loading AI insights..."

    // This could be replaced with a real network request or AI service call.
    private func loadAIInsights() {
        // Example: some mock delay or logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Imagine you used an API to get a short "insight" message
            let randomDelta = Double.random(in: -1.0...3.0)
            if randomDelta >= 0 {
                aiInsightText = "AI says: your portfolio is likely to grow by \(String(format: "%.1f", randomDelta))% this week."
            } else {
                aiInsightText = "AI warns: your portfolio might see a drop of \(String(format: "%.1f", -randomDelta))% this week."
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Insights")
                .font(.headline)
                .foregroundColor(.white)

            Text(aiInsightText)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            // Example: Display some quick AI-based tips or warnings
            if aiInsightText.contains("warns") {
                Text("Tip: Consider rebalancing your largest holding.")
                    .font(.footnote)
                    .foregroundColor(.yellow)
            } else {
                Text("Tip: Your current asset allocation looks balanced.")
                    .font(.footnote)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
        .onAppear {
            loadAIInsights()
        }
    }
}