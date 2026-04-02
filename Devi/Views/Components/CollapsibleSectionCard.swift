// MARK: - Views/Components/CollapsibleSectionCard.swift
// Reusable collapsible section wrapper with persistent expand/collapse state

import SwiftUI

/// A collapsible section that persists its expanded/collapsed state via UserDefaults.
///
/// Usage:
/// ```
/// CollapsibleSectionCard("HORA", theme: theme, sectionKey: "hora") {
///     // Peek content (visible when collapsed) — e.g. current hora summary
///     Text("Sun Hora until 2:30 PM")
/// } content: {
///     // Full content (visible when expanded)
///     HoraCard(...)
/// }
/// ```
struct CollapsibleSectionCard<Peek: View, Content: View>: View {
    let title: String
    let theme: DeviTheme
    let sectionKey: String
    let peek: Peek
    let content: Content

    @State private var isCollapsed: Bool

    @Environment(\.deviFontScale) private var scale

    // MARK: - Init

    init(
        _ title: String,
        theme: DeviTheme,
        sectionKey: String,
        isCollapsedDefault: Bool = true,
        @ViewBuilder peek: () -> Peek,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.theme = theme
        self.sectionKey = sectionKey
        self.peek = peek()
        self.content = content()

        // Read persisted state, falling back to the provided default
        let key = "collapsed.\(sectionKey)"
        let stored = UserDefaults.standard.object(forKey: key) as? Bool
        _isCollapsed = State(initialValue: stored ?? isCollapsedDefault)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header row — tappable to toggle
            headerRow
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleCollapsed()
                }

            if isCollapsed {
                // Collapsed: show peek content + "Show all" hint
                collapsedBody
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                // Expanded: show full content
                expandedBody
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 10) {
            line

            HStack(spacing: 6) {
                Text(title)
                    .scaledFont(size: 12, weight: .semibold)
                    .foregroundColor(theme.secondaryText)
                    .textCase(.uppercase)
                    .tracking(2.0)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Image(systemName: "chevron.right")
                    .scaledFont(size: 10, weight: .semibold)
                    .foregroundColor(theme.secondaryText)
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
            }
            .fixedSize()

            line
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private var line: some View {
        Rectangle()
            .fill(theme.primaryText.opacity(0.10))
            .frame(height: 0.5)
    }

    // MARK: - Collapsed State

    private var collapsedBody: some View {
        VStack(spacing: 8) {
            peek
                .padding(.horizontal)

            Text("Show all")
                .scaledFont(size: 13, weight: .medium)
                .foregroundColor(theme.accentColor)
                .padding(.bottom, 4)
        }
        .padding(.top, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            toggleCollapsed()
        }
    }

    // MARK: - Expanded State

    private var expandedBody: some View {
        content
            .padding(.top, 8)
    }

    // MARK: - Toggle

    private func toggleCollapsed() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isCollapsed.toggle()
        }
        // Persist to UserDefaults
        UserDefaults.standard.set(isCollapsed, forKey: "collapsed.\(sectionKey)")
    }
}

// MARK: - Convenience Init (no peek content)

extension CollapsibleSectionCard where Peek == EmptyView {
    /// Creates a collapsible section without peek content.
    /// When collapsed, only the header and "Show all" text are visible.
    init(
        _ title: String,
        theme: DeviTheme,
        sectionKey: String,
        isCollapsedDefault: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title,
            theme: theme,
            sectionKey: sectionKey,
            isCollapsedDefault: isCollapsedDefault,
            peek: { EmptyView() },
            content: content
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "0B1026").ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                // With peek content
                CollapsibleSectionCard(
                    "HORA",
                    theme: DeviTheme.forPeriod(.evening),
                    sectionKey: "preview_hora",
                    isCollapsedDefault: true
                ) {
                    // Peek
                    HStack {
                        Text("☉ Sun Hora until 2:30 PM")
                            .scaledFont(size: 14, weight: .regular)
                            .foregroundColor(DeviTheme.forPeriod(.evening).primaryText)
                    }
                } content: {
                    // Full content
                    VStack(spacing: 12) {
                        ForEach(0..<5) { i in
                            HStack {
                                Text("Hora \(i + 1)")
                                Spacer()
                                Text("1:00 - 2:00 PM")
                            }
                            .scaledFont(size: 14, weight: .regular)
                            .foregroundColor(DeviTheme.forPeriod(.evening).primaryText)
                            .padding(.horizontal)
                        }
                    }
                }

                // Without peek content
                CollapsibleSectionCard(
                    "TIME WINDOWS",
                    theme: DeviTheme.forPeriod(.evening),
                    sectionKey: "preview_time_windows",
                    isCollapsedDefault: false
                ) {
                    VStack(spacing: 8) {
                        Text("Rahu Kalam: 4:30 - 6:00 PM")
                        Text("Yama Gandam: 12:00 - 1:30 PM")
                    }
                    .scaledFont(size: 14, weight: .regular)
                    .foregroundColor(DeviTheme.forPeriod(.evening).primaryText)
                    .padding(.horizontal)
                }
            }
            .padding(.top, 40)
        }
    }
}
