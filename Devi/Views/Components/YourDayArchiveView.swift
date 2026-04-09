// MARK: - Views/Components/YourDayArchiveView.swift
// Tier-2 sheet showing the persistent archive of the user's recent "Your Day"
// readings. Snapshots are recorded by PanchangViewModel on each real-day load
// and stored in DaySnapshotStore (UserDefaults, capped at 90 entries).
//
// Layout: NavigationStack + ScrollView + LazyVStack of compact cards,
// newest-first. Tap a row to expand it in place and reveal the full
// supporting text, category summaries, mantra, and cosmic signature.

import SwiftUI

struct YourDayArchiveView: View {

    // MARK: - Inputs

    let snapshots: [DaySnapshot]
    let theme: DeviTheme

    // MARK: - State

    @State private var expandedID: String?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if snapshots.isEmpty {
                    emptyState
                        .padding(.top, 80)
                        .padding(.horizontal, 24)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(Array(snapshots.enumerated()), id: \.element.id) { index, snapshot in
                            row(for: snapshot)
                                .deviReveal(
                                    delay: min(0.04 * Double(index), 0.3),
                                    direction: .fadeUp
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Your Day Archive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.accentColor)
                }
            }
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func row(for snapshot: DaySnapshot) -> some View {
        let isExpanded = expandedID == snapshot.id

        VStack(alignment: .leading, spacing: 12) {
            // Date header + tithi/nakshatra chip row
            header(for: snapshot)

            // Theme statement (serif)
            if let themeStatement = snapshot.themeStatement, !themeStatement.isEmpty {
                Text(themeStatement)
                    .scaledFont(size: 18, weight: .regular, design: .serif)
                    .foregroundColor(theme.primaryText)
                    .lineLimit(isExpanded ? nil : 2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Supporting text (collapsed = 2 lines preview, expanded = full)
            if let supporting = snapshot.supportingText, !supporting.isEmpty {
                Text(supporting)
                    .deviLabel(.body, theme: theme)
                    .lineLimit(isExpanded ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Expanded-only content
            if isExpanded {
                expandedContent(for: snapshot)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Footer chips
            footer(for: snapshot)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .raised)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                expandedID = isExpanded ? nil : snapshot.id
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(isExpanded ? "Tap to collapse" : "Tap to expand")
    }

    // MARK: - Row Sections

    private func header(for snapshot: DaySnapshot) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(displayDate(for: snapshot.dateString))
                .scaledFont(size: 13, weight: .bold)
                .foregroundColor(theme.secondaryText)
                .tracking(1.5)
                .textCase(.uppercase)

            Spacer(minLength: 8)

            // Tithi chip
            chip(text: snapshot.tithiDisplayName)
            // Nakshatra chip
            chip(text: snapshot.nakshatraName)
        }
    }

    private func chip(text: String) -> some View {
        Text(text)
            .scaledFont(size: 10, weight: .medium)
            .foregroundColor(theme.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(theme.secondaryText.opacity(0.10))
            )
            .overlay(
                Capsule().stroke(theme.secondaryText.opacity(0.20), lineWidth: 0.5)
            )
            .lineLimit(1)
    }

    @ViewBuilder
    private func expandedContent(for snapshot: DaySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Category summaries (love / work / spirituality / health)
            if !snapshot.categorySummaries.isEmpty {
                Divider().background(theme.secondaryText.opacity(0.15))

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(categoryOrder, id: \.self) { key in
                        if let summary = snapshot.categorySummaries[key], !summary.isEmpty {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(key.uppercased())
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(theme.secondaryText)
                                    .tracking(1.2)
                                Text(summary)
                                    .deviLabel(.body, theme: theme)
                            }
                        }
                    }
                }
            }

            // Cosmic signature
            if let signature = snapshot.cosmicSignature, !signature.isEmpty {
                Divider().background(theme.secondaryText.opacity(0.15))

                VStack(alignment: .leading, spacing: 4) {
                    Text("COSMIC SIGNATURE")
                        .scaledFont(size: 10, weight: .bold)
                        .foregroundColor(theme.secondaryText)
                        .tracking(1.2)
                    Text(signature)
                        .scaledFont(size: 14, weight: .regular, design: .serif)
                        .foregroundColor(theme.primaryText)
                        .lineSpacing(3)
                }
            }

            // Mantra
            if let sanskrit = snapshot.mantraSanskrit, !sanskrit.isEmpty {
                Divider().background(theme.secondaryText.opacity(0.15))

                VStack(alignment: .leading, spacing: 4) {
                    Text("MANTRA")
                        .scaledFont(size: 10, weight: .bold)
                        .foregroundColor(theme.secondaryText)
                        .tracking(1.2)
                    Text(sanskrit)
                        .scaledFont(size: 15, weight: .medium, design: .serif)
                        .foregroundColor(theme.primaryText)
                    if let translation = snapshot.mantraTranslation, !translation.isEmpty {
                        Text(translation)
                            .deviLabel(.detail, theme: theme)
                    }
                }
            }
        }
    }

    private func footer(for snapshot: DaySnapshot) -> some View {
        HStack(spacing: 8) {
            // Festival chips (up to 2)
            ForEach(Array(snapshot.festivals.prefix(2).enumerated()), id: \.offset) { _, festival in
                Text(festival)
                    .scaledFont(size: 10, weight: .medium)
                    .foregroundColor(theme.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(theme.accentColor.opacity(0.10))
                    )
                    .overlay(
                        Capsule().stroke(theme.accentColor.opacity(0.25), lineWidth: 0.5)
                    )
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            // Ritual completion dot
            if snapshot.ritualCompleted {
                HStack(spacing: 4) {
                    Circle()
                        .fill(theme.auspiciousColor)
                        .frame(width: 6, height: 6)
                    Text("Ritual complete")
                        .scaledFont(size: 10, weight: .medium)
                        .foregroundColor(theme.secondaryText)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(theme.secondaryText.opacity(0.5))

            Text("Your readings will appear here as you use Devi each day.")
                .scaledFont(size: 15, weight: .regular)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Helpers

    /// Fixed display order for category summaries — mirrors HoroscopeCategory.allCases.
    private var categoryOrder: [String] {
        ["love", "work", "spirituality", "health"]
    }

    /// Format a "yyyy-MM-dd" string as a human-readable header
    /// (e.g. "Tue, Apr 7"). Uses the user's current locale.
    private func displayDate(for dateString: String) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.timeZone = TimeZone(identifier: "UTC")

        guard let date = parser.date(from: dateString) else { return dateString }

        let output = DateFormatter()
        output.dateFormat = "EEE, MMM d"
        return output.string(from: date)
    }
}
