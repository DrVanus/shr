//
//  AITabView.swift
//  CSAI1
//
//  Final version with integrated coin price tool calls, ephemeral URLSession,
//  explicit type annotations, optional Organization header, debug logging,
//  refined prompt bar toggle, and tool call support for fetching coin prices.
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
    
    // Inject MarketViewModel to access coin price data
    @EnvironmentObject var marketVM: MarketViewModel
    
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
    
    /// Calls the OpenAI Chat Completion endpoint with function calling enabled.
    private func fetchAIResponse(for userInput: String) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        
        // Define the coin price tool for OpenAI function calling
        let functions: [[String: Any]] = [[
            "name": "getCoinPrice",
            "description": "Get the current price (USD) of a cryptocurrency by name or symbol.",
            "parameters": [
                "type": "object",
                "properties": [
                    "coin": [
                        "type": "string",
                        "description": "The name or symbol of the cryptocurrency (e.g. 'Bitcoin' or 'BTC')."
                    ]
                ],
                "required": ["coin"]
            ]
        ]]
        
        // Build the initial conversation messages including a system prompt describing tool availability.
        var messages: [[String: Any]] = [
            ["role": "system", "content": "You are CryptoSage, a crypto expert AI. You have access to real-time crypto price data via tools."],
            ["role": "user", "content": userInput]
        ]
        
        let chatRequest: [String: Any] = [
            "model": "gpt-3.5-turbo-0613",
            "messages": messages,
            "functions": functions,
            "function_call": "auto"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: chatRequest)
        
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        let session = URLSession(configuration: config)
        
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
        
        // If the assistant decides to call our tool, handle the function call.
        if let functionCall = completion.choices.first?.message.functionCall, functionCall.name == "getCoinPrice" {
            // Parse the function call arguments (a JSON string)
            if let argsData = functionCall.arguments.data(using: .utf8),
               let argsDict = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any],
               let coinQuery = argsDict["coin"] as? String {
                // Call our tool to get the actual price
                let priceResult = await getCoinPrice(coin: coinQuery)
                
                // Append the function call and its result to the conversation messages
                messages.append([
                    "role": "assistant",
                    "function_call": [
                        "name": functionCall.name,
                        "arguments": functionCall.arguments
                    ]
                ])
                messages.append([
                    "role": "function",
                    "name": functionCall.name,
                    "content": priceResult
                ])
                
                // Build a follow-up request with the function result, asking the assistant to generate a final answer.
                let followUpRequest: [String: Any] = [
                    "model": "gpt-3.5-turbo-0613",
                    "messages": messages,
                    "functions": functions,
                    "function_call": "none"
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: followUpRequest)
                let (data2, response2) = try await session.data(for: request)
                if let httpResponse2 = response2 as? HTTPURLResponse, httpResponse2.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                let completion2 = try decoder.decode(ChatResponse.self, from: data2)
                let finalAnswer = completion2.choices.first?.message.content ?? ""
                return finalAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // If no function call was made, return the assistant's reply directly.
        let aiReply = completion.choices.first?.message.content ?? ""
        return aiReply.trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    // MARK: - Tool: Coin Price Fetching
    /// Returns the current USD price for a given coin (by symbol or name).
    private func getCoinPrice(coin: String) async -> String {
        // First, check the market data available in marketVM
        if let match = marketVM.coins.first(where: {
            $0.symbol.caseInsensitiveCompare(coin) == .orderedSame ||
            $0.name.caseInsensitiveCompare(coin) == .orderedSame
        }) {
            return String(format: "%.2f", match.price)
        }
        // Fallback: Use CryptoAPIService to fetch current price
        let coinID = coin.lowercased().replacingOccurrences(of: " ", with: "-")
        do {
            let priceDict = try await withCheckedThrowingContinuation { cont in
                CryptoAPIService.shared.fetchCurrentPrices(for: [coinID]) { result in
                    switch result {
                    case .success(let prices):
                        cont.resume(returning: prices)
                    case .failure(let error):
                        cont.resume(throwing: error)
                    }
                }
            }
            // Parse the response dictionary (assumes format: { "coinID": { "usd": price } })
            if let coinData = priceDict as? [String: Any],
               let coinInfo = coinData[coinID] as? [String: Any],
               let price = coinInfo["usd"] as? Double {
                return String(format: "%.2f", price)
            }
        } catch {
            print("Price fetch error: \(error)")
        }
        return "N/A"
    }
    
    // MARK: - Persistence
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
    let content: String?
    let functionCall: FunctionCall?
    
    enum CodingKeys: String, CodingKey {
        case role, content
        case functionCall = "function_call"
    }
}

struct FunctionCall: Codable {
    let name: String
    let arguments: String
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
                .environmentObject(MarketViewModel()) // Provide a preview MarketViewModel
        }
        .preferredColorScheme(.dark)
    }
}
