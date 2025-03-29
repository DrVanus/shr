//
//  ChatHistoryView.swift
//  CSAI1
//
//  A custom sheet-based history view with a bubble layout
//  and a pull-to-dismiss style (iOS 16+).
//

import SwiftUI

struct ChatHistoryView: View {
    let messages: [ChatMessage]
    
    // Allows us to dismiss this sheet programmatically
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom top bar with a grab indicator + title + close button
                topBar()
                
                // Scrollable bubble layout
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in
                            messageRow(for: msg)
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                        }
                    }
                    .padding(.top)
                }
            }
        }
    }
    
    // MARK: - Custom Top Bar
    private func topBar() -> some View {
        VStack(spacing: 6) {
            // A small grab indicator at top center
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            HStack {
                Text("Chat History")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - Each Message Row
    private func messageRow(for msg: ChatMessage) -> some View {
        HStack {
            if msg.sender == "ai" {
                bubbleView(msg)
                Spacer(minLength: 10)
            } else {
                Spacer(minLength: 10)
                bubbleView(msg)
            }
        }
    }
    
    // MARK: - Bubble Style
    private func bubbleView(_ msg: ChatMessage) -> some View {
        let isAI = (msg.sender == "ai")
        let textColor: Color = isAI ? .white : .black
        
        return VStack(alignment: .leading, spacing: 6) {
            // The main message text
            Text(msg.text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textColor)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            msg.isError
                            ? errorBubbleGradient
                            : (isAI ? aiBubbleGradient : userBubbleGradient)
                        )
                )
            
            // Optional timestamp
            Text("\(formattedDate(msg.timestamp))")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
                .padding(.leading, 4)
        }
    }
    
    // MARK: - Helper: Format Date
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
    
    // MARK: - Bubble Gradients
    // Match these to your main chat styling for consistency
    private let userBubbleGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.85, green: 0.7, blue: 0.1),
            Color(red: 0.9, green: 0.8, blue: 0.2)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let aiBubbleGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.4),
            Color(red: 0.6, green: 0.6, blue: 0.6, opacity: 0.8)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let errorBubbleGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.red.opacity(0.4),
            Color.red.opacity(0.8)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
