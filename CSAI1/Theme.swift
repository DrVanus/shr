//
//  Theme.swift
//  CSAI1
//
//  Created by YourName on 3/25/25.
//

import SwiftUI
import Combine

// MARK: - AppTheme
enum AppTheme {
    // nil => system-based; .light => always light; .dark => always dark
    static var currentColorScheme: ColorScheme? = nil
}

// MARK: - ThemedRootView
/// A container that enforces a black top bar in both light/dark mode
/// and tries to keep the status bar text white.
struct ThemedRootView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
        
        // Force black nav bar background:
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // For older iOS:
        UINavigationBar.appearance().barTintColor = .black
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().isTranslucent = false
        
        // Attempt to force white status bar text:
        UIApplication.shared.statusBarStyle = .lightContent
        
        // If you want the entire window to be forced dark, uncomment below:
        // UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
    }
    
    var body: some View {
        content
            .preferredColorScheme(AppTheme.currentColorScheme)
    }
}

// MARK: - FuturisticBackground
struct FuturisticBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            if colorScheme == .light {
                // Light mode: a darker silver gradient so the top isn’t too white
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(white: 0.35),  // slightly darker silver
                        Color(white: 0.75)   // mid-silver
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            } else {
                // Dark mode: black -> gray
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.gray.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            // 2) Radial highlight in the center
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.05),
                    Color.clear
                ]),
                center: .center,
                startRadius: 10,
                endRadius: 400
            )
            .blendMode(.lighten)
            .ignoresSafeArea()

            // 3) Primary wave lines
            WavePatternShape(lineCount: 10, amplitude: 8)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .blendMode(.overlay)
                .ignoresSafeArea()

            // 4) Secondary wave lines
            WavePatternShape(lineCount: 8, amplitude: 5)
                .stroke(Color.white.opacity(0.015), lineWidth: 0.5)
                .blendMode(.overlay)
                .rotationEffect(.degrees(180))
                .offset(y: 80)
                .ignoresSafeArea()

            // 5) Darker top overlay to keep nav area black
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.9),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            .blendMode(.multiply)

            // 6) Slight color shift
            Color.clear
                .hueRotation(.degrees(10))
                .saturation(1.25)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // 7) Subtle star sparkles
            AnimatedSparkleOverlay(sparkleCount: 12)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            // 8) Metal-based noise
            MetalPerlinNoiseView()
                .opacity(0.10)
                .blendMode(.overlay)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            // 9) Interactive ripple overlay
            InteractiveTouchOverlay()
                .ignoresSafeArea()
        }
    }
}

// MARK: - WavePatternShape
struct WavePatternShape: Shape {
    let lineCount: Int
    let amplitude: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for i in 0..<lineCount {
            let y = rect.height * CGFloat(i) / CGFloat(lineCount - 1)
            path.move(to: CGPoint(x: 0, y: y))
            path.addCurve(
                to: CGPoint(x: rect.width, y: y),
                control1: CGPoint(
                    x: rect.width * 0.3,
                    y: y + amplitude * sin(CGFloat(i))
                ),
                control2: CGPoint(
                    x: rect.width * 0.7,
                    y: y - amplitude * sin(CGFloat(i))
                )
            )
        }
        return path
    }
}

// MARK: - AnimatedSparkleOverlay
struct AnimatedSparkleOverlay: View {
    let sparkleCount: Int
    
    struct Sparkle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var offset: CGPoint
        var baseOpacity: Double
    }
    
    @State private var sparkles: [Sparkle] = []
    @State private var animateFlag = false
    @State private var containerSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(sparkles) { sp in
                    Circle()
                        // smaller star specks
                        .frame(width: 1.5, height: 1.5)
                        .position(
                            x: sp.position.x + (animateFlag ? sp.offset.x : -sp.offset.x),
                            y: sp.position.y + (animateFlag ? sp.offset.y : -sp.offset.y)
                        )
                        .foregroundColor(.white.opacity(animateFlag ? sp.baseOpacity : 0))
                }
            }
            .onAppear {
                containerSize = geo.size
                generateSparkles()
                
                // Re-randomize sparkles every 8 seconds
                Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 2)) {
                        generateSparkles()
                    }
                }
                
                // Continuously fade in/out
                withAnimation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    animateFlag.toggle()
                }
            }
            .onChange(of: geo.size) { newSize in
                containerSize = newSize
                generateSparkles()
            }
        }
    }
    
    private func generateSparkles() {
        sparkles = (0..<sparkleCount).map { _ in
            let x = CGFloat.random(in: 0..<containerSize.width)
            let y = CGFloat.random(in: 0..<containerSize.height)
            let offX = CGFloat.random(in: -3...3)
            let offY = CGFloat.random(in: -3...3)
            let op = Double.random(in: 0.02...0.08)
            
            return Sparkle(
                position: CGPoint(x: x, y: y),
                offset: CGPoint(x: offX, y: offY),
                baseOpacity: op
            )
        }
    }
}

// MARK: - InteractiveTouchOverlay
struct InteractiveTouchOverlay: View {
    @State private var ripples: [Ripple] = []
    
    struct Ripple: Identifiable {
        let id = UUID()
        var position: CGPoint
        var radius: CGFloat = 0
        var opacity: Double = 0.4
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(ripples) { ripple in
                    Circle()
                        .fill(Color.white.opacity(ripple.opacity))
                        .frame(width: ripple.radius * 2, height: ripple.radius * 2)
                        .position(ripple.position)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        addRipple(at: value.location)
                    }
            )
            .onReceive(
                Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
            ) { _ in
                updateRipples()
            }
        }
    }
    
    private func addRipple(at location: CGPoint) {
        ripples.append(Ripple(position: location))
    }
    
    private func updateRipples() {
        for i in 0..<ripples.count {
            ripples[i].radius += 1.2
            ripples[i].opacity -= 0.007
        }
        ripples.removeAll { $0.opacity <= 0 }
    }
}
