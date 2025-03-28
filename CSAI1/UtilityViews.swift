//
//  UtilityViews.swift
//  CSAI1
//
//  Reusable UI components only (no ChatMessage/ChatBubble).
//

import SwiftUI

// MARK: - Generic Card View
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(UIColor.secondarySystemBackground))
            .shadow(radius: 5)
            .overlay(content)
            .padding()
    }
}

// MARK: - Simple Trending Card
struct TrendingCard: View {
    var coin: String
    
    var body: some View {
        CardView {
            Text("Trending: \(coin)")
                .font(.headline)
        }
    }
}

// ---------- NO ChatMessage or ChatBubble here! ----------
