
import SwiftUI

// MARK: - Gradient Background
struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.92, green: 0.95, blue: 0.98),
                Color(red: 0.85, green: 0.93, blue: 0.97),
                Color(red: 0.78, green: 0.91, blue: 0.96),
                Color(red: 0.88, green: 0.94, blue: 0.98)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
