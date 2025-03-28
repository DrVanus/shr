//
//  Conversation.swift
//  CSAI1
//
//  Defines the Conversation model, which represents a chat thread.
//  It includes properties for the conversation title, chat messages, creation date, and pinned state.
//

import Foundation

struct Conversation: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date = Date()
    var pinned: Bool = false
    
    init(id: UUID = UUID(), title: String, messages: [ChatMessage] = [], createdAt: Date = Date(), pinned: Bool = false) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.pinned = pinned
    }
    
    /// Returns the date of the most recent message, if any.
    var lastMessageDate: Date? {
        return messages.last?.timestamp
    }
    
    /// Adds a new message to the conversation.
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
    }
}
