// MARK: - Views/Components/CosmicSignatureCard.swift
// AI-generated daily cosmic insight card

import SwiftUI

struct CosmicSignatureCard: View {
    let signature: String?
    let isLoading: Bool
    let theme: DeviTheme

    @State private var revealedWordCount: Int = 0
    @State private var typewriterTimer: Timer? = nil
    @State private var hasStartedTypewriter = false

    /// The portion of the signature revealed so far by the typewriter animation.
    private var visibleText: String {
        guard let signature else { return "" }
        let words = signature.split(separator: " ").map(String.init)
        return words.prefix(revealedWordCount).joined(separator: " ")
    }

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
            } else if signature != nil {
                Text(visibleText)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(theme.primaryText.opacity(0.85))
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(16)
        .deviCard(theme: theme, elevation: .prominent)
        .deviEntrance(delay: 0.06)
        .onAppear {
            if let text = signature, !text.isEmpty, !hasStartedTypewriter {
                hasStartedTypewriter = true
                startTypewriter(for: text)
            }
        }
        .onChange(of: signature) { oldValue, newValue in
            if let newText = newValue, !newText.isEmpty, !hasStartedTypewriter {
                hasStartedTypewriter = true
                revealedWordCount = 0
                startTypewriter(for: newText)
            }
        }
        .onDisappear {
            typewriterTimer?.invalidate()
            typewriterTimer = nil
        }
    }

    // MARK: - Typewriter Animation

    private func startTypewriter(for text: String) {
        typewriterTimer?.invalidate()
        let wordCount = text.split(separator: " ").count
        typewriterTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            withAnimation(.easeOut(duration: 0.15)) {
                revealedWordCount += 1
            }
            if revealedWordCount >= wordCount {
                timer.invalidate()
                typewriterTimer = nil
            }
        }
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
