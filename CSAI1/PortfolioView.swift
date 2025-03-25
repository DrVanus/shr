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
                // Show a placeholder alert
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
        .background(Color.black)
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
        // We revert back to coloring the row based on profitLoss:
        let rowPL = holding.profitLoss
        
        HStack(spacing: 12) {
            // Attempt to load coin icon from holding.imageUrl
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
            
            // Name, Symbol, Favorite Star
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
                
                // We still show daily change text here:
                Text(String(format: "24h: %.2f%%", holding.dailyChange))
                    .foregroundColor(holding.dailyChange >= 0 ? .green : .red)
                    .font(.caption)
            }
            
            Spacer()
            
            // Price & "P/L"
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(holding.currentPrice, specifier: "%.2f")")
                    .font(.headline)
                
                Text(String(format: "P/L: $%.2f", rowPL))
                    .foregroundColor(rowPL >= 0 ? .green : .red)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 8)
        // Row background color now based on profitLoss again
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
            // Subtle gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color("BrandAccent").opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Top Tab Bar
                HStack(spacing: 0) {
                    // "Portfolio" with sublabel
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
                    
                    // "Transactions"
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
                
                // Switch content
                if selectedTab == 0 {
                    overviewTab
                } else {
                    transactionsTab
                }
            }
        }
        // Present sheets for adding holdings, settings, or linking accounts
        .sheet(isPresented: $showAddSheet) {
            AddHoldingView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSettingsSheet) {
            // If you have a single definition for SettingsView, reference it here:
            SettingsView()
        }
        .sheet(isPresented: $showPaymentMethodsSheet) {
            PaymentMethodsView()
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                headerCard
                performanceChartCard
                holdingsSection
                connectExchangesSection
            }
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Transactions Tab
    private var transactionsTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Example/dummy transactions
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
    
    // MARK: - Header Card (Totals + Donut)
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
                // Left: total value & P/L (placeholder or dynamic)
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
                
                // Right: donut chart + tap to toggle legend
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
    
    // MARK: - Performance Chart Card
    private var performanceChartCard: some View {
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
            
            // Replace with your real chart or Swift Charts
            PortfolioChartView()
                .frame(height: 240)
                .padding(.top, 30)
                .padding(.bottom, 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
    
    // MARK: - Holdings Section (with Search)
    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Holdings")
                    .foregroundColor(.white)
                    .font(.headline)
                
                Spacer()
                
                Button {
                    withAnimation { showSearchBar.toggle() }
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
                .transition(.slide)
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
    
    // MARK: - Connect Exchanges & Wallets
    private var connectExchangesSection: some View {
        HStack(spacing: 8) {
            Button {
                // Show PaymentMethodsView sheet
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
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - Preview
struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView()
            .preferredColorScheme(.dark)
    }
}
