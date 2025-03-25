import SwiftUI
import Charts

/// A SwiftUI Charts-based portfolio chart view, defaulting to .all.
/// Conforms PortfolioDataPoint to Equatable so that .animation(..., value: vm.dataPoints) works.
struct PortfolioChartView: View {
    @StateObject private var vm = PortfolioChartViewModel()
    
    // For crosshair/tooltip
    @State private var selectedValue: PortfolioDataPoint? = nil
    @State private var showCrosshair: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Title + Stats
            Text("Your Portfolio Summary")
                .font(.title3).bold()
                .foregroundColor(.white)
            
            Text(vm.formattedTotalValue)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text("24h Change: \(vm.formattedDailyChange)%")
                .font(.subheadline)
                .foregroundColor(vm.dailyChange >= 0 ? .green : .red)
            
            // SwiftUI Chart (iOS 16+)
            Group {
                if #available(iOS 16, *) {
                    chartContent
                        .frame(height: 200)
                        // Animate chart updates when dataPoints changes
                        .animation(.easeInOut(duration: 0.3), value: vm.dataPoints)
                } else {
                    Text("Requires iOS 16+ for Swift Charts")
                        .foregroundColor(.gray)
                }
            }
            
            // Time Range - Centered Chips
            timeRangeChips
            
            // AI Insight
            VStack(spacing: 4) {
                Text("AI Insight")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("Your portfolio rose \(vm.formattedDailyChange)% in the last 24 hours. Tap below for deeper AI analysis.")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Button("View Full Analysis") {
                    // Insert action here
                }
                .buttonStyle(CSGoldButtonStyle()) // references your shared style
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .onAppear {
            vm.loadData(for: vm.selectedRange)
        }
    }
    
    // MARK: - Chart Content (iOS 16+)
    @ViewBuilder
    private var chartContent: some View {
        let minVal = vm.dataPoints.map { $0.value }.min() ?? 0
        
        Chart {
            // Main line + area fill
            ForEach(vm.dataPoints) { dp in
                LineMark(
                    x: .value("Date", dp.date),
                    y: .value("Value", dp.value)
                )
                .foregroundStyle(.green)
                
                AreaMark(
                    x: .value("Date", dp.date),
                    yStart: .value("Min", minVal * 0.99),
                    yEnd: .value("Value", dp.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.green.opacity(0.3), .clear]),
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
                    VStack(spacing: 2) {
                        Text(sv.date, style: .date)
                            .font(.caption2)
                            .foregroundColor(.white)
                        Text(vm.formatCurrency(sv.value))
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    .padding(6)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(6)
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
                                if let date: Date = proxy.value(atX: location.x) {
                                    if let closest = findClosest(date: date, in: vm.dataPoints) {
                                        selectedValue = closest
                                    }
                                }
                            }
                            .onEnded { _ in
                                showCrosshair = false
                            }
                    )
            }
        }
    }
    
    // MARK: - Custom Time Range Chips (centered)
    private var timeRangeChips: some View {
        HStack(spacing: 8) {
            Spacer()
            ForEach(HomeTimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut) {
                        vm.selectedRange = range
                        vm.loadData(for: range)
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(vm.selectedRange == range
                                      ? Color.yellow
                                      : Color.white.opacity(0.15))
                        )
                        .foregroundColor(vm.selectedRange == range ? .black : .white)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper for crosshair
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

// MARK: - Data Model
/// Conform to Equatable so that .animation(..., value: vm.dataPoints) works
struct PortfolioDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - View Model
class PortfolioChartViewModel: ObservableObject {
    @Published var dataPoints: [PortfolioDataPoint] = []
    
    // Set default to .all
    @Published var selectedRange: HomeTimeRange = .all
    
    var dailyChange: Double = 2.34
    var totalValue: Double = 65000
    
    var formattedDailyChange: String {
        String(format: "%.2f", dailyChange)
    }
    
    var formattedTotalValue: String {
        formatCurrency(totalValue)
    }
    
    func loadData(for range: HomeTimeRange) {
        switch range {
        case .day:
            dataPoints = makeFakeData(7)
        case .week:
            dataPoints = makeFakeData(14)
        case .month:
            dataPoints = makeFakeData(30)
        case .threeMonth:
            dataPoints = makeFakeData(90)
        case .year:
            dataPoints = makeFakeData(365)
        case .all:
            dataPoints = makeFakeData(999)
        }
    }
    
    private func makeFakeData(_ days: Int) -> [PortfolioDataPoint] {
        var results: [PortfolioDataPoint] = []
        let now = Date()
        var currentValue = totalValue
        
        for i in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: now) ?? now
            currentValue += Double.random(in: -500...500)
            results.append(PortfolioDataPoint(date: date, value: max(0, currentValue)))
        }
        
        return results.sorted { $0.date < $1.date }
    }
    
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
