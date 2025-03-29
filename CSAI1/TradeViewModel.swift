import SwiftUI
import WebKit

struct TradingViewWebView: UIViewRepresentable {
    let symbol: String   // e.g. "BINANCE:BTCUSDT"
    let interval: String // e.g. "D" for daily, "15" for 15m, etc.
    let theme: String    // "Dark" or "Light"
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false // Prevent scrolling inside the chart
        webView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body, html { margin: 0; padding: 0; background: transparent; }
            </style>
        </head>
        <body>
            <div class="tradingview-widget-container">
                <div id="tv_chart_container"></div>
                <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
                <script type="text/javascript">
                    new TradingView.widget({
                        "autosize": true,
                        "symbol": "\(symbol)",
                        "interval": "\(interval)",
                        "timezone": "Etc/UTC",
                        "theme": "\(theme)",
                        "style": "1",
                        "locale": "en",
                        "toolbar_bg": "#f1f3f6",
                        "enable_publishing": false,
                        "allow_symbol_change": true,
                        "container_id": "tv_chart_container"
                    });
                </script>
            </div>
        </body>
        </html>
        """
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }
}
