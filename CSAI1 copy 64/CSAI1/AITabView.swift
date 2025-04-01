//
//  AITabView.swift
//  CSAI1
//
//  Final version using a standard project API key with the OpenAI Assistants API.
//  This version augments the user query with live price data (via CoinbaseService) when appropriate,
//  and isolates the Coinbase calls so that any errors (e.g. timeouts) do not cancel the main assistant call.
//  NOTE: Ensure your Conversation model includes a `threadId` property.
//  Also, ensure CoinbaseService.swift is present in your project.
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
    
    // A list of quick prompts for the chat
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
    
    // Your standard project API key (should start with "sk-" and be valid)
    private let openAIKey = """
    keygoeshere
    """
    
    // Computed: returns messages for the active conversation.
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
                FuturisticBackground()
                    .ignoresSafeArea()
                
                chatBodyView
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Center title
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
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            scrollToBottom(proxy)
                        }
                    }
                    .onChange(of: currentMessages.count) { _ in
                        withAnimation { scrollToBottom(proxy) }
                    }
                    .onChange(of: activeConversationID) { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation { scrollToBottom(proxy) }
                        }
                    }
                }
                
                if showPromptBar {
                    quickReplyBar()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
                
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
    
    private func quickReplyBar() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(quickReplies, id: \.self) { reply in
                    Button(reply) { handleQuickReply(reply) }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.yellow.opacity(0.25)))
                        .overlay(RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.yellow.opacity(0.4), lineWidth: 1))
                }
                Button {
                    randomizePrompts()
                } label: {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.yellow.opacity(0.25)))
                        .overlay(RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.yellow.opacity(0.4), lineWidth: 1))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .simultaneousGesture(DragGesture(minimumDistance: 10))
        }
        .background(Color.black.opacity(0.3))
    }
    
    private func inputBar() -> some View {
        HStack {
            TextField("Ask your AI...", text: $chatText)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            Button {
                withAnimation(.easeOut(duration: 0.15)) {
                    if !showPromptBar { randomizePrompts() }
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
    
    // MARK: - Updated Live Data Augmentation
    // This function now uses non-throwing calls to CoinbaseService.
    // If fetching the live price fails (e.g. due to timeout), it simply returns the original input.
    private func maybeAugmentUserInput(_ input: String) async -> String {
        let lower = input.lowercased()
        if lower.contains("price") {
            if lower.contains("btc") {
                // Use a non-throwing fetch by using try? or simply checking the optional result
                if let btcPrice = await CoinbaseService().fetchSpotPrice(coin: "BTC", fiat: "USD") {
                    print("Fetched BTC price: \(btcPrice)")
                    return input + "\n\n[Live data: Current price of BTC is \(btcPrice) USD.]"
                } else {
                    print("Failed to fetch BTC price, proceeding without augmentation.")
                    return input
                }
            } else if lower.contains("sol") {
                if let solPrice = await CoinbaseService().fetchSpotPrice(coin: "SOL", fiat: "USD") {
                    print("Fetched SOL price: \(solPrice)")
                    return input + "\n\n[Live data: Current price of SOL is \(solPrice) USD.]"
                } else {
                    print("Failed to fetch SOL price, proceeding without augmentation.")
                    return input
                }
            }
        }
        return input
    }
    
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
        
        if convo.title == "Untitled Chat" && convo.messages.count == 1 {
            convo.title = String(trimmed.prefix(20)) + (trimmed.count > 20 ? "..." : "")
        }
        
        conversations[index] = convo
        chatText = ""
        saveConversations()
        
        isThinking = true
        
        Task {
            do {
                // Augment input with live price data if applicable.
                let augmentedInput = await maybeAugmentUserInput(trimmed)
                let aiText = try await fetchAIResponse(for: augmentedInput)
                print("Final assistant reply: \(aiText)")
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
    
    /// The core Assistants API call with updated JSON decoding and increased polling.
    private func fetchAIResponse(for userInput: String) async throws -> String {
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60
        let session = URLSession(configuration: config)
        
        var threadId: String
        if let currentConvoIndex = conversations.firstIndex(where: { $0.id == activeConversationID }),
           let existingThreadId = conversations[currentConvoIndex].threadId {
            threadId = existingThreadId
        } else {
            guard let threadURL = URL(string: "https://api.openai.com/v1/threads") else {
                throw URLError(.badURL)
            }
            var threadRequest = URLRequest(url: threadURL)
            threadRequest.httpMethod = "POST"
            threadRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            threadRequest.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
            threadRequest.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
            threadRequest.httpBody = "{}".data(using: .utf8)
            
            let (threadData, threadResponse) = try await session.data(for: threadRequest)
            logResponse(threadData, threadResponse)
            struct ThreadResponse: Codable { let id: String }
            let threadRes = try JSONDecoder().decode(ThreadResponse.self, from: threadData)
            threadId = threadRes.id
            
            if let currentConvoIndex = conversations.firstIndex(where: { $0.id == activeConversationID }) {
                conversations[currentConvoIndex].threadId = threadId
                saveConversations()
            }
        }
        
        // POST user message
        guard let messageURL = URL(string: "https://api.openai.com/v1/threads/\(threadId)/messages") else {
            throw URLError(.badURL)
        }
        var messageRequest = URLRequest(url: messageURL)
        messageRequest.httpMethod = "POST"
        messageRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        messageRequest.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        messageRequest.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        let messagePayload: [String: Any] = [
            "role": "user",
            "content": userInput
        ]
        messageRequest.httpBody = try JSONSerialization.data(withJSONObject: messagePayload)
        let (msgData, msgResponse) = try await session.data(for: messageRequest)
        logResponse(msgData, msgResponse)
        
        // POST run assistant
        guard let runURL = URL(string: "https://api.openai.com/v1/threads/\(threadId)/runs") else {
            throw URLError(.badURL)
        }
        var runRequest = URLRequest(url: runURL)
        runRequest.httpMethod = "POST"
        runRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        runRequest.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        runRequest.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        let runPayload: [String: Any] = [
            "assistant_id": "asst_YlcZqIfjPmhCl44bUO77SYaJ"
        ]
        runRequest.httpBody = try JSONSerialization.data(withJSONObject: runPayload)
        let (runData, runResponseVal) = try await session.data(for: runRequest)
        logResponse(runData, runResponseVal)
        
        struct RunResponse: Codable { let id: String }
        let runRes = try JSONDecoder().decode(RunResponse.self, from: runData)
        let runId = runRes.id
        
        // Poll for run completion – up to 30 iterations (15 seconds total)
        var assistantReply: String? = nil
        for _ in 1...30 {
            try await Task.sleep(nanoseconds: 500_000_000)
            guard let statusURL = URL(string: "https://api.openai.com/v1/threads/\(threadId)/runs/\(runId)") else {
                throw URLError(.badURL)
            }
            var statusRequest = URLRequest(url: statusURL)
            statusRequest.httpMethod = "GET"
            statusRequest.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
            statusRequest.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
            do {
                let (statusData, statusResp) = try await session.data(for: statusRequest)
                logResponse(statusData, statusResp)
                
                struct RunStatus: Codable { let status: String }
                let statusRes = try JSONDecoder().decode(RunStatus.self, from: statusData)
                if statusRes.status.lowercased() == "succeeded" || statusRes.status.lowercased() == "completed" {
                    // Fetch messages
                    guard let msgsURL = URL(string: "https://api.openai.com/v1/threads/\(threadId)/messages") else {
                        throw URLError(.badURL)
                    }
                    var msgsRequest = URLRequest(url: msgsURL)
                    msgsRequest.httpMethod = "GET"
                    msgsRequest.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
                    msgsRequest.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
                    do {
                        let (msgsData, msgsResp) = try await session.data(for: msgsRequest)
                        logResponse(msgsData, msgsResp)
                        
                        struct ThreadMessagesResponse: Codable {
                            let object: String
                            let data: [AssistantMessage]
                            let first_id: String?
                            let last_id: String?
                            let has_more: Bool?
                        }
                        struct AssistantMessage: Codable {
                            let id: String
                            let role: String
                            let content: [ContentBlock]
                        }
                        struct ContentBlock: Codable {
                            let type: String
                            let text: ContentText?
                        }
                        struct ContentText: Codable {
                            let value: String
                            let annotations: [String]?
                        }
                        
                        let msgsRes = try JSONDecoder().decode(ThreadMessagesResponse.self, from: msgsData)
                        if let lastMsg = msgsRes.data.last, lastMsg.role == "assistant" {
                            let combinedText = lastMsg.content.compactMap { $0.text?.value }.joined(separator: "\n\n")
                            assistantReply = combinedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    } catch {
                        print("Error decoding thread messages:", error)
                    }
                    if assistantReply != nil {
                        break
                    }
                }
            } catch {
                print("Error polling run status:", error)
            }
        }
        
        guard let reply = assistantReply, !reply.isEmpty else {
            throw URLError(.timedOut)
        }
        return reply
    }
    
    private func logResponse(_ data: Data, _ response: URLResponse) {
        if let httpRes = response as? HTTPURLResponse {
            print("Status code: \(httpRes.statusCode)")
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("Response body: \(body)")
        }
    }
    
    private func handleQuickReply(_ reply: String) {
        chatText = reply
        sendMessage()
    }
    
    private func randomizePrompts() {
        let shuffled = masterPrompts.shuffled()
        quickReplies = Array(shuffled.prefix(4))
    }
    
    private func clearActiveConversation() {
        guard let activeID = activeConversationID,
              let index = conversations.firstIndex(where: { $0.id == activeID }) else { return }
        var convo = conversations[index]
        convo.messages.removeAll()
        conversations[index] = convo
        saveConversations()
    }
    
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
        let bubbleColor: Color = message.isError ? Color.red.opacity(0.8) : Color.yellow.opacity(0.8)
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
        .onLongPressGesture { showTimestamp.toggle() }
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
