//
//  MarketView.swift
//  Updated with Cryptologos Logo URLs, Paging, Timeout, & Live Price Fix
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

/// An expanded coin logo dictionary using Cryptologos links.
/// These URLs (from cryptologos.cc) are known to work reliably.
/// If any image fails, the fallback logic will use the CoinGecko URL, a local asset, or an SF symbol.
private let cryptoCompareLogos: [String: String] = [
    // Common top coins
    "BTC":   "https://cryptologos.cc/logos/bitcoin-btc-logo.png?v=013",
    "ETH":   "https://cryptologos.cc/logos/ethereum-eth-logo.png?v=013",
    "USDT":  "https://cryptologos.cc/logos/tether-usdt-logo.png?v=013",
    "BNB":   "https://cryptologos.cc/logos/binance-coin-bnb-logo.png?v=013",
    "DOGE":  "https://cryptologos.cc/logos/dogecoin-doge-logo.png?v=013",
    "ADA":   "https://cryptologos.cc/logos/cardano-ada-logo.png?v=013",
    "SOL":   "https://cryptologos.cc/logos/solana-sol-logo.png?v=013",
    "XRP":   "https://cryptologos.cc/logos/xrp-xrp-logo.png?v=013",
    "TRX":   "https://cryptologos.cc/logos/tron-trx-logo.png?v=013",
    "USDC":  "https://cryptologos.cc/logos/usd-coin-usdc-logo.png?v=013",

    // More popular coins
    "MATIC": "https://cryptologos.cc/logos/polygon-matic-logo.png?v=013",
    "LTC":   "https://cryptologos.cc/logos/litecoin-ltc-logo.png?v=013",
    "DOT":   "https://cryptologos.cc/logos/polkadot-new-dot-logo.png?v=013",
    "AVAX":  "https://cryptologos.cc/logos/avalanche-avax-logo.png?v=013",
    "UNI":   "https://cryptologos.cc/logos/uniswap-uni-logo.png?v=013",
    "SHIB":  "https://cryptologos.cc/logos/shiba-inu-shib-logo.png?v=013",
    "LINK":  "https://cryptologos.cc/logos/chainlink-link-logo.png?v=013",
    "XLM":   "https://cryptologos.cc/logos/stellar-xlm-logo.png?v=013",
    "ATOM":  "https://cryptologos.cc/logos/cosmos-atom-logo.png?v=013",
    "ETC":   "https://cryptologos.cc/logos/ethereum-classic-etc-logo.png?v=013",
    "BCH":   "https://cryptologos.cc/logos/bitcoin-cash-bch-logo.png?v=013",

    // iExec RLC
    "RLC":   "https://cryptologos.cc/logos/iexec-rlc-logo.png?v=013",

    // Additional
    "LEO":    "https://cryptologos.cc/logos/unus-sed-leo-leo-logo.png?v=013",
    "WSTETH": "https://cryptologos.cc/logos/lido-steth-steth-logo.png?v=013",
    "STETH":  "https://cryptologos.cc/logos/lido-steth-steth-logo.png?v=013",
    "WBTC":   "https://cryptologos.cc/logos/wrapped-bitcoin-wbtc-logo.png?v=013",
    "TON":    "https://cryptologos.cc/logos/toncoin-ton-logo.png?v=013",
    "OM":     "https://cryptologos.cc/logos/mantra-dao-om-logo.png?v=013",
    "HBAR":   "https://cryptologos.cc/logos/hedera-hbar-logo.png?v=013",

    // Extra examples
    "APT":   "https://cryptologos.cc/logos/aptos-apt-logo.png?v=013",
    "ARB":   "https://cryptologos.cc/logos/arbitrum-arb-logo.png?v=013",
    "FIL":   "https://cryptologos.cc/logos/filecoin-fil-logo.png?v=013",
    "QNT":   "https://cryptologos.cc/logos/quant-network-qnt-logo.png?v=013",
    "NEAR":  "https://cryptologos.cc/logos/near-protocol-near-logo.png?v=013",
    "APE":   "https://cryptologos.cc/logos/apecoin-ape-logo.png?v=013",
    "ALGO":  "https://cryptologos.cc/logos/algo-algorand-logo.png?v=013",
    "VET":   "https://cryptologos.cc/logos/vechain-vet-logo.png?v=013",
    "PEPE":  "https://cryptologos.cc/logos/pepe-pepe-logo.png?v=013",
    "BUSD":  "https://cryptologos.cc/logos/binance-usd-busd-logo.png?v=013",

    // Potential new coins from user screenshots
    "SUI":   "https://cryptologos.cc/logos/sui-sui-logo.png?v=013",
    "BGB":   "https://cryptologos.cc/logos/bitget-bitget-logo.png?v=013",
    "PI":    "https://cryptologos.cc/logos/pi-network-pi-logo.png?v=013",
    "USDS":  "https://cryptologos.cc/logos/usd-stablecoin-usds-logo.png?v=013"
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
        var allCoins: [CoinGeckoMarketData] = []
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: sessionConfig)
        
        for page in 1...3 {
            let urlString = """
                https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd\
                &order=market_cap_desc&per_page=100&page=\(page)&sparkline=true\
                &price_change_percentage=1h,24h
                """
            guard let url = URL(string: urlString) else { throw URLError(.badURL) }
            
            let data = try await withTimeout(seconds: 15) {
                let (d, response) = try await session.data(from: url)
                if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                return d
            }
            
            let decoded = try JSONDecoder().decode([CoinGeckoMarketData].self, from: data)
            allCoins.append(contentsOf: decoded)
        }
        
        return .success(allCoins)
    }
    
    private func fetchCoinPaprika() async throws -> CoinFetchResult {
        let urlString = "https://api.coinpaprika.com/v1/tickers?quotes=USD&limit=100"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: sessionConfig)
        
        let (data, response) = try await session.data(from: url)
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
                MarketCacheManager.shared.saveCoinsToDisk(rawCoins)
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
                throw URLError(.cannotConnectToHost)
            }
        } catch {
            do {
                let fallbackResult = try await fetchCoinPaprika()
                switch fallbackResult {
                case .fallbackSuccess(let papCoins):
                    var updated: [MarketCoin] = []
                    for pap in papCoins {
                        let price    = pap.quotes?["USD"]?.price ?? 0
                        let vol      = pap.quotes?["USD"]?.volume_24h ?? 0
                        let change24 = pap.quotes?["USD"]?.percent_change_24h ?? 0
                        let change1h = pap.quotes?["USD"]?.percent_change_1h ?? 0
                        
                        if let existingCoin = self.coins.first(where: { $0.symbol.uppercased() == pap.symbol.uppercased() }) {
                            let newCoin = MarketCoin(
                                symbol: existingCoin.symbol,
                                name: pap.name,
                                price: price,
                                dailyChange: change24,
                                hourlyChange: change1h,
                                volume: vol,
                                sparklineData: existingCoin.sparklineData,
                                imageUrl: existingCoin.imageUrl,
                                isFavorite: existingCoin.isFavorite
                            )
                            updated.append(newCoin)
                        } else {
                            let newCoin = MarketCoin(
                                symbol: pap.symbol.uppercased(),
                                name: pap.name,
                                price: price,
                                dailyChange: change24,
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
                    // Since fallback succeeded, clear the error.
                    coinError = nil
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
        guard let url = URL(string: urlString) else { return .failure(URLError(.badURL)) }
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: sessionConfig)
        
        let (data, response) = try await session.data(from: url)
        if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
            return .failure(URLError(.badServerResponse))
        }
        
        let decoded = try JSONDecoder().decode(GlobalMarketDataResponse.self, from: data)
        return .success(decoded.data)
    }
    
    private func fetchGlobalPaprika() async throws -> GlobalMarketData {
        let urlString = "https://api.coinpaprika.com/v1/global"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: sessionConfig)
        
        let (data, response) = try await session.data(from: url)
        if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(GlobalMarketData.self, from: data)
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
                imageUrl: "https://cryptologos.cc/logos/bitcoin-btc-logo.png?v=013"
            ),
            MarketCoin(
                symbol: "ETH",
                name: "Ethereum",
                price: 1800,
                dailyChange: 3.44,
                hourlyChange: 0.50,
                volume: 210_000_000,
                sparklineData: [1790, 1795, 1802, 1808, 1805, 1810, 1807],
                imageUrl: "https://cryptologos.cc/logos/ethereum-eth-logo.png?v=013"
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
        coinRefreshTask = Task.detached { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                await self.fetchMarketDataMulti()
            }
        }
        
        globalRefreshTask = Task.detached { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 180_000_000_000)
                await self.fetchGlobalMarketDataMulti()
            }
        }
    }
    
    // MARK: - Example: Live Prices from Coinbase/Binance (Optional)
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
        .refreshable {
            await vm.fetchMarketDataMulti()
            await vm.fetchGlobalMarketDataMulti()
        }
    }
    
    private func coinRow(_ coin: MarketCoin) -> some View {
        HStack(spacing: 0) {
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
            if #available(iOS 16, *) {
                ZStack {
                    Rectangle().fill(Color.clear).frame(width: 50, height: 30)
                    sparkline(coin.sparklineData, dailyChange: coin.dailyChange)
                }
            } else {
                Spacer().frame(width: 50)
            }
            Text(String(format: "$%.2f", coin.price))
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: priceWidth, alignment: .trailing)
                .lineLimit(1)
            Text(String(format: "%.2f%%", coin.dailyChange))
                .font(.caption)
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
                .frame(width: dailyWidth, alignment: .trailing)
                .lineLimit(1)
            Text(shortVolume(coin.volume))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: volumeWidth, alignment: .trailing)
                .lineLimit(1)
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

private func coinImageView(symbol: String, urlStr: String?) -> some View {
    Group {
        if let ccURLStr = cryptoCompareLogos[symbol.uppercased()],
           let ccURL = URL(string: ccURLStr) {
            AsyncImage(url: ccURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit().frame(width: 32, height: 32).clipShape(Circle())
                case .failure(_):
                    geckoOrLocalOrSF(symbol: symbol, geckoUrl: urlStr)
                case .empty:
                    ProgressView().frame(width: 32, height: 32)
                @unknown default:
                    geckoOrLocalOrSF(symbol: symbol, geckoUrl: urlStr)
                }
            }
        } else {
            geckoOrLocalOrSF(symbol: symbol, geckoUrl: urlStr)
        }
    }
}

private func geckoOrLocalOrSF(symbol: String, geckoUrl: String?) -> some View {
    Group {
        if let geckoUrl = geckoUrl, let mainURL = URL(string: geckoUrl) {
            AsyncImage(url: mainURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit().frame(width: 32, height: 32).clipShape(Circle())
                case .failure(_):
                    localOrSF(symbol: symbol)
                case .empty:
                    ProgressView().frame(width: 32, height: 32)
                @unknown default:
                    localOrSF(symbol: symbol)
                }
            }
        } else {
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

/// Helper for explicit async timeouts.
func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            return try await operation()
        }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw URLError(.timedOut)
        }
        guard let result = try await group.next() else {
            throw URLError(.timedOut)
        }
        group.cancelAll()
        return result
    }
}
