// MARK: - Views/Components/EclipseImmersiveView.swift
// Full-screen cosmic theater — immersive eclipse experience

import SwiftUI

struct EclipseImmersiveView: View {
    let eclipse: EclipseEvent
    let theme: DeviTheme
    let timezoneIdentifier: String

    @Environment(\.dismiss) private var dismiss
    @State private var eclipseProgress: CGFloat = 0
    @State private var appeared: Bool = false

    private let eclipseBlue = Color(hex: "7B8EC4")
    private let gold = Color(hex: "D4A040")
    private let silver = Color(hex: "B8C4D8")

    var body: some View {
        ZStack {
            // Near-black atmosphere
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "050810"), location: 0.0),
                    .init(color: Color(hex: "0A1020"), location: 0.5),
                    .init(color: Color(hex: "0D1428"), location: 1.0)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle blue mist wisps
            RadialGradient(
                colors: [eclipseBlue.opacity(0.03), .clear],
                center: .center, startRadius: 50, endRadius: 300
            )
            .ignoresSafeArea()

            StarFieldView(isDaytime: false, timePeriod: .night)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    topBar.padding(.top, 8)

                    // Eclipse animation hero
                    eclipseHero
                        .opacity(appeared ? 1 : 0)

                    // Title
                    VStack(spacing: 6) {
                        Text(eclipse.displayName)
                            .font(.system(size: 28, weight: .regular, design: .serif))
                            .foregroundColor(eclipseBlue)
                            .tracking(1)

                        Text(eclipse.body.devanagari)
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(eclipseBlue.opacity(0.7))
                    }
                    .deviReveal(delay: 0.3, direction: .fadeUp)

                    // Contact timeline
                    contactTimeline
                        .deviReveal(delay: 0.4, direction: .fadeUp)

                    // Magnitude bar
                    magnitudeBar
                        .deviReveal(delay: 0.45, direction: .fadeUp)

                    // Visibility warning
                    if eclipse.moonBelowHorizon {
                        HStack(spacing: 8) {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 12))
                                .foregroundColor(eclipseBlue)
                            Text("Moon below horizon — partial visibility only")
                                .deviLabel(.detail, theme: theme)
                        }
                        .padding(12)
                        .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
                        .deviReveal(delay: 0.5, direction: .fadeUp)
                    }

                    // Mythology
                    mythologySection
                        .deviReveal(delay: 0.55, direction: .fadeUp)

                    // Mantras
                    mantrasSection
                        .deviReveal(delay: 0.6, direction: .fadeUp)

                    // Dos and Don'ts
                    dosAndDontsSection
                        .deviReveal(delay: 0.65, direction: .fadeUp)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 3).delay(0.2)) {
                eclipseProgress = 1
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            Spacer()
            ShareLink(item: ShareTextBuilder.panchangElement(
                .eclipse(eclipse),
                timezoneIdentifier: timezoneIdentifier
            )) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12))
                    Text("Share")
                        .scaledFont(size: 13, weight: .medium)
                }
                .foregroundColor(theme.secondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Eclipse Hero (animated sun/moon convergence)

    private var eclipseHero: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let bodyRadius: CGFloat = 50

            let isSolar = eclipse.body == .solar

            // Sun position (left, converges toward center)
            let sunOffset = (1 - eclipseProgress) * 70
            let sunCenter = CGPoint(
                x: center.x - (isSolar ? sunOffset : -sunOffset),
                y: center.y
            )

            // Moon position (right, converges toward center)
            let moonCenter = CGPoint(
                x: center.x + (isSolar ? sunOffset : -sunOffset),
                y: center.y
            )

            // Corona glow at center when overlapping
            if eclipseProgress > 0.5 {
                let coronaOpacity = (eclipseProgress - 0.5) * 2 * 0.15
                let coronaRect = CGRect(
                    x: center.x - bodyRadius * 2.5, y: center.y - bodyRadius * 2.5,
                    width: bodyRadius * 5, height: bodyRadius * 5
                )
                context.fill(
                    Path(ellipseIn: coronaRect),
                    with: .color(eclipseBlue.opacity(coronaOpacity))
                )
            }

            // Draw sun (gold disc)
            let sunRect = CGRect(
                x: sunCenter.x - bodyRadius, y: sunCenter.y - bodyRadius,
                width: bodyRadius * 2, height: bodyRadius * 2
            )
            context.fill(Path(ellipseIn: sunRect), with: .color(gold.opacity(0.9)))

            // Draw moon (silver disc, slightly smaller for solar; same for lunar)
            let moonRadius = isSolar ? bodyRadius * 0.95 : bodyRadius
            let moonRect = CGRect(
                x: moonCenter.x - moonRadius, y: moonCenter.y - moonRadius,
                width: moonRadius * 2, height: moonRadius * 2
            )

            if isSolar {
                // Moon is dark (silhouette) for solar eclipse
                context.fill(Path(ellipseIn: moonRect), with: .color(Color(hex: "0B1026").opacity(0.95)))
            } else {
                // Moon is silver for lunar, shadow creeps across
                context.fill(Path(ellipseIn: moonRect), with: .color(silver.opacity(0.85)))

                // Earth shadow
                let shadowOffset = (1 - eclipseProgress) * bodyRadius * 2
                let shadowRect = CGRect(
                    x: moonCenter.x - bodyRadius + shadowOffset, y: moonCenter.y - bodyRadius,
                    width: bodyRadius * 2, height: bodyRadius * 2
                )
                context.fill(Path(ellipseIn: shadowRect), with: .color(Color(hex: "0B1026").opacity(0.8)))
            }
        }
        .frame(height: 180)
    }

    // MARK: - Contact Timeline

    private var contactTimeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CONTACT TIMES")
                .deviLabel(.caption, theme: theme)

            VStack(spacing: 4) {
                ForEach(eclipse.contactTimeline, id: \.label) { contact in
                    HStack {
                        Circle()
                            .fill(contact.label == "Maximum"
                                  ? eclipseBlue
                                  : theme.secondaryText.opacity(0.4))
                            .frame(width: contact.label == "Maximum" ? 8 : 5,
                                   height: contact.label == "Maximum" ? 8 : 5)
                        Text(contact.label)
                            .scaledFont(size: 13, weight: contact.label == "Maximum" ? .semibold : .regular)
                            .foregroundColor(contact.label == "Maximum" ? theme.primaryText : theme.secondaryText)
                        Spacer()
                        Text(deviFormatTime(contact.time, timezoneIdentifier: timezoneIdentifier))
                            .scaledFont(size: 13, weight: .medium, design: .monospaced)
                            .foregroundColor(theme.primaryText)
                    }
                }
            }
            .padding(12)
            .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
        }
    }

    // MARK: - Magnitude Bar

    private var magnitudeBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MAGNITUDE")
                    .deviLabel(.caption, theme: theme)
                Spacer()
                Text(String(format: "%.3f", eclipse.magnitude))
                    .scaledFont(size: 14, weight: .semibold, design: .monospaced)
                    .foregroundColor(eclipseBlue)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.primaryText.opacity(0.08))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(eclipseBlue)
                        .frame(width: geo.size.width * min(CGFloat(eclipse.magnitude), 1.0), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .deviCard(theme: theme, elevation: .flat, cornerRadius: 14)
    }

    // MARK: - Mythology

    private var mythologySection: some View {
        let info = PanchangDescriptions.eclipseInfo
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 12))
                        .foregroundColor(eclipseBlue)
                    Text("Samudra Manthan")
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundColor(theme.primaryText)
                }
                Text(info.mythology)
                    .deviLabel(.detail, theme: theme)
                    .lineSpacing(4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(eclipseBlue)
                    Text("Spiritual Significance")
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundColor(theme.primaryText)
                }
                Text(info.spiritualSignificance)
                    .deviLabel(.detail, theme: theme)
                    .lineSpacing(4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
        }
    }

    // MARK: - Mantras

    private var mantrasSection: some View {
        let info = PanchangDescriptions.eclipseInfo
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 12))
                    .foregroundColor(eclipseBlue)
                Text("Mantras for Eclipse")
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundColor(theme.primaryText)
            }

            ForEach(info.mantras, id: \.transliteration) { mantra in
                VStack(alignment: .leading, spacing: 6) {
                    Text(mantra.devanagari)
                        .scaledFont(size: 18, weight: .regular)
                        .foregroundColor(theme.primaryText.opacity(0.9))
                        .lineSpacing(4)

                    Text(mantra.transliteration)
                        .scaledFont(size: 13, weight: .regular, design: .serif)
                        .foregroundColor(theme.secondaryText)
                        .italic()

                    Text(mantra.purpose)
                        .scaledFont(size: 12, weight: .regular)
                        .foregroundColor(theme.secondaryText.opacity(0.7))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
    }

    // MARK: - Dos and Don'ts

    private var dosAndDontsSection: some View {
        let info = PanchangDescriptions.eclipseInfo
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(theme.auspiciousColor)
                    Text("Recommended")
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundColor(theme.primaryText)
                }
                ForEach(info.dosAndDonts.doItems, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\u{2022}").foregroundColor(theme.secondaryText)
                        Text(item).deviLabel(.detail, theme: theme)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(theme.inauspiciousColor)
                    Text("Avoid")
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundColor(theme.primaryText)
                }
                ForEach(info.dosAndDonts.dontItems, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\u{2022}").foregroundColor(theme.secondaryText)
                        Text(item).deviLabel(.detail, theme: theme)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
    }
}
