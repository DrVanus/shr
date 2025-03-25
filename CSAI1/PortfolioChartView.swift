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

// MARK: - ViewModel
class PortfolioChartViewModel: ObservableObject {
    @Published var dataPoints: [PortfolioDataPoint] = []
    @Published var selectedRange: TimeRange = .all

    @Published var dailyChange: Double = 2.34
    @Published var totalValue: Double = 65000

    // Portfolio metrics
    @Published var totalPL: Double = 13500
    @Published var roiPercent: Double = 26.5
    @Published var largestHoldingName: String = "BTC"
    @Published var largestHoldingPercent: Double = 40.0

    // Additional metrics
    @Published var twentyFourHrPL: Double = 400.0
    @Published var unrealizedPL: Double = 9000.0
    @Published var realizedPL: Double = 3000.0

    init() {
        loadData(for: .all)
    }

    func loadData(for range: TimeRange) {
        let now = Date()
        self.dataPoints = (0..<30).map { i in
            PortfolioDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -i, to: now) ?? now,
                value: Double.random(in: 50000...75000)
            )
        }
        .sorted { $0.date < $1.date }
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
struct PortfolioChartView: View {
    @StateObject private var vm = PortfolioChartViewModel()

    // Crosshair
    @State private var selectedValue: PortfolioDataPoint? = nil
    @State private var showCrosshair: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title & Stats
            Text("Your Portfolio Summary")
                .font(.title3).bold()
                .foregroundColor(.white)

            Text(vm.formattedTotalValue)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("24h Change: \(vm.formattedDailyChange)%")
                .font(.subheadline)
                .foregroundColor(vm.dailyChange >= 0 ? .green : .red)

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
            TradingViewTimeRangeBar(selectedRange: $vm.selectedRange) { newRange in
                vm.loadData(for: newRange)
            }

            // 6-Metric Layout
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
            vm.loadData(for: vm.selectedRange)
        }
    }

    // MARK: - Chart Content
    @ViewBuilder
    private var chartContent: some View {
        let minVal = vm.dataPoints.map { $0.value }.min() ?? 0

        Chart {
            ForEach(vm.dataPoints) { dp in
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
                        Text(vm.formatCurrency(sv.value))
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
                                   let closest = findClosest(date: date, in: vm.dataPoints) {
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
                           value: vm.formatCurrency(vm.totalPL),
                           isPositive: vm.totalPL >= 0)
                metricCell(title: "Largest Holding",
                           value: "\(vm.largestHoldingName) (\(String(format: "%.0f", vm.largestHoldingPercent))%)",
                           isPositive: true,
                           textColor: .white)
                metricCell(title: "Overall ROI",
                           value: "\(String(format: "%.1f", vm.roiPercent))%",
                           isPositive: vm.roiPercent >= 0)
            }
            GridRow {
                metricCell(title: "24H P/L",
                           value: vm.formatCurrency(vm.twentyFourHrPL),
                           isPositive: vm.twentyFourHrPL >= 0)
                metricCell(title: "Realized P/L",
                           value: vm.formatCurrency(vm.realizedPL),
                           isPositive: vm.realizedPL >= 0)
                metricCell(title: "Unrealized P/L",
                           value: vm.formatCurrency(vm.unrealizedPL),
                           isPositive: vm.unrealizedPL >= 0)
            }
        }
    }

    // MARK: - Fallback 6-Metric Layout for < iOS 16
    private var metricsSixFallback: some View {
        VStack(spacing: 12) {
            // Row 1
            HStack(spacing: 20) {
                metricCell(
                    title: "Total P/L",
                    value: vm.formatCurrency(vm.totalPL),
                    isPositive: vm.totalPL >= 0
                )
                metricCell(
                    title: "Largest Holding",
                    value: "\(vm.largestHoldingName) (\(String(format: "%.0f", vm.largestHoldingPercent))%)",
                    isPositive: true,
                    textColor: .white
                )
                metricCell(
                    title: "Overall ROI",
                    value: "\(String(format: "%.1f", vm.roiPercent))%",
                    isPositive: vm.roiPercent >= 0
                )
            }
            // Row 2
            HStack(spacing: 20) {
                metricCell(
                    title: "24H P/L",
                    value: vm.formatCurrency(vm.twentyFourHrPL),
                    isPositive: vm.twentyFourHrPL >= 0
                )
                metricCell(
                    title: "Realized P/L",
                    value: vm.formatCurrency(vm.realizedPL),
                    isPositive: vm.realizedPL >= 0
                )
                metricCell(
                    title: "Unrealized P/L",
                    value: vm.formatCurrency(vm.unrealizedPL),
                    isPositive: vm.unrealizedPL >= 0
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
