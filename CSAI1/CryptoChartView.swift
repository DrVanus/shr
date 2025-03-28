import SwiftUI
import Charts
import WebKit

/// A renamed data model to avoid conflict with 'PricePoint' in CoinDetailView.
struct ChartPricePoint: Identifiable {
    let id = UUID()
    let time: Date
    let price: Double
}

/// A reusable Swift Charts view. Pass in your own [ChartPricePoint] data.
struct CryptoChartView: View {
    let priceData: [ChartPricePoint]
    let lineColor: Color  // e.g. .yellow

    var body: some View {
        Chart {
            ForEach(priceData) { point in
                LineMark(
                    x: .value("Time", point.time),
                    y: .value("Price", point.price)
                )
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic)
        }
        .chartYAxis {
            AxisMarks()
        }
    }
}

struct CryptoChartView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample data for preview
        let now = Date()
        let sampleData = (0..<24).map { i in
            ChartPricePoint(
                time: Calendar.current.date(byAdding: .hour, value: -i, to: now) ?? now,
                price: Double.random(in: 20000...25000)
            )
        }
        .sorted { $0.time < $1.time }

        return CryptoChartView(priceData: sampleData, lineColor: .yellow)
            .frame(height: 220)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}

// A UIViewRepresentable wrapper for TradingView chart using WKWebView
struct TradingViewChart: UIViewRepresentable {
    let symbol: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Construct TradingView embed URL for the given symbol
        // You may need to adjust the URL parameters per TradingView's documentation
        let urlString = "https://s.tradingview.com/embed-widget/single-quote/?symbol="
            + symbol
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}

// A combined chart view that lets the user toggle between the native SwiftUI chart and the TradingView chart
struct CombinedChartView: View {
    let symbol: String
    @State private var useTradingView = false
    
    // Generate sample data for the native SwiftUI chart (for demo purposes)
    private var sampleData: [ChartPricePoint] {
        let now = Date()
        return (0..<24).map { i in
            ChartPricePoint(
                time: Calendar.current.date(byAdding: .hour, value: -i, to: now) ?? now,
                price: Double.random(in: 20000...25000)
            )
        }.sorted { $0.time < $1.time }
    }
    
    var body: some View {
        VStack {
            Toggle("Use TradingView", isOn: $useTradingView)
                .padding()
            
            if useTradingView {
                TradingViewChart(symbol: symbol)
                    .frame(height: 220)
                    .padding()
            } else {
                CryptoChartView(priceData: sampleData, lineColor: .yellow)
                    .frame(height: 220)
                    .padding()
            }
        }
        .navigationTitle("Live \(symbol) Chart")
    }
}

struct CombinedChartView_Previews: PreviewProvider {
    static var previews: some View {
        CombinedChartView(symbol: "BTCUSDT")
    }
}
