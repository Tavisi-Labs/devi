// MARK: - Views/Components/UpcomingEventsSheet.swift
// Full upcoming events list grouped by month, presented as a sheet

import SwiftUI

struct UpcomingEventsSheet: View {
    let eventsByMonth: [(month: String, events: [UpcomingEvent])]
    let theme: DeviTheme
    var onSelectEvent: ((UpcomingEvent) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(eventsByMonth.enumerated()), id: \.offset) { _, group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.month)
                                .deviLabel(.section, theme: theme)
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ForEach(Array(group.events.enumerated()), id: \.element.id) { index, event in
                                    Button {
                                        onSelectEvent?(event)
                                    } label: {
                                        eventRow(event)
                                    }
                                    .buttonStyle(.plain)

                                    if index < group.events.count - 1 {
                                        Divider()
                                            .background(theme.primaryText.opacity(0.08))
                                    }
                                }
                            }
                            .deviCard(theme: theme, elevation: .raised)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Upcoming Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.accentColor)
                }
            }
        }
    }

    private func eventRow(_ event: UpcomingEvent) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(eventDotColor(event.type))
                .frame(width: 6, height: 6)

            Text(event.name)
                .scaledFont(size: 15, weight: .medium)
                .foregroundColor(theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            Text("\(event.daysAway)d")
                .scaledFont(size: 11, weight: .semibold)
                .foregroundColor(theme.secondaryText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(theme.primaryText.opacity(0.06))
                .clipShape(Capsule())

            Text(event.formattedDate)
                .scaledFont(size: 13, weight: .regular)
                .foregroundColor(theme.secondaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func eventDotColor(_ type: UpcomingEvent.EventType) -> Color {
        switch type {
        case .fasting:  return Color(hex: "c54b2a")
        case .eclipse:  return Color(hex: "7B8EC4")
        case .festival: return theme.accentColor
        }
    }
}
