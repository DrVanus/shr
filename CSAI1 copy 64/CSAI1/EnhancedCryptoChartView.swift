import SwiftUI
import Charts

/// Data model for chart points.
/// Conforms to Identifiable so we can use it in a ForEach,
/// and Equatable so that SwiftUI can animate changes in arrays of these points.
struct EnhancedChartPricePoint: Identifiable, Equatable {
    let id = UUID()
    let time: Date
    let price: Double

    static func == (lhs: EnhancedChartPricePoint, rhs: EnhancedChartPricePoint) -> Bool {
        return lhs.time == rhs.time && lhs.price == rhs.price
    }
}

/// An enhanced chart view with gradient fill, interactive tooltip, and crosshair functionality.
struct EnhancedCryptoChartView: View {
    // Array of chart data points
    let priceData: [EnhancedChartPricePoint]
    // Color for the main line (e.g., .yellow)
    let lineColor: Color
    
    // State for a basic tooltip (shows when user drags)
    @State private var selectedPoint: EnhancedChartPricePoint? = nil
    // Crosshair state toggle and location tracking
    @State private var showCrosshair: Bool = true
    @State private var crosshairLocation: CGPoint? = nil

    var body: some View {
        ZStack {
            Chart {
                // Gradient area under the price line
                ForEach(priceData) { point in
                    AreaMark(
                        x: .value("Time", point.time),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [lineColor.opacity(0.4), .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                // The main price line
                ForEach(priceData) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(lineColor)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                }
                
                // If a point is selected, show a vertical rule and a tooltip annotation.
                if let selectedPoint = selectedPoint {
                    RuleMark(x: .value("Selected Time", selectedPoint.time))
                        .foregroundStyle(Color.white.opacity(0.4))
                    
                    PointMark(
                        x: .value("Time", selectedPoint.time),
                        y: .value("Price", selectedPoint.price)
                    )
                    .annotation(position: .top) {
                        Text("\(selectedPoint.price, format: FloatingPointFormatStyle<Double>.number.precision(.fractionLength(2)))")
                            .font(.caption)
                            .padding(6)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(4)
                            .foregroundColor(.white)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour().minute())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel(format: FloatingPointFormatStyle<Double>.number.precision(.fractionLength(2)))
                }
            }
            // Chart overlay for detecting user gestures
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    let origin = geo[proxy.plotAreaFrame].origin
                                    let locationX = drag.location.x - origin.x
                                    let locationY = drag.location.y - origin.y
                                    crosshairLocation = drag.location
                                    if let date: Date = proxy.value(atX: locationX) {
                                        let closest = priceData.min {
                                            abs($0.time.timeIntervalSince(date)) < abs($1.time.timeIntervalSince(date))
                                        }
                                        selectedPoint = closest
                                    }
                                }
                                .onEnded { _ in
                                    // Optionally clear selection on end:
                                    // selectedPoint = nil
                                }
                        )
                }
            }
            
            // Crosshair lines overlay
            if showCrosshair, let loc = crosshairLocation {
                GeometryReader { geo in
                    let width = geo.size.width
                    let height = geo.size.height
                    if loc.x >= 0 && loc.y >= 0 && loc.x <= width && loc.y <= height {
                        ZStack {
                            // Vertical line
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 1, height: height)
                                .position(x: loc.x, y: height / 2)
                            // Horizontal line
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: width, height: 1)
                                .position(x: width / 2, y: loc.y)
                        }
                    }
                }
                .allowsHitTesting(false)
            }
            
            // Crosshair toggle in top-right corner
            VStack {
                HStack {
                    Spacer()
                    Toggle("Crosshair", isOn: $showCrosshair)
                        .padding(6)
                        .toggleStyle(SwitchToggleStyle(tint: .white))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.25))
                        .cornerRadius(8)
                        .padding([.top, .trailing], 8)
                }
                Spacer()
            }
        }
    }
}

struct EnhancedCryptoChartView_Previews: PreviewProvider {
    static var previews: some View {
        // Generate sample data
        let now = Date()
        let sampleData = (0..<24).map { i in
            EnhancedChartPricePoint(
                time: Calendar.current.date(byAdding: .hour, value: -i, to: now) ?? now,
                price: Double.random(in: 20000...25000)
            )
        }
        .sorted { $0.time < $1.time }
        
        return EnhancedCryptoChartView(
            priceData: sampleData,
            lineColor: .yellow
        )
        .frame(height: 300)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
        .previewLayout(.sizeThatFits)
    }
}
