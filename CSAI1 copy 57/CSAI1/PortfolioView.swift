import SwiftUI
import Charts

// Example brand accent color usage.
private let brandAccent = Color("BrandAccent")

struct PortfolioPaymentMethodsView: View {
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
        .background(FuturisticBackground())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

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
    
    // Filtered holdings to display
    private var displayedHoldings: [Holding] {
        let base = viewModel.holdings
        guard showSearchBar, !searchTerm.isEmpty else { return base }
        return base.filter {
            $0.coinName.lowercased().contains(searchTerm.lowercased()) ||
            $0.coinSymbol.lowercased().contains(searchTerm.lowercased())
        }
    }
    
    var body: some View {
        ZStack {
            // Dynamic background (assumed defined elsewhere)
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
                
                // Content switcher based on selected tab
                if selectedTab == 0 {
                    overviewTab
                } else {
                    transactionsTab
                }
            }
        }
        .onAppear {
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .sheet(isPresented: $showAddSheet) {
            // AddHoldingView is assumed to accept a view model parameter.
            AddTransactionView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()  // Your existing SettingsView.
        }
        .sheet(isPresented: $showPaymentMethodsSheet) {
            PortfolioPaymentMethodsView()
        }
        .preferredColorScheme(AppTheme.currentColorScheme)  // Assumes AppTheme is defined elsewhere.
    }
}

// MARK: - PortfolioView Subviews
extension PortfolioView {
    
    private var overviewTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                headerCard
                performanceChartCard
                holdingsSection
                connectExchangesSection
            }
            .padding(.bottom, 8)
        }
    }
    
    private var transactionsTab: some View {
        VStack {
            HStack {
                Text("Transactions")
                    .font(.headline)
                Spacer()
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            List {
                ForEach(viewModel.transactions) { tx in
                    TransactionsRow(
                        symbol: tx.coinSymbol,
                        quantity: tx.quantity,
                        price: tx.pricePerUnit,
                        date: tx.date,
                        isBuy: tx.isBuy
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if tx.isManual {
                            Button(role: .destructive) {
                                viewModel.deleteManualTransaction(tx)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                viewModel.editingTransaction = tx
                                showAddSheet = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
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
                    // Display total portfolio value.
                    Text(viewModel.totalValue, format: .currency(code: "USD"))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("Total Value")
                        .foregroundColor(viewModel.totalValue >= 0 ? .green : .red)
                        .font(.subheadline)
                }
                .padding(.leading, 16)
                
                Spacer()
                
                if #available(iOS 16.0, *) {
                    VStack(spacing: 6) {
                        // Donut pie chart showing coin distribution.
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
                            Color.gray.opacity(0.06),
                            Color.black.opacity(14.4)
                        ]),
                        startPoint: .bottomTrailing,
                        endPoint: .topLeading
                    )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            PortfolioChartView(portfolioVM: viewModel)
                .frame(height: 240)
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
}

// MARK: - Preview
struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView()
            .preferredColorScheme(.dark)
    }
}
