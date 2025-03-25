import SwiftUI

struct AppTheme {
    
    // A more subtle sage/dark teal accent
    static let sageAccent = Color(red: 0.4, green: 0.82, blue: 0.62) // #66D19E
    
    // If you want a second accent, define it here:
    static let sageAccentAlt = Color(red: 0.30, green: 0.72, blue: 0.54) // #4DB78B
    
    // A gradient background from a dark teal to near-black
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.12, green: 0.17, blue: 0.18), // #1E2B2E
            Color(red: 0.06, green: 0.08, blue: 0.09)  // #101416
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
}
