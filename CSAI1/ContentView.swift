//
//  ContentView.swift
//  CSAI1
//
//  Created by DM on 3/18/25.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        // If you have a custom tab bar, embed MarketView in a NavigationView there.
        // For demonstration, we’ll just use a simple TabView:
        TabView {
            NavigationView {
                MarketView()  // The entire Market screen
            }
            .tabItem {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Market")
            }
            
            Text("Home Screen Placeholder")
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}