import SwiftUI

enum CustomTab {
    case home, market, trade, portfolio, ai
}

struct CustomTabBar: View {
    @Binding var selectedTab: CustomTab
    
    var body: some View {
        HStack {
            
            // HOME
            Button(action: {
                selectedTab = .home
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "house.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("Home")
                        .font(.caption)
                }
            }
            .foregroundColor(selectedTab == .home ? .white : .gray)
            
            Spacer()
            
            // MARKET
            Button(action: {
                selectedTab = .market
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("Market")
                        .font(.caption)
                }
            }
            .foregroundColor(selectedTab == .market ? .white : .gray)
            
            Spacer()
            
            // TRADE
            Button(action: {
                selectedTab = .trade
            }) {
                VStack(spacing: 4) {
                    // The swap/trade icon you wanted
                    Image(systemName: "arrow.2.squarepath")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("Trade")
                        .font(.caption)
                }
            }
            .foregroundColor(selectedTab == .trade ? .white : .gray)
            
            Spacer()
            
            // PORTFOLIO
            Button(action: {
                selectedTab = .portfolio
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "chart.pie.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("Portfolio")
                        .font(.caption)
                }
            }
            .foregroundColor(selectedTab == .portfolio ? .white : .gray)
            
            Spacer()
            
            // AI CHAT
            Button(action: {
                selectedTab = .ai
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "ellipsis.bubble.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("AI Chat")
                        .font(.caption)
                }
            }
            .foregroundColor(selectedTab == .ai ? .white : .gray)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 10)
        .background(Color.black)
    }
}

struct CustomTabBar_Previews: PreviewProvider {
    @State static var selectedTab: CustomTab = .home
    
    static var previews: some View {
        CustomTabBar(selectedTab: $selectedTab)
            .previewLayout(.sizeThatFits)
            .background(Color.gray)
    }
}
