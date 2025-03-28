// MarketView.swift

import SwiftUI
import Charts

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

class MarketViewModel: ObservableObject {
    @Published var coins: [MarketCoin] = []
    @Published var filteredCoins: [MarketCoin] = []
    
    @Published var selectedSegment: MarketSegment = .all
    @Published var showSearchBar: Bool = false
    @Published var searchText: String = ""
    
    @Published var sortField: SortField = .none
    @Published var sortDirection: SortDirection = .asc
    
    private let favoritesKey = "favoriteCoinSymbols"
    
    init() {
        loadFallbackCoins()
        applyAllFiltersAndSort()
        fetchLivePricesFromCoinbase()
    }
    
    private func loadFallbackCoins() {
        // The following list includes 50 sample fallback coins.
        // Prices, dailyChange, volume, and sparklineData values are dummy values.
        coins = [
            MarketCoin(symbol: "BTC", name: "Bitcoin", price: 28000, dailyChange: -2.15, volume: 450_000_000,
                       sparklineData: [28000, 27950, 27980, 27890, 27850, 27820, 27800],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/btc.png"),
            MarketCoin(symbol: "ETH", name: "Ethereum", price: 1800, dailyChange: 3.44, volume: 210_000_000,
                       sparklineData: [1790, 1795, 1802, 1808, 1805, 1810, 1807],
                       imageUrl: "https://www.cryptocompare.com/media/37746238/eth.png"),
            MarketCoin(symbol: "USDT", name: "Tether", price: 1.0, dailyChange: 0.0, volume: 300_000_000,
                       sparklineData: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
                       imageUrl: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0xdAC17F958D2ee523a2206206994597C13D831ec7/logo.png"),
            MarketCoin(symbol: "BNB", name: "Binance Coin", price: 320, dailyChange: 1.25, volume: 150_000_000,
                       sparklineData: [315, 317, 319, 321, 322, 320, 318],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/bnb.png"),
            MarketCoin(symbol: "ADA", name: "Cardano", price: 0.95, dailyChange: 2.05, volume: 200_000_000,
                       sparklineData: [0.92, 0.93, 0.94, 0.95, 0.96, 0.95, 0.94],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/ada.png"),
            MarketCoin(symbol: "SOL", name: "Solana", price: 35, dailyChange: -1.50, volume: 120_000_000,
                       sparklineData: [36, 35.5, 35.2, 35, 34.8, 34.9, 35],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/sol.png"),
            MarketCoin(symbol: "XRP", name: "Ripple", price: 0.65, dailyChange: 0.80, volume: 100_000_000,
                       sparklineData: [0.64, 0.65, 0.66, 0.65, 0.64, 0.65, 0.66],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/xrp.png"),
            MarketCoin(symbol: "DOT", name: "Polkadot", price: 6.5, dailyChange: 1.10, volume: 80_000_000,
                       sparklineData: [6.4, 6.45, 6.5, 6.55, 6.5, 6.48, 6.5],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/dot.png"),
            MarketCoin(symbol: "DOGE", name: "Dogecoin", price: 0.07, dailyChange: -0.50, volume: 90_000_000,
                       sparklineData: [0.071, 0.07, 0.069, 0.07, 0.07, 0.069, 0.07],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/doge.png"),
            MarketCoin(symbol: "LTC", name: "Litecoin", price: 90, dailyChange: 0.95, volume: 60_000_000,
                       sparklineData: [89, 89.5, 90, 90.5, 90, 89.8, 90],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/ltc.png"),
            MarketCoin(symbol: "TRX", name: "TRON", price: 0.08, dailyChange: 1.20, volume: 70_000_000,
                       sparklineData: [0.079, 0.08, 0.081, 0.08, 0.08, 0.079, 0.08],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/trx.png"),
            MarketCoin(symbol: "SHIB", name: "Shiba Inu", price: 0.000012, dailyChange: 5.0, volume: 50_000_000,
                       sparklineData: [0.000011, 0.000012, 0.0000125, 0.000012, 0.0000118, 0.000012, 0.000012],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/shib.png"),
            MarketCoin(symbol: "MATIC", name: "Polygon", price: 1.2, dailyChange: 2.5, volume: 110_000_000,
                       sparklineData: [1.15, 1.18, 1.2, 1.22, 1.21, 1.2, 1.19],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/matic.png"),
            MarketCoin(symbol: "AVAX", name: "Avalanche", price: 20, dailyChange: -0.75, volume: 95_000_000,
                       sparklineData: [20.2, 20.1, 20, 19.9, 20, 20.1, 20],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/avax.png"),
            MarketCoin(symbol: "LINK", name: "Chainlink", price: 7.5, dailyChange: 1.80, volume: 85_000_000,
                       sparklineData: [7.4, 7.45, 7.5, 7.55, 7.5, 7.48, 7.5],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/link.png"),
            MarketCoin(symbol: "UNI", name: "Uniswap", price: 5.2, dailyChange: -1.10, volume: 65_000_000,
                       sparklineData: [5.1, 5.15, 5.2, 5.25, 5.2, 5.18, 5.2],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/uni.png"),
            MarketCoin(symbol: "ATOM", name: "Cosmos", price: 12, dailyChange: 0.50, volume: 55_000_000,
                       sparklineData: [11.8, 11.9, 12, 12.1, 12, 11.95, 12],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/atom.png"),
            MarketCoin(symbol: "XLM", name: "Stellar", price: 0.35, dailyChange: 0.25, volume: 45_000_000,
                       sparklineData: [0.34, 0.345, 0.35, 0.355, 0.35, 0.348, 0.35],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/xlm.png"),
            MarketCoin(symbol: "ALGO", name: "Algorand", price: 0.90, dailyChange: -0.80, volume: 40_000_000,
                       sparklineData: [0.89, 0.90, 0.91, 0.90, 0.89, 0.90, 0.90],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/algo.png"),
            MarketCoin(symbol: "ICP", name: "Internet Computer", price: 40, dailyChange: 2.00, volume: 35_000_000,
                       sparklineData: [39, 39.5, 40, 40.5, 40, 39.8, 40],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/icp.png"),
            MarketCoin(symbol: "VET", name: "VeChain", price: 0.10, dailyChange: 1.50, volume: 30_000_000,
                       sparklineData: [0.099, 0.10, 0.101, 0.10, 0.10, 0.099, 0.10],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/vet.png"),
            MarketCoin(symbol: "FTM", name: "Fantom", price: 0.50, dailyChange: 3.00, volume: 28_000_000,
                       sparklineData: [0.48, 0.49, 0.50, 0.51, 0.50, 0.50, 0.50],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/ftm.png"),
            MarketCoin(symbol: "XMR", name: "Monero", price: 160, dailyChange: -1.20, volume: 26_000_000,
                       sparklineData: [159, 159.5, 160, 160.2, 160, 159.8, 160],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/xmr.png"),
            MarketCoin(symbol: "AXS", name: "Axie Infinity", price: 70, dailyChange: 4.50, volume: 24_000_000,
                       sparklineData: [68, 69, 70, 71, 70, 70, 70],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/axs.png"),
            MarketCoin(symbol: "EGLD", name: "Elrond", price: 100, dailyChange: -2.00, volume: 22_000_000,
                       sparklineData: [102, 101, 100, 99, 100, 100, 100],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/egld.png"),
            MarketCoin(symbol: "FTT", name: "FTX Token", price: 40, dailyChange: 0.80, volume: 20_000_000,
                       sparklineData: [39, 39.5, 40, 40.2, 40, 40, 40],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/ftt.png"),
            MarketCoin(symbol: "NEAR", name: "NEAR Protocol", price: 3.5, dailyChange: 1.10, volume: 19_000_000,
                       sparklineData: [3.4, 3.45, 3.5, 3.55, 3.5, 3.5, 3.5],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/near.png"),
            MarketCoin(symbol: "EOS", name: "EOS", price: 2.8, dailyChange: -0.90, volume: 18_000_000,
                       sparklineData: [2.7, 2.75, 2.8, 2.85, 2.8, 2.78, 2.8],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/eos.png"),
            MarketCoin(symbol: "HBAR", name: "Hedera", price: 0.25, dailyChange: 1.00, volume: 17_000_000,
                       sparklineData: [0.24, 0.245, 0.25, 0.255, 0.25, 0.25, 0.25],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/hbar.png"),
            MarketCoin(symbol: "MKR", name: "Maker", price: 2500, dailyChange: 0.50, volume: 15_000_000,
                       sparklineData: [2490, 2495, 2500, 2505, 2500, 2500, 2500],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/mkr.png"),
            MarketCoin(symbol: "BAT", name: "Basic Attention Token", price: 0.75, dailyChange: 1.80, volume: 14_000_000,
                       sparklineData: [0.73, 0.74, 0.75, 0.76, 0.75, 0.75, 0.75],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/bat.png"),
            MarketCoin(symbol: "ZEC", name: "Zcash", price: 120, dailyChange: -1.10, volume: 13_000_000,
                       sparklineData: [119, 119.5, 120, 120.2, 120, 119.8, 120],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/zec.png"),
            MarketCoin(symbol: "DASH", name: "Dash", price: 180, dailyChange: 0.75, volume: 12_000_000,
                       sparklineData: [179, 179.5, 180, 180.5, 180, 180, 180],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/dash.png"),
            MarketCoin(symbol: "SUSHI", name: "SushiSwap", price: 3.2, dailyChange: 2.00, volume: 11_000_000,
                       sparklineData: [3.1, 3.15, 3.2, 3.25, 3.2, 3.2, 3.2],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/sushi.png"),
            MarketCoin(symbol: "COMP", name: "Compound", price: 120, dailyChange: -0.50, volume: 10_000_000,
                       sparklineData: [119, 119.5, 120, 120.2, 120, 120, 120],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/comp.png"),
            MarketCoin(symbol: "YFI", name: "Yearn Finance", price: 23000, dailyChange: 0.85, volume: 9_000_000,
                       sparklineData: [22900, 22950, 23000, 23050, 23000, 23000, 23000],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/yfi.png"),
            MarketCoin(symbol: "SNX", name: "Synthetix", price: 10, dailyChange: 1.20, volume: 8_500_000,
                       sparklineData: [9.8, 9.9, 10, 10.1, 10, 10, 10],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/snx.png"),
            MarketCoin(symbol: "REN", name: "Ren", price: 0.45, dailyChange: 2.50, volume: 8_000_000,
                       sparklineData: [0.44, 0.445, 0.45, 0.455, 0.45, 0.45, 0.45],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/ren.png"),
            MarketCoin(symbol: "ENJ", name: "Enjin Coin", price: 0.30, dailyChange: 1.75, volume: 7_500_000,
                       sparklineData: [0.29, 0.295, 0.30, 0.305, 0.30, 0.30, 0.30],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/enj.png"),
            MarketCoin(symbol: "CRO", name: "Cronos", price: 0.08, dailyChange: -0.95, volume: 7_000_000,
                       sparklineData: [0.079, 0.08, 0.081, 0.08, 0.08, 0.079, 0.08],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/cro.png"),
            MarketCoin(symbol: "STX", name: "Stacks", price: 1.8, dailyChange: 0.65, volume: 6_500_000,
                       sparklineData: [1.75, 1.77, 1.8, 1.83, 1.8, 1.8, 1.8],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/stx.png"),
            MarketCoin(symbol: "KSM", name: "Kusama", price: 150, dailyChange: 1.10, volume: 6_000_000,
                       sparklineData: [148, 149, 150, 151, 150, 150, 150],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/ksm.png"),
            MarketCoin(symbol: "RUNE", name: "THORChain", price: 3.2, dailyChange: 2.20, volume: 5_500_000,
                       sparklineData: [3.1, 3.15, 3.2, 3.25, 3.2, 3.2, 3.2],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/rune.png"),
            MarketCoin(symbol: "GRT", name: "The Graph", price: 0.75, dailyChange: 1.30, volume: 5_000_000,
                       sparklineData: [0.74, 0.745, 0.75, 0.755, 0.75, 0.75, 0.75],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/grt.png"),
            MarketCoin(symbol: "SAND", name: "Sandbox", price: 0.45, dailyChange: 2.80, volume: 4_800_000,
                       sparklineData: [0.44, 0.445, 0.45, 0.455, 0.45, 0.45, 0.45],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/sand.png"),
            MarketCoin(symbol: "FLOW", name: "Flow", price: 2.0, dailyChange: 1.50, volume: 4_500_000,
                       sparklineData: [1.95, 1.98, 2.0, 2.02, 2.0, 2.0, 2.0],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/flow.png"),
            MarketCoin(symbol: "NEO", name: "Neo", price: 10, dailyChange: -1.20, volume: 4_200_000,
                       sparklineData: [9.8, 9.9, 10, 10.1, 10, 10, 10],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/neo.png"),
            MarketCoin(symbol: "QTUM", name: "Qtum", price: 7.0, dailyChange: 0.85, volume: 4_000_000,
                       sparklineData: [6.9, 6.95, 7.0, 7.05, 7.0, 7.0, 7.0],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/qtum.png"),
            MarketCoin(symbol: "CEL", name: "Celsius", price: 0.30, dailyChange: 1.10, volume: 3_800_000,
                       sparklineData: [0.29, 0.295, 0.30, 0.305, 0.30, 0.30, 0.30],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/cel.png"),
            MarketCoin(symbol: "OMG", name: "OMG Network", price: 1.5, dailyChange: -0.95, volume: 3_600_000,
                       sparklineData: [1.48, 1.49, 1.5, 1.51, 1.5, 1.5, 1.5],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/omg.png"),
            MarketCoin(symbol: "HOT", name: "Holo", price: 0.005, dailyChange: 3.00, volume: 3_400_000,
                       sparklineData: [0.0048, 0.0049, 0.005, 0.0051, 0.005, 0.005, 0.005],
                       imageUrl: "https://www.cryptocompare.com/media/37746251/hot.png")
        ]
        loadFavorites()
    }
    
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
    
    func updateSegment(_ seg: MarketSegment) {
        selectedSegment = seg
        applyAllFiltersAndSort()
    }
    
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
    
    // MARK: - Live Data
    func fetchLivePricesFromCoinbase() {
        let coinbaseService = CoinbaseService()
        for (index, coin) in coins.enumerated() {
            coinbaseService.fetchSpotPrice(coin: coin.symbol, fiat: "USD") { newPrice in
                DispatchQueue.main.async {
                    if let newPrice = newPrice {
                        self.coins[index].price = newPrice
                    }
                    self.fetchSparklineData(symbol: coin.symbol) { newSparkline in
                        DispatchQueue.main.async {
                            if !newSparkline.isEmpty {
                                self.coins[index].sparklineData = newSparkline
                            }
                            self.applyAllFiltersAndSort()
                        }
                    }
                }
            }
        }
    }
    
    private func fetchSparklineData(symbol: String, completion: @escaping ([Double]) -> Void) {
        let pair = symbol.uppercased() + "USDT"
        let urlString = "https://api.binance.com/api/v3/klines?symbol=\(pair)&interval=1d&limit=7"
        
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil, let data = data else {
                completion([])
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [[Any]] {
                    let closes = json.map { arr -> Double in
                        Double(arr[4] as? String ?? "0") ?? 0
                    }
                    completion(closes)
                } else {
                    completion([])
                }
            } catch {
                completion([])
            }
        }.resume()
    }
}

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
                    segmentRow
                    if vm.showSearchBar { searchBar }
                    columnHeader
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
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        vm.fetchLivePricesFromCoinbase()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var topBar: some View {
        HStack {
            Text("Market")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Spacer()
            Button {
                withAnimation {
                    vm.showSearchBar.toggle()
                }
            } label: {
                Image(systemName: vm.showSearchBar ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
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
    
    private func coinRow(_ coin: MarketCoin) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                if let urlStr = coin.imageUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                                 .scaledToFit()
                                 .frame(width: 32, height: 32)
                                 .clipShape(Circle())
                        case .failure(_):
                            Circle()
                                .fill(Color.gray.opacity(0.6))
                                .frame(width: 32, height: 32)
                        case .empty:
                            ProgressView()
                                .frame(width: 32, height: 32)
                        @unknown default:
                            Circle()
                                .fill(Color.gray.opacity(0.6))
                                .frame(width: 32, height: 32)
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 32, height: 32)
                }
                
                VStack(alignment: .leading, spacing: 2) {
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
            .frame(width: 140, alignment: .leading)
            
            if #available(iOS 16, *) {
                ZStack {
                    Rectangle().fill(Color.clear)
                              .frame(width: 50, height: 30)
                    sparkline(coin.sparklineData, dailyChange: coin.dailyChange)
                }
            } else {
                Spacer().frame(width: 50)
            }
            
            Text(String(format: "$%.2f", coin.price))
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: 70, alignment: .trailing)
                .lineLimit(1)
            
            Text(String(format: "%.2f%%", coin.dailyChange))
                .font(.caption)
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
                .frame(width: 50, alignment: .trailing)
                .lineLimit(1)
            
            Text(shortVolume(coin.volume))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 70, alignment: .trailing)
                .lineLimit(1)
            
            Button {
                vm.toggleFavorite(coin)
            } label: {
                Image(systemName: coin.isFavorite ? "star.fill" : "star")
                    .foregroundColor(coin.isFavorite ? .yellow : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 40, alignment: .center)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }
    
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
    
    private func shortVolume(_ vol: Double) -> String {
        switch vol {
        case 1_000_000_000...:
            return String(format: "%.1fB", vol / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%.1fM", vol / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", vol / 1_000)
        default:
            return String(format: "%.0f", vol)
        }
    }
}

struct MarketView_Previews: PreviewProvider {
    static var previews: some View {
        MarketView()
            .environmentObject(MarketViewModel())
    }
}
