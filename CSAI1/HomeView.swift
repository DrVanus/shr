import SwiftUI
import Combine

// MARK: - Fear & Greed ViewModel
class FearGreedViewModel: ObservableObject {
    @Published var value: Int = 0
    @Published var label: String = "Neutral"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchIndex() {
        guard let url = URL(string: "https://api.alternative.me/fng/?limit=1") else { return }
        isLoading = true
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: FearGreedResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isLoading = false
                if case let .failure(error) = completion {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
            } receiveValue: { response in
                if let latest = response.data.first {
                    self.value = Int(latest.value) ?? 0
                    self.label = latest.valueClassification
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Fear & Greed API Models
struct FearGreedResponse: Decodable {
    let data: [FearGreedData]
}
struct FearGreedData: Decodable {
    let value: String
    let valueClassification: String
}

// MARK: - Crypto News ViewModel
class CryptoNewsViewModel: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchNews() {
        guard let url = URL(string: "https://api.coinstats.app/public/v1/news?skip=0&limit=3") else { return }
        isLoading = true
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: NewsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isLoading = false
                if case let .failure(error) = completion {
                    self.errorMessage = "News error: \(error.localizedDescription)"
                }
            } receiveValue: { response in
                self.articles = response.news
            }
            .store(in: &cancellables)
    }
}

// MARK: - News Models
struct NewsResponse: Decodable {
    let news: [NewsArticle]
}

// NOTE: Swift warns about `let id = UUID()` in a Decodable.
// We can either ignore the warning, make 'id' a 'var', or exclude it from decoding.
struct NewsArticle: Decodable, Identifiable {
    var id = UUID()  // changed let -> var to remove decode warning
    let title: String
    let link: String
}

// MARK: - Gold Button Style
struct CSGoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.black)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1.0, green: 0.84, blue: 0.0),
                        Color.orange
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

// MARK: - Time Range Enum
enum HomeTimeRange: String, CaseIterable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case threeMonth = "3M"
    case year = "1Y"
    case all = "ALL"
}

// MARK: - (Optional) HomeLineChart
struct HomeLineChart: View {
    let data: [Double]
    var body: some View {
        GeometryReader { geo in
            if data.count > 1,
               let minVal = data.min(),
               let maxVal = data.max(),
               maxVal > minVal {
                
                let range = maxVal - minVal
                Path { path in
                    for (index, value) in data.enumerated() {
                        let xPos = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let yPos = geo.size.height * (1 - CGFloat((value - minVal) / range))
                        if index == 0 {
                            path.move(to: CGPoint(x: xPos, y: yPos))
                        } else {
                            path.addLine(to: CGPoint(x: xPos, y: yPos))
                        }
                    }
                }
                .stroke(Color.green, lineWidth: 2)
                
                Path { path in
                    for (index, value) in data.enumerated() {
                        let xPos = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let yPos = geo.size.height * (1 - CGFloat((value - minVal) / range))
                        if index == 0 {
                            path.move(to: CGPoint(x: xPos, y: geo.size.height))
                            path.addLine(to: CGPoint(x: xPos, y: yPos))
                        } else {
                            path.addLine(to: CGPoint(x: xPos, y: yPos))
                        }
                    }
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(Color.green.opacity(0.2))
                
            } else {
                Text("No Chart Data")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - CoinCardView
struct CoinCardView: View {
    let coin: MarketCoin
    
    var body: some View {
        VStack(spacing: 6) {
            coinIconView(for: coin, size: 32)
            
            Text(coin.symbol.uppercased())
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(formatPrice(coin.price))
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text("\(coin.dailyChange, specifier: "%.2f")%")
                .font(.caption)
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
        }
        .frame(width: 90, height: 120)
        .padding(6)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
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
}

// MARK: - HomeView
struct HomeView: View {
    @StateObject private var marketVM = MarketViewModel()
    
    // Fear & Greed + News
    @StateObject private var fearGreedVM = FearGreedViewModel()
    @StateObject private var newsVM = CryptoNewsViewModel()
    
    @State private var showAllWatchlist = false
    @State private var showSettings = false
    @State private var showNotifications = false
    
    // Filter stablecoins out of trending
    private var liveTrending: [MarketCoin] {
        let stables = ["USDT", "USDC", "BUSD", "DAI"]
        return marketVM.coins
            .filter { !stables.contains($0.symbol.uppercased()) }
            .sorted { $0.volume > $1.volume }
            .prefix(3)
            .map { $0 }
    }
    
    private var liveWatchlist: [MarketCoin] {
        marketVM.coins.filter { $0.isFavorite }
    }
    
    private var liveTopGainers: [MarketCoin] {
        Array(marketVM.coins.sorted { $0.dailyChange > $1.dailyChange }.prefix(3))
    }
    
    private var liveTopLosers: [MarketCoin] {
        Array(marketVM.coins.sorted { $0.dailyChange < $1.dailyChange }.prefix(3))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.25)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            NavigationView {
                // FIX 1: disambiguate the ScrollView
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        PortfolioChartView()
                        
                        watchlistSection
                            .animation(.spring(), value: showAllWatchlist)
                        
                        marketStatsSection
                        fearGreedSection
                        aiAndInviteSection
                        
                        trendingSection
                        topMoversSection
                        arbitrageSection
                        eventsSection
                        exploreSection
                        
                        newsSection
                        transactionsSection
                        communitySection
                        footer
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    .refreshable {
                        // If MarketViewModel has a refresh method, call it here:
                        // marketVM.fetchCoins()
                        fearGreedVM.fetchIndex()
                        newsVM.fetchNews()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(.white)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showNotifications = true
                        }) {
                            Image(systemName: "bell")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .onAppear {
            fearGreedVM.fetchIndex()
            newsVM.fetchNews()
        }
        // If you don’t have a real NotificationsView, just use a placeholder:
        .sheet(isPresented: $showNotifications) {
            // REPLACE WITH YOUR NOTIFICATIONS VIEW, or remove if you don't have one
            Text("Notifications Placeholder")
                .font(.title)
                .padding()
        }
        .sheet(isPresented: $showSettings) {
            // If you have a real SettingsView, use it. Otherwise:
            Text("Settings Placeholder")
                .font(.title)
                .padding()
        }
    }
}

// MARK: - HomeView Subviews
extension HomeView {
    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeading("Your Watchlist", iconName: "eye")
            
            let coinsToShow = showAllWatchlist ? liveWatchlist : Array(liveWatchlist.prefix(3))
            ForEach(coinsToShow) { coin in
                NavigationLink(destination: CoinDetailView(coin: coin)) {
                    HStack {
                        coinIconView(for: coin, size: 24)
                        Text(coin.symbol.uppercased())
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(formatPrice(coin.price))
                            .foregroundColor(.white)
                        Text("\(coin.dailyChange, specifier: "%.2f")%")
                            .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
                    }
                    .padding(.vertical, 4)
                }
            }
            if liveWatchlist.count > 3 {
                Button(showAllWatchlist ? "Show Less" : "Show More") {
                    showAllWatchlist.toggle()
                }
                .font(.caption)
                .foregroundColor(.blue)
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
    
    private var marketStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Market Stats", iconName: "chart.bar")
            
            let columns = [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                statCell(title: "Global Market Cap", value: "$1.2T", icon: "globe")
                statCell(title: "24h Volume", value: "$63.8B", icon: "clock")
                statCell(title: "BTC Dominance", value: "46.3%", icon: "bitcoinsign.circle")
                statCell(title: "ETH Dominance", value: "19.1%", icon: "chart.bar.xaxis")
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
    
    private var fearGreedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Market Sentiment", iconName: "exclamationmark.triangle")
            
            if fearGreedVM.isLoading {
                ProgressView("Loading Fear & Greed...")
                    .foregroundColor(.white)
            } else if let error = fearGreedVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            } else {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 10)
                            .frame(width: 60, height: 60)
                        Circle()
                            .trim(from: 0, to: CGFloat(fearGreedVM.value) / 100)
                            .stroke(Color.yellow, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        Text("\(fearGreedVM.value)")
                            .font(.subheadline).bold()
                            .foregroundColor(.yellow)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fear & Greed Index: \(fearGreedVM.value) (\(fearGreedVM.label))")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                        Text("Data from alternative.me")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
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
    
    private var aiAndInviteSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "exclamationmark.shield")
                        .foregroundColor(.green)
                    Text("AI Risk Scan")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Text("Quickly analyze your portfolio risk.")
                    .font(.caption)
                    .foregroundColor(.gray)
                Button("Scan Now") {}
                    .buttonStyle(CSGoldButtonStyle())
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "gift")
                        .foregroundColor(.yellow)
                    Text("Invite & Earn BTC")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Text("Refer friends, get rewards.")
                    .font(.caption)
                    .foregroundColor(.gray)
                Button("Invite Now") {}
                    .buttonStyle(CSGoldButtonStyle())
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Trending", iconName: "flame")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(liveTrending) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            CoinCardView(coin: coin)
                        }
                    }
                }
                .padding(.vertical, 6)
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
    
    private var topMoversSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Top Gainers", iconName: "arrow.up.right")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(liveTopGainers) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            CoinCardView(coin: coin)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            
            sectionHeading("Top Losers", iconName: "arrow.down.right")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(liveTopLosers) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            CoinCardView(coin: coin)
                        }
                    }
                }
                .padding(.vertical, 6)
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
    
    private var arbitrageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Arbitrage Opportunities", iconName: "arrow.left.and.right.circle")
            Text("Find price differences across exchanges for potential profit.")
                .font(.caption)
                .foregroundColor(.gray)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BTC/USDT")
                        .foregroundColor(.white)
                    Text("Ex A: $65,000\nEx B: $66,200\nPotential: $1,200")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("ETH/USDT")
                        .foregroundColor(.white)
                    Text("Ex A: $1,800\nEx B: $1,805\nProfit: $5")
                        .font(.caption)
                        .foregroundColor(.green)
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
    
    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Events Calendar", iconName: "calendar")
            Text("Stay updated on upcoming crypto events.")
                .font(.caption)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• ETH2 Hard Fork")
                    .foregroundColor(.white)
                Text("May 30 • Upgrade to reduce fees")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("• DOGE Conference")
                    .foregroundColor(.white)
                Text("June 10 • Global doge event")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("• SOL Hackathon")
                    .foregroundColor(.white)
                Text("June 15 • Dev grants for new apps")
                    .font(.caption)
                    .foregroundColor(.gray)
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
    
    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Explore", iconName: "magnifyingglass")
            Text("Discover advanced AI and market features.")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Market Scan")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Text("Scan market signals, patterns.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("DeFi Analytics")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Text("Monitor yields, track TVL.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("NFT Explorer")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Text("Browse trending collections.")
                        .font(.caption2)
                        .foregroundColor(.gray)
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
    
    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Latest Crypto News", iconName: "newspaper")
            
            if newsVM.isLoading {
                ProgressView("Loading News...")
                    .foregroundColor(.white)
            } else if let error = newsVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            } else {
                ForEach(newsVM.articles) { article in
                    newsRow(title: article.title, link: article.link)
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
    
    private func newsRow(title: String, link: String) -> some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.4))
                .frame(width: 8, height: 8)
            Text(title)
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Button(action: {
                if let url = URL(string: link) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 4) {
                    Text("Read more...")
                        .font(.caption)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
            }
            .foregroundColor(.blue)
        }
        .padding(.vertical, 2)
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
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .preferredColorScheme(.dark)
    }
}
