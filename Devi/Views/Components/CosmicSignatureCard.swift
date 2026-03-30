// MARK: - Views/Components/CosmicSignatureCard.swift
// AI-generated daily cosmic insight card

import SwiftUI

struct CosmicSignatureCard: View {
    let signature: String?
    let isLoading: Bool
    let theme: DeviTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(theme.accentColor)
                    .symbolEffect(.pulse, isActive: true)

                Text("TODAY'S COSMIC SIGNATURE")
                    .deviLabel(.caption, theme: theme)

                Spacer()
            }

            if isLoading {
                // Shimmer loading state
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.primaryText.opacity(0.06))
                    .frame(height: 60)
                    .overlay {
                        ShimmerView(theme: theme)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else if let text = signature {
                Text(text)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(theme.primaryText.opacity(0.85))
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .contentTransition(.interpolate)
            }
        }
        .padding(16)
        .deviCard(theme: theme, elevation: .prominent)
        .deviEntrance(delay: 0.06)
    }
}

// MARK: - Shimmer Loading Effect

private struct ShimmerView: View {
    let theme: DeviTheme
    @State private var phase: CGFloat = 0

    var body: some View {
        let loc1 = max(0, min(phase - 0.3, 1.0))
        let loc2 = max(loc1, min(phase, 1.0))
        let loc3 = max(loc2, min(phase + 0.3, 1.0))

        LinearGradient(
            stops: [
                .init(color: .clear, location: loc1),
                .init(color: theme.primaryText.opacity(0.06), location: loc2),
                .init(color: .clear, location: loc3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1.3
            }
        }
    }
}
