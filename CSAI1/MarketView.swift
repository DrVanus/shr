//
//  MarketView.swift
//  Updated with Larger CryptoCompare Dictionary, More Metrics
//
//  Created by ChatGPT on 3/30/25
//

import SwiftUI
import Charts

// MARK: - Segment & Sort

enum MarketSegment: String, CaseIterable {
    case all = "All"
    case favorites = "Favorites"
    case gainers = "Gainers"
    case losers  = "Losers"
}

enum SortField: String {
    case coin, price, dailyChange, volume, none
}

enum SortDirection {
    case asc, desc
}

// MARK: - Dictionaries

/// Plan A: CryptoCompare logo URLs for popular coins (expanded)
private let cryptoCompareLogos: [String: String] = [
    // Common top coins
    "BTC":  "https://www.cryptocompare.com/media/37746251/btc.png",
    "ETH":  "https://www.cryptocompare.com/media/20646/eth_logo.png",
    "USDT": "https://www.cryptocompare.com/media/37746338/usdt.png",
    "BNB":  "https://www.cryptocompare.com/media/37746880/bnb.png",
    "DOGE": "https://www.cryptocompare.com/media/37746339/doge.png",
    "ADA":  "https://www.cryptocompare.com/media/37746235/ada.png",
    "SOL":  "https://www.cryptocompare.com/media/37746868/sol.png",
    "XRP":  "https://www.cryptocompare.com/media/37746347/xrp.png",
    "TRX":  "https://www.cryptocompare.com/media/37746892/trx.png",
    
    // More popular coins
    "MATIC": "https://www.cryptocompare.com/media/37746899/matic.png",
    "LTC":   "https://www.cryptocompare.com/media/35309662/ltc.png",
    "DOT":   "https://www.cryptocompare.com/media/37746919/dot.png",
    "AVAX":  "https://www.cryptocompare.com/media/37746896/avax.png",
    "UNI":   "https://www.cryptocompare.com/media/37747644/uni.png",
    "SHIB":  "https://www.cryptocompare.com/media/37747734/shib.png",
    "LINK":  "https://www.cryptocompare.com/media/37746251/link.png",
    "XLM":   "https://www.cryptocompare.com/media/37746347/xlm.png",
    "ATOM":  "https://www.cryptocompare.com/media/37746603/atom.png",
    "ETC":   "https://www.cryptocompare.com/media/37746253/etc.png",
    "BCH":   "https://www.cryptocompare.com/media/37746248/bch.png",
    
    // iExec RLC
    "RLC":   "https://www.cryptocompare.com/media/27011013/rlc.png",
    
    // Additional from your screenshots:
    "LEO":   "https://www.cryptocompare.com/media/37746913/leo.png",      // UNUS SED LEO
    "WSTETH":"https://www.cryptocompare.com/media/37748026/wsteth.png",  // Lido wstETH if it exists
    "WBTC":  "https://www.cryptocompare.com/media/37746346/wbtc.png",
    "TON":   "https://www.cryptocompare.com/media/37747413/ton.png",     // Toncoin
    "OM":    "https://www.cryptocompare.com/media/37746888/om.png",      // MANTRA
    "HBAR":  "https://www.cryptocompare.com/media/37746344/hbar.png",
    
    // Some coins might not exist on CryptoCompare yet:
    // SUI, BGB, PI, USDS, etc. If they are missing or 404, you'll need to add correct links.
    
    // Add more as needed...
]

// MARK: - Fetch Results

fileprivate enum CoinFetchResult {
    case success([CoinGeckoMarketData])
    case fallbackSuccess([CoinPaprikaData])
    case failure(Error)
}

fileprivate enum GlobalFetchResult {
    case success(GlobalMarketData)
    case failure(Error)
}

// MARK: - Paprika Models

struct CoinPaprikaData: Codable {
    let id: String
    let symbol: String
    let name: String
    let rank: Int?
    let circulating_supply: Double?
    let total_supply: Double?
    let max_supply: Double?
    let beta_value: Double?
    let first_data_at: String?
    let last_updated: String?
    let quotes: [String: PaprikaQuote]?
}

struct PaprikaQuote: Codable {
    let price: Double?
    let volume_24h: Double?
    let market_cap: Double?
    let fully_diluted_market_cap: Double?
    let percent_change_1h: Double?
    let percent_change_24h: Double?
    let percent_change_7d: Double?
}

// MARK: - Global Data

struct GlobalMarketDataResponse: Codable {
    let data: GlobalMarketData
}

struct GlobalMarketData: Codable {
    let active_cryptocurrencies: Int?
    let markets: Int?
    let total_market_cap: [String: Double]?
    let total_volume: [String: Double]?
    let market_cap_percentage: [String: Double]?
    let market_cap_change_percentage_24h_usd: Double?
}

// MARK: - Cache Managers

class MarketCacheManager {
    static let shared = MarketCacheManager()
    private let fileName = "cachedMarketData.json"
    private init() {}
    
    func saveCoinsToDisk(_ coins: [CoinGeckoMarketData]) {
        do {
            let data = try JSONEncoder().encode(coins)
            let url = try cacheFileURL()
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save coin data: \(error)")
        }
    }
    
    func loadCoinsFromDisk() -> [CoinGeckoMarketData]? {
        do {
            let url = try cacheFileURL()
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([CoinGeckoMarketData].self, from: data)
        } catch {
            print("Failed to load cached data: \(error)")
            return nil
        }
    }
    
    private func cacheFileURL() throws -> URL {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw URLError(.fileDoesNotExist)
        }
        return docs.appendingPathComponent(fileName)
    }
}

class GlobalCacheManager {
    static let shared = GlobalCacheManager()
    private let fileName = "cachedGlobalData.json"
    private init() {}
    
    func saveGlobalData(_ data: GlobalMarketData) {
        do {
            let encoded = try JSONEncoder().encode(data)
            let url = try cacheFileURL()
            try encoded.write(to: url, options: .atomic)
        } catch {
            print("Failed to save global data: \(error)")
        }
    }
    
    func loadGlobalData() -> GlobalMarketData? {
        do {
            let url = try cacheFileURL()
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(GlobalMarketData.self, from: data)
        } catch {
            print("Failed to load cached global data: \(error)")
            return nil
        }
    }
    
    private func cacheFileURL() throws -> URL {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw URLError(.fileDoesNotExist)
        }
        return docs.appendingPathComponent(fileName)
    }
}

// MARK: - ViewModel

@MainActor
class MarketViewModel: ObservableObject {
    @Published var coins: [MarketCoin] = []
    @Published var filteredCoins: [MarketCoin] = []
    @Published var globalData: GlobalMarketData?
    
    @Published var selectedSegment: MarketSegment = .all
    @Published var showSearchBar: Bool = false
    @Published var searchText: String = ""
    
    @Published var sortField: SortField = .none
    @Published var sortDirection: SortDirection = .asc
    
    @Published var coinError: String?
    @Published var globalError: String?
    
    private let favoritesKey = "favoriteCoinSymbols"
    private var coinRefreshTask: Task<Void, Never>?
    private var globalRefreshTask: Task<Void, Never>?
    
    init() {
        // Load cached coin data if available
        if let cached = MarketCacheManager.shared.loadCoinsFromDisk() {
            self.coins = cached.map {
                MarketCoin(
                    symbol: $0.symbol.uppercased(),
                    name: $0.name,
                    price: $0.current_price,
                    dailyChange: $0.price_change_percentage_24h ?? 0,
                    hourlyChange: $0.price_change_percentage_1h_in_currency ?? 0,
                    volume: $0.total_volume,
                    sparklineData: $0.sparkline_in_7d?.price ?? [],
                    imageUrl: $0.image
                )
            }
        } else {
            loadFallbackCoins()
        }
        
        // Load cached global data if available
        if let cachedGlobal = GlobalCacheManager.shared.loadGlobalData() {
            self.globalData = cachedGlobal
        }
        
        loadFavorites()
        applyAllFiltersAndSort()
        
        Task {
            await fetchMarketDataMulti()
            await fetchGlobalMarketDataMulti()
        }
        
        startAutoRefresh()
    }
    
    deinit {
        coinRefreshTask?.cancel()
        globalRefreshTask?.cancel()
    }
    
    // MARK: - Fetching Coin Data
    
    private func fetchCoinGecko() async throws -> CoinFetchResult {
        let urlString = """
            https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd\
            &order=market_cap_desc&per_page=100&page=1&sparkline=true\
            &price_change_percentage=1h,24h
            """
        guard let url = URL(string: urlString) else {
            return .failure(URLError(.badURL))
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
            return .failure(URLError(.badServerResponse))
        }
        let decoded = try JSONDecoder().decode([CoinGeckoMarketData].self, from: data)
        return .success(decoded)
    }
    
    private func fetchCoinPaprika() async throws -> CoinFetchResult {
        let urlString = "https://api.coinpaprika.com/v1/tickers?quotes=USD&limit=100"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode([CoinPaprikaData].self, from: data)
        return .fallbackSuccess(decoded)
    }
    
    func fetchMarketDataMulti() async {
        do {
            let result = try await fetchCoinGecko()
            switch result {
            case .success(let rawCoins):
                // Save new data to disk
                MarketCacheManager.shared.saveCoinsToDisk(rawCoins)
                
                // Convert to MarketCoin
                self.coins = rawCoins.map { raw in
                    MarketCoin(
                        symbol: raw.symbol.uppercased(),
                        name: raw.name,
                        price: raw.current_price,
                        dailyChange: raw.price_change_percentage_24h ?? 0,
                        hourlyChange: raw.price_change_percentage_1h_in_currency ?? 0,
                        volume: raw.total_volume,
                        sparklineData: raw.sparkline_in_7d?.price ?? [],
                        imageUrl: raw.image
                    )
                }
                coinError = nil
                
            default:
                // If it wasn't .success, throw to trigger fallback
                throw URLError(.cannotConnectToHost)
            }
        } catch {
            // If CoinGecko fails, try fallback
            do {
                let fallbackResult = try await fetchCoinPaprika()
                switch fallbackResult {
                case .fallbackSuccess(let papCoins):
                    // Keep sparkline from old data if possible
                    var updated: [MarketCoin] = []
                    
                    for pap in papCoins {
                        let price = pap.quotes?["USD"]?.price ?? 0
                        let vol = pap.quotes?["USD"]?.volume_24h ?? 0
                        let change24h = pap.quotes?["USD"]?.percent_change_24h ?? 0
                        let change1h = pap.quotes?["USD"]?.percent_change_1h ?? 0
                        
                        // Check if we already have a coin with this symbol
                        if let existingCoin = self.coins.first(where: {
                            $0.symbol.uppercased() == pap.symbol.uppercased()
                        }) {
                            let newCoin = MarketCoin(
                                symbol: existingCoin.symbol,
                                name: pap.name,
                                price: price,
                                dailyChange: change24h,
                                hourlyChange: change1h,
                                volume: vol,
                                sparklineData: existingCoin.sparklineData,
                                imageUrl: existingCoin.imageUrl,
                                isFavorite: existingCoin.isFavorite
                            )
                            updated.append(newCoin)
                        } else {
                            // New coin not in list before
                            let newCoin = MarketCoin(
                                symbol: pap.symbol.uppercased(),
                                name: pap.name,
                                price: price,
                                dailyChange: change24h,
                                hourlyChange: change1h,
                                volume: vol,
                                sparklineData: [],
                                imageUrl: nil,
                                isFavorite: false
                            )
                            updated.append(newCoin)
                        }
                    }
                    self.coins = updated
                    coinError = "Using fallback from CoinPaprika."
                    
                default:
                    coinError = "Coin data error: \(error.localizedDescription)"
                }
            } catch {
                coinError = "Coin data error: \(error.localizedDescription)"
            }
        }
        loadFavorites()
        applyAllFiltersAndSort()
    }
    
    // MARK: - Fetching Global Data
    
    private func fetchGlobalCoinGecko() async throws -> GlobalFetchResult {
        let urlString = "https://api.coingecko.com/api/v3/global"
        guard let url = URL(string: urlString) else {
            return .failure(URLError(.badURL))
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
            return .failure(URLError(.badServerResponse))
        }
        let decoded = try JSONDecoder().decode(GlobalMarketDataResponse.self, from: data)
        return .success(decoded.data)
    }
    
    func fetchGlobalMarketDataMulti() async {
        do {
            let result = try await fetchGlobalCoinGecko()
            switch result {
            case .success(let gData):
                GlobalCacheManager.shared.saveGlobalData(gData)
                self.globalData = gData
                globalError = nil
            default:
                throw URLError(.cannotConnectToHost)
            }
        } catch {
            // Attempt fallback aggregator from Paprika
            do {
                let fallback = try await fetchGlobalPaprika()
                GlobalCacheManager.shared.saveGlobalData(fallback)
                self.globalData = fallback
                globalError = "Using fallback aggregator for global data."
            } catch {
                globalError = "Global data error: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchGlobalPaprika() async throws -> GlobalMarketData {
        let urlString = "https://api.coinpaprika.com/v1/global"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(GlobalMarketData.self, from: data)
        return decoded
    }
    
    // MARK: - Fallback Local Data
    
    private func loadFallbackCoins() {
        self.coins = [
            MarketCoin(
                symbol: "BTC",
                name: "Bitcoin",
                price: 28000,
                dailyChange: -2.15,
                hourlyChange: -0.30,
                volume: 450_000_000,
                sparklineData: [28000, 27950, 27980, 27890, 27850, 27820, 27800],
                imageUrl: "https://www.cryptocompare.com/media/37746251/btc.png"
            ),
            MarketCoin(
                symbol: "ETH",
                name: "Ethereum",
                price: 1800,
                dailyChange: 3.44,
                hourlyChange: 0.50,
                volume: 210_000_000,
                sparklineData: [1790, 1795, 1802, 1808, 1805, 1810, 1807],
                imageUrl: "https://www.cryptocompare.com/media/20646/eth_logo.png"
            )
        ]
    }
    
    // MARK: - Favorites
    
    private func loadFavorites() {
        let saved = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        for i in coins.indices {
            if saved.contains(coins[i].symbol.uppercased()) {
                coins[i].isFavorite = true
            }
        }
    }
    
    private func saveFavorites() {
        let faves = coins.filter { $0.isFavorite }.map { $0.symbol.uppercased() }
        UserDefaults.standard.setValue(faves, forKey: favoritesKey)
    }
    
    func toggleFavorite(_ coin: MarketCoin) {
        guard let idx = coins.firstIndex(where: { $0.id == coin.id }) else { return }
        withAnimation(.spring()) {
            coins[idx].isFavorite.toggle()
        }
        saveFavorites()
        applyAllFiltersAndSort()
    }
    
    // MARK: - Sorting & Filtering
    
    @MainActor
    func updateSegment(_ seg: MarketSegment) {
        selectedSegment = seg
        applyAllFiltersAndSort()
    }
    
    @MainActor
    func updateSearch(_ query: String) {
        searchText = query
        applyAllFiltersAndSort()
    }
    
    func toggleSort(for field: SortField) {
        if sortField == field {
            sortDirection = (sortDirection == .asc) ? .desc : .asc
        } else {
            sortField = field
            sortDirection = .asc
        }
        applyAllFiltersAndSort()
    }
    
    func applyAllFiltersAndSort() {
        var result = coins
        
        let lowerSearch = searchText.lowercased()
        if !lowerSearch.isEmpty {
            result = result.filter {
                $0.symbol.lowercased().contains(lowerSearch) ||
                $0.name.lowercased().contains(lowerSearch)
            }
        }
        
        switch selectedSegment {
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .gainers:
            result = result.filter { $0.dailyChange > 0 }
        case .losers:
            result = result.filter { $0.dailyChange < 0 }
        default:
            break
        }
        
        filteredCoins = sortCoins(result)
    }
    
    private func sortCoins(_ arr: [MarketCoin]) -> [MarketCoin] {
        guard sortField != .none else { return arr }
        return arr.sorted { lhs, rhs in
            switch sortField {
            case .coin:
                let compare = lhs.symbol.localizedCaseInsensitiveCompare(rhs.symbol)
                return sortDirection == .asc ? (compare == .orderedAscending) : (compare == .orderedDescending)
            case .price:
                return sortDirection == .asc ? (lhs.price < rhs.price) : (lhs.price > rhs.price)
            case .dailyChange:
                return sortDirection == .asc ? (lhs.dailyChange < rhs.dailyChange) : (lhs.dailyChange > rhs.dailyChange)
            case .volume:
                return sortDirection == .asc ? (lhs.volume < rhs.volume) : (lhs.volume > rhs.volume)
            case .none:
                return false
            }
        }
    }
    
    // MARK: - Auto-Refresh
    
    private func startAutoRefresh() {
        // Auto-refresh coin data every 60s
        coinRefreshTask = Task.detached { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000) // 60s
                await self.fetchMarketDataMulti()
            }
        }
        
        // Auto-refresh global data every 3 min
        globalRefreshTask = Task.detached { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 180_000_000_000) // 3 min
                await self.fetchGlobalMarketDataMulti()
            }
        }
    }
    
    // Optional: example for live prices
    func fetchLivePricesFromCoinbase() {
        Task {
            for (index, coin) in coins.enumerated() {
                if let newPrice = await CoinbaseService().fetchSpotPrice(coin: coin.symbol, fiat: "USD") {
                    coins[index].price = newPrice
                }
                let newSpark = await BinanceService.fetchSparkline(symbol: coin.symbol)
                if !newSpark.isEmpty {
                    coins[index].sparklineData = newSpark
                }
            }
            applyAllFiltersAndSort()
        }
    }
}

// MARK: - Main MarketView

struct MarketView: View {
    @EnvironmentObject var vm: MarketViewModel
    
    private let coinWidth: CGFloat   = 140
    private let priceWidth: CGFloat  = 70
    private let dailyWidth: CGFloat  = 50
    private let volumeWidth: CGFloat = 70
    private let starWidth: CGFloat   = 40
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    topBar
                    summaryView
                    segmentRow
                    if vm.showSearchBar { searchBar }
                    columnHeader
                    coinList
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                withAnimation { vm.showSearchBar.toggle() }
            } label: {
                Image(systemName: vm.showSearchBar ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Global Data Summary
    
    private var summaryView: some View {
        VStack(spacing: 8) {
            if let global = vm.globalData {
                // First row: Market cap & Volume
                HStack {
                    if let cap = global.total_market_cap?["usd"] {
                        Text("Market Cap: \(cap.formattedWithAbbreviations())")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    if let vol = global.total_volume?["usd"] {
                        Text("Volume: \(vol.formattedWithAbbreviations())")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                
                // Second row: BTC Dominance & 24h Market Cap Change
                HStack {
                    if let btcDom = global.market_cap_percentage?["btc"] {
                        Text("BTC Dominance: \(String(format: "%.1f", btcDom))%")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    if let mcChange = global.market_cap_change_percentage_24h_usd {
                        Text("MC 24h: \(String(format: "%.2f", mcChange))%")
                            .font(.caption2)
                            .foregroundColor(mcChange >= 0 ? .green : .red)
                    }
                }
            } else {
                // If global data fails or is loading
                if let gErr = vm.globalError {
                    Text(gErr)
                        .font(.footnote)
                        .foregroundColor(.red)
                } else {
                    Text("Loading global market data...")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Show coin error if any
            if let cErr = vm.coinError {
                Text(cErr)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Segment Row
    
    private var segmentRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MarketSegment.allCases, id: \.self) { seg in
                    Button {
                        vm.updateSegment(seg)
                    } label: {
                        Text(seg.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(vm.selectedSegment == seg ? .black : .white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(vm.selectedSegment == seg ? Color.white : Color.white.opacity(0.1))
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search coins...", text: $vm.searchText)
                .foregroundColor(.white)
                .onChange(of: vm.searchText) { _ in
                    vm.applyAllFiltersAndSort()
                }
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Column Header
    
    private var columnHeader: some View {
        HStack(spacing: 0) {
            headerButton("Coin", .coin)
                .frame(width: coinWidth, alignment: .leading)
            
            Text("7D")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 40, alignment: .trailing)
            
            headerButton("Price", .price)
                .frame(width: priceWidth, alignment: .trailing)
            
            headerButton("24h", .dailyChange)
                .frame(width: dailyWidth, alignment: .trailing)
            
            headerButton("Vol", .volume)
                .frame(width: volumeWidth, alignment: .trailing)
            
            Spacer().frame(width: starWidth)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
    }
    
    private func headerButton(_ label: String, _ field: SortField) -> some View {
        Button {
            vm.toggleSort(for: field)
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                if vm.sortField == field {
                    Image(systemName: vm.sortDirection == .asc ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(vm.sortField == field ? Color.white.opacity(0.05) : Color.clear)
    }
    
    // MARK: - Coin List
    
    private var coinList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                if vm.filteredCoins.isEmpty {
                    Text(vm.searchText.isEmpty ? "No coins available." : "No coins match your search.")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                } else {
                    ForEach(vm.filteredCoins) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            coinRow(coin)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 16)
                    }
                }
            }
            .padding(.bottom, 12)
        }
        // Pull-to-refresh
        .refreshable {
            await vm.fetchMarketDataMulti()
            await vm.fetchGlobalMarketDataMulti()
        }
    }
    
    private func coinRow(_ coin: MarketCoin) -> some View {
        HStack(spacing: 0) {
            // Symbol + name + image
            HStack(spacing: 8) {
                coinImageView(symbol: coin.symbol, urlStr: coin.imageUrl)
                VStack(alignment: .leading, spacing: 3) {
                    Text(coin.symbol.uppercased())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(coin.name)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .frame(width: coinWidth, alignment: .leading)
            
            // 7-day sparkline
            if #available(iOS 16, *) {
                ZStack {
                    Rectangle().fill(Color.clear)
                        .frame(width: 50, height: 30)
                    sparkline(coin.sparklineData, dailyChange: coin.dailyChange)
                }
            } else {
                Spacer().frame(width: 50)
            }
            
            // Price
            Text(String(format: "$%.2f", coin.price))
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: priceWidth, alignment: .trailing)
                .lineLimit(1)
            
            // 24h change
            Text(String(format: "%.2f%%", coin.dailyChange))
                .font(.caption)
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
                .frame(width: dailyWidth, alignment: .trailing)
                .lineLimit(1)
            
            // Volume
            Text(shortVolume(coin.volume))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: volumeWidth, alignment: .trailing)
                .lineLimit(1)
            
            // Favorite star
            Button {
                vm.toggleFavorite(coin)
            } label: {
                Image(systemName: coin.isFavorite ? "star.fill" : "star")
                    .foregroundColor(coin.isFavorite ? .yellow : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: starWidth, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(height: 60)
    }
    
    // MARK: - Sparkline
    
    @ViewBuilder
    private func sparkline(_ data: [Double], dailyChange: Double) -> some View {
        if data.isEmpty {
            Rectangle().fill(Color.white.opacity(0.1))
        } else {
            let minValue = data.min() ?? 0
            let maxValue = data.max() ?? 1
            let range = maxValue - minValue
            let domainPaddingFraction = 0.15
            let lowerBound = minValue - range * domainPaddingFraction
            let upperBound = maxValue + range * domainPaddingFraction
            
            Chart {
                ForEach(data.indices, id: \.self) { i in
                    LineMark(
                        x: .value("Index", i),
                        y: .value("Price", data[i])
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(dailyChange >= 0 ? Color.green : Color.red)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: lowerBound...upperBound)
            .chartPlotStyle { plotArea in
                plotArea.frame(width: 50, height: 30)
            }
        }
    }
}

// MARK: - Coin Image Logic

/// Tries CryptoCompare link first (Plan A), then CoinGecko’s URL (Plan B),
/// then local asset (Plan C), then SF symbol (Plan D).
private func coinImageView(symbol: String, urlStr: String?) -> some View {
    Group {
        // PLAN A: CryptoCompare
        if let ccURLStr = cryptoCompareLogos[symbol.uppercased()],
           let ccURL = URL(string: ccURLStr) {
            AsyncImage(url: ccURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                case .failure(_):
                    // Plan B: CoinGecko
                    geckoOrLocalOrSF(symbol: symbol, geckoUrl: urlStr)
                case .empty:
                    ProgressView().frame(width: 32, height: 32)
                @unknown default:
                    geckoOrLocalOrSF(symbol: symbol, geckoUrl: urlStr)
                }
            }
        } else {
            // If no entry in dictionary, jump to plan B
            geckoOrLocalOrSF(symbol: symbol, geckoUrl: urlStr)
        }
    }
}

private func geckoOrLocalOrSF(symbol: String, geckoUrl: String?) -> some View {
    Group {
        // Plan B: CoinGecko
        if let geckoUrl = geckoUrl, let mainURL = URL(string: geckoUrl) {
            AsyncImage(url: mainURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                case .failure(_):
                    // Plan C: Local or SF
                    localOrSF(symbol: symbol)
                case .empty:
                    ProgressView().frame(width: 32, height: 32)
                @unknown default:
                    localOrSF(symbol: symbol)
                }
            }
        } else {
            // Plan C: Local or SF
            localOrSF(symbol: symbol)
        }
    }
}

private func localOrSF(symbol: String) -> some View {
    if UIImage(named: symbol.lowercased()) != nil {
        return AnyView(
            Image(symbol.lowercased())
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        )
    } else {
        return AnyView(
            Image(systemName: "bitcoinsign.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(.gray)
        )
    }
}

// MARK: - Helpers

extension Double {
    func formattedWithAbbreviations() -> String {
        let absValue = abs(self)
        switch absValue {
        case 1_000_000_000_000...:
            return String(format: "%.1fT", self / 1_000_000_000_000)
        case 1_000_000_000...:
            return String(format: "%.1fB", self / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%.1fM", self / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", self / 1_000)
        default:
            return String(format: "%.0f", self)
        }
    }
}

private func shortVolume(_ vol: Double) -> String {
    vol.formattedWithAbbreviations()
}
