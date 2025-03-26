//
//  PortfolioView.swift
//  CSAI1
//

import SwiftUI
import Charts

// Example brand accent color usage.
private let brandAccent = Color("BrandAccent")

// Added a “GoldAccent” color (or use .yellow) to the slice array:
private let donutSliceColors: [Color] = [
    .green, brandAccent, .mint, .blue, .teal, .purple, Color("GoldAccent")
]

// MARK: - PaymentMethodsView
/// Stub for linking user exchange accounts/wallets
struct PaymentMethodsView: View {
    @State private var showLinkAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Connect Exchanges & Wallets")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Add or link your crypto exchange accounts and wallets here to trade directly from the app.")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Button("Link Now") {
                showLinkAlert = true
            }
            .padding()
            .foregroundColor(.white)
            .background(brandAccent)
            .cornerRadius(8)
        }
        .alert(isPresented: $showLinkAlert) {
            Alert(
                title: Text("Linking Not Implemented"),
                message: Text("Real exchange/wallet linking logic will go here."),
                dismissButton: .default(Text("OK"))
            )
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Remove the fixed black background so the theme background shows through.
        .background(FuturisticBackground())
    }
}

// MARK: - ScaleButtonStyle
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - ThemedPortfolioPieChartView
struct ThemedPortfolioPieChartView: View {
    let holdings: [Holding]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart(holdings, id: \.id) { holding in
                SectorMark(
                    angle: .value("Value", holding.currentPrice * holding.quantity),
                    innerRadius: .ratio(0.6),
                    outerRadius: .ratio(0.95)
                )
                .foregroundStyle(sliceColor(for: holding.coinSymbol))
            }
            .chartLegend(.hidden)
        } else {
            Text("Pie chart requires iOS 16+.")
                .foregroundColor(.gray)
        }
    }
    
    private func sliceColor(for symbol: String) -> Color {
        let hash = abs(symbol.hashValue)
        return donutSliceColors[hash % donutSliceColors.count]
    }
}

// MARK: - PortfolioLegendView
struct PortfolioLegendView: View {
    let holdings: [Holding]
    let totalValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(holdings) { holding in
                let val = holding.currentPrice * holding.quantity
                let pct = (totalValue > 0) ? (val / totalValue * 100) : 0
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(sliceColor(for: holding.coinSymbol))
                        .frame(width: 8, height: 8)
                    
                    Text("\(holding.coinSymbol) \(String(format: "%.1f", pct))%")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func sliceColor(for symbol: String) -> Color {
        let hash = abs(symbol.hashValue)
        return donutSliceColors[hash % donutSliceColors.count]
    }
}

// MARK: - PortfolioCoinRow
struct PortfolioCoinRow: View {
    @ObservedObject var viewModel: PortfolioViewModel
    let holding: Holding
    
    var body: some View {
        let rowPL = holding.profitLoss
        
        HStack(spacing: 12) {
            if let urlStr = holding.imageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Image(systemName: "bitcoinsign.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.gray)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "bitcoinsign.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(holding.coinName) (\(holding.coinSymbol))")
                        .font(.headline)
                    Button {
                        viewModel.toggleFavorite(holding)
                    } label: {
                        Image(systemName: holding.isFavorite ? "star.fill" : "star")
                            .foregroundColor(holding.isFavorite ? .yellow : .gray)
                    }
                    .buttonStyle(.plain)
                }
                
                Text(String(format: "24h: %.2f%%", holding.dailyChange))
                    .foregroundColor(holding.dailyChange >= 0 ? .green : .red)
                    .font(.caption)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(holding.currentPrice, specifier: "%.2f")")
                    .font(.headline)
                
                Text(String(format: "P/L: $%.2f", rowPL))
                    .foregroundColor(rowPL >= 0 ? .green : .red)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 8)
        .background(
            rowPL >= 0
            ? Color.green.opacity(0.15)
            : Color.red.opacity(0.15)
        )
        .cornerRadius(8)
    }
}

// MARK: - TransactionsRow
struct TransactionsRow: View {
    let symbol: String
    let quantity: Double
    let price: Double
    let date: Date
    let isBuy: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isBuy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(isBuy ? .green : .red)
            
            VStack(alignment: .leading) {
                Text("\(isBuy ? "Buy" : "Sell") \(symbol)")
                    .font(.headline)
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(quantity, specifier: "%.2f") @ $\(price, specifier: "%.2f")")
                .font(.subheadline)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - PortfolioView
struct PortfolioView: View {
    @StateObject var viewModel = PortfolioViewModel()
    
    // Tab selection
    @State private var selectedTab: Int = 0
    
    // Search
    @State private var showSearchBar = false
    @State private var searchTerm = ""
    
    // Sheets
    @State private var showAddSheet = false
    @State private var showSettingsSheet = false
    @State private var showPaymentMethodsSheet = false
    
    // Tooltip / legend
    @State private var showTooltip = false
    @State private var showLegend = false
    
    private var displayedHoldings: [Holding] {
        let base = viewModel.displayedHoldings
        guard showSearchBar, !searchTerm.isEmpty else { return base }
        return base.filter {
            $0.coinName.lowercased().contains(searchTerm.lowercased()) ||
            $0.coinSymbol.lowercased().contains(searchTerm.lowercased())
        }
    }
    
    var body: some View {
        ZStack {
            // Use dynamic theme background instead of fixed linear gradient.
            FuturisticBackground()
            
            VStack(spacing: 0) {
                // MARK: - Top Tab Bar
                HStack(spacing: 0) {
                    Button {
                        withAnimation { selectedTab = 0 }
                    } label: {
                        VStack(spacing: 2) {
                            Text("Portfolio")
                                .font(.headline)
                            Text("Track your assets & P/L")
                                .font(.caption)
                        }
                        .foregroundColor(selectedTab == 0 ? .white : .gray)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(selectedTab == 0 ? brandAccent.opacity(0.3) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button {
                        withAnimation { selectedTab = 1 }
                    } label: {
                        Text("Transactions")
                            .font(.headline)
                            .foregroundColor(selectedTab == 1 ? .white : .gray)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(selectedTab == 1 ? brandAccent.opacity(0.3) : Color.clear)
                            .cornerRadius(8)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                // Content switcher
                if selectedTab == 0 {
                    overviewTab
                } else {
                    transactionsTab
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddHoldingView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()  // Your existing SettingsView
        }
        .sheet(isPresented: $showPaymentMethodsSheet) {
            PaymentMethodsView()
        }
        // Apply the color scheme dynamically (ensure AppTheme is defined accordingly)
        .preferredColorScheme(AppTheme.currentColorScheme)
    }
}

// MARK: - PortfolioView Subviews
extension PortfolioView {
    private var overviewTab: some View {
        ScrollView(showsIndicators: false) {
            // Slightly reduced spacing from 12 to 10
            VStack(spacing: 10) {
                headerCard
                performanceChartCard
                holdingsSection
                connectExchangesSection
            }
            // Tighter bottom spacing overall
            .padding(.bottom, 8)
        }
    }
    
    private var transactionsTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                TransactionsRow(symbol: "BTC", quantity: 0.5, price: 20000,
                                date: Date(timeIntervalSinceNow: -86400), isBuy: true)
                TransactionsRow(symbol: "ETH", quantity: 2.0, price: 1500,
                                date: Date(timeIntervalSinceNow: -172800), isBuy: true)
                TransactionsRow(symbol: "BTC", quantity: 0.2, price: 22000,
                                date: Date(), isBuy: false)
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }
    
    private var headerCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.2),
                            Color.black.opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("$65,000.00")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("Total P/L: $13,500.00")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }
                .padding(.leading, 16)
                
                Spacer()
                
                if #available(iOS 16.0, *) {
                    VStack(spacing: 6) {
                        ThemedPortfolioPieChartView(holdings: displayedHoldings)
                            .frame(width: 100, height: 100)
                            .onTapGesture {
                                withAnimation {
                                    showLegend.toggle()
                                }
                            }
                        
                        if showLegend {
                            PortfolioLegendView(
                                holdings: displayedHoldings,
                                totalValue: viewModel.totalValue
                            )
                            .transition(.opacity)
                        }
                    }
                    .padding(.trailing, 16)
                }
            }
            .padding(.vertical, 12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var performanceChartCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.14),
                            Color.black.opacity(58.4)
                        ]),
                        startPoint: .bottomTrailing,
                        endPoint: .topLeading
                    )
                )
                .shadow(color: .black.opacity(10.4), radius: 4, x: 0, y: 2)
            
            PortfolioChartView()
                .frame(height: 240)
                // Even less bottom padding around the chart/timeframe
                .padding(.top, 10.8)
                .padding(.bottom, -18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
    
    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Holdings")
                    .foregroundColor(.white)
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSearchBar.toggle()
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            
            if showSearchBar {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search Holdings...", text: $searchTerm)
                        .foregroundColor(.white)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(brandAccent.opacity(0.5), lineWidth: 1)
                )
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: showSearchBar)
                .padding(.horizontal, 16)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(displayedHoldings) { holding in
                    PortfolioCoinRow(viewModel: viewModel, holding: holding)
                        .padding(.horizontal, 16)
                }
                .onDelete { indexSet in
                    viewModel.removeHolding(at: indexSet)
                }
            }
            .padding(.top, 8)
        }
        .padding(.top, 8)
    }
    
    private var connectExchangesSection: some View {
        HStack(spacing: 8) {
            Button {
                showPaymentMethodsSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "link.circle.fill")
                    Text("Connect Exchanges & Wallets")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(brandAccent.opacity(0.3))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            Button {
                showTooltip.toggle()
            } label: {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.white)
                    .font(.title3)
            }
            .popover(isPresented: $showTooltip) {
                Text("Link your accounts to trade seamlessly.\nThis is a quick info popover!")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.black)
                    .cornerRadius(8)
            }
        }
        // Reducing bottom padding further
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Recent Transactions", iconName: "clock.arrow.circlepath")
            transactionRow(action: "Buy BTC", change: "+0.012 BTC", value: "$350", time: "3h ago")
            transactionRow(action: "Sell ETH", change: "-0.05 ETH", value: "$90", time: "1d ago")
            transactionRow(action: "Stake SOL", change: "+10 SOL", value: "", time: "2d ago")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
    
    private func transactionRow(action: String, change: String, value: String, time: String) -> some View {
        HStack {
            Text(action)
                .foregroundColor(.white)
            Spacer()
            VStack(alignment: .trailing) {
                Text(change)
                    .foregroundColor(change.hasPrefix("-") ? .red : .green)
                if !value.isEmpty {
                    Text(value)
                        .foregroundColor(.gray)
                }
            }
            Text(time)
                .foregroundColor(.gray)
                .font(.caption)
                .frame(width: 50, alignment: .trailing)
        }
    }
    
    private var communitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Community & Social", iconName: "person.3.fill")
            Text("Join our Discord, follow us on Twitter, or vote on community proposals.")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(spacing: 16) {
                VStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("Discord")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                VStack {
                    Image(systemName: "bird")
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("Twitter")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                VStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("Governance")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
    
    private var footer: some View {
        VStack(spacing: 4) {
            Text("CryptoSage AI v1.0.0 (Beta)")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
            Text("All information is provided as-is and is not guaranteed to be accurate. Final decisions are your own responsibility.")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    private func sectionHeading(_ text: String, iconName: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if let icon = iconName {
                    Image(systemName: icon)
                        .foregroundColor(.yellow)
                }
                Text(text)
                    .font(.title3).bold()
                    .foregroundColor(.white)
            }
            Divider()
                .background(Color.white.opacity(0.15))
        }
    }
    
    private func formatPrice(_ value: Double) -> String {
        guard value > 0 else { return "$0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if value < 1.0 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 8
        } else {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        }
        return "$" + (formatter.string(from: NSNumber(value: value)) ?? "0.00")
    }
    
    private func coinIconView(for coin: MarketCoin, size: CGFloat) -> some View {
        Group {
            if let imageUrl = coin.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .scaledToFill()
                             .frame(width: size, height: size)
                             .clipShape(Circle())
                    } else if phase.error != nil {
                        Circle().fill(Color.gray.opacity(0.3))
                            .frame(width: size, height: size)
                    } else {
                        ProgressView().frame(width: size, height: size)
                    }
                }
            } else {
                Circle().fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
            }
        }
    }
    
    private func statCell(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Preview
struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView()
            .preferredColorScheme(.dark)
    }
}
