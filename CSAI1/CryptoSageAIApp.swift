//
//  CryptoSageAIApp.swift
//  CSAI1
//
//  Created by DM on 3/27/25.
//


//
//  CryptoSageAIApp.swift
//  CSAI1
//
//  Created by DM on 3/16/25.
//
//  AppMain.swift
//  CRYPTOSAI
//
//  Single app entry point, with shared AppState.
//

import SwiftUI

@main
struct CryptoSageAIApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var marketVM = MarketViewModel()  // <-- Add this

    var body: some Scene {
        WindowGroup {
            ContentManagerView()
                .environmentObject(appState)
                .environmentObject(marketVM)            // <-- Inject it here
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedTab: CustomTab = .home
    @Published var isDarkMode: Bool = true
}