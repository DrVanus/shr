import SwiftUI
import Charts

// MARK: - Data Model
struct PortfolioDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - TimeRange Enum
enum TimeRange: String, CaseIterable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case threeMonth = "3M"
    case sixMonth = "6M"
    case year = "1Y"
    case threeYear = "3Y"
    case all = "ALL"
}

// MARK: - Chart ViewModel
class PortfolioChartViewModel: ObservableObject {
    @Published var dataPoints: [PortfolioDataPoint] = []
    @Published var selectedRange: TimeRange = .all
    
    // Metrics based on the portfolio data passed in.
    @Published var totalValue: Double = 0.0
    @Published var dailyChange: Double = 0.0  // Compute from historical data when available
    @Published var totalPL: Double = 0.0
    @Published var roiPercent: Double = 0.0
    @Published var largestHoldingName: String = "N/A"
    @Published var largestHoldingPercent: Double = 0.0
    @Published var twentyFourHrPL: Double = 0.0
    @Published var unrealizedPL: Double = 0.0
    @Published var realizedPL: Double = 0.0
    
    /// Loads simulated historical data based on the selected time range.
    /// In production, replace this logic with real historical data derived from transaction history and API calls.
    func loadData(for range: TimeRange, portfolioTotal: Double) {
        let now = Date()
        self.totalValue = portfolioTotal
        
        // Determine the number of data points based on the range.
        let count: Int = {
            switch range {
            case .day: return 24
            case .week: return 7
            case .month: return 30
            case .threeMonth: return 90
            case .sixMonth: return 180
            case .year: return 365
            case .threeYear: return 365 * 3
            case .all: return 365 * 3
            }
        }()
        
        // Generate simulated historical values.
        // Each point will be the portfolioTotal with a ±3% random variation.
        self.dataPoints = (0..<count).map { i in
            let date = Calendar.current.date(byAdding: .day, value: -(count - 1 - i), to: now) ?? now
            let randomFactor = Double.random(in: -0.03...0.03)  // ±3% variation
            let value = portfolioTotal * (1 + randomFactor)
            return PortfolioDataPoint(date: date, value: value)
        }.sorted { $0.date < $1.date }
        
        // For now, metrics remain placeholders
        self.dailyChange = 0.0
        self.totalPL = 0.0
        self.roiPercent = 0.0
        self.largestHoldingName = "N/A"
        self.largestHoldingPercent = 0.0
        self.twentyFourHrPL = 0.0
        self.unrealizedPL = 0.0
        self.realizedPL = 0.0
    }
    
    // Currency formatter
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    var formattedTotalValue: String {
        formatCurrency(totalValue)
    }
    
    var formattedDailyChange: String {
        String(format: "%.2f", dailyChange)
    }
}

// MARK: - TradingViewTimeRangeBar
struct TradingViewTimeRangeBar: View {
    @Binding var selectedRange: TimeRange
    let onRangeSelected: (TimeRange) -> Void

    @Namespace private var underlineAnimation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                VStack(spacing: 4) {
                    Text(range.rawValue)
                        .font(.callout.bold())
                        .foregroundColor(selectedRange == range ? .white : .gray)
                    
                    if selectedRange == range {
                        Rectangle()
                            .fill(.yellow)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "underline", in: underlineAnimation)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 2)
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        selectedRange = range
                        onRangeSelected(range)
                    }
                }
            }
        }
    }
}

// MARK: - Main PortfolioChartView
/// This view takes a PortfolioViewModel reference so it can use the current portfolio total.
struct PortfolioChartView: View {
    // Inject the main portfolio view model.
    @ObservedObject var portfolioVM: PortfolioViewModel
    @StateObject private var chartVM = PortfolioChartViewModel()

    // Crosshair states
    @State private var selectedValue: PortfolioDataPoint? = nil
    @State private var showCrosshair: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title & Stats
            Text("Your Portfolio Summary")
                .font(.title3).bold()
                .foregroundColor(.white)
            
            Text(chartVM.formattedTotalValue)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text("24h Change: \(chartVM.formattedDailyChange)%")
                .font(.subheadline)
                .foregroundColor(chartVM.dailyChange >= 0 ? .green : .red)
            
            // Chart
            Group {
                if #available(iOS 16, *) {
                    chartContent
                        .frame(height: 150)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                } else {
                    Text("Requires iOS 16+ for Swift Charts")
                        .foregroundColor(.gray)
                }
            }
            
            // Time Range Bar
            TradingViewTimeRangeBar(selectedRange: $chartVM.selectedRange) { newRange in
                chartVM.loadData(for: newRange, portfolioTotal: portfolioVM.totalValue)
            }
            
            // 6-Metric Layout (using the chart VM's metrics as placeholders)
            if #available(iOS 16.0, *) {
                metricsSixGrid
                    .padding(.top, 8)
            } else {
                metricsSixFallback
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
        .onAppear {
            chartVM.loadData(for: chartVM.selectedRange, portfolioTotal: portfolioVM.totalValue)
        }
        // Update chart data when the portfolio total changes.
        .onChange(of: portfolioVM.totalValue) { newValue in
            chartVM.loadData(for: chartVM.selectedRange, portfolioTotal: newValue)
        }
    }
    
    // MARK: - Chart Content
    @ViewBuilder
    private var chartContent: some View {
        let minVal = chartVM.dataPoints.map { $0.value }.min() ?? 0
        
        Chart {
            ForEach(chartVM.dataPoints) { dp in
                LineMark(
                    x: .value("Date", dp.date),
                    y: .value("Value", dp.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.green)
                
                AreaMark(
                    x: .value("Date", dp.date),
                    yStart: .value("Min", minVal * 0.99),
                    yEnd: .value("Value", dp.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .green.opacity(0.25),
                            .clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            // Crosshair
            if showCrosshair, let sv = selectedValue {
                RuleMark(x: .value("Selected Date", sv.date))
                    .foregroundStyle(.white.opacity(0.7))
                
                PointMark(
                    x: .value("Date", sv.date),
                    y: .value("Value", sv.value)
                )
                .symbolSize(60)
                .foregroundStyle(.white)
                .annotation(position: .top) {
                    VStack(spacing: 4) {
                        Text(sv.date, style: .date)
                            .font(.footnote)
                            .foregroundColor(.white)
                        Text(chartVM.formatCurrency(sv.value))
                            .font(.footnote).bold()
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.85))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                showCrosshair = true
                                let location = drag.location
                                let relativeX = location.x - geo[proxy.plotAreaFrame].origin.x
                                if let date: Date = proxy.value(atX: relativeX),
                                   let closest = findClosest(date: date, in: chartVM.dataPoints) {
                                    selectedValue = closest
                                }
                            }
                            .onEnded { _ in
                                showCrosshair = false
                            }
                    )
            }
        }
    }
    
    // MARK: - Grid-based 6-Metric Layout (iOS 16+)
    @available(iOS 16.0, *)
    private var metricsSixGrid: some View {
        Grid(horizontalSpacing: 20, verticalSpacing: 12) {
            GridRow {
                metricCell(title: "Total P/L",
                           value: chartVM.formatCurrency(chartVM.totalPL),
                           isPositive: chartVM.totalPL >= 0)
                metricCell(title: "Largest Holding",
                           value: "\(chartVM.largestHoldingName) (\(String(format: "%.0f", chartVM.largestHoldingPercent))%)",
                           isPositive: true,
                           textColor: .white)
                metricCell(title: "Overall ROI",
                           value: "\(String(format: "%.1f", chartVM.roiPercent))%",
                           isPositive: chartVM.roiPercent >= 0)
            }
            GridRow {
                metricCell(title: "24H P/L",
                           value: chartVM.formatCurrency(chartVM.twentyFourHrPL),
                           isPositive: chartVM.twentyFourHrPL >= 0)
                metricCell(title: "Realized P/L",
                           value: chartVM.formatCurrency(chartVM.realizedPL),
                           isPositive: chartVM.realizedPL >= 0)
                metricCell(title: "Unrealized P/L",
                           value: chartVM.formatCurrency(chartVM.unrealizedPL),
                           isPositive: chartVM.unrealizedPL >= 0)
            }
        }
    }
    
    // MARK: - Fallback 6-Metric Layout for < iOS 16
    private var metricsSixFallback: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                metricCell(
                    title: "Total P/L",
                    value: chartVM.formatCurrency(chartVM.totalPL),
                    isPositive: chartVM.totalPL >= 0
                )
                metricCell(
                    title: "Largest Holding",
                    value: "\(chartVM.largestHoldingName) (\(String(format: "%.0f", chartVM.largestHoldingPercent))%)",
                    isPositive: true,
                    textColor: .white
                )
                metricCell(
                    title: "Overall ROI",
                    value: "\(String(format: "%.1f", chartVM.roiPercent))%",
                    isPositive: chartVM.roiPercent >= 0
                )
            }
            HStack(spacing: 20) {
                metricCell(
                    title: "24H P/L",
                    value: chartVM.formatCurrency(chartVM.twentyFourHrPL),
                    isPositive: chartVM.twentyFourHrPL >= 0
                )
                metricCell(
                    title: "Realized P/L",
                    value: chartVM.formatCurrency(chartVM.realizedPL),
                    isPositive: chartVM.realizedPL >= 0
                )
                metricCell(
                    title: "Unrealized P/L",
                    value: chartVM.formatCurrency(chartVM.unrealizedPL),
                    isPositive: chartVM.unrealizedPL >= 0
                )
            }
        }
    }
    
    // MARK: - Metric Cell
    private func metricCell(title: String,
                            value: String,
                            isPositive: Bool = true,
                            textColor: Color = .green) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.callout)
                .foregroundColor(isPositive ? (textColor == .white ? .green : textColor) : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Crosshair Helper
    private func findClosest(date: Date, in points: [PortfolioDataPoint]) -> PortfolioDataPoint? {
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
}
