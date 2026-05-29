import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.12, blue: 0.35), Color(red: 0.28, green: 0.10, blue: 0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Outer glow ring
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 210, height: 210)

            // Inner circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.18), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 160, height: 160)

            // Music note
            Image(systemName: "music.note")
                .font(.system(size: 100, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(red: 0.80, green: 0.72, blue: 1.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 0.5, green: 0.3, blue: 1.0).opacity(0.7), radius: 20)
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 224))
    }
}

#Preview {
    AppIconView()
        .frame(width: 300, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 66))
}
