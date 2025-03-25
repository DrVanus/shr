import SwiftUI
import UIKit

// MARK: - Central App Theme

struct AppTheme {
    // Stores the user’s chosen appearance in UserDefaults, so it persists.
    @AppStorage("appearance") static var appearance: String = "system"
    
    // Translate the stored string into an optional ColorScheme.
    // "system" => nil (follow device setting),
    // "light" => .light, "dark" => .dark.
    static var currentColorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil  // system
        }
    }
    
    // MARK: Dark Theme (Colors, Gradients)
    struct Dark {
        static let accent       = Color(red: 0.4, green: 0.82, blue: 0.62)
        static let accentAlt    = Color(red: 0.30, green: 0.72, blue: 0.54)
        // Noticeably different gradient stops so it’s not pure black.
        static let gradientColors: [Color] = [
            Color(red: 0.16, green: 0.22, blue: 0.24), // #29383D
            Color(red: 0.03, green: 0.05, blue: 0.06)  // #070A0F
        ]
    }
    
    // MARK: Light Theme (Colors, Gradients)
    struct Light {
        static let accent       = Color(red: 0.4, green: 0.82, blue: 0.62)
        static let accentAlt    = Color(red: 0.30, green: 0.72, blue: 0.54)
        // A refined light gradient.
        static let gradientColors: [Color] = [
            Color(red: 0.95, green: 0.96, blue: 0.97),
            Color(red: 0.85, green: 0.87, blue: 0.88)
        ]
    }
    
    // Helper: pick the right gradient array based on environment color scheme.
    static func gradient(for scheme: ColorScheme) -> [Color] {
        return scheme == .dark ? Dark.gradientColors : Light.gradientColors
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var animateHue = false
    
    var body: some View {
        // Pick the gradient colors from the theme.
        let colors = AppTheme.gradient(for: colorScheme)
        LinearGradient(gradient: Gradient(colors: colors),
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
            // Optionally animate the hue for a subtle color shift over time.
            .hueRotation(.degrees(animateHue ? 360 : 0))
            .animation(.linear(duration: 20).repeatForever(autoreverses: false),
                       value: animateHue)
            .onAppear { animateHue = true }
            .ignoresSafeArea()
    }
}

// MARK: - Optional: Particles or Noise Overlays

struct ParticleBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        let emitter = CAEmitterLayer()
        emitter.emitterShape = .line
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.midX, y: -10)
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 1)
        
        let cell = CAEmitterCell()
        cell.contents = UIImage(named: "particleDot")?.cgImage  // Add "particleDot" asset
        cell.birthRate = 2
        cell.lifetime = 20
        cell.velocity = 30
        cell.velocityRange = 20
        cell.yAcceleration = 10
        cell.emissionLongitude = .pi
        cell.scale = 0.02
        cell.scaleRange = 0.01
        cell.alphaSpeed = -0.02
        
        emitter.emitterCells = [cell]
        emitter.frame = UIScreen.main.bounds
        view.layer.addSublayer(emitter)
        
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct NoiseOverlay: View {
    var body: some View {
        Image("noiseTexture") // Subtle noise image
            .resizable(resizingMode: .tile)
            .opacity(0.03)
            .blendMode(.overlay)
            .ignoresSafeArea()
    }
}

// MARK: - Futuristic Background Combining Effects

struct FuturisticBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Animated gradient (dark/light).
            AnimatedGradientBackground()
            
            // Optional particle effect.
            ParticleBackground()
                .allowsHitTesting(false)
            
            // Optional noise overlay for texture.
            NoiseOverlay()
        }
    }
}
