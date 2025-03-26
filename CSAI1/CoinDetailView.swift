//
//  CoinDetailView.swift
//  CSAI1
//
//  Cleaned-up version with no duplicate CoinDetailTradingViewWebView
//

import SwiftUI
import Charts
import WebKit

// MARK: - ChartInterval
enum ChartInterval: String, CaseIterable {
    case oneMin     = "1m"
    case fiveMin    = "5m"
    case fifteenMin = "15m"
    case thirtyMin  = "30m"
    case oneHour    = "1H"
    case fourHour   = "4H"
    case oneDay     = "1D"
    case oneWeek    = "1W"
    case oneMonth   = "1M"
    case threeMonth = "3M"
    case oneYear    = "1Y"
    case threeYear  = "3Y"
    case all        = "ALL"
    
    var binanceInterval: String {
        switch self {
        case .oneMin:     return "1m"
        case .fiveMin:    return "5m"
        case .fifteenMin: return "15m"
        case .thirtyMin:  return "30m"
        case .oneHour:    return "1h"
        case .fourHour:   return "4h"
        case .oneDay:     return "1d"
        case .oneWeek:    return "1w"
        case .oneMonth:   return "1M"
        case .threeMonth: return "1d"
        case .oneYear:    return "1d"
        case .threeYear:  return "1d"
        case .all:        return "1w"
        }
    }
    
    var binanceLimit: Int {
        switch self {
        case .oneMin:     return 60
        case .fiveMin:    return 48
        case .fifteenMin: return 24
        case .thirtyMin:  return 24
        case .oneHour:    return 48
        case .fourHour:   return 120   // Bumped up from 84
        case .oneDay:     return 60
        case .oneWeek:    return 52
        case .oneMonth:   return 12
        case .threeMonth: return 90
        case .oneYear:    return 365
        case .threeYear:  return 1095
        case .all:        return 999
        }
    }
    
    // For TradingView
    var tvValue: String {
        switch self {
        case .oneMin:     return "1"
        case .fiveMin:    return "5"
        case .fifteenMin: return "15"
        case .thirtyMin:  return "30"
        case .oneHour:    return "60"
        case .fourHour:   return "240"
        case .oneDay:     return "D"
        case .oneWeek:    return "W"
        case .oneMonth:   return "M"
        case .threeMonth: return "D"
        case .oneYear:    return "D"
        case .threeYear:  return "D"
        case .all:        return "W"
        }
    }
    
    // Hide crosshair time for these intervals
    var hideCrosshairTime: Bool {
        switch self {
        case .oneWeek, .oneMonth, .threeMonth, .oneYear, .threeYear, .all:
            return true
        default:
            return false
        }
    }
}

// MARK: - ChartType
enum ChartType: String, CaseIterable {
    case cryptoSageAI = "CryptoSage AI"
    case tradingView  = "TradingView"
}

// MARK: - CoinDetailView
struct CoinDetailView: View {
    let coin: MarketCoin
    
    @State private var selectedChartType: ChartType = .cryptoSageAI
    @State private var selectedInterval: ChartInterval = .oneDay
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    // Stats from CoinPaprika (fallback -> CoinGecko -> placeholders)
    @StateObject private var statsVM = CoinPaprikaStatsViewModel()
    
    var body: some View {
        ZStack {
            // Use your theme's background so that Theme.swift controls the background
            FuturisticBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Nav Bar
                    navBar
                    
                    // Chart
                    chartSection
                    
                    // Interval Row
                    intervalRow
                    
                    // Chart Type Toggle
                    chartTypeToggle
                    
                    // Coin Stats
                    CoinPaprikaStatsView(coinSymbol: coin.symbol, vm: statsVM)
                }
                .padding()
                .padding(.bottom, 100)
            }
            .refreshable {
                statsVM.fetchCoinPaprikaStats(coinSymbol: coin.symbol)
            }
            
            // “Trade” Button pinned at bottom
            VStack {
                Spacer()
                tradeButton
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            statsVM.fetchCoinPaprikaStats(coinSymbol: coin.symbol)
        }
    }
    
    // MARK: - Nav Bar
    private var navBar: some View {
        ZStack {
            // Left: Back button
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.yellow)
                        Text("Back")
                            .foregroundColor(.yellow)
                    }
                }
                Spacer()
            }
            
            // Center: Icon + symbol + price
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    if let uiImage = UIImage(named: coin.symbol.lowercased()) {
                        HStack(spacing: 6) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                            Text(coin.symbol.uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    } else {
                        Text(coin.symbol.uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text(formatPrice(coin.price))
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.yellow)
                }
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        Group {
            if selectedChartType == .cryptoSageAI {
                CoinDetailCustomChart(symbol: coin.symbol, interval: selectedInterval)
                    .frame(height: 330)
                    .padding(.vertical, 8)
            } else {
                let tvSymbol = "BINANCE:\(coin.symbol.uppercased())USDT"
                let tvTheme = (colorScheme == .dark) ? "Dark" : "Light"
                CoinDetailTradingViewWebView(symbol: tvSymbol,
                                             interval: selectedInterval.tvValue,
                                             theme: tvTheme)
                    .frame(height: 330)
                    .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Interval Row
    private var intervalRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChartInterval.allCases, id: \.self) { interval in
                    Button {
                        selectedInterval = interval
                    } label: {
                        Text(interval.rawValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedInterval == interval
                                          ? .yellow
                                          : Color.white.opacity(0.15))
                            )
                            .foregroundColor(selectedInterval == interval ? .black : .white)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Chart Type Toggle
    private var chartTypeToggle: some View {
        HStack(spacing: 0) {
            ForEach(ChartType.allCases, id: \.self) { type in
                Button {
                    selectedChartType = type
                } label: {
                    Text(type.rawValue)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedChartType == type ? .black : .white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedChartType == type
                            ? .yellow
                            : Color.white.opacity(0.15)
                        )
                }
            }
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Trade Button
    private var tradeButton: some View {
        Button(action: {
            // Insert your trade action here
        }) {
            Text("Trade \(coin.symbol.uppercased())")
                .font(.headline)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.yellow)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .background(Color.black.opacity(0.8))
        .shadow(color: Color.black.opacity(0.6), radius: 10, x: 0, y: -3)
    }
    
    // MARK: - Price Formatter
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

// MARK: - CoinDetailCustomChart
struct CoinDetailCustomChart: View {
    let symbol: String
    let interval: ChartInterval
    
    @StateObject private var vm = CoinDetailChartViewModel()
    @State private var crosshairValue: ChartDataPoint? = nil
    @State private var showCrosshair: Bool = false
    
    var body: some View {
        VStack {
            if vm.isLoading {
                ProgressView("Loading chart...")
                    .foregroundColor(.white)
            } else {
                if #available(iOS 16, *) {
                    if let errorMsg = vm.errorMessage {
                        errorView(errorMsg)
                    } else if vm.dataPoints.isEmpty {
                        Text("No chart data")
                            .foregroundColor(.gray)
                    } else {
                        chartContent
                    }
                } else {
                    Text("iOS 16+ required for Swift Charts")
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            vm.fetchBinanceData(symbol: symbol,
                                interval: interval.binanceInterval,
                                limit: interval.binanceLimit)
        }
        .onChange(of: interval) { _, newVal in
            vm.fetchBinanceData(symbol: symbol,
                                interval: newVal.binanceInterval,
                                limit: newVal.binanceLimit)
        }
    }
    
    // MARK: - Chart Content
    @ViewBuilder
    @available(iOS 16.0, *)
    private var chartContent: some View {
        let minClose = vm.dataPoints.map { $0.close }.min() ?? 0
        let maxClose = vm.dataPoints.map { $0.close }.max() ?? 1
        
        let topMargin = (maxClose - minClose) * 0.03
        let clampedLowerBound = max(0, minClose)
        let upperBound = maxClose + topMargin
        
        let firstDate = vm.dataPoints.first?.date ?? Date()
        let lastDate  = vm.dataPoints.last?.date ?? Date()
        
        let axisLabelCount: Int = {
            switch interval {
            case .oneMin, .fiveMin, .fifteenMin, .thirtyMin, .oneHour, .fourHour:
                return 6
            case .oneYear, .threeYear, .all:
                return 3
            default:
                return 4
            }
        }()
        
        Chart {
            ForEach(vm.dataPoints) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Close", point.close)
                )
                .foregroundStyle(.yellow)
                
                AreaMark(
                    x: .value("Time", point.date),
                    yStart: .value("Close", clampedLowerBound),
                    yEnd: .value("Close", point.close)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .yellow.opacity(0.3),
                            .yellow.opacity(0.15),
                            .yellow.opacity(0.05),
                            .clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            if showCrosshair, let cVal = crosshairValue {
                RuleMark(x: .value("Crosshair Time", cVal.date))
                    .foregroundStyle(.white.opacity(0.7))
                
                PointMark(
                    x: .value("Time", cVal.date),
                    y: .value("Close", cVal.close)
                )
                .symbolSize(80)
                .foregroundStyle(.white)
                .annotation(position: .top) {
                    VStack(spacing: 2) {
                        if interval.hideCrosshairTime {
                            Text(cVal.date, format: .dateTime.month(.abbreviated).year())
                                .font(.caption2)
                                .foregroundColor(.white)
                        } else {
                            switch interval {
                            case .oneMin, .fiveMin:
                                Text(formatTimeLocalHM(cVal.date))
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            case .fifteenMin, .thirtyMin, .oneHour, .fourHour:
                                Text(formatTimeLocal(cVal.date))
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            case .oneDay, .oneWeek, .oneMonth, .threeMonth:
                                Text(cVal.date, format: .dateTime.month(.abbreviated).day(.twoDigits))
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            default:
                                Text(cVal.date, format: .dateTime.month(.abbreviated).year())
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text(formatWithCommas(cVal.close))
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    .padding(6)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(6)
                }
            }
        }
        .chartYScale(domain: clampedLowerBound...upperBound)
        .chartXScale(domain: firstDate...lastDate)
        .chartXScale(range: 0.05...0.95)
        .chartPlotStyle { plotArea in
            plotArea
                .background(Color.black.opacity(0.05))
                .padding(.bottom, 40)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: axisLabelCount)) { value in
                AxisGridLine()
                    .foregroundStyle(.white.opacity(0.2))
                
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatAxisDate(date))
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine()
                    .foregroundStyle(.white.opacity(0.2))
                
                AxisValueLabel()
                    .foregroundStyle(.white)
                    .font(.footnote)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(Color.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                showCrosshair = true
                                let location = drag.location
                                
                                if #available(iOS 17.0, *) {
                                    if let anchor = proxy.plotFrame {
                                        let origin = geo[anchor].origin
                                        let relativeX = location.x - origin.x
                                        if let date: Date = proxy.value(atX: relativeX),
                                           let closest = findClosest(date: date, in: vm.dataPoints) {
                                            crosshairValue = closest
                                        }
                                    }
                                } else {
                                    let origin = geo[proxy.plotAreaFrame].origin
                                    let relativeX = location.x - origin.x
                                    if let date: Date = proxy.value(atX: relativeX),
                                       let closest = findClosest(date: date, in: vm.dataPoints) {
                                        crosshairValue = closest
                                    }
                                }
                            }
                            .onEnded { _ in
                                showCrosshair = false
                            }
                    )
            }
        }
        .overlay(
            LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.5)]),
                           startPoint: .top,
                           endPoint: .bottom)
                .frame(height: 40)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)
        )
    }
    
    private func errorView(_ errorMsg: String) -> some View {
        VStack(spacing: 10) {
            Text("Error loading chart")
                .foregroundColor(.red)
                .font(.headline)
            Text(errorMsg)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                vm.fetchBinanceData(symbol: symbol,
                                    interval: interval.binanceInterval,
                                    limit: interval.binanceLimit)
            }
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.yellow)
            .cornerRadius(8)
        }
        .padding()
    }
    
    private func formatAxisDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        
        switch interval {
        case .oneMin, .fiveMin:
            df.dateFormat = "h:mm a"
        case .fifteenMin, .thirtyMin, .oneHour, .fourHour:
            df.dateFormat = "ha"
        case .oneDay, .oneWeek, .oneMonth, .threeMonth:
            let day = Calendar.current.component(.day, from: date)
            df.dateFormat = (day == 1) ? "MMM" : "MMM d"
        default:
            df.dateFormat = "MMM yyyy"
        }
        return df.string(from: date)
    }
    
    private func formatTimeLocalHM(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateFormat = "h:mm a"
        return df.string(from: date)
    }
    
    private func formatTimeLocal(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateFormat = "ha"
        return df.string(from: date)
    }
    
    private func findClosest(date: Date, in points: [ChartDataPoint]) -> ChartDataPoint? {
        guard !points.isEmpty else { return nil }
        let sorted = points.sorted { $0.date < $1.date }
        if date <= sorted.first!.date { return sorted.first! }
        if date >= sorted.last!.date { return sorted.last! }
        
        var closest = sorted.first!
        var minDiff = abs(closest.date.timeIntervalSince(date))
        for point in sorted {
            let diff = abs(point.date.timeIntervalSince(date))
            if diff < minDiff {
                minDiff = diff
                closest = point
            }
        }
        return closest
    }
    
    private func formatWithCommas(_ value: Double) -> String {
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

// MARK: - ChartDataPoint
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let close: Double
}

// MARK: - CoinDetailChartViewModel
class CoinDetailChartViewModel: ObservableObject {
    @Published var dataPoints: [ChartDataPoint] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 10
        return URLSession(configuration: config)
    }()
    
    func fetchBinanceData(symbol: String, interval: String, limit: Int) {
        let pair = symbol.uppercased() + "USDT"
        let urlString = "https://api.binance.com/api/v3/klines?symbol=\(pair)&interval=\(interval)&limit=\(limit)"
        DispatchQueue.main.async {
            self.isLoading = true
            self.dataPoints = []
            self.errorMessage = nil
        }
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Invalid URL string."
            }
            return
        }
        
        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 451 {
                    self.fetchBinanceUSData(pair: pair, interval: interval, limit: limit)
                    return
                } else if httpResponse.statusCode == 400 {
                    if let data = data,
                       let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let msg = body["msg"] as? String,
                       msg.contains("Invalid interval") {
                        self.fetchBinanceData(symbol: symbol, interval: "1M", limit: 12)
                        return
                    }
                } else if httpResponse.statusCode != 200 {
                    let errorBody = String(data: data ?? Data(), encoding: .utf8) ?? "N/A"
                    DispatchQueue.main.async {
                        self.errorMessage = "HTTP \(httpResponse.statusCode)\n\(errorBody)"
                    }
                    return
                }
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data from Binance."
                }
                return
            }
            self.parseKlinesJSON(data: data)
        }.resume()
    }
    
    private func fetchBinanceUSData(pair: String, interval: String, limit: Int) {
        let fallbackURL = "https://api.binance.us/api/v3/klines?symbol=\(pair)&interval=\(interval)&limit=\(limit)"
        DispatchQueue.main.async {
            self.isLoading = true
            self.dataPoints = []
            self.errorMessage = nil
        }
        
        guard let url = URL(string: fallbackURL) else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Invalid fallback URL."
            }
            return
        }
        
        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Fallback error: \(error.localizedDescription)"
                }
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorBody = String(data: data ?? Data(), encoding: .utf8) ?? "N/A"
                DispatchQueue.main.async {
                    self.errorMessage = "Fallback HTTP \(httpResponse.statusCode)\n\(errorBody)"
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data from Binance US."
                }
                return
            }
            self.parseKlinesJSON(data: data)
        }.resume()
    }
    
    private func parseKlinesJSON(data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [[Any]] {
                if json.isEmpty {
                    DispatchQueue.main.async {
                        self.errorMessage = "Empty array.\nInvalid symbol or no data."
                    }
                    return
                }
                var results: [ChartDataPoint] = []
                for kline in json {
                    if kline.count >= 5 {
                        guard let openTimeMs = kline[0] as? Double else { continue }
                        let date = Date(timeIntervalSince1970: openTimeMs / 1000.0)
                        
                        var closeVal: Double? = nil
                        if let dbl = kline[4] as? Double {
                            closeVal = dbl
                        } else if let str = kline[4] as? String, let dbl2 = Double(str) {
                            closeVal = dbl2
                        }
                        
                        if let close = closeVal {
                            results.append(ChartDataPoint(date: date, close: close))
                        }
                    }
                }
                results.sort { $0.date < $1.date }
                DispatchQueue.main.async {
                    self.dataPoints = results
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "JSON parse error: Expected an array of arrays."
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "JSON parse error: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - CoinDetailTradingViewWebView
struct CoinDetailTradingViewWebView: UIViewRepresentable {
    let symbol: String
    let interval: String
    let theme: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        loadHTML(into: webView)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        loadHTML(into: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    private func loadHTML(into webView: WKWebView) {
        let html = """
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              html, body { margin: 0; padding: 0; height: 100%; background: transparent; }
              #tv_chart_container { width:100%; height:100%; }
            </style>
          </head>
          <body>
            <div id="tv_chart_container"></div>
            <script src="https://www.tradingview.com/tv.js"></script>
            <script>
              try {
                new TradingView.widget({
                  "container_id": "tv_chart_container",
                  "symbol": "\(symbol)",
                  "interval": "\(interval)",
                  "timezone": "Etc/UTC",
                  "theme": "\(theme)",
                  "style": "1",
                  "locale": "en",
                  "toolbar_bg": "#f1f3f6",
                  "enable_publishing": false,
                  "allow_symbol_change": true,
                  "autosize": true
                });
              } catch(e) {
                document.body.innerHTML = "<h3 style='color:yellow;text-align:center;margin-top:40px;'>TradingView is blocked in your region.</h3>";
              }
            </script>
          </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.tradingview.com"))
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView,
                     didFinish navigation: WKNavigation!) {
            print("TradingView web content finished loading.")
        }
        
        func webView(_ webView: WKWebView,
                     didFail navigation: WKNavigation!,
                     withError error: Error) {
            fallbackMessage(in: webView)
        }
        
        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            fallbackMessage(in: webView)
        }
        
        private func fallbackMessage(in webView: WKWebView) {
            let fallbackHTML = """
            <html><body style="background:transparent;color:yellow;text-align:center;padding-top:40px;">
            <h3>TradingView is blocked in your region or unavailable.</h3>
            <p>Try a VPN or different region.</p>
            </body></html>
            """
            webView.loadHTMLString(fallbackHTML, baseURL: nil)
        }
    }
}

// MARK: - CoinPaprikaStatsView
struct CoinPaprikaStatsView: View {
    let coinSymbol: String
    @ObservedObject var vm: CoinPaprikaStatsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coin Stats")
                .font(.headline)
                .foregroundColor(.white)
            
            if vm.isLoading {
                ProgressView("Loading stats...")
                    .foregroundColor(.white)
            } else if let errorMsg = vm.errorMessage {
                Text("Error: \(errorMsg)")
                    .foregroundColor(.red)
                    .font(.subheadline)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    statCell("Price (USD)", vm.price)
                    statCell("24h Change", vm.percentChange24h + "%")
                    statCell("Volume (24h)", vm.volume24h)
                    statCell("Market Cap", vm.marketCap)
                    statCell("Rank", vm.rank)
                    statCell("Circulating Supply", vm.circulatingSupply)
                    statCell("Max Supply", vm.maxSupply)
                    statCell("24h High", vm.high24h)
                    statCell("24h Low", vm.low24h)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .blur(radius: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(20)
        .padding(.horizontal, 16)
        .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
    }
    
    private func statCell(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - CoinPaprikaStatsViewModel
class CoinPaprikaStatsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    @Published var price: String = "--"
    @Published var percentChange24h: String = "--"
    @Published var volume24h: String = "--"
    @Published var marketCap: String = "--"
    @Published var rank: String = "--"
    @Published var circulatingSupply: String = "--"
    @Published var maxSupply: String = "--"
    @Published var high24h: String = "--"
    @Published var low24h: String  = "--"
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 10
        return URLSession(configuration: config)
    }()
    
    func fetchCoinPaprikaStats(coinSymbol: String) {
        let coinID = coinPaprikaMapping(coinSymbol)
        let urlStr = "https://api.coinpaprika.com/v1/tickers/\(coinID)"
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Invalid CoinPaprika URL."
            }
            self.fallbackToCoinGecko(coinSymbol)
            return
        }
        
        session.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "CoinPaprika fetch error: \(error.localizedDescription)"
                }
                self.fallbackToCoinGecko(coinSymbol)
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data from CoinPaprika."
                }
                self.fallbackToCoinGecko(coinSymbol)
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let rnk  = json["rank"] as? Int ?? 0
                    let circ = json["circulating_supply"] as? Double ?? 0
                    let maxS = json["max_supply"] as? Double ?? 0
                    
                    if let quotes = json["quotes"] as? [String: Any],
                       let usd = quotes["USD"] as? [String: Any] {
                        
                        let priceVal = usd["price"] as? Double ?? 0
                        let volVal   = usd["volume_24h"] as? Double ?? 0
                        let capVal   = usd["market_cap"] as? Double ?? 0
                        let change24 = usd["percent_change_24h"] as? Double ?? 0
                        
                        DispatchQueue.main.async {
                            self.price             = self.formatLargeNumber(priceVal)
                            self.volume24h         = self.formatLargeNumber(volVal)
                            self.marketCap         = self.formatLargeNumber(capVal)
                            self.percentChange24h  = String(format: "%.2f", change24)
                            self.rank              = "#\(rnk)"
                            self.circulatingSupply = self.formatLargeNumber(circ)
                            self.maxSupply         = self.formatLargeNumber(maxS)
                            self.high24h           = "--"
                            self.low24h            = "--"
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.errorMessage = "CoinPaprika parse error: No 'quotes->USD' found."
                        }
                        self.fallbackToCoinGecko(coinSymbol)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "CoinPaprika parse error: Unexpected JSON structure."
                    }
                    self.fallbackToCoinGecko(coinSymbol)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "CoinPaprika parse error: \(error.localizedDescription)"
                }
                self.fallbackToCoinGecko(coinSymbol)
            }
        }.resume()
    }
    
    private func fallbackToCoinGecko(_ symbol: String) {
        fetchCoinGeckoStats(coinSymbol: symbol)
    }
    
    private func coinPaprikaMapping(_ symbol: String) -> String {
        switch symbol.uppercased() {
        case "BTC":  return "btc-bitcoin"
        case "ETH":  return "eth-ethereum"
        case "DOGE": return "doge-dogecoin"
        case "LINK": return "link-chainlink"
        case "BNB":  return "bnb-binance-coin"
        default:     return "btc-bitcoin"
        }
    }
    
    // MARK: - CoinGecko
    private func fetchCoinGeckoStats(coinSymbol: String) {
        let coinID = coinGeckoMapping(coinSymbol)
        let urlStr = "https://api.coingecko.com/api/v3/coins/\(coinID)?localization=false&tickers=false&community_data=false&developer_data=false&sparkline=false"
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Invalid CoinGecko URL."
            }
            self.fallbackToCoinbase(coinSymbol)
            return
        }
        
        session.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "CoinGecko fetch error: \(error.localizedDescription)"
                }
                self.fallbackToCoinbase(coinSymbol)
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data from CoinGecko."
                }
                self.fallbackToCoinbase(coinSymbol)
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let marketData = json["market_data"] as? [String: Any] {
                    
                    let currentPrice = marketData["current_price"] as? [String: Any]
                    let priceVal = currentPrice?["usd"] as? Double ?? 0
                    let change24Val = marketData["price_change_percentage_24h"] as? Double ?? 0
                    
                    let volumeDict = marketData["total_volume"] as? [String: Any]
                    let volumeVal = volumeDict?["usd"] as? Double ?? 0
                    
                    let capDict = marketData["market_cap"] as? [String: Any]
                    let capVal = capDict?["usd"] as? Double ?? 0
                    
                    let rankVal = json["market_cap_rank"] as? Int ?? 0
                    let circSupply = marketData["circulating_supply"] as? Double ?? 0
                    let maxSupplyVal = marketData["max_supply"] as? Double ?? 0
                    
                    let highDict = marketData["high_24h"] as? [String: Any]
                    let lowDict  = marketData["low_24h"] as? [String: Any]
                    let highVal  = highDict?["usd"] as? Double ?? 0
                    let lowVal   = lowDict?["usd"] as? Double ?? 0
                    
                    DispatchQueue.main.async {
                        self.price             = self.formatLargeNumber(priceVal)
                        self.volume24h         = self.formatLargeNumber(volumeVal)
                        self.marketCap         = self.formatLargeNumber(capVal)
                        self.percentChange24h  = String(format: "%.2f", change24Val)
                        self.rank              = (rankVal > 0) ? "#\(rankVal)" : "--"
                        self.circulatingSupply = self.formatLargeNumber(circSupply)
                        self.maxSupply         = self.formatLargeNumber(maxSupplyVal)
                        self.high24h           = self.formatLargeNumber(highVal)
                        self.low24h            = self.formatLargeNumber(lowVal)
                        self.errorMessage      = nil
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "CoinGecko parse error: Unexpected JSON structure."
                    }
                    self.fallbackToCoinbase(coinSymbol)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "CoinGecko parse error: \(error.localizedDescription)"
                }
                self.fallbackToCoinbase(coinSymbol)
            }
        }.resume()
    }
    
    private func coinGeckoMapping(_ symbol: String) -> String {
        switch symbol.uppercased() {
        case "BTC":  return "bitcoin"
        case "ETH":  return "ethereum"
        case "DOGE": return "dogecoin"
        case "LINK": return "chainlink"
        case "BNB":  return "binancecoin"
        default:     return "bitcoin"
        }
    }
    
    // MARK: - Final Fallback -> Placeholders
    private func fallbackToCoinbase(_ symbol: String) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage      = nil
            self.price             = "--"
            self.volume24h         = "--"
            self.marketCap         = "--"
            self.percentChange24h  = "--"
            self.rank              = "--"
            self.circulatingSupply = "--"
            self.maxSupply         = "--"
            self.high24h           = "--"
            self.low24h            = "--"
        }
    }
    
    // MARK: - Helpers
    func formatLargeNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        if value >= 1_000_000_000 {
            let shortVal = value / 1_000_000_000
            return formatter.string(from: NSNumber(value: shortVal)).map { "\($0)B" } ?? "--"
        } else if value >= 1_000_000 {
            let shortVal = value / 1_000_000
            return formatter.string(from: NSNumber(value: shortVal)).map { "\($0)M" } ?? "--"
        } else if value >= 1_000 {
            let shortVal = value / 1_000
            return formatter.string(from: NSNumber(value: shortVal)).map { "\($0)K" } ?? "--"
        } else {
            return formatter.string(from: NSNumber(value: value)) ?? String(value)
        }
    }
}
