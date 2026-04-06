// MARK: - Views/Components/ImmersiveDetailRouter.swift
// Routes immersive full-screen element views

import SwiftUI

struct ImmersiveDetailRouter: View {
    @ObservedObject var vm: PanchangViewModel
    let element: PanchangElement
    let theme: DeviTheme
    let timezoneIdentifier: String
    let cityName: String
    var panchangContext: DailyPanchang?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        switch element {
        case .tithi(let tithi):
            TithiImmersiveView(
                tithi: tithi,
                theme: theme,
                timezoneIdentifier: timezoneIdentifier,
                panchangContext: panchangContext
            )
        case .nakshatra(let nakshatra):
            NakshatraImmersiveView(
                nakshatra: nakshatra,
                theme: theme,
                timezoneIdentifier: timezoneIdentifier
            )
        case .eclipse(let eclipse):
            EclipseImmersiveView(
                eclipse: eclipse,
                theme: theme,
                timezoneIdentifier: timezoneIdentifier
            )
        case .navratriDay(let day):
            NavratriImmersiveView(
                day: day,
                theme: theme,
                timezoneIdentifier: timezoneIdentifier
            )
        case .hora(let hora):
            HoraImmersiveView(
                hora: hora,
                allHoras: panchangContext?.horas ?? [],
                theme: theme,
                timezoneIdentifier: timezoneIdentifier
            )
        case .vedicSky:
            VedicSkyView(
                theme: theme,
                timezoneIdentifier: timezoneIdentifier
            )
        default:
            // Fallback — shouldn't be reached via router
            VStack {
                Spacer()
                Text("View not available")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .overlay(alignment: .topLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
    }
}
