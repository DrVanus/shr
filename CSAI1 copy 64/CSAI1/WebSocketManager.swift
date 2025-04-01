//
//  WebSocketManager.swift
//  CSAI1
//
//  Created by DM on 3/27/25.
//


import Foundation
import Combine

/// WebSocketManager handles a persistent WebSocket connection for real‑time updates.
/// You can use this to receive balance changes, trade updates, or market data.
class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    // Published property to update SwiftUI views in real time.
    @Published var lastMessage: String = ""
    
    // Replace with your WebSocket URL (this could be a direct Shrimpy endpoint or your backend relay).
    private let socketURL = URL(string: "wss://your-backend.com/ws")!
    
    private init() {}
    
    /// Connects to the WebSocket server and starts receiving messages.
    func connect() {
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: socketURL)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    /// Disconnects from the WebSocket server.
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    /// Continuously receives messages from the WebSocket.
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("WebSocket receiving error: \(error)")
                // Optionally, try to reconnect after a delay
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self.lastMessage = text
                        // Here, you can decode JSON and update your data model as needed
                    }
                case .data(let data):
                    DispatchQueue.main.async {
                        self.lastMessage = String(decoding: data, as: UTF8.self)
                        // Parse data if sent in binary format
                    }
                @unknown default:
                    break
                }
                // Continue listening for the next message
                self.receiveMessage()
            }
        }
    }
    
    /// Sends a text message over the WebSocket connection.
    func sendMessage(_ message: String, completion: @escaping (Error?) -> Void = { _ in }) {
        let wsMessage = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(wsMessage, completionHandler: completion)
    }
}
