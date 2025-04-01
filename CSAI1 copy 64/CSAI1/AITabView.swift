//
//  AITabView.swift
//  CSAI1
//
//  Demonstrates real-time streaming from OpenAI Chat Completions API (gpt-3.5-turbo).
//  Removed Coinbase calls entirely. This strictly queries OpenAI for streaming responses.
//

import SwiftUI

struct AITabView: View {
    @State private var conversations: [Conversation] = []
    @State private var activeConversationID: UUID? = nil
    
    @State private var showHistory = false
    @State private var chatText: String = ""
    @State private var isThinking: Bool = false
    @State private var showPromptBar: Bool = true
    
    // For quick prompts
    private let masterPrompts: [String] = [
        "What's the current price of BTC?",
        "Compare Ethereum and Bitcoin",
        "Show me a 24h price chart for SOL",
        "How is my portfolio performing?",
        "Explain yield farming",
        "Should I buy or sell right now?",
        "What are the top 10 coins by market cap?",
        "Any new NFT trends?",
        "Is my portfolio well diversified?",
        "How to minimize fees when trading?",
        "What is a stablecoin?"
    ]
    @State private var quickReplies: [String] = []
    
    // 1) Insert your real OpenAI API key here:
    private let openAIKey = "keygoeshere"

    // 2) A “system” message that defines the AI’s persona and scope:
    private let systemRoleContent = """
    You are CryptoSage AI, a specialized virtual assistant focused on cryptocurrencies and blockchain technology. 
    You provide information, insights, and educational explanations about various digital assets, market trends, 
    protocols, and related topics. You are professional but friendly, and you do not provide direct financial advice.
    """

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
                Color.black.edgesIgnoringSafeArea(.all)
                
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        // Chat transcript
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(currentMessages) { msg in
                                        ChatBubble(message: msg).id(msg.id)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(activeConversationTitle())
                        .font(.headline)
                        .foregroundColor(.white)
                }
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

// MARK: - Subviews
extension AITabView {
    private func thinkingIndicator() -> some View {
        HStack {
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
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
}

// MARK: - Logic
extension AITabView {
    private func activeConversationTitle() -> String {
        guard let activeID = activeConversationID,
              let convo = conversations.first(where: { $0.id == activeID }) else {
            return "AI Chat"
        }
        return convo.title
    }
    
    private func handleQuickReply(_ reply: String) {
        chatText = reply
        sendMessage()
    }
    
    private func randomizePrompts() {
        quickReplies = Array(masterPrompts.shuffled().prefix(4))
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let lastID = currentMessages.last?.id {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }
    
    private func sendMessage() {
        guard let activeID = activeConversationID,
              let index = conversations.firstIndex(where: { $0.id == activeID }) else {
            // If no conversation is active, create a new one
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
        
        // If it's the first message, set the conversation title
        if convo.title == "Untitled Chat" && convo.messages.count == 1 {
            convo.title = String(trimmed.prefix(20)) + (trimmed.count > 20 ? "..." : "")
        }
        
        conversations[index] = convo
        chatText = ""
        saveConversations()
        
        isThinking = true
        
        Task {
            do {
                var partialReply = ""
                
                // Insert an empty AI message first, so we can update it with streaming text
                await MainActor.run {
                    let placeholder = ChatMessage(sender: "ai", text: "")
                    conversations[index].messages.append(placeholder)
                    saveConversations()
                }
                
                // Stream from OpenAI
                let stream = try await streamChatCompletion(userInput: trimmed)
                
                for try await token in stream {
                    partialReply += token
                    // Update last AI message with partial text
                    await MainActor.run {
                        guard let idx = conversations.firstIndex(where: { $0.id == activeID }) else { return }
                        if let lastMsgIndex = conversations[idx].messages.lastIndex(where: { $0.sender == "ai" }) {
                            conversations[idx].messages[lastMsgIndex].text = partialReply
                            saveConversations()
                        }
                    }
                }
                
                // Done streaming
                await MainActor.run {
                    isThinking = false
                    saveConversations()
                }
            } catch {
                print("OpenAI streaming error: \(error.localizedDescription)")
                await MainActor.run {
                    guard let idx = conversations.firstIndex(where: { $0.id == activeID }) else { return }
                    let errMsg = ChatMessage(sender: "ai", text: "AI failed: \(error.localizedDescription)", isError: true)
                    conversations[idx].messages.append(errMsg)
                    isThinking = false
                    saveConversations()
                }
            }
        }
    }
}

// MARK: - Streaming Chat
extension AITabView {
    /// Streams partial tokens from OpenAI's Chat Completions (gpt-3.5-turbo).
    private func streamChatCompletion(userInput: String) async throws -> AsyncThrowingStream<String, Error> {
        // Build the request body
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "stream": true,
            "messages": [
                ["role": "system", "content": systemRoleContent],
                ["role": "user",   "content": userInput]
            ]
        ]
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Important: accept SSE streaming
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        // Configure a URLSession with a longer timeout if needed
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 60  // Increase if your connection is slow
        sessionConfig.timeoutIntervalForResource = 90
        
        let session = URLSession(configuration: sessionConfig,
                                 delegate: StreamingDelegate(),
                                 delegateQueue: nil)
        
        // We'll create an AsyncThrowingStream that yields partial tokens as they arrive:
        return AsyncThrowingStream<String, Error> { continuation in
            // We'll build a "completion handler" style task, but parse data in the delegate
            let streamingTask = session.dataTask(with: request)
            
            // Provide a callback in the delegate so it can yield tokens:
            (session.delegate as? StreamingDelegate)?.onToken = { token in
                continuation.yield(token)
            }
            (session.delegate as? StreamingDelegate)?.onFinished = { maybeError in
                if let e = maybeError {
                    continuation.finish(throwing: e)
                } else {
                    continuation.finish()
                }
            }
            
            streamingTask.resume()
        }
    }
}

/// A URLSession delegate that parses chunked SSE data from OpenAI and yields partial text tokens.
class StreamingDelegate: NSObject, URLSessionDataDelegate {
    /// Callback for each token chunk
    var onToken: ((String) -> Void)?
    /// Callback when streaming is finished or fails
    var onFinished: ((Error?) -> Void)?
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data) {
        
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        // The SSE data typically has lines beginning with "data: "
        let lines = chunk.components(separatedBy: .newlines)
        
        for line in lines {
            if line.hasPrefix("data: ") {
                let jsonString = line.replacingOccurrences(of: "data: ", with: "")
                if jsonString == "[DONE]" {
                    // End of stream
                    onFinished?(nil)
                    return
                }
                // Attempt to parse JSON
                if let jsonData = jsonString.data(using: .utf8) {
                    do {
                        let response = try JSONDecoder().decode(StreamingChunk.self, from: jsonData)
                        // Each chunk has an array of choices; each choice has a 'delta' with optional 'content'
                        if let content = response.choices.first?.delta.content {
                            onToken?(content)
                        }
                    } catch {
                        // If we can't decode a chunk, just ignore or log
                        print("Chunk decoding error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        onFinished?(error)
    }
}

// The structure that matches the streaming JSON chunk
struct StreamingChunk: Decodable {
    let id: String?
    let object: String?
    let choices: [Choice]
}

struct Choice: Decodable {
    let delta: Delta
    let finish_reason: String?
}

struct Delta: Decodable {
    let content: String?
    let role: String?
}

// MARK: - Data Persistence
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
    @State private var showTimestamp = false
    
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
