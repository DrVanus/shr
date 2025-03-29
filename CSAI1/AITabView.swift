//
//  AITabView.swift
//  CSAI1
//
//  Final version with ephemeral URLSession, explicit type annotation,
//  optional Organization header, debug logging, and refined prompt bar toggle.
//

import SwiftUI

struct AITabView: View {
    // All stored conversations
    @State private var conversations: [Conversation] = []
    // Which conversation is currently active
    @State private var activeConversationID: UUID? = nil
    
    // Controls whether the history sheet is shown
    @State private var showHistory = false
    
    // The user's chat input
    @State private var chatText: String = ""
    // Whether the AI is "thinking"
    @State private var isThinking: Bool = false
    
    // Whether to show or hide the prompt bar
    @State private var showPromptBar: Bool = true
    
    // A relevant list of prompts for a crypto/portfolio AI
    private let masterPrompts: [String] = [
        "What's the current price of BTC?",
        "Compare Ethereum and Bitcoin",
        "Show me a 24h price chart for SOL",
        "How is my portfolio performing?",
        "What's the best time to buy crypto?",
        "What is staking and how does it work?",
        "Are there any new DeFi projects I should watch?",
        "Give me the top gainers and losers today",
        "Explain yield farming",
        "Should I buy or sell right now?",
        "What are the top 10 coins by market cap?",
        "What's the difference between a limit and market order?",
        "Show me a price chart for RLC",
        "What is a stablecoin?",
        "Any new NFT trends?",
        "Compare LTC with DOGE",
        "Is my portfolio well diversified?",
        "How to minimize fees when trading?",
        "What's the best exchange for altcoins?"
    ]
    
    // Currently displayed quick replies
    @State private var quickReplies: [String] = []
    
    // Your OpenAI key here
    private let openAIKey = """
    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
    """
    
    // Computed: returns the messages for the active conversation
    private var currentMessages: [ChatMessage] {
        guard let activeID = activeConversationID,
              let index = conversations.firstIndex(where: { $0.id == activeID }) else {
            return []
        }
        return conversations[index].messages
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Replace FuturisticBackground() with your theme-based background if desired
                FuturisticBackground()
                    .ignoresSafeArea()
                
                // Main chat overlay
                chatBodyView
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Title in the center
                ToolbarItem(placement: .principal) {
                    Text(activeConversationTitle())
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                // History button on the left
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showHistory.toggle()
                    } label: {
                        Image(systemName: "text.bubble")
                            .imageScale(.large)
                    }
                    .foregroundColor(.white)
                    .sheet(isPresented: $showHistory) {
                        ConversationHistoryView(
                            conversations: conversations,
                            onSelectConversation: { convo in
                                activeConversationID = convo.id
                                showHistory = false
                                saveConversations()
                            },
                            onNewChat: {
                                let newConvo = Conversation(title: "Untitled Chat")
                                conversations.append(newConvo)
                                activeConversationID = newConvo.id
                                showHistory = false
                                saveConversations()
                            },
                            onDeleteConversation: { convo in
                                if let idx = conversations.firstIndex(where: { $0.id == convo.id }) {
                                    conversations.remove(at: idx)
                                    if convo.id == activeConversationID {
                                        activeConversationID = conversations.first?.id
                                    }
                                    saveConversations()
                                }
                            },
                            onRenameConversation: { convo, newTitle in
                                if let idx = conversations.firstIndex(where: { $0.id == convo.id }) {
                                    conversations[idx].title = newTitle.isEmpty ? "Untitled Chat" : newTitle
                                    saveConversations()
                                }
                            },
                            onTogglePin: { convo in
                                if let idx = conversations.firstIndex(where: { $0.id == convo.id }) {
                                    conversations[idx].pinned.toggle()
                                    saveConversations()
                                }
                            }
                        )
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                    }
                }
            }
            .onAppear {
                loadConversations()
                if activeConversationID == nil, let first = conversations.first {
                    activeConversationID = first.id
                }
                randomizePrompts()
            }
        }
    }
}

// MARK: - Subviews & Helpers
extension AITabView {
    /// The main chat content
    private var chatBodyView: some View {
        ZStack(alignment: .bottom) {
            Color.clear
            
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(currentMessages) { msg in
                                ChatBubble(message: msg)
                                    .id(msg.id)
                            }
                            if isThinking {
                                thinkingIndicator()
                            }
                        }
                        .padding(.vertical)
                    }
                    // Scroll to bottom on first appear
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            scrollToBottom(proxy)
                        }
                    }
                    // Scroll to bottom when new messages arrive
                    .onChange(of: currentMessages.count) { _ in
                        withAnimation {
                            scrollToBottom(proxy)
                        }
                    }
                    // Scroll to bottom when switching conversations
                    .onChange(of: activeConversationID) { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                scrollToBottom(proxy)
                            }
                        }
                    }
                }
                
                // If the prompt bar is shown, place it above the input bar
                if showPromptBar {
                    quickReplyBar()
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            )
                        )
                }
                
                // Input bar for chat (with integrated lightbulb)
                inputBar()
            }
        }
    }
    
    private func activeConversationTitle() -> String {
        guard let activeID = activeConversationID,
              let convo = conversations.first(where: { $0.id == activeID }) else {
            return "AI Chat"
        }
        return convo.title
    }
    
    private func thinkingIndicator() -> some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Text("CryptoSage is thinking...")
                .foregroundColor(.white)
                .font(.caption)
            Spacer()
        }
        .padding(.horizontal)
    }
    
    /// Quick replies row with shuffle arrow (removed X button)
    private func quickReplyBar() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(quickReplies, id: \.self) { reply in
                    Button(reply) {
                        handleQuickReply(reply)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.yellow.opacity(0.25))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                    )
                }
                
                // Shuffle arrow icon to randomize prompts
                Button {
                    randomizePrompts()
                } label: {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.yellow.opacity(0.25))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .simultaneousGesture(DragGesture(minimumDistance: 10))
        }
        .background(Color.black.opacity(0.3))
    }
    
    /// The chat input bar with a text field, lightbulb toggle, and send button
    private func inputBar() -> some View {
        HStack {
            TextField("Ask your AI...", text: $chatText)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            // Lightbulb button to show/hide prompt bar
            Button {
                withAnimation(.easeOut(duration: 0.15)) {
                    // If we are about to show the bar, randomize the prompts
                    if !showPromptBar {
                        randomizePrompts()
                    }
                    showPromptBar.toggle()
                }
            } label: {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Color.yellow.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            }
            .padding(.leading, 6)
            
            // Send button
            Button(action: sendMessage) {
                Text("Send")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.yellow.opacity(0.8))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
    }
    
    /// Send the user's typed message to the AI
    private func sendMessage() {
        guard let activeID = activeConversationID,
              let index = conversations.firstIndex(where: { $0.id == activeID }) else {
            let newConvo = Conversation(title: "Untitled Chat")
            conversations.append(newConvo)
            activeConversationID = newConvo.id
            saveConversations()
            return
        }
        
        let trimmed = chatText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        var convo = conversations[index]
        let userMsg = ChatMessage(sender: "user", text: trimmed)
        convo.messages.append(userMsg)
        
        // Update conversation title if needed
        if convo.title == "Untitled Chat" && convo.messages.count == 1 {
            convo.title = String(trimmed.prefix(20)) + (trimmed.count > 20 ? "..." : "")
        }
        
        conversations[index] = convo
        chatText = ""
        saveConversations()
        
        // Show AI "thinking"
        isThinking = true
        
        Task {
            do {
                let aiText = try await fetchAIResponse(for: trimmed)
                await MainActor.run {
                    guard let idx = self.conversations.firstIndex(where: { $0.id == self.activeConversationID }) else { return }
                    var updatedConvo = self.conversations[idx]
                    let aiMsg = ChatMessage(sender: "ai", text: aiText)
                    updatedConvo.messages.append(aiMsg)
                    self.conversations[idx] = updatedConvo
                    self.isThinking = false
                    self.saveConversations()
                }
            } catch {
                print("OpenAI error: \(error.localizedDescription)")
                await MainActor.run {
                    guard let idx = self.conversations.firstIndex(where: { $0.id == self.activeConversationID }) else { return }
                    var updatedConvo = self.conversations[idx]
                    let errMsg = ChatMessage(sender: "ai", text: "AI failed: \(error.localizedDescription)", isError: true)
                    updatedConvo.messages.append(errMsg)
                    self.conversations[idx] = updatedConvo
                    self.isThinking = false
                    self.saveConversations()
                }
            }
        }
    }
    
    /// Calls the OpenAI Chat Completion endpoint
    private func fetchAIResponse(for userInput: String) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        
        let session = URLSession(configuration: config)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        
        let chatRequest: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": userInput]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: chatRequest)
        
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("OpenAI HTTP Status Code: \(httpResponse.statusCode)")
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            print("OpenAI Response Body:\n\(responseBody)\n")
            guard httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let completion = try decoder.decode(ChatResponse.self, from: data)
        return completion.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    /// Called when user taps one of the quick replies
    private func handleQuickReply(_ reply: String) {
        chatText = reply
        sendMessage()
    }
    
    /// Shuffle the masterPrompts and pick 4 random suggestions
    private func randomizePrompts() {
        let shuffled = masterPrompts.shuffled()
        quickReplies = Array(shuffled.prefix(4))
    }
    
    /// Clears messages from the active conversation
    private func clearActiveConversation() {
        guard let activeID = activeConversationID,
              let index = conversations.firstIndex(where: { $0.id == activeID }) else { return }
        var convo = conversations[index]
        convo.messages.removeAll()
        conversations[index] = convo
        saveConversations()
    }
    
    /// Helper to scroll to the bottom in a ScrollViewReader
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let lastID = currentMessages.last?.id {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }
}

// MARK: - Persistence
extension AITabView {
    private func saveConversations() {
        do {
            let data = try JSONEncoder().encode(conversations)
            UserDefaults.standard.set(data, forKey: "csai_conversations")
        } catch {
            print("Failed to encode conversations: \(error)")
        }
    }
    
    private func loadConversations() {
        guard let data = UserDefaults.standard.data(forKey: "csai_conversations") else { return }
        do {
            conversations = try JSONDecoder().decode([Conversation].self, from: data)
        } catch {
            print("Failed to decode conversations: \(error)")
        }
    }
}

// MARK: - OpenAI API Models
struct ChatResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: MessageParam
}

struct MessageParam: Codable {
    let role: String
    let content: String
}

// MARK: - ChatBubble
struct ChatBubble: View {
    let message: ChatMessage
    
    @State private var showTimestamp: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            if message.sender == "ai" {
                aiView
                Spacer()
            } else {
                Spacer()
                userView
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private var aiView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.text)
                .font(.system(size: 16))
                .foregroundColor(.white)
            Text(formattedTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var userView: some View {
        let bubbleColor: Color = message.isError
            ? Color.red.opacity(0.8)
            : Color.yellow.opacity(0.8)
        let textColor: Color = message.isError ? .white : .black
        
        return VStack(alignment: .trailing, spacing: 4) {
            Text(message.text)
                .font(.system(size: 16))
                .foregroundColor(textColor)
            if showTimestamp {
                Text("Sent at \(formattedTime(message.timestamp))")
                    .font(.caption2)
                    .foregroundColor(textColor.opacity(0.7))
            }
        }
        .padding(12)
        .background(bubbleColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onLongPressGesture {
            showTimestamp.toggle()
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct AITabView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AITabView()
        }
        .preferredColorScheme(.dark)
    }
}
