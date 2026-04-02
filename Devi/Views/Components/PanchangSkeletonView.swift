// MARK: - Views/Components/PanchangSkeletonView.swift
// Atmospheric shimmer loading skeleton — shown while panchang data is computing.
// Mirrors the hero arc + moon + tithi text + Right Now card layout.

import SwiftUI

struct PanchangSkeletonView: View {
    let theme: DeviTheme

    // MARK: - Shimmer State

    @State private var shimmerOffset: CGFloat = -1.0

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Hero area: arc + moon + text lines
            ZStack {
                // Semicircle placeholder (sun arc track)
                SunArcShape()
                    .stroke(
                        theme.primaryText.opacity(0.04),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6])
                    )
                    .frame(width: 360, height: 180)

                // Center content: moon circle + text placeholders
                VStack(spacing: 10) {
                    // Moon placeholder
                    Circle()
                        .fill(theme.primaryText.opacity(0.06))
                        .frame(width: 44, height: 44)

                    // Tithi name placeholder
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(theme.primaryText.opacity(0.05))
                        .frame(width: 120, height: 14)

                    // Countdown placeholder
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(theme.primaryText.opacity(0.04))
                        .frame(width: 160, height: 36)
                }
                .offset(y: 20)
            }
            .frame(height: 240)
            .overlay { shimmerOverlay }
            .clipped()

            // Sunrise / Sunset time placeholders
            HStack {
                timePlaceholder
                Spacer()
                timePlaceholder
            }
            .padding(.horizontal, 48)

            // Right Now card placeholder
            VStack(alignment: .leading, spacing: 12) {
                // Section header placeholder
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(theme.primaryText.opacity(0.04))
                    .frame(width: 80, height: 10)

                // Row placeholders (3 rows to suggest content)
                ForEach(0..<3, id: \.self) { index in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(theme.primaryText.opacity(0.05))
                            .frame(width: 8, height: 8)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(theme.primaryText.opacity(0.04))
                            .frame(height: 12)
                            .frame(maxWidth: rowWidth(for: index))

                        Spacer()

                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(theme.primaryText.opacity(0.03))
                            .frame(width: 48, height: 10)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.primaryText.opacity(0.03))
            )
            .padding(.horizontal, 16)
            .overlay { shimmerOverlay }
            .clipped()
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 1.0
            }
        }
    }

    // MARK: - Shimmer Overlay

    /// A translucent gradient band that sweeps left-to-right across the content,
    /// evoking a sky slowly brightening rather than a generic loading bar.
    private var shimmerOverlay: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let bandWidth = width * 0.6

            // Map shimmerOffset from -1...1 to sweep across the full width
            let leading = (shimmerOffset + 1) / 2 * (width + bandWidth) - bandWidth

            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: theme.accentColor.opacity(0.04), location: 0.35),
                            .init(color: theme.accentColor.opacity(0.05), location: 0.5),
                            .init(color: theme.accentColor.opacity(0.04), location: 0.65),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: bandWidth)
                .offset(x: leading)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    /// Time label placeholder (sunrise/sunset position)
    private var timePlaceholder: some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(theme.primaryText.opacity(0.04))
                .frame(width: 44, height: 8)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(theme.primaryText.opacity(0.05))
                .frame(width: 56, height: 12)
        }
    }

    /// Vary row widths to look organic rather than uniform
    private func rowWidth(for index: Int) -> CGFloat {
        switch index {
        case 0: return 140
        case 1: return 100
        default: return 120
        }
    }
}

// MARK: - Preview

#Preview("Dark") {
    ZStack {
        DeviTheme.forPeriod(.evening).backgroundGradient
            .ignoresSafeArea()

        ScrollView {
            PanchangSkeletonView(theme: DeviTheme.forPeriod(.evening))
                .padding(.top, 40)
        }
    }
}

#Preview("Light") {
    ZStack {
        DeviTheme.forPeriod(.morning, appearance: .alwaysLight).backgroundGradient
            .ignoresSafeArea()

        ScrollView {
            PanchangSkeletonView(theme: DeviTheme.forPeriod(.morning, appearance: .alwaysLight))
                .padding(.top, 40)
        }
    }
}
